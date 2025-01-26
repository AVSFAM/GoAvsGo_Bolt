/*
  # Fix leaderboard view and points calculation

  1. Changes
    - Drop and recreate leaderboard view with proper username handling
    - Update points calculation logic
    - Add proper view permissions

  2. Security
    - Maintain RLS policies
    - Grant proper view permissions
*/

-- Drop existing view if it exists
DROP VIEW IF EXISTS leaderboard_with_usernames;

-- Create the view with proper username handling and sorting
CREATE VIEW leaderboard_with_usernames AS
SELECT 
  l.id,
  l.user_id,
  COALESCE(p.username, 'Anonymous Player') as username,
  l.correct_predictions,
  l.total_predictions,
  l.points,
  l.updated_at
FROM leaderboard l
LEFT JOIN profiles p ON l.user_id = p.user_id
ORDER BY l.points DESC NULLS LAST;

-- Grant access to the view
GRANT SELECT ON leaderboard_with_usernames TO authenticated;
GRANT SELECT ON leaderboard_with_usernames TO anon;

-- Refresh the leaderboard data
WITH user_stats AS (
  SELECT 
    p.user_id,
    COUNT(*) FILTER (WHERE p.is_correct = true) as correct_count,
    COUNT(*) as total_count,
    SUM(CASE WHEN p.is_correct THEN 10 ELSE -5 END) as points
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
  GREATEST(points, 0),
  now()
FROM user_stats
ON CONFLICT (user_id)
DO UPDATE SET
  correct_predictions = EXCLUDED.correct_predictions,
  total_predictions = EXCLUDED.total_predictions,
  points = GREATEST(EXCLUDED.points, 0),
  updated_at = EXCLUDED.updated_at;