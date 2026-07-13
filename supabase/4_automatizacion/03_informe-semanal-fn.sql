-- ============================================================
-- MIGRIN Control de Calidad — Función para informe semanal
-- Ejecutar en SQL Editor de Supabase ANTES de desplegar
-- la Edge Function informe-semanal.
--
-- Crea: fn_informe_semanal(p_desde date, p_hasta date)
--   Retorna un JSON con resumen + detalle por producto
--   para el rango de fechas indicado (pensado para una
--   semana lunes-domingo, pero acepta cualquier rango).
--
-- Comparte la misma estructura que fn_informe_mensual (ver
-- 01_informe-mensual-fn.sql), ya corregida ahi: usa una
-- subconsulta + to_jsonb() en vez de anidar funciones
-- agregadas dentro de jsonb_build_object (invalido en
-- PostgreSQL), y turno_a/turno_b (los valores reales de la
-- columna turno: 'A' y 'B'), no turno_am/pm/noche.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_informe_semanal(p_desde date, p_hasta date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_resumen      jsonb;
  v_por_producto jsonb;
BEGIN
  -- Resumen general de la semana
  SELECT jsonb_build_object(
    'total_ensayos',      COUNT(*)::int,
    'productos_activos',  COUNT(DISTINCT producto_key)::int,
    'analistas_activos',  COUNT(DISTINCT analista)::int,
    'dias_con_actividad', COUNT(DISTINCT fecha_muestreo)::int
  )
  INTO v_resumen
  FROM ensayos
  WHERE fecha_muestreo BETWEEN p_desde AND p_hasta;

  -- Detalle por producto, ordenado por cantidad de ensayos
  SELECT jsonb_agg(to_jsonb(t) ORDER BY t.n DESC)
  INTO v_por_producto
  FROM (
    SELECT
      producto_key,
      MAX(producto_label) AS producto_label,
      COUNT(*)::int AS n,
      COUNT(DISTINCT analista)::int AS analistas,
      COUNT(*) FILTER (WHERE turno = 'A')::int AS turno_a,
      COUNT(*) FILTER (WHERE turno = 'B')::int AS turno_b,
      MIN(fecha_muestreo)::text AS primera,
      MAX(fecha_muestreo)::text AS ultima,
      ROUND(AVG(pct_humedad)::numeric, 1) AS humedad_prom
    FROM ensayos
    WHERE fecha_muestreo BETWEEN p_desde AND p_hasta
    GROUP BY producto_key
  ) t;

  RETURN jsonb_build_object(
    'fecha_inicio', p_desde::text,
    'fecha_fin',    p_hasta::text,
    'resumen',      COALESCE(v_resumen,      '{}'),
    'por_producto', COALESCE(v_por_producto, '[]')
  );
END;
$$;

-- Probar la función (reemplaza las fechas según necesites):
-- SELECT fn_informe_semanal('2026-07-06','2026-07-12');


-- ============================================================
-- Seccion de CALIDAD A36 del informe semanal.
-- Crea: fn_informe_semanal_a36(p_desde date, p_hasta date)
--   Retorna JSON con:
--   - n_ensayos, cumplen_lirquen, cumplen_cch (conteos de la semana)
--   - promedios: promedio semanal de SiO2/Al2O3/Fe2O3/Humedad y del
--     retenido acumulado por malla, cada uno con limite y estado
--     (CUMPLE/FUERA) contra las EETT de AMBOS clientes
--   - fuera_lirquen: cada ensayo que NO cumple la EETT de Vidrios
--     Lirquen, con fecha, folio, turno, ACOPIO y la lista de
--     parametros violados (valor medido + limite)
-- Requiere las vistas v_ia_ensayos, v_ia_granulometria y
-- v_ia_especificaciones (carpeta 6_consulta_ia).
-- El detalle de violaciones se reporta solo contra Lirquen porque la
-- EETT quimica de Cristalerias es incompatible con el A36 TLH
-- estandar (Al2O3 2,2-3,0% vs el ~0,2% del material), por lo que
-- listar sus violaciones ensayo a ensayo seria ruido repetido; CCh
-- se refleja en el conteo cumplen_cch y en la tabla de promedios.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_informe_semanal_a36(p_desde date, p_hasta date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_n        int;
  v_cum_lir  int;
  v_cum_cch  int;
  v_fuera    jsonb;
  v_prom     jsonb;
BEGIN
  -- ── Violaciones por ensayo (quimica + humedad + mallas) y lista de
  --    ensayos fuera de norma vs Vidrios Lirquen, con su acopio ──
  WITH med_q AS (
    SELECT e.id, e.fecha, e.folio, e.turno, e.analista,
           COALESCE(NULLIF(e.num_acopio,''),'—') AS acopio,
           kv.key AS parametro, NULL::text AS malla, kv.value::numeric AS medido
    FROM v_ia_ensayos e,
    LATERAL jsonb_each_text(jsonb_build_object(
      'SiO2',e.sio2,'Al2O3',e.al2o3,'Fe2O3',e.fe2o3,'CaO',e.cao,'MgO',e.mgo,
      'K2O',e.k2o,'Na2O',e.na2o,'TiO2',e.tio2,'Humedad',e.humedad_pct)) kv
    WHERE e.producto_key='A36' AND e.fecha BETWEEN p_desde AND p_hasta
      AND kv.value IS NOT NULL
  ),
  med_g AS (
    SELECT g.id, g.fecha, e.folio, g.turno, g.analista,
           COALESCE(NULLIF(g.num_acopio,''),'—') AS acopio,
           'Granulometria' AS parametro, g.malla, g.retenido_acumulado_pct AS medido
    FROM v_ia_granulometria g
    JOIN v_ia_ensayos e ON e.id = g.id
    WHERE g.producto_key='A36' AND g.fecha BETWEEN p_desde AND p_hasta
      AND g.malla <> 'Fondo' AND g.retenido_acumulado_pct IS NOT NULL
  ),
  med AS (SELECT * FROM med_q UNION ALL SELECT * FROM med_g),
  viol AS (
    SELECT m.id, m.fecha, m.folio, m.turno, m.acopio, m.parametro, m.malla,
           m.medido, s.cliente, s.limite, s.valor AS lim_valor
    FROM med m
    JOIN v_ia_especificaciones s
      ON s.producto_key='A36'
     AND ((m.malla IS NULL AND s.parametro = m.parametro AND s.malla IS NULL)
       OR (m.malla IS NOT NULL AND s.parametro='Granulometria' AND s.malla = m.malla))
    WHERE (s.limite IN ('min','retAcumMin','retMin','pasMin') AND m.medido < s.valor)
       OR (s.limite IN ('max','retAcumMax','retMax','pasMax') AND m.medido > s.valor)
  ),
  ens AS (SELECT DISTINCT id, fecha, folio, turno, acopio FROM med)
  SELECT
    (SELECT COUNT(*) FROM ens),
    (SELECT COUNT(*) FROM ens e
      WHERE NOT EXISTS (SELECT 1 FROM viol v WHERE v.id=e.id AND v.cliente ILIKE '%Lirquen%')),
    (SELECT COUNT(*) FROM ens e
      WHERE NOT EXISTS (SELECT 1 FROM viol v WHERE v.id=e.id AND v.cliente ILIKE '%Cristal%')),
    (SELECT COALESCE(jsonb_agg(sub.f ORDER BY sub.f->>'fecha', (sub.f->>'folio')), '[]'::jsonb)
     FROM (
       SELECT jsonb_build_object(
         'fecha',  e.fecha::text,
         'folio',  e.folio,
         'turno',  e.turno,
         'acopio', e.acopio,
         'violaciones', (
           SELECT jsonb_agg(jsonb_build_object(
             'parametro', CASE WHEN v.malla IS NOT NULL THEN 'Ret.Acum '||v.malla ELSE v.parametro END,
             'valor',     ROUND(v.medido,3),
             'limite',    v.limite,
             'lim_valor', v.lim_valor
           ) ORDER BY v.malla NULLS FIRST, v.parametro)
           FROM viol v WHERE v.id=e.id AND v.cliente ILIKE '%Lirquen%'
         )
       ) AS f
       FROM ens e
       WHERE EXISTS (SELECT 1 FROM viol v WHERE v.id=e.id AND v.cliente ILIKE '%Lirquen%')
     ) sub)
  INTO v_n, v_cum_lir, v_cum_cch, v_fuera;

  -- ── Promedios semanales vs EETT de ambos clientes ──
  WITH med_q AS (
    SELECT 'SiO2' AS parametro, NULL::text AS malla, AVG(sio2) AS promedio FROM v_ia_ensayos WHERE producto_key='A36' AND fecha BETWEEN p_desde AND p_hasta
    UNION ALL SELECT 'Al2O3', NULL, AVG(al2o3) FROM v_ia_ensayos WHERE producto_key='A36' AND fecha BETWEEN p_desde AND p_hasta
    UNION ALL SELECT 'Fe2O3', NULL, AVG(fe2o3) FROM v_ia_ensayos WHERE producto_key='A36' AND fecha BETWEEN p_desde AND p_hasta
    UNION ALL SELECT 'Humedad', NULL, AVG(humedad_pct) FROM v_ia_ensayos WHERE producto_key='A36' AND fecha BETWEEN p_desde AND p_hasta
  ),
  med_g AS (
    SELECT 'Granulometria' AS parametro, malla, AVG(retenido_acumulado_pct) AS promedio
    FROM v_ia_granulometria
    WHERE producto_key='A36' AND fecha BETWEEN p_desde AND p_hasta AND malla <> 'Fondo'
    GROUP BY malla
  ),
  prom AS (
    SELECT parametro, malla, ROUND(promedio::numeric,3) AS promedio
    FROM (SELECT * FROM med_q UNION ALL SELECT * FROM med_g) x
    WHERE promedio IS NOT NULL
  ),
  prom_eval AS (
    SELECT
      CASE WHEN p.malla IS NOT NULL THEN 'Ret.Acum '||p.malla ELSE p.parametro END AS parametro,
      p.promedio,
      p.malla,
      lir.txt   AS lir_limite,  lir.estado AS lir_estado,
      cch.txt   AS cch_limite,  cch.estado AS cch_estado
    FROM prom p
    LEFT JOIN LATERAL (
      SELECT string_agg(
               CASE WHEN s.limite IN ('min','retAcumMin','retMin','pasMin') THEN '>= '||s.valor
                    ELSE '<= '||s.valor END, ' y '),
             CASE WHEN bool_or((s.limite IN ('min','retAcumMin','retMin','pasMin') AND p.promedio < s.valor)
                            OR (s.limite IN ('max','retAcumMax','retMax','pasMax') AND p.promedio > s.valor))
                  THEN 'FUERA' ELSE 'CUMPLE' END
      FROM v_ia_especificaciones s
      WHERE s.producto_key='A36' AND s.cliente ILIKE '%Lirquen%'
        AND ((p.malla IS NULL AND s.parametro=p.parametro AND s.malla IS NULL)
          OR (p.malla IS NOT NULL AND s.parametro='Granulometria' AND s.malla=p.malla))
      HAVING COUNT(*)>0
    ) lir(txt,estado) ON true
    LEFT JOIN LATERAL (
      SELECT string_agg(
               CASE WHEN s.limite IN ('min','retAcumMin','retMin','pasMin') THEN '>= '||s.valor
                    ELSE '<= '||s.valor END, ' y '),
             CASE WHEN bool_or((s.limite IN ('min','retAcumMin','retMin','pasMin') AND p.promedio < s.valor)
                            OR (s.limite IN ('max','retAcumMax','retMax','pasMax') AND p.promedio > s.valor))
                  THEN 'FUERA' ELSE 'CUMPLE' END
      FROM v_ia_especificaciones s
      WHERE s.producto_key='A36' AND s.cliente ILIKE '%Cristal%'
        AND ((p.malla IS NULL AND s.parametro=p.parametro AND s.malla IS NULL)
          OR (p.malla IS NOT NULL AND s.parametro='Granulometria' AND s.malla=p.malla))
      HAVING COUNT(*)>0
    ) cch(txt,estado) ON true
    WHERE lir.txt IS NOT NULL OR cch.txt IS NOT NULL
  )
  SELECT COALESCE(jsonb_agg(to_jsonb(pe) ORDER BY pe.malla NULLS FIRST, pe.parametro), '[]'::jsonb)
  INTO v_prom
  FROM prom_eval pe;

  RETURN jsonb_build_object(
    'n_ensayos',       COALESCE(v_n,0),
    'cumplen_lirquen', COALESCE(v_cum_lir,0),
    'cumplen_cch',     COALESCE(v_cum_cch,0),
    'promedios',       COALESCE(v_prom,'[]'::jsonb),
    'fuera_lirquen',   COALESCE(v_fuera,'[]'::jsonb)
  );
END;
$$;

-- Probar la función (reemplaza las fechas según necesites):
-- SELECT fn_informe_semanal_a36('2026-07-06','2026-07-12');
