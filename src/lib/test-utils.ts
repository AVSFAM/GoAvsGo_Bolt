import { describe, it, expect, vi } from 'vitest';
import { supabase } from './supabase';

export async function runScoringTests() {
  const results: string[] = [];
  let success = true;

  try {
    // Clean up test data
    await supabase.rpc('cleanup_test_data');
    results.push('✅ Cleaned up existing test data');

    // Create test user
    const testUser = await createTestUser();
    results.push('✅ Created test user');

    // Get MacKinnon's ID
    const mackinnon = await findMacKinnon();
    results.push('✅ Found MacKinnon in players');

    // Create test game
    const game = await createTestGame();
    results.push('✅ Created test game');

    // Create prediction
    await createTestPrediction(testUser.id, mackinnon.id, game.id);
    results.push('✅ Created prediction');

    // Verify game prediction
    await verifyGamePrediction(game.id, mackinnon.id);
    results.push('✅ Verified game prediction');

    // Wait for leaderboard update
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Verify points
    await verifyLeaderboardPoints(testUser.username);
    results.push('✅ Verified leaderboard points');

  } catch (error: any) {
    success = false;
    results.push(`❌ Error: ${error.message}`);
  }

  return {
    success,
    results: results.join('\n')
  };
}

async function createTestUser(retryCount = 0): Promise<{ id: string; username: string }> {
  try {
    const timestamp = Date.now();
    const username = `TestUser${timestamp}`;
    const email = `testuser${timestamp}@example.com`;

    const { data: authData, error: signUpError } = await supabase.auth.signUp({
      email,
      password: 'testpass123'
    });

    if (signUpError) throw signUpError;
    if (!authData.user) throw new Error('No user returned from signup');

    const { error: profileError } = await supabase.rpc(
      'create_user_profile',
      {
        p_user_id: authData.user.id,
        p_desired_username: username
      }
    );

    if (profileError) throw profileError;

    return { id: authData.user.id, username };
  } catch (error: any) {
    if (error.message.includes('user_already_exists') && retryCount < 3) {
      return createTestUser(retryCount + 1);
    }
    throw error;
  }
}

async function createTestGame() {
  const { data, error } = await supabase
    .from('games')
    .insert([{
      opponent: 'Test Team',
      game_time: new Date(Date.now() + 30 * 60000).toISOString(),
      is_home: true,
      location: 'Test Arena'
    }])
    .select()
    .single();

  if (error) throw error;
  return data;
}

async function findMacKinnon() {
  const { data, error } = await supabase
    .from('players')
    .select()
    .eq('name', 'Nathan MacKinnon')
    .eq('is_active', true)
    .limit(1)
    .single();

  if (error) throw error;
  return data;
}

async function createTestPrediction(userId: string, playerId: string, gameId: string) {
  const { error } = await supabase
    .from('predictions')
    .insert([{
      user_id: userId,
      player_id: playerId,
      game_id: gameId,
      game_date: new Date().toISOString().split('T')[0]
    }]);

  if (error) throw error;
}

async function verifyGamePrediction(gameId: string, playerId: string) {
  const { error } = await supabase.rpc('verify_game_predictions', {
    game_id: gameId,
    correct_player: playerId
  });

  if (error) throw error;
}

async function verifyLeaderboardPoints(username: string) {
  const { data, error } = await supabase
    .from('leaderboard_with_usernames')
    .select()
    .eq('username', username)
    .maybeSingle();

  if (error) throw error;
  if (!data) throw new Error('Leaderboard entry not found');
  if (data.points !== 10) {
    throw new Error(`Expected 10 points, got ${data.points}`);
  }
}