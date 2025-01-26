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
    
    -- Check if username is available
    IF NOT EXISTS (
      SELECT 1 FROM profiles p WHERE p.username = unique_username
    ) THEN
      RETURN unique_username;
    END IF;
    
    counter := counter + 1;
    EXIT WHEN counter >= max_attempts;
  END LOOP;
  
  -- Final fallback: use timestamp and random number
  RETURN normalized_base || 
         extract(epoch from clock_timestamp())::bigint::text ||
         floor(random() * 100)::text;
END;
$$;

-- Create improved profile creation function
CREATE OR REPLACE FUNCTION create_user_profile(
  p_user_id uuid,
  p_desired_username text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_final_username text;
  v_normalized_username text;
  v_retry_count integer := 0;
  v_max_retries integer := 3;
BEGIN
  -- Input validation
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  -- Clean and normalize the username
  v_normalized_username := COALESCE(
    nullif(regexp_replace(
      lower(trim(p_desired_username)),
      '[^a-z0-9_-]',
      '',
      'g'
    ), ''),
    'user'
  );
  
  -- Check if profile already exists
  SELECT p.username INTO v_final_username
  FROM profiles p
  WHERE p.user_id = p_user_id;
  
  IF v_final_username IS NOT NULL THEN
    RETURN v_final_username;
  END IF;
  
  -- Try to create profile with retries
  WHILE v_retry_count < v_max_retries LOOP
    BEGIN
      -- Try original username first
      IF v_retry_count = 0 THEN
        INSERT INTO profiles (user_id, username)
        VALUES (p_user_id, v_normalized_username)
        ON CONFLICT DO NOTHING
        RETURNING username INTO v_final_username;
      END IF;
      
      -- If original username failed, generate a unique one
      IF v_final_username IS NULL THEN
        v_final_username := generate_unique_username(v_normalized_username);
        
        INSERT INTO profiles (user_id, username)
        VALUES (p_user_id, v_final_username);
      END IF;
      
      -- Initialize leaderboard entry
      INSERT INTO leaderboard (
        user_id,
        correct_predictions,
        total_predictions,
        points
      ) VALUES (
        p_user_id,
        0,
        0,
        0
      );
      
      -- If we get here, everything succeeded
      RETURN v_final_username;
    EXCEPTION
      WHEN unique_violation THEN
        -- Only retry on unique violations
        v_retry_count := v_retry_count + 1;
        IF v_retry_count >= v_max_retries THEN
          RAISE EXCEPTION 'Failed to create unique username after % attempts', v_max_retries;
        END IF;
        v_final_username := NULL;
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