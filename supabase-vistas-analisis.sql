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
LANGUAGE sql IMMUTABLE AS $$ SELECT NULLIF(REPLACE(t,',','.'),'')::numeric $$;

-- Borrar versiones previas:
DROP VIEW IF EXISTS v_arenas_a36_serie, v_arenas_a36_carta, v_arenas_a38_serie, v_arenas_a38_carta, v_arenas_alimentacion_serie, v_arenas_alimentacion_carta, v_arenas_lodos_arenas_serie, v_arenas_lodos_arenas_carta, v_arenas_molino_1_serie, v_arenas_molino_1_carta, v_arenas_molino_2_serie, v_arenas_molino_2_carta, v_arenas_muestras_esp_serie, v_arenas_muestras_esp_carta, v_arenas_over_2007_serie, v_arenas_over_2007_carta, v_arenas_rechazo_2001_serie, v_arenas_rechazo_2001_carta, v_arenas_under_2007_serie, v_arenas_under_2007_carta, v_arenas_under_tack_serie, v_arenas_under_tack_carta, v_arenas_veralia_alta_serie, v_arenas_veralia_alta_carta, v_arenas_veralia_baja_serie, v_arenas_veralia_baja_carta, v_despachos_lirquen_serie, v_despachos_lirquen_carta, v_despachos_llayllay_serie, v_despachos_llayllay_carta, v_despachos_padre_hurtado_serie, v_despachos_padre_hurtado_carta, v_cuarzo_alim_serie, v_cuarzo_alim_carta, v_cuarzo_compacta_serie, v_cuarzo_compacta_carta, v_cuarzo_dlk_serie, v_cuarzo_dlk_carta, v_cuarzo_lodos_cuarzo_serie, v_cuarzo_lodos_cuarzo_carta, v_cuarzo_tlh_serie, v_cuarzo_tlh_carta, v_turco_alimentacion_serie, v_turco_alimentacion_carta, v_turco_arenas_minas_serie, v_turco_arenas_minas_carta, v_turco_cilindro_serie, v_turco_cilindro_carta, v_turco_fierrillo_casillero_serie, v_turco_fierrillo_casillero_carta, v_turco_grano_mina_serie, v_turco_grano_mina_carta, v_turco_lodo_serie, v_turco_lodo_carta, v_turco_tlh_serie, v_turco_tlh_carta CASCADE;

-- ============================================================
-- PLANTA: ARENAS
-- ============================================================

-- ── A36 ──
CREATE OR REPLACE VIEW v_arenas_a36_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#18'),(1,'#20'),(2,'#25'),(3,'#30'),(4,'#35'),(5,'#40'),(6,'#60'),(7,'#100'),(8,'#120'),(9,'#140'),(10,'#170'),(11,'#200'),(12,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'A36'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'A36'
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

CREATE OR REPLACE VIEW v_arenas_a36_carta AS
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
FROM v_arenas_a36_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── A38 ──
CREATE OR REPLACE VIEW v_arenas_a38_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#16'),(1,'#18'),(2,'#20'),(3,'#30'),(4,'#35'),(5,'#40'),(6,'#45'),(7,'#60'),(8,'#100'),(9,'#120'),(10,'#140'),(11,'#170'),(12,'#200'),(13,'#270'),(14,'#400')) AS t(ord,tamiz)
  WHERE e.producto_key = 'A38'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'A38'
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

CREATE OR REPLACE VIEW v_arenas_a38_carta AS
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
FROM v_arenas_a38_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── ALIM ──
CREATE OR REPLACE VIEW v_arenas_alimentacion_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#16'),(1,'#18'),(2,'#20'),(3,'#25'),(4,'#30'),(5,'#35'),(6,'#40'),(7,'#60'),(8,'#100'),(9,'#120'),(10,'#140'),(11,'#170'),(12,'#200'),(13,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'ALIM'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'ALIM'
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

