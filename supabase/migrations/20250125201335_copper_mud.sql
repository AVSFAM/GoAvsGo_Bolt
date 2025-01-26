-- First, deactivate Mikko Rantanen
UPDATE players
SET is_active = false
WHERE name = 'Mikko Rantanen';

-- Then insert new players
INSERT INTO players (name, number, position, is_active)
VALUES
  ('Jack Drury', 18, 'Center', true),
  ('Martin Necas', 88, 'Center', true)
ON CONFLICT (name, number, position) 
DO UPDATE SET 
  is_active = true,
  number = EXCLUDED.number,
  position = EXCLUDED.position;