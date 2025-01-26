import { supabase } from './supabase';
import type { Game, Player, Prediction, LeaderboardEntry } from './types';

// Cache durations
const CACHE_DURATION = 1000 * 60 * 5; // 5 minutes
const LEADERBOARD_CACHE_DURATION = 1000 * 30; // 30 seconds
const caches = new Map<string, { data: any; timestamp: number }>();

// Error types
export class DatabaseError extends Error {
  constructor(message: string, public originalError: any) {
    super(message);
    this.name = 'DatabaseError';
  }
}

// Service layer for database operations
export const db = {
  // Cache management
  private: {
    getCache<T>(key: string, duration = CACHE_DURATION): T | null {
      const cache = caches.get(key);
      if (!cache) return null;
      if (Date.now() - cache.timestamp > duration) {
        caches.delete(key);
        return null;
      }
      return cache.data as T;
    },

    setCache(key: string, data: any) {
      caches.set(key, { data, timestamp: Date.now() });
    },

    clearCache(key?: string) {
      if (key) {
        caches.delete(key);
      } else {
        caches.clear();
      }
    }
  },

  // Games
  async getGames(): Promise<Game[]> {
    try {
      const cached = this.private.getCache<Game[]>('games');
      if (cached) return cached;

      const { data, error } = await supabase
        .from('games')
        .select('*')
        .order('game_time');
      
      if (error) throw new DatabaseError('Failed to fetch games', error);
      if (!data) return [];
      
      // Sort games by date
      const sortedGames = data.sort((a, b) => {
        const dateA = new Date(a.game_time);
        const dateB = new Date(b.game_time);
        return dateA.getTime() - dateB.getTime();
      });
      
      this.private.setCache('games', sortedGames);
      return sortedGames;
    } catch (error) {
      console.error('Error fetching games:', error);
      throw error;
    }
  },

  async getPastUnverifiedGames(): Promise<Game[]> {
    try {
      const { data, error } = await supabase
        .from('games')
        .select('*')
        .lt('game_time', new Date().toISOString())
        .eq('verified', false)
        .order('game_time', { ascending: false });
      
      if (error) throw new DatabaseError('Failed to fetch past unverified games', error);
      return data || [];
    } catch (error) {
      console.error('Error fetching past unverified games:', error);
      throw error;
    }
  },

  // Players
  async getPlayers(): Promise<Player[]> {
    try {
      const cached = this.private.getCache<Player[]>('players');
      if (cached) return cached;

      const { data, error } = await supabase
        .from('players')
        .select('*')
        .eq('is_active', true)
        .order('last_name, first_name');
      
      if (error) throw new DatabaseError('Failed to fetch players', error);
      if (!data) return [];
      
      // Sort players by position and number
      const sortedPlayers = data.sort((a, b) => {
        // Sort by position first (Forwards, Defense, Goalies)
        const positionOrder = { 'Center': 1, 'Left Wing': 2, 'Right Wing': 3, 'Defense': 4, 'Goalie': 5 };
        const posA = positionOrder[a.position as keyof typeof positionOrder] || 99;
        const posB = positionOrder[b.position as keyof typeof positionOrder] || 99;
        if (posA !== posB) return posA - posB;
        
        // Then by number
        return a.number - b.number;
      });
      
      this.private.setCache('players', sortedPlayers);
      return sortedPlayers;
    } catch (error) {
      console.error('Error fetching players:', error);
      throw error;
    }
  },

  // Predictions
  async createPrediction(userId: string, playerId: string, gameId: string): Promise<Prediction> {
    try {
      // Validate game hasn't started
      const { data: game, error: gameError } = await supabase
        .from('games')
        .select('game_time, opponent')
        .eq('id', gameId)
        .single();

      if (gameError) throw new DatabaseError('Failed to fetch game', gameError);
      if (!game) throw new Error('Game not found');

      const gameTime = new Date(game.game_time);
      if (gameTime <= new Date()) {
        throw new Error(`Cannot make predictions after the ${game.opponent} game has started`);
      }

      // Create prediction
      const { data, error } = await supabase
        .from('predictions')
        .insert([{
          user_id: userId,
          player_id: playerId,
          game_id: gameId,
          game_date: new Date().toISOString().split('T')[0]
        }])
        .select('*, player:players(*), game:games(*)')
        .single();

      if (error) {
        if (error.message.includes('unique_user_game_prediction')) {
          throw new Error('You have already made a prediction for this game');
        }
        throw new DatabaseError('Failed to create prediction', error);
      }
      
      // Clear affected caches
      this.private.clearCache('predictions');
      return data;
    } catch (error) {
      console.error('Error creating prediction:', error);
      throw error;
    }
  },

  // Leaderboard
  async getLeaderboard(forceRefresh = false): Promise<LeaderboardEntry[]> {
    try {
      if (!forceRefresh) {
        const cached = this.private.getCache<LeaderboardEntry[]>('leaderboard', LEADERBOARD_CACHE_DURATION);
        if (cached) return cached;
      }

      const { data, error } = await supabase
        .from('leaderboard_with_usernames')
        .select('*')
        .order('points', { ascending: false })
        .limit(10);

      if (error) throw new DatabaseError('Failed to fetch leaderboard', error);
      if (!data) return [];
      
      this.private.setCache('leaderboard', data);
      return data;
    } catch (error) {
      console.error('Error fetching leaderboard:', error);
      throw error;
    }
  },

  // Admin functions
  async verifyGame(gameId: string, playerId: string): Promise<void> {
    try {
      // Validate game exists and is in the past
      const { data: game, error: gameError } = await supabase
        .from('games')
        .select('game_time, verified, opponent')
        .eq('id', gameId)
        .single();

      if (gameError) throw new DatabaseError('Failed to fetch game', gameError);
      if (!game) throw new Error('Game not found');
      if (game.verified) throw new Error(`The ${game.opponent} game is already verified`);
      if (new Date(game.game_time) > new Date()) {
        throw new Error(`Cannot verify the ${game.opponent} game before it starts`);
      }

      // Verify game
      const { error } = await supabase.rpc('verify_game_predictions', {
        game_id: gameId,
        correct_player: playerId
      });

      if (error) throw new DatabaseError('Failed to verify game', error);
      
      // Clear affected caches
      this.private.clearCache('leaderboard');
      this.private.clearCache('games');
      this.private.clearCache('predictions');
    } catch (error) {
      console.error('Error verifying game:', error);
      throw error;
    }
  }
};