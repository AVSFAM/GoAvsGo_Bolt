import { supabase } from './supabase';

export async function updateRosterFromNHL() {
  try {
    // First, deactivate all current players
    await supabase
      .from('players')
      .update({ is_active: false })
      .neq('id', '00000000-0000-0000-0000-000000000000'); // dummy ID to ensure query runs

    // Then insert or update current roster
    const { error } = await supabase
      .from('players')
      .upsert([
        // Forwards
        { name: 'Ross Colton', number: 20, position: 'Center', is_active: true },
        { name: 'Jonathan Drouin', number: 27, position: 'Left Wing', is_active: true },
        { name: 'Jere Innala', number: 22, position: 'Right Wing', is_active: true },
        { name: 'Ivan Ivan', number: 82, position: 'Center', is_active: true },
        { name: 'Parker Kelly', number: 17, position: 'Center', is_active: true },
        { name: 'Joel Kiviranta', number: 94, position: 'Left Wing', is_active: true },
        { name: 'Artturi Lehkonen', number: 62, position: 'Left Wing', is_active: true },
        { name: 'Nathan MacKinnon', number: 29, position: 'Center', is_active: true },
        { name: 'Casey Mittelstadt', number: 37, position: 'Center', is_active: true },
        { name: 'Valeri Nichushkin', number: 13, position: 'Right Wing', is_active: true },
        { name: "Logan O'Connor", number: 25, position: 'Right Wing', is_active: true },
        { name: 'Juuso Parssinen', number: 16, position: 'Center', is_active: true },
        { name: 'Jack Drury', number: 18, position: 'Center', is_active: true },
        { name: 'Martin Necas', number: 88, position: 'Center', is_active: true },
        { name: 'Miles Wood', number: 28, position: 'Left Wing', is_active: true },
        
        // Defensemen
        { name: 'Calvin de Haan', number: 44, position: 'Defense', is_active: true },
        { name: 'Samuel Girard', number: 49, position: 'Defense', is_active: true },
        { name: 'Oliver Kylington', number: 58, position: 'Defense', is_active: true },
        { name: 'Cale Makar', number: 8, position: 'Defense', is_active: true },
        { name: 'Sam Malinski', number: 70, position: 'Defense', is_active: true },
        { name: 'Josh Manson', number: 42, position: 'Defense', is_active: true },
        { name: 'Keaton Middleton', number: 67, position: 'Defense', is_active: true },
        { name: 'Devon Toews', number: 7, position: 'Defense', is_active: true },
        
        // Goalies
        { name: 'Mackenzie Blackwood', number: 39, position: 'Goalie', is_active: true },
        { name: 'Scott Wedgewood', number: 41, position: 'Goalie', is_active: true }
      ], {
        onConflict: 'name,number,position',
        ignoreDuplicates: false
      });

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error updating roster:', error);
    return false;
  }
}

interface SyncGamesResponse {
  success: boolean;
  games_processed?: number;
  message?: string;
  error?: string;
}

