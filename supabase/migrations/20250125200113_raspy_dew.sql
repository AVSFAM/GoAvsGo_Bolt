-- Drop existing function if it exists
DROP FUNCTION IF EXISTS sync_games();

-- Create sync_games function with proper error handling and RETURNS JSON
CREATE OR REPLACE FUNCTION sync_games()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_start_date timestamptz;
  v_end_date timestamptz;
  v_game_count integer;
  v_result json;
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

  -- Prepare result JSON
  SELECT json_build_object(
    'success', true,
    'games_processed', v_game_count,
    'message', v_game_count || ' games were processed'
  ) INTO v_result;

  RETURN v_result;

EXCEPTION
  WHEN undefined_table THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Games table does not exist'
    );
  WHEN insufficient_privilege THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Insufficient privileges to modify games'
    );
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Error syncing games: ' || SQLERRM
    );
END;
$$;

-- Grant execute permission to all users
GRANT EXECUTE ON FUNCTION sync_games() TO authenticated;
GRANT EXECUTE ON FUNCTION sync_games() TO anon;

-- Comment to help PostgREST recognize the function
COMMENT ON FUNCTION sync_games() IS 'Syncs upcoming games for the next 14 days';

-- Ensure the function is exposed via PostgREST
ALTER FUNCTION sync_games() SET "pgrst.select" = 'sync_games';