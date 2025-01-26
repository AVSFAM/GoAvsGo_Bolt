/*
  # Fix leaderboard display

  1. Changes
    - Drop and recreate leaderboard view with proper username handling
    - Ensure points are never null
    - Add proper sorting
    - Grant necessary permissions

  2. Security
    - Grant SELECT permissions to both authenticated and anonymous users
*/

-- Drop existing view if it exists
DROP VIEW IF EXISTS leaderboard_with_usernames;

-- Create the view with proper username handling and sorting
CREATE VIEW leaderboard_with_usernames AS
SELECT 
  l.id,
  l.user_id,
  p.username,
  l.correct_predictions,
  l.total_predictions,
  COALESCE(l.points, 0) as points,
  l.updated_at
FROM leaderboard l
INNER JOIN profiles p ON l.user_id = p.user_id
ORDER BY COALESCE(l.points, 0) DESC;

-- Grant access to the view
GRANT SELECT ON leaderboard_with_usernames TO authenticated;
GRANT SELECT ON leaderboard_with_usernames TO anon;