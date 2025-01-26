/*
  # Add username support
  
  1. New Tables
    - `profiles`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `username` (text, unique)
      - `created_at` (timestamp)
  
  2. Security
    - Enable RLS on `profiles` table
    - Add policies for profile management
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL UNIQUE,
  username text UNIQUE NOT NULL CHECK (char_length(username) >= 3),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can read all profiles"
  ON profiles FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Update leaderboard view to show usernames
CREATE OR REPLACE VIEW public.leaderboard_with_usernames AS
SELECT 
  l.*,
  p.username
FROM leaderboard l
LEFT JOIN profiles p ON l.user_id = p.user_id;

-- Drop old leaderboard policies
DROP POLICY IF EXISTS "Users can view all leaderboard entries" ON leaderboard;
DROP POLICY IF EXISTS "System can update leaderboard" ON leaderboard;

-- Create new leaderboard policies
CREATE POLICY "Anyone can view leaderboard"
  ON leaderboard FOR SELECT
  TO public
  USING (true);

CREATE POLICY "System can manage leaderboard"
  ON leaderboard FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);