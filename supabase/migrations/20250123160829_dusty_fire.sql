/*
  # Add test users and predictions

  1. Changes
    - Insert test users into auth.users
    - Create profiles with usernames for test users
    - Add some predictions for these users
    - Update leaderboard with initial points
*/

-- Insert test users into auth.users
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'avalanchefan1@example.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000002', 'avalanchefan2@example.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000003', 'avalanchefan3@example.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000004', 'avalanchefan4@example.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', now(), now(), now()),
  ('00000000-0000-0000-0000-000000000005', 'avalanchefan5@example.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', now(), now(), now())
ON CONFLICT (id) DO NOTHING;

-- Create profiles with usernames
INSERT INTO profiles (user_id, username)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'MacKFanatic'),
  ('00000000-0000-0000-0000-000000000002', 'RantanenRules'),
  ('00000000-0000-0000-0000-000000000003', 'MakarMagic'),
  ('00000000-0000-0000-0000-000000000004', 'AvsAllDay'),
  ('00000000-0000-0000-0000-000000000005', 'BallArenaLegend')
ON CONFLICT (user_id) DO NOTHING;

-- Insert initial leaderboard entries
INSERT INTO leaderboard (user_id, correct_predictions, total_predictions, points)
VALUES
  ('00000000-0000-0000-0000-000000000001', 3, 5, 20),
  ('00000000-0000-0000-0000-000000000002', 4, 6, 25),
  ('00000000-0000-0000-0000-000000000003', 5, 7, 35),
  ('00000000-0000-0000-0000-000000000004', 2, 4, 10),
  ('00000000-0000-0000-0000-000000000005', 3, 5, 15)
ON CONFLICT (user_id) DO UPDATE SET
  correct_predictions = EXCLUDED.correct_predictions,
  total_predictions = EXCLUDED.total_predictions,
  points = EXCLUDED.points;