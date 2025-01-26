/*
  # Add delete policy for players table

  1. Changes
    - Add policy to allow authenticated users to delete players
    
  2. Security
    - Only authenticated users can delete players
*/

CREATE POLICY "Authenticated users can delete players"
  ON players FOR DELETE
  TO authenticated
  USING (true);