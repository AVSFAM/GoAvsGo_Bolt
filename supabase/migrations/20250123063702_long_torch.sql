/*
  # Fix predictions table RLS policies

  1. Changes
    - Drop existing RLS policies for predictions table
    - Create new policies that properly handle authenticated users
    - Allow users to upsert their own predictions
    - Allow users to view their own predictions
  
  2. Security
    - Enable RLS on predictions table
    - Ensure users can only manage their own predictions
    - Maintain data isolation between users
*/

-- First drop existing policies
DROP POLICY IF EXISTS "Users can create their own predictions" ON predictions;
DROP POLICY IF EXISTS "Users can view their own predictions" ON predictions;

-- Create new policies
CREATE POLICY "Users can manage their own predictions"
  ON predictions
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Ensure RLS is enabled
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;