/*
  # Fix verify_game_predictions function

  1. Changes
    - Update parameter names to match client calls
    - Simplify function to reduce complexity
    - Maintain same functionality with clearer parameter names

  2. Security
    - Maintains SECURITY DEFINER setting
    - Preserves existing access controls
*/

-- Drop existing function
DROP FUNCTION IF EXISTS verify_game_predictions(uuid, uuid);

-- Create function with matching parameter names
CREATE OR REPLACE FUNCTION verify_game_predictions(
  correct_player uuid,
  game_id uuid
)
RETURNS void AS $$
BEGIN
  -- Update the game first
  UPDATE games
  SET correct_player_id = correct_player,
      verified = true
  WHERE id = game_id;

  -- Update all predictions for this game
  UPDATE predictions
  SET is_correct = (player_id = correct_player),
      admin_verified = true
  WHERE game_id = game_id;

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