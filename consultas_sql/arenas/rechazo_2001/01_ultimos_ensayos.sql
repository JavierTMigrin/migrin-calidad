-- Producto: REC2001 | Planta: ARENAS
-- Ejecutar en el SQL Editor de Supabase.
-- Ultimos 50 ensayos con todos los datos del formulario.
SELECT * FROM v_rechazo_2001
ORDER BY fecha_muestreo DESC, created_at DESC
LIMIT 50;