-- Drop existing verify_game_predictions function
DROP FUNCTION IF EXISTS verify_game_predictions(uuid, uuid);

-- Create improved verify_game_predictions function with proper column references
CREATE OR REPLACE FUNCTION verify_game_predictions(
  target_game_id uuid,
  target_player_id uuid
)
RETURNS void AS $$
DECLARE
  game_exists boolean;
  game_already_verified boolean;
BEGIN
  -- Check if game exists
  SELECT EXISTS (
    SELECT 1 FROM games WHERE id = target_game_id
  ) INTO game_exists;

  IF NOT game_exists THEN
    RAISE EXCEPTION 'Game with ID % does not exist', target_game_id;
  END IF;

  -- Check if game is already verified
  SELECT verified INTO game_already_verified
  FROM games
  WHERE id = target_game_id;

  IF game_already_verified THEN
    RAISE EXCEPTION 'Game is already verified';
  END IF;

  -- Begin atomic transaction
  BEGIN
    -- Update the game with the correct player and mark as verified
    UPDATE games
    SET correct_player_id = target_player_id,
        verified = true
    WHERE id = target_game_id;

    -- Update all predictions for this game
    UPDATE predictions p
    SET is_correct = (p.player_id = target_player_id),
        admin_verified = true
    WHERE p.game_id = target_game_id;

    -- Recalculate points for all affected users
    WITH affected_users AS (
      SELECT DISTINCT p.user_id
      FROM predictions p
      WHERE p.game_id = target_game_id
    ),
    user_stats AS (
      SELECT 
        p.user_id,
        COUNT(*) FILTER (WHERE p.is_correct = true) as correct_count,
        COUNT(*) as total_count,
        SUM(CASE WHEN p.is_correct THEN 10 ELSE -5 END) as total_points
      FROM predictions p
      JOIN games g ON p.game_id = g.id
      WHERE p.user_id IN (SELECT user_id FROM affected_users)
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

    -- If we get here, everything succeeded
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      -- If anything fails, the transaction will be rolled back
      RAISE EXCEPTION 'Failed to verify game: %', SQLERRM;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;