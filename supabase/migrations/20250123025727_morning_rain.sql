/*
  # Insert Avalanche roster data

  1. Data Population
    - Inserts current Colorado Avalanche roster data into the players table
    - Includes player names, numbers, and positions
    - All players set as active by default
*/

INSERT INTO players (name, number, position, is_active)
VALUES
  ('Nathan MacKinnon', 29, 'C', true),
  ('Mikko Rantanen', 96, 'RW', true),
  ('Cale Makar', 8, 'D', true),
  ('Valeri Nichushkin', 13, 'RW', true),
  ('Jonathan Drouin', 27, 'LW', true),
  ('Artturi Lehkonen', 62, 'LW', true),
  ('Devon Toews', 7, 'D', true),
  ('Ross Colton', 20, 'C', true),
  ('Miles Wood', 28, 'LW', true),
  ('Tomas Tatar', 90, 'LW', true),
  ('Andrew Cogliano', 11, 'LW', true),
  ('Logan O''Connor', 25, 'RW', true),
  ('Joel Kiviranta', 94, 'RW', true),
  ('Fredrik Olofsson', 22, 'LW', true),
  ('Samuel Girard', 49, 'D', true),
  ('Josh Manson', 42, 'D', true),
  ('Bowen Byram', 4, 'D', true),
  ('Jack Johnson', 3, 'D', true),
  ('Caleb Jones', 82, 'D', true),
  ('Alexandar Georgiev', 40, 'G', true),
  ('Ivan Prosvetov', 50, 'G', true)
ON CONFLICT (id) DO NOTHING;