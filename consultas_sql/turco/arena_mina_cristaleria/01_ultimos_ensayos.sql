-- Producto: TT_AMCRIST | Planta: TURCO
-- Ejecutar en el SQL Editor de Supabase.
-- Ultimos 50 ensayos con todos los datos del formulario.
SELECT * FROM v_tt_arena_mina_cristaleria
ORDER BY fecha_muestreo DESC, created_at DESC
LIMIT 50;