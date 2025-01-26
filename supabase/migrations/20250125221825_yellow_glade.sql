-- Add unique constraint for games
ALTER TABLE games
ADD CONSTRAINT unique_game_time_opponent UNIQUE (game_time, opponent);

-- Remove old games
DELETE FROM games;

-- Insert fresh set of games
INSERT INTO games (opponent, game_time, is_home, location)
VALUES
  ('Los Angeles Kings', now() + interval '2 days', true, 'Ball Arena'),
  ('Edmonton Oilers', now() + interval '4 days', false, 'Rogers Place'),
  ('Calgary Flames', now() + interval '6 days', true, 'Ball Arena'),
  ('St. Louis Blues', now() + interval '8 days', false, 'Enterprise Center'),
  ('Dallas Stars', now() + interval '10 days', true, 'Ball Arena'),
  ('Vegas Golden Knights', now() + interval '12 days', false, 'T-Mobile Arena'),
  ('Arizona Coyotes', now() + interval '14 days', true, 'Ball Arena');