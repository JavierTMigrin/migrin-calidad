-- ============================================================
-- MIGRIN Control de Calidad - Catalogo de vistas para Excel
-- Ejecutar en el SQL Editor de Supabase.
--
-- Crea v_catalogo: un listado AUTO-ACTUALIZABLE de todas las
-- vistas disponibles con su URL completa de conexion.
-- Al crear vistas nuevas aparecen solas en este listado.
--
-- Conectar Excel a:
--   https://wxjclxmtceuhlbwxtptc.supabase.co/rest/v1/v_catalogo?select=*
-- ============================================================

CREATE OR REPLACE VIEW v_catalogo AS
SELECT
  v.table_name AS vista,
  -- Planta deducida del nombre:
  CASE
    WHEN v.table_name = 'v_catalogo'                THEN '— Indice —'
    WHEN v.table_name = 'v_ensayos_todos'           THEN 'Todas'
    WHEN v.table_name LIKE 'v_arenas_%'             THEN 'Arenas'
    WHEN v.table_name LIKE 'v_despachos_%'
      OR v.table_name LIKE 'v_desp_%'               THEN 'Despachos'
    WHEN v.table_name LIKE 'v_cuarzo_%'
      OR v.table_name IN ('v_alim_cuarzo','v_tlh_cuarzo','v_compacta','v_dlk','v_lodos_cuarzo') THEN 'Cuarzo'
    WHEN v.table_name LIKE 'v_turco_%'
      OR v.table_name LIKE 'v_tt_%'                 THEN 'Turco'
    ELSE 'Arenas'
  END AS planta,
  -- Tipo de vista:
  CASE
    WHEN v.table_name = 'v_catalogo'        THEN 'Indice de vistas'
    WHEN v.table_name LIKE '%_serie'        THEN 'Serie granulometrica (rp/ra/pasante + moviles + EETT)'
    WHEN v.table_name LIKE '%_carta'        THEN 'Carta de control (media, desv std, LCS/LCI, % cumplimiento)'
    WHEN v.table_name = 'v_ensayos_todos'   THEN 'Todos los registros (datos crudos)'
    ELSE 'Datos del formulario (ret. parcial % + quimica)'
  END AS tipo,
  -- URL completa lista para pegar en Excel (Datos > Desde la web > Avanzadas):
  'https://wxjclxmtceuhlbwxtptc.supabase.co/rest/v1/' || v.table_name || '?select=*' AS url,
  -- Cantidad de columnas que entrega:
  (SELECT COUNT(*) FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = v.table_name) AS n_columnas
FROM information_schema.views v
WHERE v.table_schema = 'public'
  AND v.table_name LIKE 'v\_%'
ORDER BY
  CASE
    WHEN v.table_name = 'v_catalogo' THEN 0
    WHEN v.table_name = 'v_ensayos_todos' THEN 1
    ELSE 2
  END,
  2, -- planta
  vista;

GRANT SELECT ON v_catalogo TO anon, authenticated;
