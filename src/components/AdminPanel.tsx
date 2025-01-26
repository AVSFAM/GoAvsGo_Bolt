import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { db } from '../lib/db';
import type { Game, Player } from '../lib/types';
import { LoadingSpinner } from './LoadingSpinner';
import { ErrorMessage } from './ErrorMessage';
import { useAsync } from '../hooks/useAsync';

export function AdminPanel() {
  // State
  const [selectedGame, setSelectedGame] = useState<string>('');
  const [selectedPlayer, setSelectedPlayer] = useState<string>('');
  const [message, setMessage] = useState('');

  // Async data loading
  const { 
    data: games = [], 
    error: gamesError,
    loading: gamesLoading,
    execute: refreshGames
  } = useAsync<Game[]>(() => db.getPastUnverifiedGames());

  const {
    data: players = [],
    error: playersError,
    loading: playersLoading,
    execute: refreshPlayers
  } = useAsync<Player[]>(() => db.getPlayers());

  // Verification state
  const [verifying, setVerifying] = useState(false);

  const handleVerifyPrediction = async () => {
    if (!selectedGame || !selectedPlayer) {
      setMessage('Please select both a game and a player');
      return;
    }

    setVerifying(true);
    setMessage('');

    try {
      await db.verifyGame(selectedGame, selectedPlayer);
      setMessage('Game predictions verified successfully!');
      setSelectedGame('');
      setSelectedPlayer('');
      refreshGames(); // Refresh games list
    } catch (err) {
      console.error('Error verifying prediction:', err);
      setMessage(err instanceof Error ? err.message : 'Failed to verify predictions');
    } finally {
      setVerifying(false);
    }
  };

  // Show loading state
  if (gamesLoading || playersLoading) {
    return (
      <div className="bg-[#6F263D]/20 rounded-lg p-6 backdrop-blur-sm border border-white/10">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  // Show error state
  if (gamesError || playersError) {
    return (
      <div className="bg-[#6F263D]/20 rounded-lg p-6 backdrop-blur-sm border border-white/10">
        <ErrorMessage 
          error={gamesError || playersError || 'Failed to load data'} 
          onRetry={() => {
            refreshGames();
            refreshPlayers();
          }}
        />
      </div>
    );
  }

  return (
    <div className="bg-[#6F263D]/20 rounded-lg p-6 backdrop-blur-sm border border-white/10">
      <h2 className="text-xl font-semibold mb-4">Admin Panel 🛠️</h2>

      <div className="space-y-6">
        <div>
          <h3 className="text-lg font-medium mb-3">Verify Game Predictions</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">Select Game</label>
              <select
                value={selectedGame}
                onChange={(e) => setSelectedGame(e.target.value)}
                className="w-full bg-white/20 rounded-lg p-3 text-white"
                disabled={verifying}
              >
                <option value="">Choose a game...</option>
                {games.map((game) => (
                  <option key={game.id} value={game.id} disabled={game.verified}>
                    {format(new Date(game.game_time), 'MMM d, h:mm aa')} - {game.is_home ? 'vs' : '@'} {game.opponent}
                    {game.verified ? ' (Verified)' : ''}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium mb-1">Select First Goal Scorer</label>
              <select
                value={selectedPlayer}
                onChange={(e) => setSelectedPlayer(e.target.value)}
                className="w-full bg-white/20 rounded-lg p-3 text-white"
                disabled={verifying}
              >
                <option value="">Choose a player...</option>
                {players.map((player) => (
                  <option key={player.id} value={player.id}>
                    #{player.number} - {player.last_name}, {player.first_name} ({player.position})
                  </option>
                ))}
              </select>
            </div>

            <button
              onClick={handleVerifyPrediction}
              disabled={verifying || !selectedGame || !selectedPlayer}
              className="w-full bg-[#A2AAAD] text-[#6F263D] py-3 rounded-lg font-semibold hover:bg-[#A2AAAD]/90 transition disabled:opacity-50"
            >
              {verifying ? (
                <div className="flex items-center justify-center">
                  <LoadingSpinner size="sm" />
                  <span className="ml-2">Processing...</span>
                </div>
              ) : (
                'Verify Predictions'
              )}
            </button>
          </div>
        </div>

        {message && (
          <div className={`p-4 rounded-lg ${message.includes('Error') || message.includes('Failed') ? 'bg-red-500/20' : 'bg-green-500/20'}`}>
            {message}
          </div>
        )}
      </div>
    </div>
  );
}