CREATE OR REPLACE VIEW v_arenas_alimentacion_carta AS
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
FROM v_arenas_alimentacion_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── LODOSA ──
CREATE OR REPLACE VIEW v_arenas_lodos_arenas_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#120')) AS t(ord,tamiz)
  WHERE e.producto_key = 'LODOSA'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'LODOSA'
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

CREATE OR REPLACE VIEW v_arenas_lodos_arenas_carta AS
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
FROM v_arenas_lodos_arenas_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── MOL1 ──
CREATE OR REPLACE VIEW v_arenas_molino_1_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1_4'),(1,'#4'),(2,'#6'),(3,'#8'),(4,'#14'),(5,'#18'),(6,'#30'),(7,'#35'),(8,'#60'),(9,'#100'),(10,'#120'),(11,'#170')) AS t(ord,tamiz)
  WHERE e.producto_key = 'MOL1'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'MOL1'
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

CREATE OR REPLACE VIEW v_arenas_molino_1_carta AS
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
FROM v_arenas_molino_1_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── MOL2 ──
CREATE OR REPLACE VIEW v_arenas_molino_2_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1_4'),(1,'#4'),(2,'#6'),(3,'#8'),(4,'#14'),(5,'#18'),(6,'#30'),(7,'#35'),(8,'#60'),(9,'#100'),(10,'#120'),(11,'#170')) AS t(ord,tamiz)
  WHERE e.producto_key = 'MOL2'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'MOL2'
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

CREATE OR REPLACE VIEW v_arenas_molino_2_carta AS
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
FROM v_arenas_molino_2_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── MESP ──
CREATE OR REPLACE VIEW v_arenas_muestras_esp_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1_4'),(1,'#4'),(2,'#6'),(3,'#8'),(4,'#14'),(5,'#18'),(6,'#30'),(7,'#35'),(8,'#60'),(9,'#100'),(10,'#120'),(11,'#170')) AS t(ord,tamiz)
  WHERE e.producto_key = 'MESP'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'MESP'
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

CREATE OR REPLACE VIEW v_arenas_muestras_esp_carta AS
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
FROM v_arenas_muestras_esp_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── OVR2007 ──
CREATE OR REPLACE VIEW v_arenas_over_2007_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1_4'),(1,'#4'),(2,'#6'),(3,'#8'),(4,'#14'),(5,'#18'),(6,'#30'),(7,'#35'),(8,'#60'),(9,'#100'),(10,'#120'),(11,'#170')) AS t(ord,tamiz)
  WHERE e.producto_key = 'OVR2007'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'OVR2007'
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

CREATE OR REPLACE VIEW v_arenas_over_2007_carta AS
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
FROM v_arenas_over_2007_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── REC2001 ──
CREATE OR REPLACE VIEW v_arenas_rechazo_2001_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1_4'),(1,'#4'),(2,'#6'),(3,'#8'),(4,'#14'),(5,'#18'),(6,'#25'),(7,'#30'),(8,'#35'),(9,'#60'),(10,'#100'),(11,'#120'),(12,'#170')) AS t(ord,tamiz)
  WHERE e.producto_key = 'REC2001'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'REC2001'
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

CREATE OR REPLACE VIEW v_arenas_rechazo_2001_carta AS
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
FROM v_arenas_rechazo_2001_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── UND2007 ──
CREATE OR REPLACE VIEW v_arenas_under_2007_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1_4'),(1,'#4'),(2,'#6'),(3,'#8'),(4,'#14'),(5,'#18'),(6,'#30'),(7,'#35'),(8,'#60'),(9,'#100'),(10,'#120'),(11,'#170')) AS t(ord,tamiz)
  WHERE e.producto_key = 'UND2007'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'UND2007'
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

