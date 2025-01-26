/*
  # Fix function parameter names

  1. Changes
    - Update parameter names to match client code
    - Keep explicit table aliases and column references
*/

-- Drop existing function
DROP FUNCTION IF EXISTS verify_game_predictions(uuid, uuid);

-- Create function with parameter names matching client code
CREATE OR REPLACE FUNCTION verify_game_predictions(
  game_id uuid,
  correct_player uuid
)
RETURNS void AS $$
BEGIN
  -- Update the game first with explicit table alias and parameter reference
  UPDATE games AS g
  SET correct_player_id = correct_player,
      verified = true
  WHERE g.id = game_id;

  -- Update all predictions for this game with explicit table alias and parameter reference
  UPDATE predictions AS p
  SET is_correct = (p.player_id = correct_player),
      admin_verified = true
  WHERE p.game_id = game_id;

  -- Update leaderboard with explicit table aliases and column references
  WITH user_stats AS (
    SELECT 
      pred.user_id,
      COUNT(*) FILTER (WHERE pred.is_correct = true) as correct_count,
      COUNT(*) as total_count,
      SUM(CASE WHEN pred.is_correct THEN 10 ELSE -5 END) as total_points
    FROM predictions pred
    JOIN games g ON g.id = pred.game_id
    WHERE pred.admin_verified = true
      AND g.verified = true
    GROUP BY pred.user_id
  )
  INSERT INTO leaderboard (
    user_id,
    correct_predictions,
    total_predictions,
    points,
    updated_at
  )
  SELECT 
    stats.user_id,
    stats.correct_count,
    stats.total_count,
    stats.total_points,
    now()
  FROM user_stats stats
  ON CONFLICT (user_id)
  DO UPDATE SET
    correct_predictions = EXCLUDED.correct_predictions,
    total_predictions = EXCLUDED.total_predictions,
    points = EXCLUDED.points,
    updated_at = EXCLUDED.updated_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;