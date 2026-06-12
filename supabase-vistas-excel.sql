-- ============================================================
-- MIGRIN Control de Calidad - Vistas para conexion Excel/Power BI
-- Una vista por formulario con granulometria/quimica expandidas.
-- Ejecutar en el SQL Editor de Supabase.
-- ============================================================

CREATE OR REPLACE VIEW v_a36 AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_25,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_170,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'A36'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_a38 AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_45,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_170,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>13,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(granu->>14,',','.'),'')::numeric AS t_400,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'A38'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_alimentacion AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_25,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_170,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>13,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'ALIM'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_rechazo_2001 AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_14,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_25,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_170,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'REC2001'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_veralia_alta AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'VERALTA'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_veralia_baja AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'VERBAJA'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_molino_1 AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_14,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_170,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'MOL1'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_molino_2 AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_14,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_170,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'MOL2'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_under_2007 AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_14,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_170,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'UND2007'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_over_2007 AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_14,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_170,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'OVR2007'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_under_tack AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_14,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_170,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'UTACK'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_muestras_esp AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_14,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_170,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'MESP'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_lodos_arenas AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_120,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'LODOSA'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_desp_padre_hurtado AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_50,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_70,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'DESP_PH'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_desp_lirquen AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_25,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_170,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'DESP_LIR'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_desp_llayllay AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_25,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_170,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'DESP_LLAY'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_control_granos AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_14,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_20,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'CGRANOS'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_materias_primas AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'MPRIMA'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_alim_cuarzo AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_3_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_1_2,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_5_16,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_5,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_12,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'CALIM'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tlh_cuarzo AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_1,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_3_4,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_1_2,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_5_16,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_1_4,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_5,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_12,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'CTLH'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_compacta AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_170,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'CCOMP'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_dlk AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_35,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_60,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_170,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>11,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(granu->>12,',','.'),'')::numeric AS t_400,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'CDLK'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_lodos_cuarzo AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_120,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'CLODOS'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_tlh AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_50,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_70,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_TLH'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_alimentacion AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_50,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_70,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  (extra->'mezcla'->>'banco') AS mezcla_banco,
  (extra->'mezcla'->>'amarilla') AS mezcla_amarilla,
  (extra->'mezcla'->>'blanca') AS mezcla_blanca,
  (extra->'mezcla'->>'grancilla') AS mezcla_grancilla,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_ALIM'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_granos AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_20,
  (extra->>'punto') AS punto_muestreo,
  NULLIF(extra->'arcillas'->>0,'')::numeric AS arcillas_16,
  NULLIF(extra->'arcillas'->>1,'')::numeric AS arcillas_18,
  NULLIF(extra->'arcillas'->>2,'')::numeric AS arcillas_20,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_GRANOS'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_arcillas AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  (extra->>'tipoArena') AS tipo_arena,
  NULLIF(REPLACE(extra->>'temperatura',',','.'),'')::numeric AS temperatura_f,
  NULLIF(REPLACE(extra->>'lectura1',',','.'),'')::numeric AS lectura_1,
  NULLIF(REPLACE(extra->>'lectura2',',','.'),'')::numeric AS lectura_2,
  NULLIF(REPLACE(extra->>'pctArena',',','.'),'')::numeric AS pct_arena,
  NULLIF(REPLACE(extra->>'pctArcillas',',','.'),'')::numeric AS pct_arcillas,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_ARCILLAS'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_arenas_minas AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_50,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_70,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  (extra->>'tipoArena') AS tipo_arena,
  NULLIF(REPLACE(extra->>'pctArcilla',',','.'),'')::numeric AS pct_arcilla,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_AMINAS'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_cilindro AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_50,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_70,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(extra->'salidaGranu'->>0,',','.'),'')::numeric AS sal_t_16,
  NULLIF(REPLACE(extra->'salidaGranu'->>1,',','.'),'')::numeric AS sal_t_18,
  NULLIF(REPLACE(extra->'salidaGranu'->>2,',','.'),'')::numeric AS sal_t_20,
  NULLIF(REPLACE(extra->'salidaGranu'->>3,',','.'),'')::numeric AS sal_t_30,
  NULLIF(REPLACE(extra->'salidaGranu'->>4,',','.'),'')::numeric AS sal_t_40,
  NULLIF(REPLACE(extra->'salidaGranu'->>5,',','.'),'')::numeric AS sal_t_50,
  NULLIF(REPLACE(extra->'salidaGranu'->>6,',','.'),'')::numeric AS sal_t_70,
  NULLIF(REPLACE(extra->'salidaGranu'->>7,',','.'),'')::numeric AS sal_t_100,
  NULLIF(REPLACE(extra->'salidaGranu'->>8,',','.'),'')::numeric AS sal_t_140,
  NULLIF(REPLACE(extra->'salidaGranu'->>9,',','.'),'')::numeric AS sal_t_200,
  NULLIF(REPLACE(extra->'salidaGranu'->>10,',','.'),'')::numeric AS sal_t_270,
  NULLIF(REPLACE(extra->>'salidaPan',',','.'),'')::numeric AS sal_pan,
  NULLIF(REPLACE(extra->>'totalEntrada',',','.'),'')::numeric AS total_entrada,
  NULLIF(REPLACE(extra->>'totalSalida',',','.'),'')::numeric AS total_salida,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_CILINDRO'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_floculante AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  (extra->>'horario') AS horario,
  NULLIF(REPLACE(extra->>'solucionMl',',','.'),'')::numeric AS solucion_ml,
  NULLIF(REPLACE(extra->>'flocMadreG',',','.'),'')::numeric AS floc_madre_g,
  NULLIF(REPLACE(extra->>'flocDilG',',','.'),'')::numeric AS floc_dilucion_g,
  NULLIF(REPLACE(extra->>'concMadreGl',',','.'),'')::numeric AS conc_madre_gl,
  NULLIF(REPLACE(extra->>'concDilGl',',','.'),'')::numeric AS conc_dilucion_gl,
  (extra->>'estado') AS estado,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_FLOC'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_lodo AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_50,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_80,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_120,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(extra->>'menos100',',','.'),'')::numeric AS menos_100_pasante,
  NULLIF(REPLACE(extra->>'mas120',',','.'),'')::numeric AS mas_120_ret_acum,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_LODO'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_grano_mina AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_4,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_6,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_8,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_12,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  (extra->>'sector') AS sector,
  (extra->>'hora') AS hora_muestreo,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_GMINA'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_arena_mina_cristaleria AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  (extra->>'tipoArena') AS tipo_arena,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_AMCRIST'
