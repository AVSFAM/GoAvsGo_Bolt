/*
  # Avalanche Goal Prediction Schema

  1. New Tables
    - `players`
      - `id` (uuid, primary key)
      - `name` (text)
      - `number` (integer)
      - `position` (text)
      - `is_active` (boolean)
    
    - `predictions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `player_id` (uuid, references players)
      - `game_date` (date)
      - `is_correct` (boolean)
      - `created_at` (timestamp)
    
    - `leaderboard`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `correct_predictions` (integer)
      - `total_predictions` (integer)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Players table
CREATE TABLE IF NOT EXISTS players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  number integer NOT NULL,
  position text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Predictions table
CREATE TABLE IF NOT EXISTS predictions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  player_id uuid REFERENCES players NOT NULL,
  game_date date NOT NULL,
  is_correct boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Leaderboard table
CREATE TABLE IF NOT EXISTS leaderboard (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  correct_predictions integer DEFAULT 0,
  total_predictions integer DEFAULT 0,
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Players are viewable by everyone"
  ON players FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can create their own predictions"
  ON predictions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own predictions"
  ON predictions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view all leaderboard entries"
  ON leaderboard FOR SELECT
  TO public
  USING (true);

CREATE POLICY "System can update leaderboard"
  ON leaderboard FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);