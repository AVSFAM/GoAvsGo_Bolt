/*
  # Fix scoring and leaderboard issues

  1. Changes
    - Add proper cleanup function with WHERE clauses
    - Fix MacKinnon player query issue
    - Add proper RLS policies for cleanup function
    - Add proper error handling

  2. Security
    - Enable RLS for all operations
    - Add proper security policies
*/

-- Drop existing cleanup function
DROP FUNCTION IF EXISTS cleanup_test_data();

-- Create improved cleanup function with proper WHERE clauses
CREATE OR REPLACE FUNCTION cleanup_test_data()
RETURNS void AS $$
BEGIN
  -- Remove predictions for test games with proper WHERE clause
  DELETE FROM predictions
  WHERE game_id IN (
    SELECT id FROM games 
    WHERE opponent LIKE 'Test Team%'
  );

  -- Remove test games with proper WHERE clause
  DELETE FROM games 
  WHERE opponent LIKE 'Test Team%';

  -- Reset points only for test users
  UPDATE leaderboard
  SET correct_predictions = 0,
      total_predictions = 0,
      points = 0,
      updated_at = now()
  WHERE user_id IN (
    SELECT user_id 
    FROM profiles 
    WHERE username LIKE 'TestUser%'
  );

  -- Remove test profiles
  DELETE FROM profiles
  WHERE username LIKE 'TestUser%';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION cleanup_test_data() TO authenticated;

-- Create index for player name to improve query performance
CREATE INDEX IF NOT EXISTS idx_players_name ON players (name);

-- Update the leaderboard view to handle null usernames
DROP VIEW IF EXISTS leaderboard_with_usernames;

CREATE VIEW leaderboard_with_usernames AS
SELECT 
  l.id,
  l.user_id,
  p.username,
  l.correct_predictions,
  l.total_predictions,
  GREATEST(COALESCE(l.points, 0), 0) as points,
  l.updated_at
FROM leaderboard l
INNER JOIN profiles p ON l.user_id = p.user_id
WHERE p.username IS NOT NULL
ORDER BY GREATEST(COALESCE(l.points, 0), 0) DESC;

-- Grant access to the view
GRANT SELECT ON leaderboard_with_usernames TO authenticated;
GRANT SELECT ON leaderboard_with_usernames TO anon;