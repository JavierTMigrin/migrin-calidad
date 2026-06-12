# Genera la carpeta consultas_sql/ con consultas estadisticas
# organizadas por planta y producto, basadas en las vistas
# (supabase-vistas-excel.sql + supabase-vistas-analisis.sql).
$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$src = Join-Path $dir 'supabase-vistas-excel.sql'
$out = Join-Path $dir 'consultas_sql'
$txt = [System.IO.File]::ReadAllText($src)
$utf8 = New-Object System.Text.UTF8Encoding($false)

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

# Parsear productos con granulometria (rp_) y su vista base
$products = @()
foreach($block in ($txt -split '(?=CREATE OR REPLACE VIEW )')){
  if($block -notmatch 'CREATE OR REPLACE VIEW (v_\w+) AS'){ continue }
  $vbase = $Matches[1]
  $name = $vbase -replace '^v_',''
  if($name -eq 'ensayos_todos'){ continue }
  if($block -notmatch "WHERE producto_key = '(\w+)'"){ continue }
  $key = $Matches[1]
  $hasGranu = $block -match ' AS rp_'
  $hasQuim  = $block -match ' AS sio2'
  $products += [pscustomobject]@{
    key=$key; vbase=$vbase; planta=(Get-Planta $name); short=(Get-Short $name)
    hasGranu=$hasGranu; hasQuim=$hasQuim
  }
}

if(Test-Path $out){ Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Path $out | Out-Null

$nFiles = 0
foreach($p in $products){
  $pdir = Join-Path $out (Join-Path $p.planta $p.short)
  New-Item -ItemType Directory -Path $pdir -Force | Out-Null
  $serie = "v_$($p.planta)_$($p.short)_serie"
  $carta = "v_$($p.planta)_$($p.short)_carta"
  $hdr = "-- Producto: $($p.key) | Planta: $($p.planta.ToUpper())`n-- Ejecutar en el SQL Editor de Supabase.`n"

  # 01: ultimos ensayos (vista base, datos del formulario)
  $q = @"
$hdr-- Ultimos 50 ensayos con todos los datos del formulario.
SELECT * FROM $($p.vbase)
ORDER BY fecha_muestreo DESC, created_at DESC
LIMIT 50;
"@
  [System.IO.File]::WriteAllText((Join-Path $pdir '01_ultimos_ensayos.sql'), $q, $utf8); $nFiles++

  if($p.hasGranu){
    # 02: serie granulometrica completa
    $q = @"
$hdr-- Serie granulometrica completa: retenido parcial, acumulado y
-- pasante por tamiz, con promedios moviles y limites EETT.
SELECT * FROM $serie;
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '02_serie_granulometrica.sql'), $q, $utf8); $nFiles++

    # 03: carta de control
    $q = @"
$hdr-- Carta de control por tamiz: n, media, desviacion estandar,
-- coef. de variacion, limites +/-3 sigma, EETT y % cumplimiento.
SELECT * FROM $carta;
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '03_carta_de_control.sql'), $q, $utf8); $nFiles++

    # 04: fuera de norma
    $q = @"
$hdr-- Mediciones FUERA de los limites EETT (requiere EETT cargada en Ajustes).
SELECT folio, fecha_muestreo, turno, analista, tamiz,
       ret_parcial, ret_acumulado, pasante_acum,
       eett_rp_min, eett_rp_max, eett_ra_min, eett_ra_max,
       eett_pas_min, eett_pas_max
FROM $serie
WHERE estado_eett = 'FUERA'
ORDER BY fecha_muestreo DESC, orden_tamiz;
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '04_fuera_de_norma.sql'), $q, $utf8); $nFiles++

    # 05: resumen mensual
    $q = @"
