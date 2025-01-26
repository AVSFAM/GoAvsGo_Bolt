-- First, remove all predictions for games on dates with duplicates
DELETE FROM predictions
WHERE game_id IN (
  SELECT id FROM games 
  WHERE game_time::date IN (
    '2024-01-30'::date, -- Edmonton games
    '2024-02-01'::date, -- Calgary games
    '2024-02-03'::date, -- St. Louis games
    '2024-02-05'::date, -- Dallas games
    '2024-02-07'::date, -- Vegas games
    '2024-02-09'::date  -- Arizona games
  )
);

-- Then remove all games on those dates
DELETE FROM games 
WHERE game_time::date IN (
  '2024-01-30'::date, -- Edmonton games
  '2024-02-01'::date, -- Calgary games
  '2024-02-03'::date, -- St. Louis games
  '2024-02-05'::date, -- Dallas games
  '2024-02-07'::date, -- Vegas games
  '2024-02-09'::date  -- Arizona games
);

-- Insert only the correct games for those dates
INSERT INTO games (opponent, game_time, is_home, location)
VALUES
  -- February Games
  ('Edmonton Oilers', '2024-02-07 19:30:00-07', false, 'Rogers Place');

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