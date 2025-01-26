-- First, remove all predictions for test/duplicate games
DELETE FROM predictions
WHERE game_id IN (
  SELECT id FROM games 
  WHERE opponent LIKE 'Test Team%'
  OR game_time::date = '2024-01-28'::date -- Remove ALL games on Jan 28
  OR (opponent = 'Los Angeles Kings' AND game_time::date = '2024-01-25'::date)
  OR (opponent = 'Vegas Golden Knights' AND game_time::date = '2024-01-27'::date)
);

-- Then remove the test/duplicate games
DELETE FROM games 
WHERE opponent LIKE 'Test Team%'
OR game_time::date = '2024-01-28'::date -- Remove ALL games on Jan 28
OR (opponent = 'Los Angeles Kings' AND game_time::date = '2024-01-25'::date)
OR (opponent = 'Vegas Golden Knights' AND game_time::date = '2024-01-27'::date);

-- Reset points for any affected users
WITH affected_users AS (
  SELECT DISTINCT user_id
  FROM predictions p
  JOIN games g ON p.game_id = g.id
  WHERE g.verified = true
)
UPDATE leaderboard l
SET 
  correct_predictions = COALESCE(
    (SELECT COUNT(*) FROM predictions p
     JOIN games g ON p.game_id = g.id
     WHERE p.user_id = l.user_id 
     AND p.is_correct = true 
     AND g.verified = true),
    0
  ),
  total_predictions = COALESCE(
    (SELECT COUNT(*) FROM predictions p
     JOIN games g ON p.game_id = g.id
     WHERE p.user_id = l.user_id
     AND g.verified = true),
    0
  ),
  points = COALESCE(
    (SELECT SUM(CASE WHEN p.is_correct THEN 10 ELSE -5 END)
     FROM predictions p
     JOIN games g ON p.game_id = g.id
     WHERE p.user_id = l.user_id
     AND g.verified = true),
    0
  )
WHERE l.user_id IN (SELECT user_id FROM affected_users);