$hdr-- Resumen estadistico MENSUAL por tamiz del retenido parcial:
-- n, media, desv std, min, max y % de cumplimiento EETT.
SELECT
  TO_CHAR(fecha_muestreo::date, 'YYYY-MM') AS mes,
  tamiz,
  MIN(orden_tamiz)                  AS orden_tamiz,
  COUNT(ret_parcial)                AS n_datos,
  ROUND(AVG(ret_parcial), 2)        AS media_rp,
  ROUND(STDDEV_SAMP(ret_parcial),3) AS desv_std_rp,
  ROUND(MIN(ret_parcial), 2)        AS min_rp,
  ROUND(MAX(ret_parcial), 2)        AS max_rp,
  ROUND(AVG(ret_acumulado), 2)      AS media_ra,
  ROUND(COUNT(*) FILTER (WHERE estado_eett='OK')::numeric
    / NULLIF(COUNT(*) FILTER (WHERE estado_eett IS NOT NULL),0)*100, 1) AS pct_cumplimiento
FROM $serie
GROUP BY 1, 2
ORDER BY mes DESC, orden_tamiz;
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '05_resumen_mensual.sql'), $q, $utf8); $nFiles++

    # 06: comparativa por turno
    $q = @"
$hdr-- Comparativa del retenido parcial promedio por TURNO y tamiz.
SELECT
  tamiz,
  MIN(orden_tamiz) AS orden_tamiz,
  turno,
  COUNT(ret_parcial)                AS n_datos,
  ROUND(AVG(ret_parcial), 2)        AS media_rp,
  ROUND(STDDEV_SAMP(ret_parcial),3) AS desv_std_rp
FROM $serie
WHERE turno IS NOT NULL
GROUP BY tamiz, turno
ORDER BY orden_tamiz, turno;
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '06_comparativa_turnos.sql'), $q, $utf8); $nFiles++

    # 07: comparativa por analista
    $q = @"
$hdr-- Comparativa del retenido parcial promedio por ANALISTA y tamiz
-- (util para detectar sesgos de medicion entre analistas).
SELECT
  tamiz,
  MIN(orden_tamiz) AS orden_tamiz,
  analista,
  COUNT(ret_parcial)                AS n_datos,
  ROUND(AVG(ret_parcial), 2)        AS media_rp,
  ROUND(STDDEV_SAMP(ret_parcial),3) AS desv_std_rp
FROM $serie
GROUP BY tamiz, analista
ORDER BY orden_tamiz, analista;
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '07_comparativa_analistas.sql'), $q, $utf8); $nFiles++

    # 08: tendencia con moviles (ultimo tamiz critico configurable)
    $q = @"
$hdr-- Tendencia temporal de UN tamiz: valores + promedios moviles.
-- Cambia '#100' por el tamiz que quieras analizar.
SELECT folio, fecha_muestreo, turno, analista,
       ret_parcial, rp_movil_7, rp_movil_30,
       ret_acumulado, ra_movil_7, estado_eett
