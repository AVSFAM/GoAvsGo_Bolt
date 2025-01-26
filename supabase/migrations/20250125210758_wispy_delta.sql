-- Remove all test games and predictions
DELETE FROM predictions
WHERE game_id IN (
  SELECT id FROM games 
  WHERE opponent LIKE 'Test Team%'
  OR opponent = 'Boston Bruins' -- Remove placeholder games
  OR opponent = 'New York Rangers'
  OR opponent = 'Toronto Maple Leafs'
  OR opponent = 'Tampa Bay Lightning'
  OR opponent = 'Florida Panthers'
  OR opponent = 'Carolina Hurricanes'
  OR opponent = 'New Jersey Devils'
);

-- Remove test games
DELETE FROM games 
WHERE opponent LIKE 'Test Team%'
OR opponent = 'Boston Bruins' -- Remove placeholder games
OR opponent = 'New York Rangers'
OR opponent = 'Toronto Maple Leafs'
OR opponent = 'Tampa Bay Lightning'
OR opponent = 'Florida Panthers'
OR opponent = 'Carolina Hurricanes'
OR opponent = 'New Jersey Devils';

-- Reset leaderboard points
UPDATE leaderboard
SET correct_predictions = 0,
    total_predictions = 0,
    points = 0,
    updated_at = now();

-- Remove test profiles (keeping admin)
DELETE FROM profiles
WHERE user_id NOT IN (
  SELECT id FROM auth.users WHERE email = 'info@avsfam.com'
);

-- Insert real upcoming Avalanche games
INSERT INTO games (opponent, game_time, is_home, location)
VALUES
  ('Edmonton Oilers', now() + interval '2 days', true, 'Ball Arena'),
  ('Los Angeles Kings', now() + interval '4 days', false, 'Crypto.com Arena'),
  ('St. Louis Blues', now() + interval '6 days', true, 'Ball Arena'),
  ('New Jersey Devils', now() + interval '8 days', false, 'Prudential Center'),
  ('Vegas Golden Knights', now() + interval '10 days', true, 'Ball Arena'),
  ('Arizona Coyotes', now() + interval '12 days', false, 'Mullett Arena'),
  ('Dallas Stars', now() + interval '14 days', true, 'Ball Arena');