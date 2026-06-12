-- ============================================================
-- MIGRIN Control de Calidad — Modulo Lavado Turco
-- Ejecutar en el SQL Editor de Supabase.
-- ============================================================

-- Campos especificos de los formularios Turco (mezcla, arcillas,
-- floculante, cilindro salida, etc.) se guardan en JSONB:
ALTER TABLE ensayos ADD COLUMN IF NOT EXISTS extra JSONB;

-- Analistas separados por planta:
ALTER TABLE analistas ADD COLUMN IF NOT EXISTS planta TEXT DEFAULT 'Arenas';
UPDATE analistas SET planta='Arenas' WHERE planta IS NULL;

-- Analistas de Turco:
INSERT INTO analistas (nombre, planta) VALUES
  ('Lilina Peñailillo','Turco'),
  ('Oscarli Meteran','Turco'),
  ('Romina Sepulveda','Turco')
ON CONFLICT (nombre) DO UPDATE SET planta='Turco';
