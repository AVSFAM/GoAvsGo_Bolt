-- First, remove all predictions for games that have duplicates
DELETE FROM predictions
WHERE game_id IN (
  SELECT g1.id
  FROM games g1
  JOIN games g2 ON g1.opponent = g2.opponent 
    AND DATE_TRUNC('day', g1.game_time) = DATE_TRUNC('day', g2.game_time)
    AND g1.id > g2.id
);

-- Then remove the duplicate games, keeping only the earliest created record for each game
DELETE FROM games g1
WHERE EXISTS (
  SELECT 1
  FROM games g2
  WHERE g1.opponent = g2.opponent 
    AND DATE_TRUNC('day', g1.game_time) = DATE_TRUNC('day', g2.game_time)
    AND g1.id > g2.id
);

-- Update game times to ensure they are correct
UPDATE games
SET 
  game_time = 
    CASE 
      -- April games should be in MDT (-06)
      WHEN EXTRACT(MONTH FROM game_time) = 4 
      THEN game_time AT TIME ZONE 'MST' AT TIME ZONE 'MDT'
      -- All other games remain in MST (-07)
      ELSE game_time
    END,
  -- Ensure home/away and locations are correct
  is_home = 
    CASE opponent
      WHEN 'New York Rangers' THEN false
      WHEN 'New York Islanders' THEN false
      WHEN 'St. Louis Blues' THEN 
        CASE WHEN game_time::date = '2024-01-31' THEN true
             WHEN game_time::date = '2024-02-23' THEN false
             WHEN game_time::date = '2024-03-29' THEN true
             WHEN game_time::date = '2024-04-05' THEN false
        END
      WHEN 'Philadelphia Flyers' THEN true
      WHEN 'Vancouver Canucks' THEN 
        CASE WHEN game_time::date = '2024-02-04' THEN false
             WHEN game_time::date = '2024-04-10' THEN true
        END
      WHEN 'Calgary Flames' THEN 
        CASE WHEN game_time::date = '2024-02-06' THEN false
             WHEN game_time::date = '2024-03-14' THEN false
             WHEN game_time::date = '2024-03-31' THEN true
        END
      WHEN 'Edmonton Oilers' THEN false
      WHEN 'Nashville Predators' THEN false
      WHEN 'New Jersey Devils' THEN true
      WHEN 'Minnesota Wild' THEN 
        CASE WHEN game_time::date = '2024-02-28' THEN true
             WHEN game_time::date = '2024-03-11' THEN false
        END
      WHEN 'Pittsburgh Penguins' THEN true
      WHEN 'San Jose Sharks' THEN true
      WHEN 'Toronto Maple Leafs' THEN true
      WHEN 'Chicago Blackhawks' THEN 
        CASE WHEN game_time::date = '2024-03-10' THEN true
             WHEN game_time::date = '2024-04-02' THEN false
        END
      WHEN 'Dallas Stars' THEN true
      WHEN 'Detroit Red Wings' THEN true
      WHEN 'Los Angeles Kings' THEN false
      WHEN 'Vegas Golden Knights' THEN true
      WHEN 'Columbus Blue Jackets' THEN false
    END,
  location = 
    CASE 
      WHEN is_home THEN 'Ball Arena'
      ELSE 
        CASE opponent
          WHEN 'New York Rangers' THEN 'Madison Square Garden'
          WHEN 'New York Islanders' THEN 'UBS Arena'
          WHEN 'St. Louis Blues' THEN 'Enterprise Center'
          WHEN 'Vancouver Canucks' THEN 'Rogers Arena'
          WHEN 'Calgary Flames' THEN 'Scotiabank Saddledome'
          WHEN 'Edmonton Oilers' THEN 'Rogers Place'
          WHEN 'Nashville Predators' THEN 'Bridgestone Arena'
          WHEN 'Minnesota Wild' THEN 'Xcel Energy Center'
          WHEN 'Chicago Blackhawks' THEN 'United Center'
          WHEN 'Los Angeles Kings' THEN 'Crypto.com Arena'
          WHEN 'Columbus Blue Jackets' THEN 'Nationwide Arena'
        END
    END;

-- Recalculate points for all users
WITH user_stats AS (
  SELECT 
    p.user_id,
    COUNT(*) FILTER (WHERE p.is_correct = true) as correct_count,
    COUNT(*) as total_count,
    SUM(CASE WHEN p.is_correct THEN 10 ELSE -5 END) as total_points
  FROM predictions p
  JOIN games g ON p.game_id = g.id
  WHERE p.admin_verified = true
    AND g.verified = true
  GROUP BY p.user_id
)
UPDATE leaderboard l
SET 
  correct_predictions = COALESCE(s.correct_count, 0),
  total_predictions = COALESCE(s.total_count, 0),
  points = GREATEST(COALESCE(s.total_points, 0), 0),
  updated_at = now()
FROM user_stats s
WHERE l.user_id = s.user_id;