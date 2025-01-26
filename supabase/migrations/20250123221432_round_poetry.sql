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
  COALESCE(l.points, 0) as points,
  l.updated_at
FROM leaderboard l
LEFT JOIN profiles p ON l.user_id = p.user_id
ORDER BY COALESCE(l.points, 0) DESC;

-- Grant access to the view
GRANT SELECT ON leaderboard_with_usernames TO authenticated;
GRANT SELECT ON leaderboard_with_usernames TO anon;