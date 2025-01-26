-- Drop the existing view if it exists
DROP VIEW IF EXISTS leaderboard_with_usernames;

-- Create an improved view that properly joins with profiles
CREATE OR REPLACE VIEW leaderboard_with_usernames AS
SELECT 
  l.id,
  l.user_id,
  p.username,
  l.correct_predictions,
  l.total_predictions,
  l.points,
  l.updated_at
FROM leaderboard l
LEFT JOIN profiles p ON l.user_id = p.user_id
WHERE l.points > 0
ORDER BY l.points DESC;

-- Refresh the leaderboard data
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