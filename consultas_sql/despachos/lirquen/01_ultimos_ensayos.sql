-- Producto: DESP_LIR | Planta: DESPACHOS
-- Ejecutar en el SQL Editor de Supabase.
-- Ultimos 50 ensayos con todos los datos del formulario.
SELECT * FROM v_desp_lirquen
ORDER BY fecha_muestreo DESC, created_at DESC
LIMIT 50;