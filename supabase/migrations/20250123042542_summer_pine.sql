/*
  # Update scoring system for predictions

  1. Changes
    - Add points column to leaderboard table
    - Add trigger to update points when predictions are verified
    - Update leaderboard policies

  2. Points System
    - Correct prediction: +10 points
    - Incorrect prediction: -5 points
*/

-- Add points column to leaderboard
ALTER TABLE leaderboard
ADD COLUMN points integer DEFAULT 0;

-- Create function to update points
CREATE OR REPLACE FUNCTION update_leaderboard_points()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process verified predictions
  IF NEW.admin_verified = true THEN
    -- Update or create leaderboard entry
    INSERT INTO leaderboard (user_id, correct_predictions, total_predictions, points)
    VALUES (
      NEW.user_id,
      CASE WHEN NEW.is_correct THEN 1 ELSE 0 END,
      1,
      CASE WHEN NEW.is_correct THEN 10 ELSE -5 END
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
      correct_predictions = CASE WHEN NEW.is_correct 
        THEN leaderboard.correct_predictions + 1 
        ELSE leaderboard.correct_predictions END,
      total_predictions = leaderboard.total_predictions + 1,
      points = leaderboard.points + (CASE WHEN NEW.is_correct THEN 10 ELSE -5 END),
      updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for predictions
DROP TRIGGER IF EXISTS update_leaderboard_on_prediction ON predictions;
CREATE TRIGGER update_leaderboard_on_prediction
  AFTER UPDATE ON predictions
  FOR EACH ROW
  WHEN (OLD.admin_verified IS DISTINCT FROM NEW.admin_verified)
  EXECUTE FUNCTION update_leaderboard_points();