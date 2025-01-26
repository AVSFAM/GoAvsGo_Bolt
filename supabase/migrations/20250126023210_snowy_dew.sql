-- Update Rangers game time to 11:00 AM MST
UPDATE games 
SET game_time = '2024-01-26 11:00:00-07'
WHERE opponent = 'New York Rangers'
  AND game_time::date = '2024-01-26'::date;

-- Ensure any predictions for this game are preserved
-- by updating the game_id reference in predictions
WITH old_game AS (
  SELECT id as old_id, 
         (SELECT id FROM games WHERE opponent = 'New York Rangers' AND game_time::date = '2024-01-26'::date) as new_id
  FROM games 
  WHERE opponent = 'New York Rangers'
  AND game_time::date = '2024-01-26'::date
)
UPDATE predictions
SET game_id = old_game.new_id
FROM old_game
WHERE game_id = old_game.old_id;