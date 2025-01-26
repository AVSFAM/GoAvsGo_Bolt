-- Drop existing functions
DROP FUNCTION IF EXISTS create_user_profile(uuid, text);
DROP FUNCTION IF EXISTS generate_unique_username(text);

-- Create improved username generation function with retries
CREATE OR REPLACE FUNCTION generate_unique_username(base_username text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  unique_username text;
  normalized_base text;
  counter integer := 0;
  max_attempts integer := 10;
BEGIN
  -- Normalize the base username
  normalized_base := regexp_replace(
    lower(trim(base_username)),
    '[^a-z0-9_-]',
    '',
    'g'
  );
  
  -- Ensure minimum length
  IF length(normalized_base) < 3 THEN
    normalized_base := 'user' || normalized_base;
  END IF;
  
  -- Truncate if too long to leave room for suffixes
  IF length(normalized_base) > 20 THEN
    normalized_base := substr(normalized_base, 1, 20);
  END IF;
  
  -- Try different username variations
  LOOP
    -- First try: exact match
    IF counter = 0 THEN
      unique_username := normalized_base;
    -- Second try: add random number
    ELSIF counter = 1 THEN
      unique_username := normalized_base || floor(random() * 9000 + 1000)::text;
    -- Third try: add timestamp
    ELSIF counter = 2 THEN
      unique_username := normalized_base || extract(epoch from clock_timestamp())::bigint % 10000;
    -- Subsequent tries: combine timestamp and random
    ELSE
      unique_username := normalized_base || 
                        extract(epoch from clock_timestamp())::bigint % 1000 ||
                        floor(random() * 900 + 100)::text;
    END IF;
    
    -- Check if username is available using explicit locking
    BEGIN
      PERFORM 1 
      FROM profiles 
      WHERE username = unique_username
      FOR UPDATE SKIP LOCKED;
      
      IF NOT FOUND THEN
        RETURN unique_username;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- Continue to next attempt on any error
        NULL;
    END;
    
    counter := counter + 1;
    EXIT WHEN counter >= max_attempts;
    -- Add small delay between attempts
    PERFORM pg_sleep(0.1);
  END LOOP;
  
  -- Final fallback: use timestamp and random number
  RETURN normalized_base || 
         extract(epoch from clock_timestamp())::bigint::text ||
         floor(random() * 100)::text;
END;
$$;

-- Create improved profile creation function with transaction isolation
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
  normalized_username text;
  retry_count integer := 0;
  max_retries integer := 3;
BEGIN
  -- Input validation
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  -- Clean and normalize the username
  normalized_username := COALESCE(
    nullif(regexp_replace(
      lower(trim(desired_username)),
      '[^a-z0-9_-]',
      '',
      'g'
    ), ''),
    'user'
  );
  
  -- Set transaction isolation level
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
  
  -- Check if profile already exists
  SELECT username INTO final_username
  FROM profiles
  WHERE user_id = create_user_profile.user_id;
  
  IF final_username IS NOT NULL THEN
    RETURN final_username;
  END IF;
  
  -- Try to create profile with retries
  WHILE retry_count < max_retries LOOP
    BEGIN
      -- Try original username first
      IF retry_count = 0 THEN
        INSERT INTO profiles (user_id, username)
        VALUES (user_id, normalized_username)
        ON CONFLICT DO NOTHING
        RETURNING username INTO final_username;
      END IF;
      
      -- If original username failed, generate a unique one
      IF final_username IS NULL THEN
        final_username := generate_unique_username(normalized_username);
        
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
      
      -- If we get here, everything succeeded
      RETURN final_username;
    EXCEPTION
      WHEN unique_violation THEN
        -- Only retry on unique violations
        retry_count := retry_count + 1;
        IF retry_count >= max_retries THEN
          RAISE EXCEPTION 'Failed to create unique username after % attempts', max_retries;
        END IF;
        -- Rollback the failed attempt
        ROLLBACK;
        -- Start a new transaction
        BEGIN
        END;
      WHEN OTHERS THEN
        -- Re-raise other errors
        RAISE;
    END;
  END LOOP;
  
  -- We should never get here due to the RAISE in the loop
  RAISE EXCEPTION 'Unexpected error in profile creation';
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION generate_unique_username(text) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_profile(uuid, text) TO authenticated;