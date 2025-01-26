export interface Player {
  id: string;
  name: string;
  first_name: string;
  last_name: string;
  number: number;
  position: string;
  is_active: boolean;
}

export interface Game {
  id: string;
  opponent: string;
  game_time: string;
  is_home: boolean;
  location: string;
  verified: boolean;
  correct_player_id?: string;
}

export interface Prediction {
  id: string;
  user_id: string;
  player_id: string;
  game_id: string;
  game_date: string;
  is_correct: boolean;
  admin_verified: boolean;
  created_at: string;
  player: Player;
  game: Game;
}

export interface Rule {
  id: string;
  title: string;
  content: string;
  order_number: number;
  created_at: string;
}

export interface LeaderboardEntry {
  id: string;
  user_id: string;
  username: string;
  correct_predictions: number;
  total_predictions: number;
  points: number;
  updated_at: string;
}