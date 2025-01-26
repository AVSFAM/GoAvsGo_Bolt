import { supabase } from './supabase';

// Test the connection and log details
console.log('Testing Supabase connection...');
console.log('URL:', import.meta.env.VITE_SUPABASE_URL);
console.log('Key (first 10 chars):', import.meta.env.VITE_SUPABASE_ANON_KEY.substring(0, 10) + '...');

interface TestResult {
  table: string;
  select: boolean;
  insert?: boolean;
  update?: boolean;
  delete?: boolean;
  error?: string;
}

// Test all table permissions
export async function testConnection() {
  const results: TestResult[] = [];

  try {
    // Test players table
    const playersResult = await testTablePermissions('players');
    results.push(playersResult);

    // Test games table
    const gamesResult = await testTablePermissions('games');
    results.push(gamesResult);

    // Test profiles table
    const profilesResult = await testTablePermissions('profiles');
    results.push(profilesResult);

    // Test predictions table
    const predictionsResult = await testTablePermissions('predictions');
    results.push(predictionsResult);

    // Test leaderboard view
    const leaderboardResult = await testTablePermissions('leaderboard_with_usernames', true);
    results.push(leaderboardResult);

    // Log results in a formatted table
    console.table(results);

    // Return overall success status
    return !results.some(r => r.error);
  } catch (err) {
    console.error('Supabase connection error:', err);
    return false;
  }
}

async function testTablePermissions(tableName: string, viewOnly = false): Promise<TestResult> {
  const result: TestResult = {
    table: tableName,
    select: false
  };

  try {
    // Test SELECT
    const selectResult = await supabase
      .from(tableName)
      .select('*')
      .limit(1);
    result.select = !selectResult.error;
    
    if (!viewOnly) {
      // Test INSERT (with immediate deletion to avoid data pollution)
      const insertResult = await supabase
        .from(tableName)
        .insert([{ test: true }])
        .select();
      result.insert = !insertResult.error;

      if (insertResult.data?.[0]?.id) {
        // Test UPDATE
        const updateResult = await supabase
          .from(tableName)
          .update({ test: false })
          .eq('id', insertResult.data[0].id);
        result.update = !updateResult.error;

        // Test DELETE
        const deleteResult = await supabase
          .from(tableName)
          .delete()
          .eq('id', insertResult.data[0].id);
        result.delete = !deleteResult.error;
      }
    }
  } catch (err: any) {
    result.error = err.message;
  }

  return result;
}

// Test RPC functions
export async function testRPCFunctions() {
  try {
    // Test sync_games function
    const syncResult = await supabase.rpc('sync_games');
    console.log('sync_games test:', syncResult.error || 'Success');

    // Test verify_game_predictions function (with dummy data)
    const verifyResult = await supabase.rpc('verify_game_predictions', {
      game_id: '00000000-0000-0000-0000-000000000000',
      correct_player: '00000000-0000-0000-0000-000000000000'
    });
    console.log('verify_game_predictions test:', verifyResult.error || 'Success');

    return true;
  } catch (err) {
    console.error('RPC function test error:', err);
    return false;
  }
}