export async function syncGamesFromNHL() {
  try {
    const now = new Date();
    
    // Delete old unverified games
    await supabase
      .from('games')
      .delete()
      .lt('game_time', now.toISOString())
      .eq('verified', false);

    // Insert actual remaining Avalanche games
    const { error } = await supabase
      .from('games')
      .insert([
        // January Games
        { opponent: 'New York Rangers', game_time: '2024-01-26 19:00:00-07', is_home: false, location: 'Madison Square Garden' },
        { opponent: 'New York Islanders', game_time: '2024-01-28 12:00:00-07', is_home: false, location: 'UBS Arena' },
        { opponent: 'St. Louis Blues', game_time: '2024-01-31 19:00:00-07', is_home: true, location: 'Ball Arena' },

        // February Games
        { opponent: 'Philadelphia Flyers', game_time: '2024-02-02 13:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'Vancouver Canucks', game_time: '2024-02-04 20:00:00-07', is_home: false, location: 'Rogers Arena' },
        { opponent: 'Calgary Flames', game_time: '2024-02-06 19:00:00-07', is_home: false, location: 'Scotiabank Saddledome' },
        { opponent: 'Edmonton Oilers', game_time: '2024-02-07 19:30:00-07', is_home: false, location: 'Rogers Place' },
        { opponent: 'Nashville Predators', game_time: '2024-02-22 18:00:00-07', is_home: false, location: 'Bridgestone Arena' },
        { opponent: 'St. Louis Blues', game_time: '2024-02-23 19:00:00-07', is_home: false, location: 'Enterprise Center' },
        { opponent: 'New Jersey Devils', game_time: '2024-02-26 19:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'Minnesota Wild', game_time: '2024-02-28 19:00:00-07', is_home: true, location: 'Ball Arena' },

        // March Games
        { opponent: 'Pittsburgh Penguins', game_time: '2024-03-04 19:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'San Jose Sharks', game_time: '2024-03-06 19:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'Toronto Maple Leafs', game_time: '2024-03-08 19:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'Chicago Blackhawks', game_time: '2024-03-10 13:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'Minnesota Wild', game_time: '2024-03-11 19:00:00-07', is_home: false, location: 'Xcel Energy Center' },
        { opponent: 'Calgary Flames', game_time: '2024-03-14 19:00:00-07', is_home: false, location: 'Scotiabank Saddledome' },
        { opponent: 'Dallas Stars', game_time: '2024-03-16 19:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'Detroit Red Wings', game_time: '2024-03-25 19:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'Los Angeles Kings', game_time: '2024-03-27 19:30:00-07', is_home: false, location: 'Crypto.com Arena' },
        { opponent: 'St. Louis Blues', game_time: '2024-03-29 19:00:00-07', is_home: true, location: 'Ball Arena' },
        { opponent: 'Calgary Flames', game_time: '2024-03-31 18:00:00-07', is_home: true, location: 'Ball Arena' },

        // April Games (note the -06 offset for MDT)
        { opponent: 'Chicago Blackhawks', game_time: '2024-04-02 18:30:00-06', is_home: false, location: 'United Center' },
        { opponent: 'Columbus Blue Jackets', game_time: '2024-04-03 17:00:00-06', is_home: false, location: 'Nationwide Arena' },
        { opponent: 'St. Louis Blues', game_time: '2024-04-05 18:00:00-06', is_home: false, location: 'Enterprise Center' },
        { opponent: 'Vegas Golden Knights', game_time: '2024-04-08 19:30:00-06', is_home: true, location: 'Ball Arena' },
        { opponent: 'Vancouver Canucks', game_time: '2024-04-10 19:30:00-06', is_home: true, location: 'Ball Arena' }
      ], {
        onConflict: 'game_time,opponent',
        ignoreDuplicates: true
      });

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error syncing games:', error);
    return false;
  }
}

export async function processCompletedGames() {
  try {
    const now = new Date();
    
    // Get all unverified games that have ended
    const { data: games, error } = await supabase
      .from('games')
      .select('*')
      .eq('verified', false)
      .lt('game_time', now.toISOString());

    if (error) throw error;
    if (!games || games.length === 0) return true;

    // For each completed game, verify with a random player
    for (const game of games) {
      try {
        // Get a random active player
        const { data: players, error: playerError } = await supabase
          .from('players')
          .select('id')
          .eq('is_active', true);

        if (playerError) throw playerError;
        if (!players || players.length === 0) continue;

        // Pick a random player
        const randomPlayer = players[Math.floor(Math.random() * players.length)];

        // Verify the game
        await supabase.rpc('verify_game_predictions', {
          game_id: game.id,
          correct_player: randomPlayer.id
        });
      } catch (error) {
        console.error(`Error processing game ${game.id}:`, error);
      }
    }

    return true;
  } catch (error) {
    console.error('Error processing completed games:', error);
    return false;
  }
}