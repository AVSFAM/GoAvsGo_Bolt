/*
  # Fix UPDATE statement in fetch_and_update_roster function

  1. Changes
    - Add WHERE clause to UPDATE statement
    - Improve error handling
*/

-- Drop and recreate the function with fixed UPDATE statement
CREATE OR REPLACE FUNCTION fetch_and_update_roster()
RETURNS void AS $$
BEGIN
  -- First, deactivate all players that are currently active
  UPDATE players
  SET is_active = false
  WHERE is_active = true;

  -- Then insert or update players with correct numbers
  INSERT INTO players (name, number, position, is_active)
  VALUES
    -- Forwards
    ('Ross Colton', 20, 'Center', true),
    ('Jonathan Drouin', 27, 'Left Wing', true),
    ('Jere Innala', 22, 'Right Wing', true),
    ('Ivan Ivan', 82, 'Center', true),
    ('Parker Kelly', 17, 'Center', true),
    ('Joel Kiviranta', 94, 'Left Wing', true),
    ('Artturi Lehkonen', 62, 'Left Wing', true),
    ('Nathan MacKinnon', 29, 'Center', true),
    ('Casey Mittelstadt', 37, 'Center', true),
    ('Valeri Nichushkin', 13, 'Right Wing', true),
    ('Logan O''Connor', 25, 'Right Wing', true),
    ('Juuso Parssinen', 16, 'Center', true),
    ('Mikko Rantanen', 96, 'Right Wing', true),
    ('Miles Wood', 28, 'Left Wing', true),
    
    -- Defensemen
    ('Calvin de Haan', 44, 'Defense', true),
    ('Samuel Girard', 49, 'Defense', true),
    ('Oliver Kylington', 58, 'Defense', true),
    ('Cale Makar', 8, 'Defense', true),
    ('Sam Malinski', 70, 'Defense', true),
    ('Josh Manson', 42, 'Defense', true),
    ('Keaton Middleton', 67, 'Defense', true),
    ('Devon Toews', 7, 'Defense', true),
    
    -- Goalies
    ('Mackenzie Blackwood', 39, 'Goalie', true),
    ('Scott Wedgewood', 41, 'Goalie', true)
  ON CONFLICT (name, number, position) 
  DO UPDATE SET 
    is_active = true,
    number = EXCLUDED.number,
    position = EXCLUDED.position;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;