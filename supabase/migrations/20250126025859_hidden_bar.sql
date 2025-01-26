/*
  # Clean up duplicate games and verification status

  1. Changes
    - Remove any remaining duplicate games
    - Ensure all future games are unverified
    - Reset predictions for future games
    - Recalculate leaderboard points
    - Add index to improve game lookup performance

  2. Security
    - Maintains data integrity by preventing future games from being verified
    - Ensures accurate leaderboard scores
*/

-- First, identify and remove duplicate games
WITH DuplicateGames AS (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('day', game_time), opponent 
                             ORDER BY id) as rn
    FROM games
  ) t
  WHERE rn > 1
)
DELETE FROM predictions
WHERE game_id IN (SELECT id FROM DuplicateGames);

DELETE FROM games
WHERE id IN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('day', game_time), opponent 
                             ORDER BY id) as rn
    FROM games
  ) t
  WHERE rn > 1
);

-- Ensure all future games are unverified
UPDATE games
SET 
  verified = false,
  correct_player_id = null
WHERE game_time > now();

-- Reset predictions for future games
UPDATE predictions p
SET 
  is_correct = false,
  admin_verified = false
FROM games g
WHERE p.game_id = g.id
AND g.game_time > now();

-- Recalculate points based only on past verified games
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
    AND g.game_time < now()
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

-- Add index to improve game lookup performance
CREATE INDEX IF NOT EXISTS idx_games_time_opponent 
ON games (DATE_TRUNC('day', game_time), opponent);

-- Add index for game time queries
CREATE INDEX IF NOT EXISTS idx_games_time 
ON games (game_time);

-- Analyze tables to update statistics
ANALYZE games;
ANALYZE predictions;
ANALYZE leaderboard;