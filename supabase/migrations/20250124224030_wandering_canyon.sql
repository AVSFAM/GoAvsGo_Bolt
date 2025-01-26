-- Drop existing policies for games table
DROP POLICY IF EXISTS "Games are viewable by everyone" ON games;
DROP POLICY IF EXISTS "Admins can manage games" ON games;

-- Create improved policies for games table
CREATE POLICY "Anyone can view games"
  ON games FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage games"
  ON games FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update games"
  ON games FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can delete games"
  ON games FOR DELETE
  TO authenticated
  USING (true);

-- Ensure RLS is enabled
ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON games TO authenticated;
GRANT SELECT ON games TO anon;

-- Create function to sync games with proper permissions
CREATE OR REPLACE FUNCTION sync_games()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete old unverified games
  DELETE FROM games
  WHERE game_time < now()
    AND verified = false;

  -- Insert new games
  INSERT INTO games (opponent, game_time, is_home, location, verified)
  SELECT 
    opponent,
    game_time,
    is_home,
    location,
    false as verified
  FROM (
    SELECT 
      unnest(ARRAY[
        'Boston Bruins',
        'New York Rangers',
        'Toronto Maple Leafs',
        'Tampa Bay Lightning',
        'Florida Panthers',
        'Carolina Hurricanes',
        'New Jersey Devils',
        'Detroit Red Wings'
      ]) as opponent,
      generate_series(
        date_trunc('hour', now()) + interval '1 day',
        date_trunc('hour', now()) + interval '14 days',
        interval '2 days'
      ) as game_time,
      generate_series(1, 8) % 2 = 0 as is_home,
      CASE WHEN generate_series(1, 8) % 2 = 0 
        THEN 'Ball Arena'
        ELSE 'Away Arena'
      END as location
  ) as games;
END;
$$;