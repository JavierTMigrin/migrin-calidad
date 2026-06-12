# Genera supabase-vistas-analisis.sql a partir de supabase-vistas-excel.sql
# Por cada producto con granulometria crea:
#   v_<planta>_<producto>_serie : formato largo (1 fila por ensayo x tamiz)
#                                 rp / ra / pasante + moviles + EETT + estado
#   v_<planta>_<producto>_carta : carta de control por tamiz (n, media, desv,
#                                 LCS/LCI 3 sigma, cv, min/max, % cumplimiento)
$ErrorActionPreference = 'Stop'
$dir  = $PSScriptRoot
$src  = Join-Path $dir 'supabase-vistas-excel.sql'
$dst  = Join-Path $dir 'supabase-vistas-analisis.sql'
$txt  = [System.IO.File]::ReadAllText($src)

function Get-Planta([string]$name){
  if($name -match '^desp_'){ return 'despachos' }
  if($name -match '^tt_'){ return 'turco' }
  if($name -in @('alim_cuarzo','tlh_cuarzo','compacta','dlk','lodos_cuarzo')){ return 'cuarzo' }
  return 'arenas'
}
function Get-Short([string]$name){
  if($name -match '^desp_(.+)$'){ return $Matches[1] }
  if($name -match '^tt_(.+)$'){ return $Matches[1] }
  if($name -match '^(alim|tlh)_cuarzo$'){ return $Matches[1] }
  return $name
}

# ── Parsear bloques de vistas del archivo fuente ──
$products = @()
foreach($block in ($txt -split '(?=CREATE OR REPLACE VIEW )')){
  if($block -notmatch 'CREATE OR REPLACE VIEW (v_\w+) AS'){ continue }
  $vname = $Matches[1] -replace '^v_',''
  if($block -notmatch "WHERE producto_key = '(\w+)'"){ continue }
  $key = $Matches[1]
  $sieves = @()
  foreach($m in [regex]::Matches($block, "REPLACE\(granu->>(\d+),',','\.'\),''\)::numeric / NULLIF\(peso_final,0\) \* 100, 2\) AS rp_(\w+)")){
    $sieves += [pscustomobject]@{ ord=[int]$m.Groups[1].Value; label='#'+$m.Groups[2].Value }
  }
  if($sieves.Count -eq 0){ continue }
  $products += [pscustomobject]@{
    key=$key; vname=$vname; planta=(Get-Planta $vname); short=(Get-Short $vname); sieves=$sieves
  }
}

