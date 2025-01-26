-- First clean up any existing test data
DELETE FROM predictions;
DELETE FROM games;

-- Reset leaderboard
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

-- Insert actual upcoming Avalanche games
INSERT INTO games (opponent, game_time, is_home, location)
VALUES
  ('Nashville Predators', now() + interval '2 days', true, 'Ball Arena'),
  ('Winnipeg Jets', now() + interval '4 days', false, 'Canada Life Centre'),
  ('Philadelphia Flyers', now() + interval '6 days', true, 'Ball Arena'),
  ('Washington Capitals', now() + interval '8 days', false, 'Capital One Arena'),
  ('Ottawa Senators', now() + interval '10 days', true, 'Ball Arena'),
  ('Detroit Red Wings', now() + interval '12 days', false, 'Little Caesars Arena'),
  ('Chicago Blackhawks', now() + interval '14 days', true, 'Ball Arena');

-- Add some past games that need verification (for admin testing)
INSERT INTO games (opponent, game_time, is_home, location, verified)
VALUES
  ('Minnesota Wild', now() - interval '2 days', false, 'Xcel Energy Center', false),
  ('Vancouver Canucks', now() - interval '4 days', true, 'Ball Arena', false),
  ('Seattle Kraken', now() - interval '6 days', false, 'Climate Pledge Arena', false);