CREATE OR REPLACE VIEW v_arenas_under_2007_carta AS
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
FROM v_arenas_under_2007_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── UTACK ──
CREATE OR REPLACE VIEW v_arenas_under_tack_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1_4'),(1,'#4'),(2,'#6'),(3,'#8'),(4,'#14'),(5,'#18'),(6,'#30'),(7,'#35'),(8,'#60'),(9,'#100'),(10,'#120'),(11,'#170')) AS t(ord,tamiz)
  WHERE e.producto_key = 'UTACK'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'UTACK'
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

CREATE OR REPLACE VIEW v_arenas_under_tack_carta AS
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
FROM v_arenas_under_tack_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── VERALTA ──
CREATE OR REPLACE VIEW v_arenas_veralia_alta_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#20'),(1,'#30'),(2,'#60'),(3,'#100'),(4,'#140'),(5,'#200')) AS t(ord,tamiz)
  WHERE e.producto_key = 'VERALTA'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'VERALTA'
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

CREATE OR REPLACE VIEW v_arenas_veralia_alta_carta AS
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
FROM v_arenas_veralia_alta_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── VERBAJA ──
CREATE OR REPLACE VIEW v_arenas_veralia_baja_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#20'),(1,'#30'),(2,'#60'),(3,'#100'),(4,'#140'),(5,'#200')) AS t(ord,tamiz)
  WHERE e.producto_key = 'VERBAJA'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'VERBAJA'
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

CREATE OR REPLACE VIEW v_arenas_veralia_baja_carta AS
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
FROM v_arenas_veralia_baja_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ============================================================
-- PLANTA: DESPACHOS
-- ============================================================

-- ── DESP_LIR ──
CREATE OR REPLACE VIEW v_despachos_lirquen_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#18'),(1,'#20'),(2,'#25'),(3,'#30'),(4,'#35'),(5,'#40'),(6,'#60'),(7,'#100'),(8,'#120'),(9,'#140'),(10,'#170'),(11,'#200'),(12,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'DESP_LIR'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'DESP_LIR'
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

CREATE OR REPLACE VIEW v_despachos_lirquen_carta AS
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
FROM v_despachos_lirquen_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── DESP_LLAY ──
CREATE OR REPLACE VIEW v_despachos_llayllay_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#18'),(1,'#20'),(2,'#25'),(3,'#30'),(4,'#35'),(5,'#40'),(6,'#60'),(7,'#100'),(8,'#120'),(9,'#140'),(10,'#170'),(11,'#200'),(12,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'DESP_LLAY'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'DESP_LLAY'
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

CREATE OR REPLACE VIEW v_despachos_llayllay_carta AS
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
FROM v_despachos_llayllay_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── DESP_PH ──
CREATE OR REPLACE VIEW v_despachos_padre_hurtado_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#20'),(1,'#30'),(2,'#40'),(3,'#50'),(4,'#70'),(5,'#100'),(6,'#140'),(7,'#200'),(8,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'DESP_PH'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'DESP_PH'
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

CREATE OR REPLACE VIEW v_despachos_padre_hurtado_carta AS
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
FROM v_despachos_padre_hurtado_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ============================================================
-- PLANTA: CUARZO
-- ============================================================

-- ── CALIM ──
CREATE OR REPLACE VIEW v_cuarzo_alim_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1'),(1,'#3_4'),(2,'#1_2'),(3,'#5_16'),(4,'#1_4'),(5,'#4'),(6,'#5'),(7,'#6'),(8,'#8'),(9,'#12'),(10,'#16'),(11,'#20'),(12,'#100')) AS t(ord,tamiz)
  WHERE e.producto_key = 'CALIM'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'CALIM'
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

CREATE OR REPLACE VIEW v_cuarzo_alim_carta AS
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
FROM v_cuarzo_alim_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── CCOMP ──
CREATE OR REPLACE VIEW v_cuarzo_compacta_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#18'),(1,'#20'),(2,'#30'),(3,'#35'),(4,'#40'),(5,'#60'),(6,'#100'),(7,'#120'),(8,'#140'),(9,'#170'),(10,'#200'),(11,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'CCOMP'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'CCOMP'
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