$plantaOrder = @('arenas','despachos','cuarzo','turco')
$products = $products | Sort-Object @{e={$plantaOrder.IndexOf($_.planta)}}, short

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine(@"
-- ============================================================
-- MIGRIN Control de Calidad - Vistas de ANALISIS GRANULOMETRICO
-- Ejecutar en el SQL Editor de Supabase (despues de folio + vistas base).
--
-- Por cada producto con granulometria se crean 2 vistas:
--
--  v_<planta>_<producto>_serie  (formato largo: 1 fila por ensayo x tamiz)
--    orden_tamiz, tamiz          : banda granulometrica en orden
--    ret_parcial                 : retenido parcial % (masa/peso final*100)
--    ret_acumulado               : retenido acumulado %
--    pasante_acum                : pasante acumulado % (100 - acumulado)
--    rp_movil_7 / rp_movil_30    : promedio movil del ret. parcial
--    ra_movil_7                  : promedio movil del ret. acumulado
--    eett_*                      : limites EETT vigentes (tabla especificaciones)
--    estado_eett                 : OK / FUERA / null (sin EETT definida)
--
--  v_<planta>_<producto>_carta  (carta de control: 1 fila por tamiz)
--    n_datos, media, desv_std, cv%, LCS/LCI (3 sigma), min/max,
--    limites EETT, n_fuera y % de cumplimiento
--
-- Conexion Excel/Power BI igual que las vistas base:
--   https://wxjclxmtceuhlbwxtptc.supabase.co/rest/v1/<vista>?select=*
-- ============================================================

-- Funcion auxiliar: texto con coma decimal -> numeric (null si vacio)
CREATE OR REPLACE FUNCTION num_seguro(t TEXT) RETURNS numeric
LANGUAGE sql IMMUTABLE AS `$`$ SELECT NULLIF(REPLACE(t,',','.'),'')::numeric `$`$;
"@)

# DROP de todas las vistas de analisis
$allNames = @()
foreach($p in $products){
  $allNames += "v_$($p.planta)_$($p.short)_serie"
  $allNames += "v_$($p.planta)_$($p.short)_carta"
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('-- Borrar versiones previas:')
[void]$sb.AppendLine('DROP VIEW IF EXISTS ' + ($allNames -join ', ') + ' CASCADE;')

$curPlanta = ''
foreach($p in $products){
  if($p.planta -ne $curPlanta){
    $curPlanta = $p.planta
    $up = $curPlanta.ToUpper()
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('-- ============================================================')
    [void]$sb.AppendLine("-- PLANTA: $up")
    [void]$sb.AppendLine('-- ============================================================')
  }
  $serie = "v_$($p.planta)_$($p.short)_serie"
  $carta = "v_$($p.planta)_$($p.short)_carta"
  $values = ($p.sieves | ForEach-Object { "($($_.ord),'$($_.label)')" }) -join ','
  $nota = if($p.key -eq 'TT_CILINDRO'){ ' (solo granulometria de ENTRADA)' } else { '' }

  [void]$sb.AppendLine(@"

-- ── $($p.key)$nota ──
CREATE OR REPLACE VIEW $serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES $values) AS t(ord,tamiz)
  WHERE e.producto_key = '$($p.key)'
),
acum AS (
  SELECT l.*, ROUND(SUM(l.rp) OVER (PARTITION BY l.id ORDER BY l.ord), 2) AS ra
  FROM largo l
),
con_lims AS (
  SELECT a.*,
    num_seguro(s.specs->'granulometria'->a.tamiz->>'retMin')     AS eett_rp_min,
    num_seguro(s.specs->'granulometria'->a.tamiz->>'retMax')     AS eett_rp_max,
    num_seguro(s.specs->'granulometria'->a.tamiz->>'retAcumMin') AS eett_ra_min,
    num_seguro(s.specs->'granulometria'->a.tamiz->>'retAcumMax') AS eett_ra_max,
    num_seguro(s.specs->'granulometria'->a.tamiz->>'pasMin')     AS eett_pas_min,
    num_seguro(s.specs->'granulometria'->a.tamiz->>'pasMax')     AS eett_pas_max
  FROM acum a
  LEFT JOIN especificaciones s ON s.producto_key = '$($p.key)'
)
SELECT
  c.folio, c.fecha_muestreo, c.turno, c.analista, c.tipo_muestra, c.num_acopio,
  c.ord AS orden_tamiz, c.tamiz,
  c.rp AS ret_parcial,
  c.ra AS ret_acumulado,
  ROUND(100 - c.ra, 2) AS pasante_acum,
  ROUND(AVG(c.rp) OVER w7, 2)  AS rp_movil_7,
  ROUND(AVG(c.rp) OVER w30, 2) AS rp_movil_30,
  ROUND(AVG(c.ra) OVER w7, 2)  AS ra_movil_7,
  c.eett_rp_min, c.eett_rp_max, c.eett_ra_min, c.eett_ra_max,
  c.eett_pas_min, c.eett_pas_max,
  CASE
    WHEN c.eett_rp_min IS NULL AND c.eett_rp_max IS NULL AND c.eett_ra_min IS NULL
     AND c.eett_ra_max IS NULL AND c.eett_pas_min IS NULL AND c.eett_pas_max IS NULL
    THEN NULL
    WHEN (c.eett_rp_min  IS NOT NULL AND c.rp < c.eett_rp_min)
      OR (c.eett_rp_max  IS NOT NULL AND c.rp > c.eett_rp_max)
      OR (c.eett_ra_min  IS NOT NULL AND c.ra < c.eett_ra_min)
      OR (c.eett_ra_max  IS NOT NULL AND c.ra > c.eett_ra_max)
      OR (c.eett_pas_min IS NOT NULL AND (100 - c.ra) < c.eett_pas_min)
      OR (c.eett_pas_max IS NOT NULL AND (100 - c.ra) > c.eett_pas_max)
    THEN 'FUERA'
    ELSE 'OK'
  END AS estado_eett
FROM con_lims c
WINDOW
  w7  AS (PARTITION BY c.tamiz ORDER BY c.fecha_muestreo, c.created_at ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),
  w30 AS (PARTITION BY c.tamiz ORDER BY c.fecha_muestreo, c.created_at ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
ORDER BY c.fecha_muestreo DESC, c.created_at DESC, c.ord;

CREATE OR REPLACE VIEW $carta AS
SELECT
  tamiz,
  MIN(orden_tamiz)                                            AS orden_tamiz,
  COUNT(ret_parcial)                                          AS n_datos,
  ROUND(AVG(ret_parcial), 2)                                  AS media_rp,
  ROUND(STDDEV_SAMP(ret_parcial), 3)                          AS desv_std_rp,
  ROUND(STDDEV_SAMP(ret_parcial)/NULLIF(AVG(ret_parcial),0)*100, 1) AS cv_rp_pct,
  ROUND(AVG(ret_parcial) + 3*STDDEV_SAMP(ret_parcial), 2)     AS lcs_rp_3s,
  ROUND(GREATEST(AVG(ret_parcial) - 3*STDDEV_SAMP(ret_parcial), 0), 2) AS lci_rp_3s,
  ROUND(MIN(ret_parcial), 2)                                  AS min_rp,
  ROUND(MAX(ret_parcial), 2)                                  AS max_rp,
  ROUND(AVG(ret_acumulado), 2)                                AS media_ra,
  ROUND(STDDEV_SAMP(ret_acumulado), 3)                        AS desv_std_ra,
  ROUND(AVG(ret_acumulado) + 3*STDDEV_SAMP(ret_acumulado), 2) AS lcs_ra_3s,
  ROUND(GREATEST(AVG(ret_acumulado) - 3*STDDEV_SAMP(ret_acumulado), 0), 2) AS lci_ra_3s,
  ROUND(AVG(pasante_acum), 2)                                 AS media_pasante,
  MAX(eett_rp_min)  AS eett_rp_min,  MAX(eett_rp_max)  AS eett_rp_max,
  MAX(eett_ra_min)  AS eett_ra_min,  MAX(eett_ra_max)  AS eett_ra_max,
  MAX(eett_pas_min) AS eett_pas_min, MAX(eett_pas_max) AS eett_pas_max,
  COUNT(*) FILTER (WHERE estado_eett = 'FUERA')               AS n_fuera,
  ROUND(COUNT(*) FILTER (WHERE estado_eett = 'OK')::numeric
        / NULLIF(COUNT(*) FILTER (WHERE estado_eett IS NOT NULL), 0) * 100, 1) AS pct_cumplimiento
FROM $serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);
"@)
}

[void]$sb.AppendLine('')
[void]$sb.AppendLine('-- Permisos de lectura:')
[void]$sb.AppendLine('GRANT SELECT ON ' + ($allNames -join ', ') + ' TO anon, authenticated;')

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($dst, $sb.ToString(), $utf8NoBom)
Write-Host "Generado: $dst"
Write-Host "Productos: $($products.Count) | Vistas: $($allNames.Count)"
$products | ForEach-Object { Write-Host ("  {0,-10} {1,-22} {2}" -f $_.planta, $_.short, $_.key) }
