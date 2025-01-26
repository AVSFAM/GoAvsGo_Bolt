/*
  # Simplify verify_game_predictions function

  1. Changes
    - Simplify the function to reduce complexity
    - Remove transaction blocks that may cause connection issues
    - Keep core functionality intact
    - Use consistent parameter names

  2. Security
    - Maintain SECURITY DEFINER setting
    - Keep existing RLS policies intact
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS verify_game_predictions(uuid, uuid);

-- Create simplified version of the function
CREATE OR REPLACE FUNCTION verify_game_predictions(
  game_id uuid,
  correct_player uuid
)
RETURNS void AS $$
BEGIN
  -- Update the game first
  UPDATE games
  SET correct_player_id = correct_player,
      verified = true
  WHERE id = game_id;

  -- Update all predictions for this game
  UPDATE predictions p
  SET is_correct = (p.player_id = correct_player),
      admin_verified = true
  WHERE p.game_id = game_id;

  -- Update leaderboard
  WITH user_stats AS (
    SELECT 
      p.user_id,
      COUNT(*) FILTER (WHERE p.is_correct = true) as correct_count,
      COUNT(*) as total_count,
      SUM(CASE WHEN p.is_correct THEN 10 ELSE -5 END) as total_points
    FROM predictions p
    JOIN games g ON p.game_id = g.id
    WHERE p.admin_verified = true
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;