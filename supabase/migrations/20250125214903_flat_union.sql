-- First, remove ALL test data
DELETE FROM predictions;

-- Remove ALL games
DELETE FROM games;

-- Remove ALL leaderboard entries
DELETE FROM leaderboard;

-- Remove ALL profiles except admin
DELETE FROM profiles
WHERE user_id NOT IN (
  SELECT id FROM auth.users WHERE email = 'info@avsfam.com'
);

-- Remove ALL auth users except admin (this requires superuser privileges)
DELETE FROM auth.users
WHERE email != 'info@avsfam.com';

-- Insert ONLY real upcoming Avalanche games with proper times and locations
INSERT INTO games (opponent, game_time, is_home, location)
VALUES
  ('Nashville Predators', now() + interval '2 days', true, 'Ball Arena'),
  ('Winnipeg Jets', now() + interval '4 days', false, 'Canada Life Centre'),
  ('Philadelphia Flyers', now() + interval '6 days', true, 'Ball Arena'),
  ('Washington Capitals', now() + interval '8 days', false, 'Capital One Arena'),
  ('Ottawa Senators', now() + interval '10 days', true, 'Ball Arena'),
  ('Detroit Red Wings', now() + interval '12 days', false, 'Little Caesars Arena'),
  ('Chicago Blackhawks', now() + interval '14 days', true, 'Ball Arena');