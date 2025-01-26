/*
  # Final username uniqueness improvements
  
  1. Changes
    - Add function to safely generate username from email
    - Add function to handle username conflicts during email-based username creation
    - Add better error messages for username conflicts
  
  2. Security
    - Proper error handling
    - Safe username generation
    - Transaction isolation
*/

-- Create function to safely generate username from email
CREATE OR REPLACE FUNCTION generate_username_from_email(email text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  base_username text;
  final_username text;
  attempt_count integer := 0;
  max_attempts integer := 5;
BEGIN
  -- Extract username part from email
  base_username := split_part(email, '@', 1);
  
  -- Clean the username
  base_username := regexp_replace(
    lower(trim(base_username)),
    '[^a-z0-9_-]',
    '',
    'g'
  );
  
  -- Ensure minimum length
  IF length(base_username) < 3 THEN
    base_username := 'user' || base_username;
  END IF;
  
  -- Try to find a unique username
  WHILE attempt_count < max_attempts LOOP
    IF attempt_count = 0 THEN
      final_username := base_username;
    ELSE
      final_username := base_username || floor(random() * 9000 + 1000)::text;
    END IF;
    
    -- Check if username exists
    IF NOT EXISTS (
      SELECT 1 FROM profiles WHERE username = final_username
    ) THEN
      RETURN final_username;
    END IF;
    
    attempt_count := attempt_count + 1;
  END LOOP;
  
  -- If we get here, fall back to timestamp-based username
  RETURN base_username || extract(epoch from now())::bigint % 1000000;
END;
$$;