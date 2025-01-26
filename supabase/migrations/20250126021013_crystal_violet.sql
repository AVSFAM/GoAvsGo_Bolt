-- First, remove all predictions for duplicate Coyotes games
DELETE FROM predictions
WHERE game_id IN (
  SELECT id FROM games 
  WHERE opponent = 'Arizona Coyotes'
  AND game_time::date = '2024-02-09'::date
);

-- Then remove all duplicate Coyotes games from February 9th
DELETE FROM games 
WHERE opponent = 'Arizona Coyotes'
AND game_time::date = '2024-02-09'::date;

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