CREATE OR REPLACE VIEW v_cuarzo_compacta_carta AS
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
FROM v_cuarzo_compacta_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── CDLK ──
CREATE OR REPLACE VIEW v_cuarzo_dlk_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#6'),(1,'#18'),(2,'#30'),(3,'#35'),(4,'#40'),(5,'#60'),(6,'#100'),(7,'#120'),(8,'#140'),(9,'#170'),(10,'#200'),(11,'#270'),(12,'#400')) AS t(ord,tamiz)
  WHERE e.producto_key = 'CDLK'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'CDLK'
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

CREATE OR REPLACE VIEW v_cuarzo_dlk_carta AS
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
FROM v_cuarzo_dlk_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── CLODOS ──
CREATE OR REPLACE VIEW v_cuarzo_lodos_cuarzo_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#120')) AS t(ord,tamiz)
  WHERE e.producto_key = 'CLODOS'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'CLODOS'
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

CREATE OR REPLACE VIEW v_cuarzo_lodos_cuarzo_carta AS
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
FROM v_cuarzo_lodos_cuarzo_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── CTLH ──
CREATE OR REPLACE VIEW v_cuarzo_tlh_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#1'),(1,'#3_4'),(2,'#1_2'),(3,'#5_16'),(4,'#1_4'),(5,'#4'),(6,'#5'),(7,'#6'),(8,'#8'),(9,'#12'),(10,'#16'),(11,'#20'),(12,'#100')) AS t(ord,tamiz)
  WHERE e.producto_key = 'CTLH'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'CTLH'
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

CREATE OR REPLACE VIEW v_cuarzo_tlh_carta AS
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
FROM v_cuarzo_tlh_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ============================================================
-- PLANTA: TURCO
-- ============================================================

-- ── TT_ALIM ──
CREATE OR REPLACE VIEW v_turco_alimentacion_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#16'),(1,'#18'),(2,'#20'),(3,'#30'),(4,'#40'),(5,'#50'),(6,'#70'),(7,'#100'),(8,'#140'),(9,'#200'),(10,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'TT_ALIM'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'TT_ALIM'
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

CREATE OR REPLACE VIEW v_turco_alimentacion_carta AS
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
FROM v_turco_alimentacion_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── TT_AMINAS ──
CREATE OR REPLACE VIEW v_turco_arenas_minas_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#16'),(1,'#18'),(2,'#20'),(3,'#30'),(4,'#40'),(5,'#50'),(6,'#70'),(7,'#100'),(8,'#140'),(9,'#200'),(10,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'TT_AMINAS'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'TT_AMINAS'
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

CREATE OR REPLACE VIEW v_turco_arenas_minas_carta AS
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
FROM v_turco_arenas_minas_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── TT_CILINDRO (solo granulometria de ENTRADA) ──
CREATE OR REPLACE VIEW v_turco_cilindro_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#16'),(1,'#18'),(2,'#20'),(3,'#30'),(4,'#40'),(5,'#50'),(6,'#70'),(7,'#100'),(8,'#140'),(9,'#200'),(10,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'TT_CILINDRO'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'TT_CILINDRO'
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

CREATE OR REPLACE VIEW v_turco_cilindro_carta AS
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
FROM v_turco_cilindro_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── TT_FIERRC ──
CREATE OR REPLACE VIEW v_turco_fierrillo_casillero_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#16'),(1,'#18'),(2,'#20'),(3,'#30'),(4,'#40'),(5,'#50'),(6,'#70'),(7,'#100'),(8,'#140'),(9,'#200'),(10,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'TT_FIERRC'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'TT_FIERRC'
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

CREATE OR REPLACE VIEW v_turco_fierrillo_casillero_carta AS
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
FROM v_turco_fierrillo_casillero_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── TT_GMINA ──
CREATE OR REPLACE VIEW v_turco_grano_mina_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#4'),(1,'#6'),(2,'#8'),(3,'#12'),(4,'#16'),(5,'#18'),(6,'#30')) AS t(ord,tamiz)
  WHERE e.producto_key = 'TT_GMINA'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'TT_GMINA'
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

