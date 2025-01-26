-- Drop any existing policies
DROP POLICY IF EXISTS "Players are viewable by everyone" ON players;
DROP POLICY IF EXISTS "Authenticated users can insert players" ON players;
DROP POLICY IF EXISTS "Authenticated users can update players" ON players;
DROP POLICY IF EXISTS "Authenticated users can delete players" ON players;
DROP POLICY IF EXISTS "Anyone can view games" ON games;
DROP POLICY IF EXISTS "Authenticated users can manage games" ON games;

-- Create policies for players table
CREATE POLICY "Anyone can view players"
  ON players FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage players"
  ON players FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create policies for games table
CREATE POLICY "Anyone can view games"
  ON players FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage games"
  ON games FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Grant necessary permissions
GRANT ALL ON players TO authenticated;
GRANT SELECT ON players TO anon;
GRANT ALL ON games TO authenticated;
GRANT SELECT ON games TO anon;