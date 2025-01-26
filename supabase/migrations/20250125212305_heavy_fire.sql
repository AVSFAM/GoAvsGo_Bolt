-- Drop existing function if it exists
DROP FUNCTION IF EXISTS sync_games;

-- Create sync_games function with proper PostgREST support
CREATE OR REPLACE FUNCTION sync_games()
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
      ('Nashville Predators', v_start_date + interval '1 day', true, 'Ball Arena'),
      ('Winnipeg Jets', v_start_date + interval '3 days', false, 'Canada Life Centre'),
      ('Philadelphia Flyers', v_start_date + interval '5 days', true, 'Ball Arena'),
      ('Washington Capitals', v_start_date + interval '7 days', false, 'Capital One Arena'),
      ('Ottawa Senators', v_start_date + interval '9 days', true, 'Ball Arena'),
      ('Detroit Red Wings', v_start_date + interval '11 days', false, 'Little Caesars Arena'),
      ('Chicago Blackhawks', v_start_date + interval '13 days', true, 'Ball Arena')
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
COMMENT ON FUNCTION sync_games() IS 'Syncs upcoming games for the next 14 days';

-- Ensure RPC is enabled for this function
ALTER FUNCTION sync_games() SET "pgrst.select" = '*';