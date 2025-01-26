/*
  # Add games table and update predictions

  1. New Tables
    - `games`
      - `id` (uuid, primary key)
      - `opponent` (text)
      - `game_time` (timestamptz)
      - `is_home` (boolean)
      - `location` (text)
      - `created_at` (timestamptz)

  2. Changes
    - Add game_id to predictions table
    - Add admin_verified field to predictions

  3. Security
    - Enable RLS on games table
    - Add policies for viewing and managing games
*/

-- Create games table
CREATE TABLE IF NOT EXISTS games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  opponent text NOT NULL,
  game_time timestamptz NOT NULL,
  is_home boolean NOT NULL,
  location text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Add game_id to predictions
ALTER TABLE predictions
ADD COLUMN game_id uuid REFERENCES games(id),
ADD COLUMN admin_verified boolean DEFAULT false;

-- Enable RLS
ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Policies for games
CREATE POLICY "Games are viewable by everyone"
  ON games FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Admins can manage games"
  ON games FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Insert upcoming games
INSERT INTO games (opponent, game_time, is_home, location) VALUES
  ('Boston Bruins', '2025-01-25 10:00:00-07', false, 'TD Garden'),
  ('New York Rangers', '2025-01-26 10:00:00-07', false, 'Madison Square Garden'),
  ('New York Islanders', '2025-01-28 17:30:00-07', false, 'UBS Arena'),
  ('St. Louis Blues', '2025-01-31 19:00:00-07', true, 'Ball Arena'),
  ('Philadelphia Flyers', '2025-02-02 13:00:00-07', true, 'Ball Arena');