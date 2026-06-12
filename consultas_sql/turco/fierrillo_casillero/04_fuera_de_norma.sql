-- Producto: TT_FIERRC | Planta: TURCO
-- Ejecutar en el SQL Editor de Supabase.
-- Mediciones FUERA de los limites EETT (requiere EETT cargada en Ajustes).
SELECT folio, fecha_muestreo, turno, analista, tamiz,
       ret_parcial, ret_acumulado, pasante_acum,
       eett_rp_min, eett_rp_max, eett_ra_min, eett_ra_max,
       eett_pas_min, eett_pas_max
FROM v_turco_fierrillo_casillero_serie
WHERE estado_eett = 'FUERA'
ORDER BY fecha_muestreo DESC, orden_tamiz;