/*
  # Fix username creation race condition
  
  1. Changes
    - Add advisory lock to prevent concurrent username creation
    - Add better error handling for concurrent attempts
    - Add cleanup for failed attempts
  
  2. Security
    - Proper transaction isolation
    - Advisory locks for concurrency control
    - Safe username generation
*/

-- Drop existing function
DROP FUNCTION IF EXISTS create_user_profile(uuid, text);

-- Create improved function with advisory locks
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
  lock_obtained boolean;
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
  
  -- Try to obtain advisory lock
  SELECT pg_try_advisory_xact_lock(hashtext('create_user_profile'::text)) INTO lock_obtained;
  
  IF NOT lock_obtained THEN
    -- If we can't get the lock, someone else is creating a profile
    -- Wait a bit and try with a generated username
    PERFORM pg_sleep(0.5);
    final_username := generate_unique_username(desired_username);
  ELSE
    -- We got the lock, try with the original username first
    BEGIN
      INSERT INTO profiles (user_id, username)
      VALUES (user_id, desired_username)
      ON CONFLICT DO NOTHING
      RETURNING username INTO final_username;
    EXCEPTION
      WHEN unique_violation THEN
        -- If we still get a violation, fall back to generated username
        final_username := NULL;
    END;
  END IF;
  
  -- If we couldn't use the original username, try with generated ones
  WHILE final_username IS NULL AND retry_count < max_retries LOOP
    BEGIN
      final_username := generate_unique_username(desired_username);
      
      INSERT INTO profiles (user_id, username)
      VALUES (user_id, final_username);
      
      EXIT;
    EXCEPTION
      WHEN unique_violation THEN
        retry_count := retry_count + 1;
        final_username := NULL;
        
        IF retry_count >= max_retries THEN
          RAISE EXCEPTION 'Failed to create unique username after % attempts', max_retries;
        END IF;
        
        -- Small delay between retries
        PERFORM pg_sleep(0.1);
    END;
  END LOOP;
  
  -- If we still don't have a username, something went very wrong
  IF final_username IS NULL THEN
    RAISE EXCEPTION 'Failed to generate a unique username';
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
$$;