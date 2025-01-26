-- First, ensure verified column exists and has default false
ALTER TABLE games 
ALTER COLUMN verified SET DEFAULT false;

-- Set all games to unverified
UPDATE games
SET 
  verified = false,
  correct_player_id = null;

-- Add constraint to prevent verifying future games if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'no_verify_future_games'
  ) THEN
    ALTER TABLE games 
    ADD CONSTRAINT no_verify_future_games 
    CHECK (
      CASE 
        WHEN verified = true THEN game_time < now()
        ELSE true
      END
    );
  END IF;
END $$;

-- Reset any predictions for unverified games
UPDATE predictions p
SET 
  is_correct = false,
  admin_verified = false
FROM games g
WHERE p.game_id = g.id
AND g.verified = false;

-- Recalculate points for all users
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
UPDATE leaderboard l
SET 
  correct_predictions = COALESCE(s.correct_count, 0),
  total_predictions = COALESCE(s.total_count, 0),
  points = GREATEST(COALESCE(s.total_points, 0), 0),
  updated_at = now()
FROM user_stats s
WHERE l.user_id = s.user_id;

-- Add index for game verification status
CREATE INDEX IF NOT EXISTS idx_games_verified 
ON games (verified, game_time);