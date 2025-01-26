-- First, remove ALL predictions and games
DELETE FROM predictions;
DELETE FROM games;

-- Reset ALL leaderboard entries
UPDATE leaderboard
SET correct_predictions = 0,
    total_predictions = 0,
    points = 0,
    updated_at = now();

-- Insert ONLY the actual remaining Avalanche games with correct times and venues
INSERT INTO games (opponent, game_time, is_home, location)
VALUES
  -- January Games
  ('New York Rangers', '2024-01-26 19:00:00-07', false, 'Madison Square Garden'),
  ('New York Islanders', '2024-01-28 12:00:00-07', false, 'UBS Arena'),
  ('St. Louis Blues', '2024-01-31 19:00:00-07', true, 'Ball Arena'),

  -- February Games
  ('Philadelphia Flyers', '2024-02-02 13:00:00-07', true, 'Ball Arena'),
  ('Vancouver Canucks', '2024-02-04 20:00:00-07', false, 'Rogers Arena'),
  ('Calgary Flames', '2024-02-06 19:00:00-07', false, 'Scotiabank Saddledome'),
  ('Edmonton Oilers', '2024-02-07 19:30:00-07', false, 'Rogers Place'),
  ('Nashville Predators', '2024-02-22 18:00:00-07', false, 'Bridgestone Arena'),
  ('St. Louis Blues', '2024-02-23 19:00:00-07', false, 'Enterprise Center'),
  ('New Jersey Devils', '2024-02-26 19:00:00-07', true, 'Ball Arena'),
  ('Minnesota Wild', '2024-02-28 19:00:00-07', true, 'Ball Arena'),

  -- March Games
  ('Pittsburgh Penguins', '2024-03-04 19:00:00-07', true, 'Ball Arena'),
  ('San Jose Sharks', '2024-03-06 19:00:00-07', true, 'Ball Arena'),
  ('Toronto Maple Leafs', '2024-03-08 19:00:00-07', true, 'Ball Arena'),
  ('Chicago Blackhawks', '2024-03-10 13:00:00-07', true, 'Ball Arena'),
  ('Minnesota Wild', '2024-03-11 19:00:00-07', false, 'Xcel Energy Center'),
  ('Calgary Flames', '2024-03-14 19:00:00-07', false, 'Scotiabank Saddledome'),
  ('Dallas Stars', '2024-03-16 19:00:00-07', true, 'Ball Arena'),
  ('Detroit Red Wings', '2024-03-25 19:00:00-07', true, 'Ball Arena'),
  ('Los Angeles Kings', '2024-03-27 19:30:00-07', false, 'Crypto.com Arena'),
  ('St. Louis Blues', '2024-03-29 19:00:00-07', true, 'Ball Arena'),
  ('Calgary Flames', '2024-03-31 18:00:00-07', true, 'Ball Arena'),

  -- April Games (note the -06 offset for MDT)
  ('Chicago Blackhawks', '2024-04-02 18:30:00-06', false, 'United Center'),
  ('Columbus Blue Jackets', '2024-04-03 17:00:00-06', false, 'Nationwide Arena'),
  ('St. Louis Blues', '2024-04-05 18:00:00-06', false, 'Enterprise Center'),
  ('Vegas Golden Knights', '2024-04-08 19:30:00-06', true, 'Ball Arena'),
  ('Vancouver Canucks', '2024-04-10 19:30:00-06', true, 'Ball Arena');