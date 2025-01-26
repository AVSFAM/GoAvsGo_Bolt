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

  -- Verify operation was successful
  IF v_game_count = 0 THEN
    RAISE NOTICE 'No new games were added or updated';
  ELSE
    RAISE NOTICE '% games were processed', v_game_count;
  END IF;

EXCEPTION
  WHEN undefined_table THEN
    RAISE EXCEPTION 'Games table does not exist';
  WHEN insufficient_privilege THEN
    RAISE EXCEPTION 'Insufficient privileges to modify games';
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error syncing games: % %', SQLERRM, SQLSTATE;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION sync_games() TO authenticated;
GRANT EXECUTE ON FUNCTION sync_games() TO anon;

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