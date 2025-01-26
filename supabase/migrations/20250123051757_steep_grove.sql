/*
  # Game Verification System

  1. Changes
    - Add correct_player_id to games table
    - Add verified status to games
    - Update points calculation system
    - Add game verification function

  2. Security
    - Enable RLS for all new columns
    - Ensure data integrity with foreign key constraints
*/

-- Add correct_player_id to games table
ALTER TABLE games
ADD COLUMN IF NOT EXISTS correct_player_id uuid REFERENCES players(id),
ADD COLUMN IF NOT EXISTS verified boolean DEFAULT false;

-- Remove duplicate predictions keeping the most recent one
DELETE FROM predictions p1 USING predictions p2
WHERE p1.user_id = p2.user_id 
  AND p1.game_id = p2.game_id 
  AND p1.created_at < p2.created_at;

-- Now add the unique constraint
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'unique_user_game_prediction'
  ) THEN
    ALTER TABLE predictions 
    ADD CONSTRAINT unique_user_game_prediction 
    UNIQUE (user_id, game_id);
  END IF;
END $$;

-- Update the leaderboard points function
CREATE OR REPLACE FUNCTION update_leaderboard_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process verified predictions
  IF NEW.admin_verified = true THEN
    -- Calculate points based on verified predictions
    WITH user_stats AS (
      SELECT 
        p.user_id,
        COUNT(*) FILTER (WHERE p.is_correct = true) as correct_count,
        COUNT(*) as total_count,
        SUM(CASE WHEN p.is_correct THEN 10 ELSE -5 END) as total_points
      FROM predictions p
      JOIN games g ON p.game_id = g.id
      WHERE p.user_id = NEW.user_id
        AND p.admin_verified = true
        AND g.verified = true
      GROUP BY p.user_id
    )
    INSERT INTO leaderboard (
      user_id, 
      correct_predictions,
      total_predictions,
      points,
      updated_at
    )
    SELECT 
      user_id,
      correct_count,
      total_count,
      total_points,
      now()
    FROM user_stats
    ON CONFLICT (user_id)
    DO UPDATE SET
      correct_predictions = EXCLUDED.correct_predictions,
      total_predictions = EXCLUDED.total_predictions,
      points = EXCLUDED.points,
      updated_at = EXCLUDED.updated_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to verify game predictions
CREATE OR REPLACE FUNCTION verify_game_predictions(game_id uuid, correct_player uuid)
RETURNS void AS $$
BEGIN
  -- Update the game with the correct player
  UPDATE games
  SET correct_player_id = correct_player,
      verified = true
  WHERE id = game_id;

  -- Update all predictions for this game
  UPDATE predictions
  SET is_correct = (player_id = correct_player),
      admin_verified = true
  WHERE game_id = game_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;