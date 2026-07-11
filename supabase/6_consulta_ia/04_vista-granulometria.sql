-- ============================================================
-- MIGRIN — Asistente de consultas IA: RESULTADOS DE GRANULOMETRIA POR MALLA
-- Ejecutar en el SQL Editor de Supabase (despues de 01, 02 y 03).
--
-- La tabla `ensayos` guarda la granulometria como un arreglo JSONB de
-- pesos en gramos (`granu`), en el mismo orden que usa la app (ver
-- SIEVE_CONFIG en calidad.src.html). Esa correspondencia indice->malla
-- solo existe hoy en el codigo JS del frontend, no en la base de
-- datos. `mallas_config` la replica para los productos que tienen
-- limites EETT de granulometria, y `v_ia_granulometria` calcula el
-- retenido parcial/acumulado y el pasante por malla, replicando la
-- logica de calcGranu() del frontend.
--
-- NOTA: `mallas_config` no empieza con "v_ia_" a proposito: es una
-- tabla de mapeo interno, no debe aparecer en el esquema que ve el
-- modelo (solo v_ia_granulometria, que ya viene calculada).
-- ============================================================

CREATE OR REPLACE VIEW mallas_config AS
SELECT * FROM (VALUES
  ('A36',0,'#18',1.000),('A36',1,'#20',0.850),('A36',2,'#25',0.710),
  ('A36',3,'#30',0.600),('A36',4,'#35',0.500),('A36',5,'#40',0.425),
  ('A36',6,'#60',0.250),('A36',7,'#100',0.150),('A36',8,'#120',0.125),
  ('A36',9,'#140',0.106),('A36',10,'#170',0.090),('A36',11,'#200',0.075),
  ('A36',12,'#270',0.053),
  ('A38',0,'#16',1.180),('A38',1,'#18',1.000),('A38',2,'#20',0.850),
  ('A38',3,'#30',0.600),('A38',4,'#35',0.500),('A38',5,'#40',0.425),
  ('A38',6,'#45',0.355),('A38',7,'#60',0.250),('A38',8,'#100',0.150),
  ('A38',9,'#120',0.125),('A38',10,'#140',0.106),('A38',11,'#170',0.090),
  ('A38',12,'#200',0.075),('A38',13,'#270',0.053),('A38',14,'#400',0.038),
  ('VERALTA',0,'#20',0.850),('VERALTA',1,'#30',0.600),('VERALTA',2,'#60',0.250),
  ('VERALTA',3,'#100',0.150),('VERALTA',4,'#140',0.106),('VERALTA',5,'#200',0.075),
  ('VERBAJA',0,'#20',0.850),('VERBAJA',1,'#30',0.600),('VERBAJA',2,'#60',0.250),
  ('VERBAJA',3,'#100',0.150),('VERBAJA',4,'#140',0.106),('VERBAJA',5,'#200',0.075),
  ('DESP_PH',0,'#20',0.850),('DESP_PH',1,'#30',0.600),('DESP_PH',2,'#40',0.425),
  ('DESP_PH',3,'#50',0.300),('DESP_PH',4,'#70',0.212),('DESP_PH',5,'#100',0.150),
  ('DESP_PH',6,'#140',0.106),('DESP_PH',7,'#200',0.075),('DESP_PH',8,'#270',0.053),
  ('DESP_LIR',0,'#18',1.000),('DESP_LIR',1,'#20',0.850),('DESP_LIR',2,'#25',0.710),
  ('DESP_LIR',3,'#30',0.600),('DESP_LIR',4,'#35',0.500),('DESP_LIR',5,'#40',0.425),
  ('DESP_LIR',6,'#60',0.250),('DESP_LIR',7,'#100',0.150),('DESP_LIR',8,'#120',0.125),
  ('DESP_LIR',9,'#140',0.106),('DESP_LIR',10,'#170',0.090),('DESP_LIR',11,'#200',0.075),
  ('DESP_LIR',12,'#270',0.053),
  ('DESP_LLAY',0,'#18',1.000),('DESP_LLAY',1,'#20',0.850),('DESP_LLAY',2,'#25',0.710),
  ('DESP_LLAY',3,'#30',0.600),('DESP_LLAY',4,'#35',0.500),('DESP_LLAY',5,'#40',0.425),
  ('DESP_LLAY',6,'#60',0.250),('DESP_LLAY',7,'#100',0.150),('DESP_LLAY',8,'#120',0.125),
  ('DESP_LLAY',9,'#140',0.106),('DESP_LLAY',10,'#170',0.090),('DESP_LLAY',11,'#200',0.075),
  ('DESP_LLAY',12,'#270',0.053),
  ('TT_LODO',0,'#40',0.425),('TT_LODO',1,'#50',0.300),('TT_LODO',2,'#80',0.180),
  ('TT_LODO',3,'#100',0.150),('TT_LODO',4,'#120',0.125),('TT_LODO',5,'#200',0.075),
  ('CTLH',0,'1"',25.400),('CTLH',1,'3/4"',19.050),('CTLH',2,'1/2"',12.700),
  ('CTLH',3,'5/16"',8.000),('CTLH',4,'1/4"',6.350),('CTLH',5,'#4',4.750),
  ('CTLH',6,'#5',4.000),('CTLH',7,'#6',3.350),('CTLH',8,'#8',2.360),
  ('CTLH',9,'#12',1.680),('CTLH',10,'#16',1.180),('CTLH',11,'#20',0.850),
  ('CTLH',12,'#100',0.150),
  ('CDLK',0,'#6',3.350),('CDLK',1,'#18',1.000),('CDLK',2,'#30',0.600),
  ('CDLK',3,'#35',0.500),('CDLK',4,'#40',0.425),('CDLK',5,'#60',0.250),
  ('CDLK',6,'#100',0.150),('CDLK',7,'#120',0.125),('CDLK',8,'#140',0.106),
  ('CDLK',9,'#170',0.090),('CDLK',10,'#200',0.075),('CDLK',11,'#270',0.053),
  ('CDLK',12,'#400',0.038),
  ('CLODOS',0,'#120',0.125)
) AS t(producto_key, idx, malla, mm);

