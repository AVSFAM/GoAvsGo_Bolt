-- First, remove all predictions
DELETE FROM predictions;

-- Then remove all games
DELETE FROM games;

-- Reset leaderboard points
UPDATE leaderboard
SET correct_predictions = 0,
    total_predictions = 0,
    points = 0,
    updated_at = now();

-- Remove all profiles except admin
DELETE FROM profiles
WHERE user_id NOT IN (
  SELECT id FROM auth.users WHERE email = 'info@avsfam.com'
);

-- Create a function to clean test data
CREATE OR REPLACE FUNCTION cleanup_test_data()
RETURNS void AS $$
BEGIN
  -- Remove all predictions for test games
  DELETE FROM predictions
  WHERE game_id IN (
    SELECT id FROM games 
    WHERE opponent LIKE 'Test Team%'
  );

  -- Remove test games
  DELETE FROM games 
  WHERE opponent LIKE 'Test Team%';

  -- Reset leaderboard
  UPDATE leaderboard
  SET correct_predictions = 0,
      total_predictions = 0,
      points = 0,
      updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;