/*
  # Fix verify_game_predictions function

  1. Changes
    - Use underscored parameter names to avoid ambiguity
    - Add WITH clause for predictions update
    - Fully qualify all column references
*/

-- Drop existing function
DROP FUNCTION IF EXISTS verify_game_predictions(uuid, uuid);

-- Create function with underscored parameters and WITH clause
CREATE OR REPLACE FUNCTION verify_game_predictions(
  _game_id uuid,
  _correct_player uuid
)
RETURNS void AS $$
BEGIN
  UPDATE games AS g
  SET correct_player_id = _correct_player,
      verified = true
  WHERE g.id = _game_id;

  WITH updated_predictions AS (
    UPDATE predictions AS p
    SET is_correct = (p.player_id = _correct_player),
        admin_verified = true
    WHERE p.game_id = _game_id
    RETURNING p.user_id, p.is_correct
  ),
  user_stats AS (
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