CREATE OR REPLACE VIEW v_turco_grano_mina_carta AS
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
FROM v_turco_grano_mina_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── TT_LODO ──
CREATE OR REPLACE VIEW v_turco_lodo_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#40'),(1,'#50'),(2,'#80'),(3,'#100'),(4,'#120'),(5,'#200')) AS t(ord,tamiz)
  WHERE e.producto_key = 'TT_LODO'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'TT_LODO'
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

CREATE OR REPLACE VIEW v_turco_lodo_carta AS
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
FROM v_turco_lodo_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- ── TT_TLH ──
CREATE OR REPLACE VIEW v_turco_tlh_serie AS
WITH largo AS (
  SELECT e.folio, e.id, e.fecha_muestreo, e.created_at, e.turno, e.analista,
         e.tipo_muestra, e.num_acopio, t.ord, t.tamiz,
         ROUND(num_seguro(e.granu->>t.ord) / NULLIF(e.peso_final,0) * 100, 2) AS rp
  FROM ensayos e
  CROSS JOIN LATERAL (VALUES (0,'#16'),(1,'#18'),(2,'#20'),(3,'#30'),(4,'#40'),(5,'#50'),(6,'#70'),(7,'#100'),(8,'#140'),(9,'#200'),(10,'#270')) AS t(ord,tamiz)
  WHERE e.producto_key = 'TT_TLH'
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
  LEFT JOIN especificaciones s ON s.producto_key = 'TT_TLH'
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

CREATE OR REPLACE VIEW v_turco_tlh_carta AS
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
FROM v_turco_tlh_serie
GROUP BY tamiz
ORDER BY MIN(orden_tamiz);

-- Permisos de lectura:
GRANT SELECT ON v_arenas_a36_serie, v_arenas_a36_carta, v_arenas_a38_serie, v_arenas_a38_carta, v_arenas_alimentacion_serie, v_arenas_alimentacion_carta, v_arenas_lodos_arenas_serie, v_arenas_lodos_arenas_carta, v_arenas_molino_1_serie, v_arenas_molino_1_carta, v_arenas_molino_2_serie, v_arenas_molino_2_carta, v_arenas_muestras_esp_serie, v_arenas_muestras_esp_carta, v_arenas_over_2007_serie, v_arenas_over_2007_carta, v_arenas_rechazo_2001_serie, v_arenas_rechazo_2001_carta, v_arenas_under_2007_serie, v_arenas_under_2007_carta, v_arenas_under_tack_serie, v_arenas_under_tack_carta, v_arenas_veralia_alta_serie, v_arenas_veralia_alta_carta, v_arenas_veralia_baja_serie, v_arenas_veralia_baja_carta, v_despachos_lirquen_serie, v_despachos_lirquen_carta, v_despachos_llayllay_serie, v_despachos_llayllay_carta, v_despachos_padre_hurtado_serie, v_despachos_padre_hurtado_carta, v_cuarzo_alim_serie, v_cuarzo_alim_carta, v_cuarzo_compacta_serie, v_cuarzo_compacta_carta, v_cuarzo_dlk_serie, v_cuarzo_dlk_carta, v_cuarzo_lodos_cuarzo_serie, v_cuarzo_lodos_cuarzo_carta, v_cuarzo_tlh_serie, v_cuarzo_tlh_carta, v_turco_alimentacion_serie, v_turco_alimentacion_carta, v_turco_arenas_minas_serie, v_turco_arenas_minas_carta, v_turco_cilindro_serie, v_turco_cilindro_carta, v_turco_fierrillo_casillero_serie, v_turco_fierrillo_casillero_carta, v_turco_grano_mina_serie, v_turco_grano_mina_carta, v_turco_lodo_serie, v_turco_lodo_carta, v_turco_tlh_serie, v_turco_tlh_carta TO anon, authenticated;
