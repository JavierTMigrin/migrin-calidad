-- ============================================================
-- MIGRIN Control de Calidad — Función para informe mensual
-- Ejecutar en SQL Editor de Supabase ANTES de desplegar
-- la Edge Function informe-mensual.
--
-- Crea: fn_informe_mensual(p_year int, p_month int)
--   Retorna un JSON con resumen + detalle por producto
--   para el mes indicado.
-- ============================================================

-- NOTA (corregido): esta funcion nunca pudo ejecutarse desde su creacion,
-- por dos bugs independientes: (1) referenciaba una columna "planta" que
-- no existe en `ensayos` (la planta se deriva en el frontend a partir del
-- producto_key, no se guarda en la BD); (2) jsonb_agg(jsonb_build_object(
-- ...MAX(x)...)) anida una funcion agregada dentro de otra, lo que
-- PostgreSQL prohibe ("aggregate function calls cannot be nested"). Se
-- corrige moviendo la agregacion a una subconsulta y envolviendo cada fila
-- ya agregada con to_jsonb(). Tambien se cambia turno_am/pm/noche (valores
-- que jamas existieron en la columna turno) por turno_a/turno_b (los
-- valores reales: 'A' y 'B').
CREATE OR REPLACE FUNCTION fn_informe_mensual(p_year int, p_month int)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_inicio       date;
  v_fin          date;
  v_resumen      jsonb;
  v_por_producto jsonb;
BEGIN
  v_inicio := make_date(p_year, p_month, 1);
  v_fin    := (v_inicio + interval '1 month - 1 day')::date;

  -- Resumen general del mes
  SELECT jsonb_build_object(
    'total_ensayos',      COUNT(*)::int,
    'productos_activos',  COUNT(DISTINCT producto_key)::int,
    'analistas_activos',  COUNT(DISTINCT analista)::int,
    'dias_con_actividad', COUNT(DISTINCT fecha_muestreo)::int
  )
  INTO v_resumen
  FROM ensayos
  WHERE fecha_muestreo BETWEEN v_inicio AND v_fin;

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
    WHERE fecha_muestreo BETWEEN v_inicio AND v_fin
    GROUP BY producto_key
  ) t;

  RETURN jsonb_build_object(
    'periodo',      to_char(v_inicio, 'TMMonth YYYY'),
    'mes',          p_month,
    'anio',         p_year,
    'fecha_inicio', v_inicio::text,
    'fecha_fin',    v_fin::text,
    'resumen',      COALESCE(v_resumen,      '{}'),
    'por_producto', COALESCE(v_por_producto, '[]')
  );
END;
$$;

-- Probar la función (reemplaza año/mes según necesites):
-- SELECT fn_informe_mensual(2026, 5);
