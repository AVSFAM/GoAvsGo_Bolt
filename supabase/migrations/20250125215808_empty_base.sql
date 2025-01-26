-- Drop old sync_games function if it exists
DROP FUNCTION IF EXISTS sync_games();

-- Create new sync_games function that uses fallback data
CREATE OR REPLACE FUNCTION sync_games()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_games_result jsonb;
  v_roster_result jsonb;
BEGIN
  -- Load fallback games
  SELECT load_fallback_games() INTO v_games_result;
  
  -- Load fallback roster
  SELECT load_fallback_roster() INTO v_roster_result;
  
  -- Return combined result
  RETURN jsonb_build_object(
    'success', true,
    'games_processed', (v_games_result->>'games_processed')::integer,
    'players_processed', (v_roster_result->>'players_processed')::integer,
    'message', 'Successfully loaded fallback data'
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION sync_games() TO authenticated;
GRANT EXECUTE ON FUNCTION sync_games() TO anon;

-- Add helpful comment
COMMENT ON FUNCTION sync_games() IS 'Syncs games and roster using fallback data';