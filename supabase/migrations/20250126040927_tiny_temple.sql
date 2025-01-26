-- Drop existing tables and functions
DROP FUNCTION IF EXISTS sync_games();
DROP FUNCTION IF EXISTS verify_game_predictions(uuid, uuid);
DROP TABLE IF EXISTS predictions;
DROP TABLE IF EXISTS games;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS leaderboard;
DROP TABLE IF EXISTS profiles;

-- Create tables
CREATE TABLE players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  number integer NOT NULL,
  position text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT unique_player_identity UNIQUE (name, number, position)
);

CREATE TABLE games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  opponent text NOT NULL,
  game_time timestamptz NOT NULL,
  is_home boolean NOT NULL,
  location text NOT NULL,
  verified boolean DEFAULT false,
  correct_player_id uuid REFERENCES players(id),
  created_at timestamptz DEFAULT now(),
  CONSTRAINT unique_game_time_opponent UNIQUE (game_time, opponent),
  CONSTRAINT no_verify_future_games CHECK (
    CASE 
      WHEN verified = true THEN game_time < now()
      ELSE true
    END
  )
);

CREATE TABLE profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL UNIQUE,
  username text UNIQUE NOT NULL CHECK (char_length(username) >= 3),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE predictions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  player_id uuid REFERENCES players(id) NOT NULL,
  game_id uuid REFERENCES games(id) NOT NULL,
  game_date date NOT NULL,
  is_correct boolean DEFAULT false,
  admin_verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT unique_user_game_prediction UNIQUE (user_id, game_id)
);

CREATE TABLE leaderboard (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL UNIQUE,
  correct_predictions integer DEFAULT 0,
  total_predictions integer DEFAULT 0,
  points integer DEFAULT 0,
  updated_at timestamptz DEFAULT now()
);

-- Create view for leaderboard with usernames
CREATE OR REPLACE VIEW leaderboard_with_usernames AS
SELECT 
  l.id,
  l.user_id,
  p.username,
  l.correct_predictions,
  l.total_predictions,
  GREATEST(COALESCE(l.points, 0), 0) as points,
  l.updated_at
FROM leaderboard l
INNER JOIN profiles p ON l.user_id = p.user_id
ORDER BY GREATEST(COALESCE(l.points, 0), 0) DESC;

-- Create function to verify game predictions
CREATE OR REPLACE FUNCTION verify_game_predictions(
  game_id uuid,
  correct_player uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update the game with the correct player
  UPDATE games
  SET correct_player_id = correct_player,
      verified = true
  WHERE id = game_id;

  -- Update all predictions for this game
  UPDATE predictions
  SET is_correct = (player_id = correct_player),
      admin_verified = true
  WHERE game_id = game_id;

  -- Update leaderboard
  WITH user_stats AS (
    SELECT 
      p.user_id,
      COUNT(*) FILTER (WHERE p.is_correct = true) as correct_count,
      COUNT(*) as total_count,
      SUM(CASE WHEN p.is_correct THEN 10 ELSE -5 END) as total_points
    FROM predictions p
    JOIN games g ON p.game_id = g.id
    WHERE p.admin_verified = true
      AND g.verified = true
    GROUP BY p.user_id
  )
  INSERT INTO leaderboard (
    user_id,
    correct_predictions,
    total_predictions,
    points,
    updated_at
  )
  SELECT 
    user_id,
    correct_count,
    total_count,
    GREATEST(total_points, 0),
    now()
  FROM user_stats
  ON CONFLICT (user_id)
  DO UPDATE SET
    correct_predictions = EXCLUDED.correct_predictions,
    total_predictions = EXCLUDED.total_predictions,
    points = GREATEST(EXCLUDED.points, 0),
    updated_at = EXCLUDED.updated_at;
END;
$$;

-- Create function to create user profile
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
  SELECT username INTO v_final_username
  FROM profiles
  WHERE user_id = p_user_id;
  
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
        v_final_username := v_normalized_username || 
                           extract(epoch from clock_timestamp())::bigint % 10000 ||
                           floor(random() * 900 + 100)::text;
        
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
      
      RETURN v_final_username;
    EXCEPTION
      WHEN unique_violation THEN
        v_retry_count := v_retry_count + 1;
        IF v_retry_count >= v_max_retries THEN
          RAISE EXCEPTION 'Failed to create unique username after % attempts', v_max_retries;
        END IF;
        v_final_username := NULL;
      WHEN OTHERS THEN
        RAISE;
    END;
  END LOOP;
  
  RAISE EXCEPTION 'Unexpected error in profile creation';
END;
$$;

-- Enable RLS
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Anyone can view players"
  ON players FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage players"
  ON players FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can view games"
  ON games FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage games"
  ON games FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

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

CREATE POLICY "Users can manage their own predictions"
  ON predictions FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Anyone can view leaderboard"
  ON leaderboard FOR SELECT
  TO public
  USING (true);

CREATE POLICY "System can manage leaderboard"
  ON leaderboard FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create indexes
CREATE INDEX idx_players_sort ON players (last_name, first_name);
CREATE INDEX idx_games_verified ON games (verified, game_time);
CREATE INDEX idx_games_time ON games (game_time);
CREATE INDEX idx_games_time_opponent ON games (DATE_TRUNC('day', game_time), opponent);

-- Grant permissions
GRANT ALL ON players TO authenticated;
GRANT SELECT ON players TO anon;
GRANT ALL ON games TO authenticated;
GRANT SELECT ON games TO anon;
GRANT ALL ON profiles TO authenticated;
GRANT SELECT ON profiles TO anon;
GRANT ALL ON predictions TO authenticated;
GRANT SELECT ON predictions TO anon;
GRANT ALL ON leaderboard TO authenticated;
GRANT SELECT ON leaderboard TO anon;
GRANT SELECT ON leaderboard_with_usernames TO authenticated;
GRANT SELECT ON leaderboard_with_usernames TO anon;
GRANT EXECUTE ON FUNCTION verify_game_predictions(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_profile(uuid, text) TO authenticated;