ORDER BY fecha_muestreo DESC, created_at DESC;

CREATE OR REPLACE VIEW v_tt_fierrillo_casillero AS
SELECT
  folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida,
  NULLIF(REPLACE(granu->>0,',','.'),'')::numeric AS t_16,
  NULLIF(REPLACE(granu->>1,',','.'),'')::numeric AS t_18,
  NULLIF(REPLACE(granu->>2,',','.'),'')::numeric AS t_20,
  NULLIF(REPLACE(granu->>3,',','.'),'')::numeric AS t_30,
  NULLIF(REPLACE(granu->>4,',','.'),'')::numeric AS t_40,
  NULLIF(REPLACE(granu->>5,',','.'),'')::numeric AS t_50,
  NULLIF(REPLACE(granu->>6,',','.'),'')::numeric AS t_70,
  NULLIF(REPLACE(granu->>7,',','.'),'')::numeric AS t_100,
  NULLIF(REPLACE(granu->>8,',','.'),'')::numeric AS t_140,
  NULLIF(REPLACE(granu->>9,',','.'),'')::numeric AS t_200,
  NULLIF(REPLACE(granu->>10,',','.'),'')::numeric AS t_270,
  NULLIF(REPLACE(quimica->>'sio2',',','.'),'')::numeric AS sio2,
  NULLIF(REPLACE(quimica->>'al2o3',',','.'),'')::numeric AS al2o3,
  NULLIF(REPLACE(quimica->>'fe2o3',',','.'),'')::numeric AS fe2o3,
  NULLIF(REPLACE(quimica->>'cao',',','.'),'')::numeric AS cao,
  NULLIF(REPLACE(quimica->>'mgo',',','.'),'')::numeric AS mgo,
  NULLIF(REPLACE(quimica->>'k2o',',','.'),'')::numeric AS k2o,
  NULLIF(REPLACE(quimica->>'na2o',',','.'),'')::numeric AS na2o,
  NULLIF(REPLACE(quimica->>'tio2',',','.'),'')::numeric AS tio2,
  observaciones, enviado_por, created_at
FROM ensayos
WHERE producto_key = 'TT_FIERRC'
ORDER BY fecha_muestreo DESC, created_at DESC;

-- Vista general (todos los formularios, sin expandir granulometria)
CREATE OR REPLACE VIEW v_ensayos_todos AS
SELECT folio, id, fecha_muestreo, fecha_envio, hora_envio, turno, analista,
  producto_key, producto_label, tipo_muestra, num_acopio,
  peso_inicial, peso_final, peso_fondo, pct_humedad,
  guia, lote, hora_salida, granu, quimica, extra,
  observaciones, enviado_por, created_at
FROM ensayos ORDER BY fecha_muestreo DESC;

-- Permisos de lectura para las vistas (acceso via API con la publishable key)
GRANT SELECT ON v_a36, v_a38, v_alimentacion, v_rechazo_2001, v_veralia_alta, v_veralia_baja, v_molino_1, v_molino_2, v_under_2007, v_over_2007, v_under_tack, v_muestras_esp, v_lodos_arenas, v_desp_padre_hurtado, v_desp_lirquen, v_desp_llayllay, v_control_granos, v_materias_primas, v_alim_cuarzo, v_tlh_cuarzo, v_compacta, v_dlk, v_lodos_cuarzo, v_tt_tlh, v_tt_alimentacion, v_tt_granos, v_tt_arcillas, v_tt_arenas_minas, v_tt_cilindro, v_tt_floculante, v_tt_lodo, v_tt_grano_mina, v_tt_arena_mina_cristaleria, v_tt_fierrillo_casillero, v_ensayos_todos TO anon, authenticated;
