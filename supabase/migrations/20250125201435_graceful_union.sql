-- Drop existing function if it exists
DROP FUNCTION IF EXISTS sync_games();

-- Create sync_games function with proper PostgREST support
CREATE OR REPLACE FUNCTION sync_games()
RETURNS TABLE (
  success boolean,
  games_processed integer,
  message text
)
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

  -- Return result as a single row
  RETURN QUERY SELECT 
    true::boolean as success,
    v_game_count::integer as games_processed,
    format('%s games were processed', v_game_count)::text as message;

EXCEPTION
  WHEN undefined_table THEN
    RETURN QUERY SELECT 
      false::boolean,
      0::integer,
      'Games table does not exist'::text;
  WHEN insufficient_privilege THEN
    RETURN QUERY SELECT 
      false::boolean,
      0::integer,
      'Insufficient privileges to modify games'::text;
  WHEN OTHERS THEN
    RETURN QUERY SELECT 
      false::boolean,
      0::integer,
      format('Error syncing games: %s', SQLERRM)::text;
END;
$$;

-- Grant execute permission to all users
GRANT EXECUTE ON FUNCTION sync_games() TO authenticated;
GRANT EXECUTE ON FUNCTION sync_games() TO anon;

-- Add comment to help PostgREST
COMMENT ON FUNCTION sync_games() IS 'Syncs upcoming games for the next 14 days';