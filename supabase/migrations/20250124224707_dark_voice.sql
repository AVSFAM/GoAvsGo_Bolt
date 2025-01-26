-- Drop existing sync_games function if it exists
DROP FUNCTION IF EXISTS sync_games();

-- Create improved sync_games function with proper error handling
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
  VALUES
    ('Boston Bruins', v_start_date + interval '1 day', true, 'Ball Arena', false),
    ('New York Rangers', v_start_date + interval '3 days', false, 'Madison Square Garden', false),
    ('Toronto Maple Leafs', v_start_date + interval '5 days', true, 'Ball Arena', false),
    ('Tampa Bay Lightning', v_start_date + interval '7 days', false, 'Amalie Arena', false),
    ('Florida Panthers', v_start_date + interval '9 days', true, 'Ball Arena', false),
    ('Carolina Hurricanes', v_start_date + interval '11 days', false, 'PNC Arena', false),
    ('New Jersey Devils', v_start_date + interval '13 days', true, 'Ball Arena', false)
  ON CONFLICT (game_time, opponent) 
  DO UPDATE SET
    is_home = EXCLUDED.is_home,
    location = EXCLUDED.location;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error syncing games: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION sync_games() TO authenticated;

-- Ensure RLS is enabled
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

-- Add unique constraint if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'unique_game_time_opponent'
  ) THEN
    ALTER TABLE games 
    ADD CONSTRAINT unique_game_time_opponent 
    UNIQUE (game_time, opponent);
  END IF;
END $$;