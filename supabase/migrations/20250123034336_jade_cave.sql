/*
  # Update players table RLS policies

  1. Changes
    - Add policy to allow authenticated users to insert players
    - Add policy to allow authenticated users to update players
    - These policies are needed for the roster update functionality

  2. Security
    - Maintains existing read access for everyone
    - Adds write access for authenticated users only
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Players are viewable by everyone" ON players;

-- Create new policies
CREATE POLICY "Players are viewable by everyone"
  ON players FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can insert players"
  ON players FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update players"
  ON players FOR UPDATE
  TO authenticated
  USING (true);