/*
  # Fix username uniqueness handling with improved error handling

  1. Changes
    - Add retries and better error handling to username generation
    - Add transaction isolation level
    - Add cleanup for failed attempts
    - Add better validation and sanitization
  
  2. Security
    - Improved input validation
    - Transaction isolation to prevent race conditions
    - Proper error handling and cleanup
*/

-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS generate_unique_username(text);
DROP FUNCTION IF EXISTS create_user_profile(uuid, text);

-- Create improved function to generate unique username
CREATE OR REPLACE FUNCTION generate_unique_username(base_username text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  unique_username text;
  counter integer := 0;
  max_attempts integer := 20;
  base_cleaned text;
BEGIN
  -- Clean and validate base username
  base_cleaned := regexp_replace(
    lower(trim(base_username)),
    '[^a-z0-9_-]',
    '',
    'g'
  );
  
  IF length(base_cleaned) < 3 THEN
    base_cleaned := 'user' || base_cleaned;
  END IF;
  
  -- Start with the cleaned base username
  unique_username := base_cleaned;
  
  -- Keep trying until we find a unique username or hit max attempts
  WHILE counter < max_attempts LOOP
    BEGIN
      -- Check if username exists with FOR UPDATE SKIP LOCKED to prevent race conditions
      PERFORM 1 
      FROM profiles 
      WHERE username = unique_username
      FOR UPDATE SKIP LOCKED;
      
      IF NOT FOUND THEN
        RETURN unique_username;
      END IF;
      
      -- Generate a new username with increasing complexity
      CASE counter
        WHEN 0 THEN
          -- First try: Add 4 random digits
          unique_username := base_cleaned || floor(random() * 9000 + 1000)::text;
        WHEN 1 THEN
          -- Second try: Add timestamp
          unique_username := base_cleaned || extract(epoch from now())::bigint % 1000000;
        ELSE
          -- Subsequent tries: Add timestamp and random chars
          unique_username := base_cleaned || 
                           extract(epoch from now())::bigint % 10000 ||
                           chr(floor(random() * 26 + 97)::int) ||
                           chr(floor(random() * 26 + 97)::int);
      END CASE;
      
      counter := counter + 1;
      
      -- Small delay to prevent tight loops
      PERFORM pg_sleep(0.1);
    EXCEPTION
      WHEN OTHERS THEN
        -- Log error and continue
        RAISE NOTICE 'Error in attempt %: %', counter, SQLERRM;
        counter := counter + 1;
    END;
  END LOOP;
  
  -- If we get here, we couldn't find a unique username
  RAISE EXCEPTION 'Could not generate unique username after % attempts', max_attempts;
END;
$$;

-- Create improved function to safely create user profile
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
  retry_count integer := 0;
  max_retries integer := 3;
BEGIN
  -- Input validation
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  IF desired_username IS NULL OR length(trim(desired_username)) < 1 THEN
    desired_username := 'user';
  END IF;
  
  -- Clean the username
  desired_username := regexp_replace(
    lower(trim(desired_username)),
    '[^a-z0-9_-]',
    '',
    'g'
  );
  
  -- Ensure minimum length
  IF length(desired_username) < 3 THEN
    desired_username := 'user' || desired_username;
  END IF;
  
  -- Start a transaction with serializable isolation
  BEGIN
    -- Set transaction isolation level
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    -- Try to insert with original username
    INSERT INTO profiles (user_id, username)
    VALUES (user_id, desired_username)
    ON CONFLICT DO NOTHING
    RETURNING username INTO final_username;
    
    -- If insert failed, generate a unique username
    IF final_username IS NULL THEN
      -- Try with generated username
      WHILE retry_count < max_retries AND final_username IS NULL LOOP
        BEGIN
          final_username := generate_unique_username(desired_username);
          
          INSERT INTO profiles (user_id, username)
          VALUES (user_id, final_username);
          
          EXIT;
        EXCEPTION
          WHEN unique_violation THEN
            retry_count := retry_count + 1;
            IF retry_count >= max_retries THEN
              RAISE EXCEPTION 'Failed to create unique username after % attempts', max_retries;
            END IF;
        END;
      END LOOP;
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
    WHEN OTHERS THEN
      -- Cleanup any partial data
      DELETE FROM profiles WHERE user_id = user_id;
      DELETE FROM leaderboard WHERE user_id = user_id;
      
      RAISE EXCEPTION 'Failed to create profile: %', SQLERRM;
  END;
END;
$$;