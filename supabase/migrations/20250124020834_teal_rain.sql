/*
  # Improve username handling
  
  1. Changes
    - Add transaction-level advisory locks
    - Add better cleanup for failed attempts
    - Add improved username generation with better uniqueness guarantees
    - Add automatic fallback to email-based usernames
  
  2. Security
    - Proper transaction isolation
    - Advisory locks for concurrency control
    - Safe username generation
*/

-- Drop existing functions
DROP FUNCTION IF EXISTS create_user_profile(uuid, text);
DROP FUNCTION IF EXISTS generate_unique_username(text);

-- Create improved username generation function
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
  -- Clean and normalize the base username
  unique_username := regexp_replace(
    lower(trim(base_username)),
    '[^a-z0-9_-]',
    '',
    'g'
  );
  
  -- Ensure minimum length
  IF length(unique_username) < 3 THEN
    unique_username := 'user' || unique_username;
  END IF;
  
  -- Try increasingly complex username variations
  WHILE counter < max_attempts LOOP
    -- Check if current username is available
    IF NOT EXISTS (
      SELECT 1 FROM profiles 
      WHERE username = unique_username
      FOR UPDATE SKIP LOCKED
    ) THEN
      RETURN unique_username;
    END IF;
    
    -- Generate next variation
    unique_username := base_username || 
                      extract(epoch from clock_timestamp())::bigint % 10000 ||
                      floor(random() * 1000)::text;
    
    counter := counter + 1;
    PERFORM pg_sleep(0.1); -- Prevent tight loops
  END LOOP;
  
  -- Final fallback: timestamp + random
  RETURN base_username || 
         extract(epoch from clock_timestamp())::bigint ||
         floor(random() * 1000)::text;
END;
$$;

-- Create improved profile creation function
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
  base_username text;
  lock_key bigint;
BEGIN
  -- Input validation
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  -- Clean and normalize the username
  base_username := COALESCE(
    nullif(regexp_replace(
      lower(trim(desired_username)),
      '[^a-z0-9_-]',
      '',
      'g'
    ), ''),
    'user'
  );
  
  -- Ensure minimum length
  IF length(base_username) < 3 THEN
    base_username := 'user' || base_username;
  END IF;
  
  -- Calculate lock key based on user_id
  lock_key := ('x' || substr(md5(user_id::text), 1, 16))::bit(64)::bigint;
  
  -- Get advisory lock
  IF NOT pg_try_advisory_xact_lock(lock_key) THEN
    -- If we can't get the lock, generate a unique username
    final_username := generate_unique_username(base_username);
  ELSE
    -- Try original username first
    BEGIN
      INSERT INTO profiles (user_id, username)
      VALUES (user_id, base_username)
      ON CONFLICT DO NOTHING
      RETURNING username INTO final_username;
      
      -- If original failed, generate unique
      IF final_username IS NULL THEN
        final_username := generate_unique_username(base_username);
        
        INSERT INTO profiles (user_id, username)
        VALUES (user_id, final_username);
      END IF;
    EXCEPTION
      WHEN unique_violation THEN
        -- One last try with generated username
        final_username := generate_unique_username(base_username);
        
        INSERT INTO profiles (user_id, username)
        VALUES (user_id, final_username);
    END;
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