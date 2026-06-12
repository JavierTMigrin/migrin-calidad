-- Producto: CTLH | Planta: CUARZO
-- Ejecutar en el SQL Editor de Supabase.
-- Resumen estadistico MENSUAL por tamiz del retenido parcial:
-- n, media, desv std, min, max y % de cumplimiento EETT.
SELECT
  TO_CHAR(fecha_muestreo::date, 'YYYY-MM') AS mes,
  tamiz,
  MIN(orden_tamiz)                  AS orden_tamiz,
  COUNT(ret_parcial)                AS n_datos,
  ROUND(AVG(ret_parcial), 2)        AS media_rp,
  ROUND(STDDEV_SAMP(ret_parcial),3) AS desv_std_rp,
  ROUND(MIN(ret_parcial), 2)        AS min_rp,
  ROUND(MAX(ret_parcial), 2)        AS max_rp,
  ROUND(AVG(ret_acumulado), 2)      AS media_ra,
  ROUND(COUNT(*) FILTER (WHERE estado_eett='OK')::numeric
    / NULLIF(COUNT(*) FILTER (WHERE estado_eett IS NOT NULL),0)*100, 1) AS pct_cumplimiento
FROM v_cuarzo_tlh_serie
GROUP BY 1, 2
ORDER BY mes DESC, orden_tamiz;