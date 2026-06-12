-- Producto: CTLH | Planta: CUARZO
-- Ejecutar en el SQL Editor de Supabase.
-- Evolucion de Fe2O3 y SiO2 en el tiempo con promedio movil de 7.
SELECT folio, fecha_muestreo, turno, analista, sio2, fe2o3,
  ROUND(AVG(fe2o3) OVER (ORDER BY fecha_muestreo, created_at
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 4) AS fe2o3_movil_7,
  ROUND(AVG(sio2) OVER (ORDER BY fecha_muestreo, created_at
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 3) AS sio2_movil_7
FROM v_tlh_cuarzo
ORDER BY fecha_muestreo, created_at;