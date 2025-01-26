-- Drop existing policies for games table
DROP POLICY IF EXISTS "Anyone can view games" ON games;
DROP POLICY IF EXISTS "Authenticated users can manage games" ON games;

-- Create simplified policies for games table
CREATE POLICY "Anyone can view games"
  ON games FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage games"
  ON games FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Ensure RLS is enabled
ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON games TO authenticated;
GRANT SELECT ON games TO anon;

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