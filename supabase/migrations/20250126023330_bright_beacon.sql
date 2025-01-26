-- Unverify all future games
UPDATE games
SET 
  verified = false,
  correct_player_id = null
WHERE game_time > now();

-- Reset any predictions for future games
UPDATE predictions p
SET 
  is_correct = false,
  admin_verified = false
FROM games g
WHERE p.game_id = g.id
AND g.game_time > now();

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