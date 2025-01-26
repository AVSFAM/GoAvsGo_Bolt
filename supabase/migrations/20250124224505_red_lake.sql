-- Add unique constraint to games table
ALTER TABLE games 
ADD CONSTRAINT unique_game_time_opponent 
UNIQUE (game_time, opponent);

-- Drop existing sync_games function
DROP FUNCTION IF EXISTS sync_games();

-- Create improved sync_games function with better error handling
CREATE OR REPLACE FUNCTION sync_games()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_start_date timestamptz;
  v_end_date timestamptz;
BEGIN
  -- Set date range
  v_start_date := date_trunc('hour', now()) + interval '1 day';
  v_end_date := date_trunc('hour', now()) + interval '14 days';

  -- Delete old unverified games
  DELETE FROM games
  WHERE game_time < now()
    AND verified = false;

  -- Insert new games for the next 14 days
  INSERT INTO games (opponent, game_time, is_home, location, verified)
  SELECT 
    opponent,
    game_time,
    is_home,
    CASE WHEN is_home THEN 'Ball Arena' ELSE opponent || ' Arena' END as location,
    false as verified
  FROM (
    SELECT 
      opponent,
      game_time,
      row_number() % 2 = 1 as is_home
    FROM (
      SELECT unnest(ARRAY[
        'Boston Bruins',
        'New York Rangers',
        'Toronto Maple Leafs',
        'Tampa Bay Lightning',
        'Florida Panthers',
        'Carolina Hurricanes',
        'New Jersey Devils',
        'Detroit Red Wings',
        'Montreal Canadiens',
        'Ottawa Senators',
        'Buffalo Sabres',
        'Pittsburgh Penguins',
        'Washington Capitals',
        'Philadelphia Flyers'
      ]) as opponent,
      generate_series(
        v_start_date,
        v_end_date,
        interval '2 days'
      ) as game_time
    ) s
  ) g
  ON CONFLICT (game_time, opponent) DO UPDATE
  SET 
    is_home = EXCLUDED.is_home,
    location = EXCLUDED.location;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error syncing games: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION sync_games() TO authenticated;

-- Ensure RLS is enabled and policies are correct
ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view games" ON games;
DROP POLICY IF EXISTS "Authenticated users can manage games" ON games;

-- Create simplified policies
CREATE POLICY "Anyone can view games"
  ON games FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage games"
  ON games FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Grant necessary permissions
GRANT ALL ON games TO authenticated;
GRANT SELECT ON games TO anon;