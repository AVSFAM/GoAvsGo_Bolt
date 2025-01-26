-- Drop existing sync_games function
DROP FUNCTION IF EXISTS sync_games();

-- Create improved sync_games function with correct schedule
CREATE OR REPLACE FUNCTION sync_games()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_game_count integer;
BEGIN
  -- Delete old unverified games
  DELETE FROM games
  WHERE game_time < now()
    AND verified = false;

  -- Insert actual remaining Avalanche games
  WITH new_games AS (
    INSERT INTO games (opponent, game_time, is_home, location)
    VALUES
      -- January Home Games
      ('New York Rangers', '2024-01-26 19:00:00-07', true, 'Ball Arena'),
      ('St. Louis Blues', '2024-01-31 19:00:00-07', true, 'Ball Arena'),

      -- January Away Games
      ('New York Islanders', '2024-01-28 12:00:00-07', false, 'UBS Arena'),

      -- February Home Games
      ('Philadelphia Flyers', '2024-02-02 13:00:00-07', true, 'Ball Arena'),
      ('New Jersey Devils', '2024-02-26 19:00:00-07', true, 'Ball Arena'),
      ('Minnesota Wild', '2024-02-28 19:00:00-07', true, 'Ball Arena'),

      -- February Away Games
      ('Vancouver Canucks', '2024-02-04 20:00:00-07', false, 'Rogers Arena'),
      ('Calgary Flames', '2024-02-06 19:00:00-07', false, 'Scotiabank Saddledome'),
      ('Edmonton Oilers', '2024-02-07 19:30:00-07', false, 'Rogers Place'),
      ('Nashville Predators', '2024-02-22 18:00:00-07', false, 'Bridgestone Arena'),
      ('St. Louis Blues', '2024-02-23 19:00:00-07', false, 'Enterprise Center'),

      -- March Home Games
      ('Pittsburgh Penguins', '2024-03-04 19:00:00-07', true, 'Ball Arena'),
      ('San Jose Sharks', '2024-03-06 19:00:00-07', true, 'Ball Arena'),
      ('Toronto Maple Leafs', '2024-03-08 19:00:00-07', true, 'Ball Arena'),
      ('Chicago Blackhawks', '2024-03-10 13:00:00-07', true, 'Ball Arena'),
      ('St. Louis Blues', '2024-03-29 19:00:00-07', true, 'Ball Arena'),
      ('Calgary Flames', '2024-03-31 18:00:00-07', true, 'Ball Arena'),

      -- April Home Games
      ('Vegas Golden Knights', '2024-04-08 19:30:00-06', true, 'Ball Arena'),
      ('Vancouver Canucks', '2024-04-10 19:30:00-06', true, 'Ball Arena'),

      -- April Away Games
      ('Chicago Blackhawks', '2024-04-02 18:30:00-06', false, 'United Center'),
      ('Columbus Blue Jackets', '2024-04-03 17:00:00-06', false, 'Nationwide Arena'),
      ('St. Louis Blues', '2024-04-05 18:00:00-06', false, 'Enterprise Center'),
      ('Los Angeles Kings', '2024-04-12 19:30:00-06', false, 'Crypto.com Arena'),
      ('Anaheim Ducks', '2024-04-13 19:30:00-06', false, 'Honda Center')
    ON CONFLICT (game_time, opponent) 
    DO UPDATE SET
      is_home = EXCLUDED.is_home,
      location = EXCLUDED.location
    WHERE games.verified = false
    RETURNING id
  )
  SELECT COUNT(*) INTO v_game_count FROM new_games;

  -- Return result as JSONB
  RETURN jsonb_build_object(
    'success', true,
    'games_processed', v_game_count,
    'message', format('%s games were processed', v_game_count)
  );

EXCEPTION
  WHEN undefined_table THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Games table does not exist'
    );
  WHEN insufficient_privilege THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Insufficient privileges to modify games'
    );
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', format('Error syncing games: %s', SQLERRM)
    );
END;
$$;

-- Grant execute permission to all users
GRANT EXECUTE ON FUNCTION sync_games() TO authenticated;
GRANT EXECUTE ON FUNCTION sync_games() TO anon;

-- Add comment to help PostgREST
COMMENT ON FUNCTION sync_games() IS 'Syncs remaining Avalanche games for the 2023-24 season';