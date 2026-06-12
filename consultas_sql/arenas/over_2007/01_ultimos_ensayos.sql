-- Producto: OVR2007 | Planta: ARENAS
-- Ejecutar en el SQL Editor de Supabase.
-- Ultimos 50 ensayos con todos los datos del formulario.
SELECT * FROM v_over_2007
ORDER BY fecha_muestreo DESC, created_at DESC
LIMIT 50;