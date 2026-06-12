-- Producto: UND2007 | Planta: ARENAS
-- Ejecutar en el SQL Editor de Supabase.
-- Comparativa del retenido parcial promedio por ANALISTA y tamiz
-- (util para detectar sesgos de medicion entre analistas).
SELECT
  tamiz,
  MIN(orden_tamiz) AS orden_tamiz,
  analista,
  COUNT(ret_parcial)                AS n_datos,
  ROUND(AVG(ret_parcial), 2)        AS media_rp,
  ROUND(STDDEV_SAMP(ret_parcial),3) AS desv_std_rp
FROM v_arenas_under_2007_serie
GROUP BY tamiz, analista
ORDER BY orden_tamiz, analista;