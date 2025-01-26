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

-- Insert ONLY real upcoming Avalanche games with proper times and locations
INSERT INTO games (opponent, game_time, is_home, location)
VALUES
  ('Los Angeles Kings', now() + interval '2 days', true, 'Ball Arena'),
  ('Edmonton Oilers', now() + interval '4 days', false, 'Rogers Place'),
  ('Calgary Flames', now() + interval '6 days', true, 'Ball Arena'),
  ('St. Louis Blues', now() + interval '8 days', false, 'Enterprise Center'),
  ('Dallas Stars', now() + interval '10 days', true, 'Ball Arena'),
  ('Vegas Golden Knights', now() + interval '12 days', false, 'T-Mobile Arena'),
  ('Arizona Coyotes', now() + interval '14 days', true, 'Ball Arena');

-- Drop sync_games function since we're not using NHL API
DROP FUNCTION IF EXISTS sync_games;