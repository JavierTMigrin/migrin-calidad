-- ============================================================
-- MIGRIN — Asistente de consultas IA: VISTA DE ESPECIFICACIONES (EETT)
-- Ejecutar en el SQL Editor de Supabase (después de 01 y 02).
--
-- La tabla `especificaciones` guarda los limites EETT como JSONB con
-- forma variable: algunos productos tienen un solo cliente/spec
-- directo (A38, VERALTA, ...) y otros tienen varios clientes anidados
-- (A36: LIRQUEN y CRISTALERIAS). Esta vista aplana ambas formas en
-- una fila por limite, para que el asistente pueda responder
-- preguntas de EETT con SQL simple en vez de tener que razonar sobre
-- JSONB anidado de forma heterogenea.
-- ============================================================

CREATE OR REPLACE VIEW v_ia_especificaciones AS
WITH base AS (
  SELECT
    e.producto_key,
    CASE
      WHEN e.specs ? 'quimica' OR e.specs ? 'granulometria' OR e.specs ? 'humedad' OR e.specs ? 'd50Max'
        THEN jsonb_build_object(COALESCE(e.specs->>'nombre', e.producto_key), e.specs)
      ELSE e.specs
    END AS specs_por_cliente
  FROM especificaciones e
),
clientes AS (
  SELECT b.producto_key, kv.key AS cliente, kv.value AS spec
  FROM base b, jsonb_each(b.specs_por_cliente) AS kv
)
SELECT producto_key, cliente, 'Humedad' AS parametro, NULL::text AS malla, 'max' AS limite,
       (spec->'humedad'->>'max')::numeric AS valor, '%' AS unidad
FROM clientes WHERE spec ? 'humedad' AND (spec->'humedad'->>'max') IS NOT NULL
UNION ALL
SELECT producto_key, cliente, 'D50', NULL, 'max', (spec->>'d50Max')::numeric, 'mm'
FROM clientes WHERE spec ? 'd50Max' AND spec->>'d50Max' IS NOT NULL
UNION ALL
SELECT c.producto_key, c.cliente, q.key, NULL, 'min', NULLIF(q.value->>'min','')::numeric, '%'
FROM clientes c, jsonb_each(c.spec->'quimica') AS q(key,value)
WHERE c.spec ? 'quimica' AND NULLIF(q.value->>'min','') IS NOT NULL
UNION ALL
SELECT c.producto_key, c.cliente, q.key, NULL, 'max', NULLIF(q.value->>'max','')::numeric, '%'
FROM clientes c, jsonb_each(c.spec->'quimica') AS q(key,value)
WHERE c.spec ? 'quimica' AND NULLIF(q.value->>'max','') IS NOT NULL
UNION ALL
SELECT c.producto_key, c.cliente, 'Granulometria', g.key, gf.campo, gf.valor, '%'
FROM clientes c, jsonb_each(c.spec->'granulometria') AS g(key,value),
LATERAL (VALUES
  ('retAcumMin',NULLIF(g.value->>'retAcumMin','')::numeric),
  ('retAcumMax',NULLIF(g.value->>'retAcumMax','')::numeric),
  ('retMin',NULLIF(g.value->>'retMin','')::numeric),
  ('retMax',NULLIF(g.value->>'retMax','')::numeric),
  ('pasMin',NULLIF(g.value->>'pasMin','')::numeric),
  ('pasMax',NULLIF(g.value->>'pasMax','')::numeric)
) AS gf(campo,valor)
WHERE c.spec ? 'granulometria' AND gf.valor IS NOT NULL;

COMMENT ON VIEW v_ia_especificaciones IS
  'Limites de especificacion tecnica (EETT) por producto y cliente. Una fila por cada limite definido: parametro (nombre del oxido, Humedad, D50, o "Granulometria" para mallas), malla (numero de malla cuando parametro=Granulometria, si no NULL), limite (min o max), valor (el numero del limite), unidad. Ej: producto_key=A36, cliente=Vidrios Lirquen, parametro=SiO2, limite=min, valor=98.5 significa que el SiO2 debe ser >= 98.5% para ese cliente. Usar para responder preguntas sobre EETT, especificaciones tecnicas, limites o normas de un producto.';
COMMENT ON COLUMN v_ia_especificaciones.cliente IS 'Nombre del cliente/especificacion (ej. Vidrios Lirquen, Cristalerias Chile). Para productos con una sola EETT, coincide con el producto_key.';
COMMENT ON COLUMN v_ia_especificaciones.parametro IS 'Que se limita: nombre del oxido en mayusculas (SiO2, Al2O3, Fe2O3, CaO, MgO, K2O, Na2O, TiO2, K2O_Na2O), "Humedad", "D50", o "Granulometria" (ver columna malla).';
COMMENT ON COLUMN v_ia_especificaciones.malla IS 'Numero de malla (ej. #35, #120) cuando parametro=Granulometria; NULL para los demas parametros.';
COMMENT ON COLUMN v_ia_especificaciones.limite IS 'Si el valor es el limite minimo o maximo permitido. Para malla, ademas puede ser retAcumMin/retAcumMax (retenido acumulado) o retMin/retMax (retenido parcial) o pasMin/pasMax (pasante).';

GRANT SELECT ON v_ia_especificaciones TO ia_readonly;
