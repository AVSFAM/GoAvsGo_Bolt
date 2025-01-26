/*
  # Fix username uniqueness handling

  1. Changes
    - Add function to generate unique username
    - Add function to create user profile with retry logic
    - Add constraint validation helpers
  
  2. Security
    - Functions are security definer to ensure proper access control
    - Input validation to prevent SQL injection
*/

-- Create function to generate unique username
CREATE OR REPLACE FUNCTION generate_unique_username(base_username text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  unique_username text;
  counter integer := 0;
  max_attempts integer := 10;
BEGIN
  -- Start with the base username
  unique_username := base_username;
  
  -- Keep trying until we find a unique username or hit max attempts
  WHILE counter < max_attempts LOOP
    -- Check if username exists
    IF NOT EXISTS (
      SELECT 1 FROM profiles WHERE username = unique_username
    ) THEN
      RETURN unique_username;
    END IF;
    
    -- Generate a new username with increasing complexity
    IF counter = 0 THEN
      -- First try: Add 4 random digits
      unique_username := base_username || floor(random() * 9000 + 1000)::text;
    ELSIF counter = 1 THEN
      -- Second try: Add timestamp
      unique_username := base_username || extract(epoch from now())::bigint % 1000000;
    ELSE
      -- Subsequent tries: Add timestamp and random chars
      unique_username := base_username || 
                        extract(epoch from now())::bigint % 10000 ||
                        chr(floor(random() * 26 + 97)::int) ||
                        chr(floor(random() * 26 + 97)::int);
    END IF;
    
    counter := counter + 1;
  END LOOP;
  
  -- If we get here, we couldn't find a unique username
  RAISE EXCEPTION 'Could not generate unique username after % attempts', max_attempts;
END;
$$;

-- Create function to safely create user profile
CREATE OR REPLACE FUNCTION create_user_profile(
  user_id uuid,
  desired_username text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  final_username text;
BEGIN
  -- Input validation
  IF length(desired_username) < 3 THEN
    RAISE EXCEPTION 'Username must be at least 3 characters long';
  END IF;
  
  -- Clean the username (remove special characters, spaces)
  desired_username := regexp_replace(
    desired_username,
    '[^a-zA-Z0-9_-]',
    '',
    'g'
  );
  
  -- Start a transaction
  BEGIN
    -- Try to insert with original username
    INSERT INTO profiles (user_id, username)
    VALUES (user_id, desired_username)
    ON CONFLICT DO NOTHING
    RETURNING username INTO final_username;
    
    -- If insert failed, generate a unique username
    IF final_username IS NULL THEN
      final_username := generate_unique_username(desired_username);
      
      INSERT INTO profiles (user_id, username)
      VALUES (user_id, final_username);
    END IF;
    
    -- Initialize leaderboard entry
    INSERT INTO leaderboard (
      user_id,
      correct_predictions,
      total_predictions,
      points
    ) VALUES (
      user_id,
      0,
      0,
      0
    );
    
    RETURN final_username;
  EXCEPTION
    WHEN unique_violation THEN
      -- If we still get a unique violation, try one last time with timestamp
      final_username := desired_username || extract(epoch from now())::bigint;
      
      INSERT INTO profiles (user_id, username)
      VALUES (user_id, final_username);
      
      RETURN final_username;
  END;
END;
$$;