-- Create function to load fallback games
CREATE OR REPLACE FUNCTION load_fallback_games()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_start_date timestamptz;
  v_game_count integer;
BEGIN
  -- Set start date
  v_start_date := date_trunc('hour', now()) + interval '1 day';

  -- Delete old unverified games
  DELETE FROM games
  WHERE game_time < now()
    AND verified = false;

  -- Insert hardcoded games
  WITH new_games AS (
    INSERT INTO games (opponent, game_time, is_home, location)
    VALUES
      ('Los Angeles Kings', v_start_date + interval '2 days', true, 'Ball Arena'),
      ('Edmonton Oilers', v_start_date + interval '4 days', false, 'Rogers Place'),
      ('Calgary Flames', v_start_date + interval '6 days', true, 'Ball Arena'),
      ('St. Louis Blues', v_start_date + interval '8 days', false, 'Enterprise Center'),
      ('Dallas Stars', v_start_date + interval '10 days', true, 'Ball Arena'),
      ('Vegas Golden Knights', v_start_date + interval '12 days', false, 'T-Mobile Arena'),
      ('Arizona Coyotes', v_start_date + interval '14 days', true, 'Ball Arena')
    ON CONFLICT (game_time, opponent) 
    DO UPDATE SET
      is_home = EXCLUDED.is_home,
      location = EXCLUDED.location
    WHERE games.verified = false
    RETURNING id
  )
  SELECT COUNT(*) INTO v_game_count FROM new_games;

  RETURN jsonb_build_object(
    'success', true,
    'games_processed', v_game_count,
    'message', format('%s games were loaded from fallback data', v_game_count)
  );
END;
$$;

-- Create function to load fallback roster
CREATE OR REPLACE FUNCTION load_fallback_roster()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_player_count integer;
BEGIN
  -- First, deactivate all current players
  UPDATE players
  SET is_active = false;

  -- Insert or update players with current roster
  WITH updated_players AS (
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
      ('Jack Drury', 18, 'Center', true),
      ('Martin Necas', 88, 'Center', true),
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
      position = EXCLUDED.position
    RETURNING id
  )
  SELECT COUNT(*) INTO v_player_count FROM updated_players;

  RETURN jsonb_build_object(
    'success', true,
    'players_processed', v_player_count,
    'message', format('%s players loaded from fallback data', v_player_count)
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION load_fallback_games() TO authenticated;
GRANT EXECUTE ON FUNCTION load_fallback_roster() TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION load_fallback_games() IS 'Loads hardcoded upcoming games when NHL API is unavailable';
COMMENT ON FUNCTION load_fallback_roster() IS 'Loads hardcoded current roster when NHL API is unavailable';