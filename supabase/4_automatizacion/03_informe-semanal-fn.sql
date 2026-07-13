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
