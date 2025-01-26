/*
  # Remove test games and clean up

  1. Changes
    - Remove all test games
    - Remove all predictions for test games
    - Reset leaderboard points
*/

-- First, remove all predictions for test games
DELETE FROM predictions
WHERE game_id IN (
  SELECT id FROM games 
  WHERE opponent LIKE 'Test Team%'
);

-- Then remove the test games
DELETE FROM games 
WHERE opponent LIKE 'Test Team%';

-- Reset leaderboard points
UPDATE leaderboard
SET correct_predictions = 0,
    total_predictions = 0,
    points = 0,
    updated_at = now();