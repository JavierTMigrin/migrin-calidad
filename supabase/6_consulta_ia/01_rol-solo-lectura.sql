-- ============================================================
-- MIGRIN — Asistente de consultas IA: ROL DE SOLO LECTURA
-- Ejecutar en el SQL Editor de Supabase.
--
-- Este rol es el que usa la Edge Function "consulta-ia" para
-- ejecutar las consultas generadas por la IA. Solo puede LEER:
-- no puede insertar, actualizar, borrar ni modificar nada.
-- ============================================================

-- 1) Crear el rol (cambia la clave por una larga y aleatoria)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ia_readonly') THEN
    CREATE ROLE ia_readonly LOGIN PASSWORD 'CAMBIA_ESTA_CLAVE_POR_UNA_LARGA';
  END IF;
END $$;

-- 2) Permisos: solo lectura sobre el esquema public (incluye vistas)
GRANT USAGE ON SCHEMA public TO ia_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ia_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ia_readonly;

-- 3) Quitar explícitamente cualquier permiso de escritura (defensa en profundidad)
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA public FROM ia_readonly;

-- 4) Blindaje a nivel de rol: toda sesión de este usuario es de SOLO LECTURA
--    y con un límite de tiempo por consulta (evita consultas que se cuelguen).
ALTER ROLE ia_readonly SET default_transaction_read_only = on;
ALTER ROLE ia_readonly SET statement_timeout = '8s';

-- ============================================================
-- OPCIONAL (más restrictivo): exponer SOLO las vistas v_ia_*
-- Descomenta para que la IA solo pueda ver las vistas de dominio
-- y no las tablas crudas:
--
--   REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM ia_readonly;
--   GRANT SELECT ON v_ia_ensayos TO ia_readonly;
--   -- agrega aquí cada vista v_ia_* que quieras exponer
-- ============================================================

-- 5) La cadena de conexión para la Edge Function queda así
--    (toma el HOST y el puerto desde Supabase → Project Settings → Database):
--
--   postgresql://ia_readonly:TU_CLAVE@HOST:5432/postgres?sslmode=require
--
--    Esa cadena completa es el secret READONLY_DATABASE_URL de la función.
