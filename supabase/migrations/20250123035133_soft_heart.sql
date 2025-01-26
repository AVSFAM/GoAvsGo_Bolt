/*
  # Fix player duplicates and add constraints

  1. Changes
    - Add unique constraint to prevent future duplicates
    - Add ON DELETE CASCADE to predictions table to allow player cleanup
  
  2. Security
    - No changes to RLS policies
*/

-- First, modify the predictions table to cascade deletes
ALTER TABLE predictions
DROP CONSTRAINT predictions_player_id_fkey,
ADD CONSTRAINT predictions_player_id_fkey 
  FOREIGN KEY (player_id) 
  REFERENCES players(id) 
  ON DELETE CASCADE;

-- Add a unique constraint to prevent duplicates
ALTER TABLE players
ADD CONSTRAINT unique_player_identity 
  UNIQUE (name, number, position);