FROM $serie
WHERE tamiz = '#100'
ORDER BY fecha_muestreo, folio;
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '08_tendencia_un_tamiz.sql'), $q, $utf8); $nFiles++
  }

  if($p.hasQuim){
    # 09: estadistica quimica
    $q = @"
$hdr-- Estadistica de la quimica: n, media, desv std, min, max por oxido.
SELECT 'SiO2' AS oxido, COUNT(sio2) AS n, ROUND(AVG(sio2),3) AS media,
       ROUND(STDDEV_SAMP(sio2),4) AS desv_std, MIN(sio2) AS minimo, MAX(sio2) AS maximo FROM $($p.vbase)
UNION ALL
SELECT 'Al2O3', COUNT(al2o3), ROUND(AVG(al2o3),3), ROUND(STDDEV_SAMP(al2o3),4), MIN(al2o3), MAX(al2o3) FROM $($p.vbase)
UNION ALL
SELECT 'Fe2O3', COUNT(fe2o3), ROUND(AVG(fe2o3),3), ROUND(STDDEV_SAMP(fe2o3),4), MIN(fe2o3), MAX(fe2o3) FROM $($p.vbase)
UNION ALL
SELECT 'CaO', COUNT(cao), ROUND(AVG(cao),3), ROUND(STDDEV_SAMP(cao),4), MIN(cao), MAX(cao) FROM $($p.vbase)
UNION ALL
SELECT 'MgO', COUNT(mgo), ROUND(AVG(mgo),3), ROUND(STDDEV_SAMP(mgo),4), MIN(mgo), MAX(mgo) FROM $($p.vbase)
UNION ALL
SELECT 'K2O', COUNT(k2o), ROUND(AVG(k2o),3), ROUND(STDDEV_SAMP(k2o),4), MIN(k2o), MAX(k2o) FROM $($p.vbase)
UNION ALL
SELECT 'Na2O', COUNT(na2o), ROUND(AVG(na2o),3), ROUND(STDDEV_SAMP(na2o),4), MIN(na2o), MAX(na2o) FROM $($p.vbase)
UNION ALL
SELECT 'TiO2', COUNT(tio2), ROUND(AVG(tio2),3), ROUND(STDDEV_SAMP(tio2),4), MIN(tio2), MAX(tio2) FROM $($p.vbase);
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '09_estadistica_quimica.sql'), $q, $utf8); $nFiles++

    # 10: evolucion quimica con movil
    $q = @"
$hdr-- Evolucion de Fe2O3 y SiO2 en el tiempo con promedio movil de 7.
SELECT folio, fecha_muestreo, turno, analista, sio2, fe2o3,
  ROUND(AVG(fe2o3) OVER (ORDER BY fecha_muestreo, created_at
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 4) AS fe2o3_movil_7,
  ROUND(AVG(sio2) OVER (ORDER BY fecha_muestreo, created_at
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 3) AS sio2_movil_7
FROM $($p.vbase)
ORDER BY fecha_muestreo, created_at;
"@
    [System.IO.File]::WriteAllText((Join-Path $pdir '10_evolucion_quimica.sql'), $q, $utf8); $nFiles++
  }
}

# README de la carpeta
$readme = @"
# Consultas SQL — Control de Calidad MIGRIN

Consultas estadisticas listas para pegar en el SQL Editor de Supabase,
organizadas por planta y producto:

``consultas_sql/<planta>/<producto>/<nn>_<consulta>.sql``

| Archivo | Que entrega |
|---|---|
| 01_ultimos_ensayos | Ultimos 50 registros con todos los datos del formulario |
| 02_serie_granulometrica | rp/ra/pasante por tamiz + moviles 7 y 30 + EETT + estado |
| 03_carta_de_control | n, media, desv std, CV, LCS/LCI 3 sigma, % cumplimiento |
| 04_fuera_de_norma | Solo mediciones que violan la EETT |
| 05_resumen_mensual | Estadistica mensual por tamiz |
| 06_comparativa_turnos | Media y desv por turno |
| 07_comparativa_analistas | Media y desv por analista (sesgos de medicion) |
| 08_tendencia_un_tamiz | Serie temporal de un tamiz (editable) |
| 09_estadistica_quimica | n/media/desv/min/max por oxido |
| 10_evolucion_quimica | Fe2O3 y SiO2 en el tiempo con movil 7 |

Requisitos: haber ejecutado supabase-eett-setup.sql,
supabase-folio-setup.sql, supabase-vistas-excel.sql y
supabase-vistas-analisis.sql.

Las consultas tambien sirven via REST para Excel agregando los filtros
a la URL de la vista (ver CONEXION_EXCEL.md). Esta carpeta se regenera
con ``gen-consultas-sql.ps1``.
"@
[System.IO.File]::WriteAllText((Join-Path $out 'README.md'), $readme, $utf8)

Write-Host "Productos: $($products.Count) | Archivos SQL: $nFiles"