COMMENT ON VIEW mallas_config IS 'Mapa interno: para cada producto, que malla (y su abertura en mm) corresponde a cada posicion (idx, base 0) del arreglo granu de la tabla ensayos. Uso interno de v_ia_granulometria; no consultar directamente para responder preguntas de negocio.';

GRANT SELECT ON mallas_config TO ia_readonly;

-- ── Resultados medidos por malla (retenido parcial/acumulado, pasante) ──
CREATE OR REPLACE VIEW v_ia_granulometria AS
WITH pesos AS (
  SELECT
    e.id, e.producto_key, e.fecha_muestreo::date AS fecha, e.turno, e.analista,
    e.tipo_muestra, e.num_acopio, e.peso_final, e.peso_fondo,
    (ord.idx - 1)::int AS idx,
    -- Parseo defensivo (igual a como lo hace la app en JS): reemplaza solo
    -- la PRIMERA coma por punto y toma el numero valido inicial, para no
    -- romper la vista si algun dato historico viene mal tipeado
    -- (ej. "1,965,17" con doble coma). Grupo NO capturante: en Postgres,
    -- substring(x from patron) devuelve el grupo capturado si el patron
    -- tiene parentesis normales — usar (?:...) para evitar ese error.
    NULLIF((substring(regexp_replace(ord.valor, ',', '.') from '^-?[0-9]+(?:\.[0-9]+)?')), '')::numeric AS peso_malla
  FROM ensayos e,
  LATERAL jsonb_array_elements_text(e.granu) WITH ORDINALITY AS ord(valor, idx)
  WHERE e.granu IS NOT NULL AND jsonb_typeof(e.granu) = 'array'
),
conmalla AS (
  SELECT p.*, m.malla, m.mm
  FROM pesos p
  JOIN mallas_config m ON m.producto_key = p.producto_key AND m.idx = p.idx
),
totales AS (
  SELECT id, SUM(peso_malla) AS suma_mallas FROM conmalla GROUP BY id
)
SELECT
  c.id, c.producto_key, c.fecha, c.turno, c.analista, c.tipo_muestra, c.num_acopio,
  c.malla, c.mm,
  CASE WHEN c.peso_final>0 THEN ROUND(c.peso_malla/c.peso_final*100, 3) END AS retenido_parcial_pct,
  CASE WHEN c.peso_final>0 THEN ROUND(SUM(c.peso_malla) OVER (PARTITION BY c.id ORDER BY c.idx) / c.peso_final*100, 3) END AS retenido_acumulado_pct,
  CASE WHEN c.peso_final>0 THEN ROUND(100 - SUM(c.peso_malla) OVER (PARTITION BY c.id ORDER BY c.idx) / c.peso_final*100, 3) END AS pasante_pct
FROM conmalla c
UNION ALL
SELECT
  e.id, e.producto_key, e.fecha_muestreo::date, e.turno, e.analista, e.tipo_muestra, e.num_acopio,
  'Fondo', NULL,
  CASE WHEN e.peso_final>0 THEN ROUND(e.peso_fondo/e.peso_final*100,3) END,
  CASE WHEN e.peso_final>0 THEN ROUND((COALESCE(t.suma_mallas,0)+e.peso_fondo)/e.peso_final*100,3) END,
  CASE WHEN e.peso_final>0 THEN ROUND(100 - (COALESCE(t.suma_mallas,0)+e.peso_fondo)/e.peso_final*100,3) END
FROM ensayos e
LEFT JOIN totales t ON t.id = e.id
WHERE e.peso_fondo IS NOT NULL
  AND e.producto_key IN (SELECT DISTINCT producto_key FROM mallas_config);

COMMENT ON VIEW v_ia_granulometria IS
  'Resultado granulometrico medido por malla, una fila por (ensayo, malla). retenido_parcial_pct = % retenido en esa malla especifica. retenido_acumulado_pct = % retenido acumulado desde la malla mas gruesa hasta esta (el que se compara contra los limites de v_ia_especificaciones donde limite=retAcumMin/retAcumMax). pasante_pct = % que pasa esa malla (100 - retenido_acumulado_pct). La fila con malla=''Fondo'' es el residuo final de la bandeja. Usar junto con v_ia_especificaciones (parametro=''Granulometria'', columna malla) para comparar resultados reales contra los limites EETT por malla.';
COMMENT ON COLUMN v_ia_granulometria.mm IS 'Abertura de la malla en milimetros (NULL para la fila Fondo).';

GRANT SELECT ON v_ia_granulometria TO ia_readonly;

-- ============================================================
-- NOTA DE CALIDAD DE DATOS (no corregida automaticamente):
-- El ensayo id='mqwnx6srctm2j' (A36, folio 6645, 2026-06-27) tiene en
-- granu[12] (malla #270) el valor "1,965,17" (doble coma). Por el
-- cierre granulometrico (peso_final=200, peso_fondo=4.753, suma del
-- resto de mallas=193.282) el valor correcto deberia ser "1,965"
-- (193.282+1.965+4.753=200.000 exacto). El parseo defensivo de esta
-- vista evita que la vista se rompa, pero el numero que calcula para
-- esa fila no sera el correcto hasta corregir el dato de origen.
-- ============================================================
