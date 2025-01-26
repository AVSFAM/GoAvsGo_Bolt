/*
  # Fix leaderboard trigger function

  1. Changes
    - Update trigger function to handle all prediction updates
    - Add unique constraint to leaderboard
    - Reset function to properly track points
*/

-- First, drop the existing trigger and function
DROP TRIGGER IF EXISTS update_leaderboard_on_prediction ON predictions;
DROP FUNCTION IF EXISTS update_leaderboard_points;

-- Add unique constraint to leaderboard if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'leaderboard_user_id_key'
  ) THEN
    ALTER TABLE leaderboard ADD CONSTRAINT leaderboard_user_id_key UNIQUE (user_id);
  END IF;
END $$;

-- Create new function to update points
CREATE OR REPLACE FUNCTION update_leaderboard_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process verified predictions
  IF NEW.admin_verified = true THEN
    -- Calculate points
    WITH user_stats AS (
      SELECT 
        user_id,
        COUNT(*) FILTER (WHERE is_correct = true) as correct_count,
        COUNT(*) as total_count,
        SUM(CASE WHEN is_correct THEN 10 ELSE -5 END) as total_points
      FROM predictions
      WHERE user_id = NEW.user_id
        AND admin_verified = true
      GROUP BY user_id
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

-- Create new trigger
CREATE TRIGGER update_leaderboard_on_prediction
  AFTER UPDATE ON predictions
  FOR EACH ROW
  WHEN (OLD.admin_verified IS DISTINCT FROM NEW.admin_verified OR OLD.is_correct IS DISTINCT FROM NEW.is_correct)
  EXECUTE FUNCTION update_leaderboard_points();