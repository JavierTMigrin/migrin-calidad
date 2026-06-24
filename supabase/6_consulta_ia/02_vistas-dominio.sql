-- ============================================================
-- MIGRIN — Asistente de consultas IA: VISTAS DE DOMINIO
-- Ejecutar en el SQL Editor de Supabase (después del rol).
--
-- Estas vistas exponen los conceptos del negocio con nombres y
-- columnas claras (química como columnas, no dentro de JSONB).
-- La IA genera SQL mucho más preciso contra estas vistas que
-- contra la tabla cruda. Los COMMENT alimentan la introspección
-- del esquema que recibe el modelo como contexto.
-- ============================================================

-- ── Vista principal: un ensayo por fila, química aplanada ──
CREATE OR REPLACE VIEW v_ia_ensayos AS
SELECT
  e.id,
  e.folio,
  e.fecha_muestreo::date                      AS fecha,
  e.producto_key,
  e.producto_label                            AS producto,
  e.turno,
  e.analista,
  e.tipo_muestra,
  e.num_acopio,
  e.peso_inicial,
  e.peso_final,
  e.pct_humedad                                              AS humedad_pct,
  NULLIF(replace(e.quimica->>'sio2',  ',', '.'), '')::numeric AS sio2,
  NULLIF(replace(e.quimica->>'al2o3', ',', '.'), '')::numeric AS al2o3,
  NULLIF(replace(e.quimica->>'fe2o3', ',', '.'), '')::numeric AS fe2o3,
  NULLIF(replace(e.quimica->>'cao',   ',', '.'), '')::numeric AS cao,
  NULLIF(replace(e.quimica->>'mgo',   ',', '.'), '')::numeric AS mgo,
  NULLIF(replace(e.quimica->>'k2o',   ',', '.'), '')::numeric AS k2o,
  NULLIF(replace(e.quimica->>'na2o',  ',', '.'), '')::numeric AS na2o,
  NULLIF(replace(e.quimica->>'tio2',  ',', '.'), '')::numeric AS tio2,
  COALESCE(NULLIF(replace(e.quimica->>'k2o',  ',', '.'), '')::numeric, 0)
    + COALESCE(NULLIF(replace(e.quimica->>'na2o', ',', '.'), '')::numeric, 0) AS k2o_na2o,
  e.observaciones,
  e.enviado_por,
  e.created_at
FROM ensayos e;

COMMENT ON VIEW v_ia_ensayos IS
  'Un ensayo de control de calidad por fila. Química (óxidos) ya expandida a columnas numéricas en %. Usar esta vista para promedios, leyes químicas, humedad, filtros por fecha/producto/turno/analista.';
COMMENT ON COLUMN v_ia_ensayos.fecha          IS 'Fecha de muestreo (date). Para filtrar por mes: date_trunc(''month'', fecha).';
COMMENT ON COLUMN v_ia_ensayos.producto_key   IS 'Código corto del producto (ej. A36, A38, ALIM, CALIM, VSI_ENT).';
COMMENT ON COLUMN v_ia_ensayos.producto       IS 'Nombre legible del producto.';
COMMENT ON COLUMN v_ia_ensayos.turno          IS 'Turno (A, B o C).';
COMMENT ON COLUMN v_ia_ensayos.humedad_pct    IS 'Porcentaje de humedad.';
COMMENT ON COLUMN v_ia_ensayos.sio2           IS 'Ley de SiO2 (sílice) en %.';
COMMENT ON COLUMN v_ia_ensayos.al2o3          IS 'Ley de Al2O3 (alúmina) en %.';
COMMENT ON COLUMN v_ia_ensayos.fe2o3          IS 'Ley de Fe2O3 (hierro) en %.';
COMMENT ON COLUMN v_ia_ensayos.k2o_na2o       IS 'Suma K2O + Na2O en % (calculada).';

GRANT SELECT ON v_ia_ensayos TO ia_readonly;

-- ── Resumen mensual por producto (atajo para preguntas de tendencia) ──
CREATE OR REPLACE VIEW v_ia_resumen_mensual AS
SELECT
  producto_key,
  producto,
  date_trunc('month', fecha)::date AS mes,
  COUNT(*)                         AS n_ensayos,
  ROUND(AVG(sio2), 3)              AS sio2_prom,
  ROUND(AVG(al2o3), 3)             AS al2o3_prom,
  ROUND(AVG(fe2o3), 3)             AS fe2o3_prom,
  ROUND(AVG(humedad_pct), 2)       AS humedad_prom
FROM v_ia_ensayos
GROUP BY producto_key, producto, date_trunc('month', fecha);

COMMENT ON VIEW v_ia_resumen_mensual IS
  'Promedios mensuales de química y humedad por producto. Una fila por (producto, mes).';

GRANT SELECT ON v_ia_resumen_mensual TO ia_readonly;

-- ============================================================
-- GRANULOMETRÍA / P80 / D50
-- La granulometría ya está expandida y con series/curvas en las
-- vistas creadas por 2_vistas/01_vistas-excel.sql y
-- 2_vistas/02_vistas-analisis.sql. Para que la IA pueda usarlas,
-- basta con que el rol ia_readonly tenga SELECT sobre ellas
-- (ya incluido por el GRANT SELECT ON ALL TABLES del paso anterior).
-- Si más adelante quieres una vista de P80/D50 lista para la IA,
-- la agregamos aquí encima de esas vistas.
-- ============================================================
