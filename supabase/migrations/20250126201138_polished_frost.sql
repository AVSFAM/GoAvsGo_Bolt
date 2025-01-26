-- Insert current Avalanche roster
INSERT INTO players (name, first_name, last_name, number, position, is_active)
VALUES
  -- Forwards
  ('Ross Colton', 'Ross', 'Colton', 20, 'Center', true),
  ('Jonathan Drouin', 'Jonathan', 'Drouin', 27, 'Left Wing', true),
  ('Jere Innala', 'Jere', 'Innala', 22, 'Right Wing', true),
  ('Ivan Ivan', 'Ivan', 'Ivan', 82, 'Center', true),
  ('Parker Kelly', 'Parker', 'Kelly', 17, 'Center', true),
  ('Joel Kiviranta', 'Joel', 'Kiviranta', 94, 'Left Wing', true),
  ('Artturi Lehkonen', 'Artturi', 'Lehkonen', 62, 'Left Wing', true),
  ('Nathan MacKinnon', 'Nathan', 'MacKinnon', 29, 'Center', true),
  ('Casey Mittelstadt', 'Casey', 'Mittelstadt', 37, 'Center', true),
  ('Valeri Nichushkin', 'Valeri', 'Nichushkin', 13, 'Right Wing', true),
  ('Logan O''Connor', 'Logan', 'O''Connor', 25, 'Right Wing', true),
  ('Juuso Parssinen', 'Juuso', 'Parssinen', 16, 'Center', true),
  ('Jack Drury', 'Jack', 'Drury', 18, 'Center', true),
  ('Martin Necas', 'Martin', 'Necas', 88, 'Center', true),
  ('Miles Wood', 'Miles', 'Wood', 28, 'Left Wing', true),
  
  -- Defensemen
  ('Calvin de Haan', 'Calvin', 'de Haan', 44, 'Defense', true),
  ('Samuel Girard', 'Samuel', 'Girard', 49, 'Defense', true),
  ('Oliver Kylington', 'Oliver', 'Kylington', 58, 'Defense', true),
  ('Cale Makar', 'Cale', 'Makar', 8, 'Defense', true),
  ('Sam Malinski', 'Sam', 'Malinski', 70, 'Defense', true),
  ('Josh Manson', 'Josh', 'Manson', 42, 'Defense', true),
  ('Keaton Middleton', 'Keaton', 'Middleton', 67, 'Defense', true),
  ('Devon Toews', 'Devon', 'Toews', 7, 'Defense', true),
  
  -- Goalies
  ('Mackenzie Blackwood', 'Mackenzie', 'Blackwood', 39, 'Goalie', true),
  ('Scott Wedgewood', 'Scott', 'Wedgewood', 41, 'Goalie', true);

-- Insert remaining Avalanche games
INSERT INTO games (opponent, game_time, is_home, location)
VALUES
  -- January Games
  ('New York Rangers', '2024-01-26 11:00:00-07', false, 'Madison Square Garden'),
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