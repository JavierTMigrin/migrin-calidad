-- Producto: LODOSA | Planta: ARENAS
-- Ejecutar en el SQL Editor de Supabase.
-- Tendencia temporal de UN tamiz: valores + promedios moviles.
-- Cambia '#100' por el tamiz que quieras analizar.
SELECT folio, fecha_muestreo, turno, analista,
       ret_parcial, rp_movil_7, rp_movil_30,
       ret_acumulado, ra_movil_7, estado_eett
FROM v_arenas_lodos_arenas_serie
WHERE tamiz = '#100'
ORDER BY fecha_muestreo, folio;