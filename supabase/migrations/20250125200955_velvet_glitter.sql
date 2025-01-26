-- Drop existing function if it exists
DROP FUNCTION IF EXISTS sync_games(json);
DROP FUNCTION IF EXISTS sync_games();

-- Create sync_games function with proper parameter handling for PostgREST
CREATE OR REPLACE FUNCTION sync_games(options jsonb DEFAULT '{}'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_start_date timestamptz;
  v_end_date timestamptz;
  v_game_count integer;
BEGIN
  -- Set date range
  v_start_date := date_trunc('hour', now()) + interval '1 day';
  v_end_date := date_trunc('hour', now()) + interval '14 days';

  -- Delete old unverified games
  DELETE FROM games
  WHERE game_time < now()
    AND verified = false;

  -- Insert new games for the next 14 days
  WITH new_games AS (
    INSERT INTO games (opponent, game_time, is_home, location)
    VALUES
      ('Boston Bruins', v_start_date + interval '1 day', true, 'Ball Arena'),
      ('New York Rangers', v_start_date + interval '3 days', false, 'Madison Square Garden'),
      ('Toronto Maple Leafs', v_start_date + interval '5 days', true, 'Ball Arena'),
      ('Tampa Bay Lightning', v_start_date + interval '7 days', false, 'Amalie Arena'),
      ('Florida Panthers', v_start_date + interval '9 days', true, 'Ball Arena'),
      ('Carolina Hurricanes', v_start_date + interval '11 days', false, 'PNC Arena'),
      ('New Jersey Devils', v_start_date + interval '13 days', true, 'Ball Arena')
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