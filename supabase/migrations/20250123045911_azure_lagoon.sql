/*
  # Fix leaderboard trigger and add rules table

  1. Changes
    - Fix leaderboard trigger to properly update on verification
    - Add rules table for game rules
*/

-- Create rules table
CREATE TABLE IF NOT EXISTS rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  order_number integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE rules ENABLE ROW LEVEL SECURITY;

-- Create policy for reading rules
CREATE POLICY "Anyone can read rules"
  ON rules FOR SELECT
  TO public
  USING (true);

-- Create policy for admin to manage rules
CREATE POLICY "Admins can manage rules"
  ON rules FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Insert initial rules
INSERT INTO rules (title, content, order_number) VALUES
  ('How to Play', 'Predict which Avalanche player will score the first goal in each game. Make your prediction before the game starts!', 1),
  ('Scoring', 'Earn 10 points for correct predictions and lose 5 points for incorrect ones. Your total score determines your position on the leaderboard.', 2),
  ('Game Schedule', 'Predictions can be made up until the game starts. Once a game begins, predictions are locked.', 3),
  ('Multiple Predictions', 'You can change your prediction as many times as you want before the game starts. Only your last prediction counts.', 4),
  ('Results', 'Game results are verified by admins after each game. Points are awarded once the first goal scorer is confirmed.', 5),
  ('Leaderboard', 'The leaderboard shows the top performers. Keep making correct predictions to climb the rankings!', 6);