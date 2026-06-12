-- Producto: LODOSA | Planta: ARENAS
-- Ejecutar en el SQL Editor de Supabase.
-- Comparativa del retenido parcial promedio por TURNO y tamiz.
SELECT
  tamiz,
  MIN(orden_tamiz) AS orden_tamiz,
  turno,
  COUNT(ret_parcial)                AS n_datos,
  ROUND(AVG(ret_parcial), 2)        AS media_rp,
  ROUND(STDDEV_SAMP(ret_parcial),3) AS desv_std_rp
FROM v_arenas_lodos_arenas_serie
WHERE turno IS NOT NULL
GROUP BY tamiz, turno
ORDER BY orden_tamiz, turno;