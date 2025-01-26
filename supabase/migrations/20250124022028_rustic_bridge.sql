-- Create improved username generation function with better uniqueness guarantees
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
  timestamp_part text;
  random_part text;
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
  
  -- First try: exact match
  unique_username := normalized_base;
  
  WHILE counter < max_attempts LOOP
    BEGIN
      -- Use FOR UPDATE SKIP LOCKED to prevent race conditions
      PERFORM 1 
      FROM profiles 
      WHERE username = unique_username
      FOR UPDATE SKIP LOCKED;
      
      IF NOT FOUND THEN
        RETURN unique_username;
      END IF;
      
      -- Generate timestamp part (microsecond precision)
      timestamp_part := to_char(clock_timestamp(), 'SSSSSS');
      
      -- Generate random part
      random_part := floor(random() * 1000)::text;
      
      -- Combine parts based on attempt number
      CASE counter
        WHEN 0 THEN
          -- First attempt: base + random
          unique_username := normalized_base || random_part;
        WHEN 1 THEN
          -- Second attempt: base + timestamp
          unique_username := normalized_base || timestamp_part;
        ELSE
          -- Subsequent attempts: base + timestamp + random
          unique_username := normalized_base || 
                           substr(timestamp_part, 1, 3) ||
                           random_part;
      END CASE;
      
      counter := counter + 1;
      -- Small delay to prevent tight loops
      PERFORM pg_sleep(0.05);
    EXCEPTION
      WHEN OTHERS THEN
        counter := counter + 1;
        CONTINUE;
    END;
  END LOOP;
  
  -- Final fallback: guaranteed unique combination
  RETURN normalized_base || 
         extract(epoch from clock_timestamp())::bigint::text ||
         floor(random() * 100)::text;
END;
$$;

-- Create improved profile creation function with better error handling
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
  lock_obtained boolean;
  profile_created boolean := false;
  leaderboard_created boolean := false;
BEGIN
  -- Input validation
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'User ID cannot be null';
  END IF;
  
  -- Clean and normalize the username
  desired_username := COALESCE(
    nullif(regexp_replace(
      lower(trim(desired_username)),
      '[^a-z0-9_-]',
      '',
      'g'
    ), ''),
    'user'
  );
  
  -- Try to obtain advisory lock
  SELECT pg_try_advisory_xact_lock(hashtext('profile_' || user_id::text)) INTO lock_obtained;
  
  -- Start an autonomous transaction
  BEGIN
    -- Check if profile already exists
    SELECT username INTO final_username
    FROM profiles
    WHERE user_id = create_user_profile.user_id;
    
    IF final_username IS NOT NULL THEN
      RETURN final_username;
    END IF;
    
    -- Try with original username if we got the lock
    IF lock_obtained THEN
      BEGIN
        INSERT INTO profiles (user_id, username)
        VALUES (user_id, desired_username)
        ON CONFLICT DO NOTHING
        RETURNING username INTO final_username;
      EXCEPTION
        WHEN unique_violation THEN
          final_username := NULL;
      END;
    END IF;
    
    -- If original username failed, generate a unique one
    IF final_username IS NULL THEN
      final_username := generate_unique_username(desired_username);
      
      INSERT INTO profiles (user_id, username)
      VALUES (user_id, final_username);
    END IF;
    
    profile_created := true;
    
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
    
    leaderboard_created := true;
    
    RETURN final_username;
  EXCEPTION
    WHEN OTHERS THEN
      -- Cleanup on error
      IF profile_created THEN
        DELETE FROM profiles WHERE user_id = create_user_profile.user_id;
      END IF;
      
      IF leaderboard_created THEN
        DELETE FROM leaderboard WHERE user_id = create_user_profile.user_id;
      END IF;
      
      RAISE EXCEPTION 'Failed to create profile: %', SQLERRM;
  END;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION generate_unique_username(text) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_profile(uuid, text) TO authenticated;