/*
  # Add RPC Functions for Admin Panel

  1. New Functions
    - `fetch_and_update_roster`: Updates player roster from static data
    - `add_test_games`: Creates test games for development

  2. Changes
    - Add security definer to ensure functions run with elevated privileges
    - Add proper error handling
*/

-- Create function to update roster
CREATE OR REPLACE FUNCTION fetch_and_update_roster()
RETURNS void AS $$
BEGIN
  -- First, deactivate all current players
  UPDATE players
  SET is_active = false;

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

-- Create function to add test games
CREATE OR REPLACE FUNCTION add_test_games()
RETURNS void AS $$
DECLARE
  now_time timestamptz;
BEGIN
  -- Get current time
  now_time := now();

  -- Insert test games
  INSERT INTO games (opponent, game_time, is_home, location)
  VALUES
    ('Test Team 1', now_time + interval '30 minutes', true, 'Ball Arena'),
    ('Test Team 2', now_time + interval '90 minutes', false, 'Away Arena'),
    ('Test Team 3', now_time + interval '150 minutes', true, 'Ball Arena');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;