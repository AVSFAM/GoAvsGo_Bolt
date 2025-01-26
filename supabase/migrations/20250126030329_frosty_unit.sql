/*
  # Add and populate player name fields

  1. Changes
    - Add first_name and last_name columns to players table
    - Split existing name field into first and last names
    - Update player sorting to use last_name, first_name

  2. Security
    - Maintains existing RLS policies
    - No data loss - keeps original name field
*/

-- Add new columns if they don't exist
ALTER TABLE players
ADD COLUMN IF NOT EXISTS first_name text,
ADD COLUMN IF NOT EXISTS last_name text;

-- Split existing names into first and last name
WITH split_names AS (
  SELECT 
    id,
    CASE 
      WHEN name LIKE '% de %' THEN -- Handle 'de' in names like 'Calvin de Haan'
        substring(name from '^(.*?)\s(?:de\s.*$)')
      ELSE
        split_part(name, ' ', 1)
    END as first_name,
    CASE 
      WHEN name LIKE '% de %' THEN -- Handle 'de' in names like 'Calvin de Haan'
        substring(name from '\s(de\s.*$)')
      WHEN name LIKE '%O''Connor' THEN -- Handle O'Connor special case
        'O''Connor'
      ELSE
        substring(name from ' (.*)$')
    END as last_name
  FROM players
)
UPDATE players p
SET 
  first_name = sn.first_name,
  last_name = TRIM(sn.last_name)
FROM split_names sn
WHERE p.id = sn.id;

-- Create index for sorting
DROP INDEX IF EXISTS idx_players_name;
DROP INDEX IF EXISTS idx_players_sort;
CREATE INDEX idx_players_sort ON players (last_name, first_name);

-- Add NOT NULL constraints after data is populated
ALTER TABLE players
ALTER COLUMN first_name SET NOT NULL,
ALTER COLUMN last_name SET NOT NULL;

-- Update all active players with correct names
UPDATE players
SET 
  first_name = split_part(name, ' ', 1),
  last_name = substring(name from ' (.*)$'),
  is_active = true
WHERE name IN (
  'Ross Colton',
  'Jonathan Drouin',
  'Jere Innala',
  'Ivan Ivan',
  'Parker Kelly',
  'Joel Kiviranta',
  'Artturi Lehkonen',
  'Nathan MacKinnon',
  'Casey Mittelstadt',
  'Valeri Nichushkin',
  'Logan O''Connor',
  'Juuso Parssinen',
  'Jack Drury',
  'Martin Necas',
  'Miles Wood',
  'Calvin de Haan',
  'Samuel Girard',
  'Oliver Kylington',
  'Cale Makar',
  'Sam Malinski',
  'Josh Manson',
  'Keaton Middleton',
  'Devon Toews',
  'Mackenzie Blackwood',
  'Scott Wedgewood'
);