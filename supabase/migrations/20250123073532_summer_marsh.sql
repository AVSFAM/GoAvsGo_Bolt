/*
  # Fix verify_game_predictions function parameter order

  1. Changes
    - Match parameter order with client code (correct_player, game_id)
    - Use DECLARE ALIAS to avoid ambiguity
    - Prefix internal variables with v_
*/

-- Drop existing function
DROP FUNCTION IF EXISTS verify_game_predictions(uuid, uuid);

-- Create function with matching parameter order and ALIAS declarations
CREATE OR REPLACE FUNCTION verify_game_predictions(
  correct_player uuid,
  game_id uuid
)
RETURNS void AS $$
DECLARE
  v_game_id ALIAS FOR game_id;
  v_correct_player ALIAS FOR correct_player;
BEGIN
  UPDATE games AS g
  SET correct_player_id = v_correct_player,
      verified = true
  WHERE g.id = v_game_id;

  WITH updated_predictions AS (
    UPDATE predictions AS p
    SET is_correct = (p.player_id = v_correct_player),
        admin_verified = true
    WHERE p.game_id = v_game_id
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