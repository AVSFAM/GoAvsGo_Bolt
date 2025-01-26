import React, { useState, useEffect } from 'react';
import { Pocket as Hockey, Trophy, User, ArrowLeft, Book, Info } from 'lucide-react';
import { format, isPast, addHours } from 'date-fns';
import { Session } from '@supabase/supabase-js';
import type { Player, Game, Prediction, LeaderboardEntry } from '../lib/types';
import { AdminPanel } from './AdminPanel';
import { PredictionConfirmation } from './PredictionConfirmation';
import { AuthModal } from './AuthModal';
import { RulesPage } from './RulesPage';
import { SignedOutScreen } from './SignedOutScreen';
import { LoadingSpinner } from './LoadingSpinner';
import { ErrorMessage } from './ErrorMessage';
import { useAsync } from '../hooks/useAsync';
import { useInterval } from '../hooks/useInterval';
import { db } from '../lib/db';
import { useAuth } from '../hooks/useAuth';

export function AppContent() {
  // Auth states from custom hook
  const { session, isAdmin, username, signOut } = useAuth();
  const [showAuth, setShowAuth] = useState(false);
  const [isSignUp, setIsSignUp] = useState(false);
  const [showRules, setShowRules] = useState(false);

  // Game states with loading and error handling
  const { 
    data: players = [], 
    error: playersError,
    loading: playersLoading,
    execute: refreshPlayers
  } = useAsync<Player[]>(() => db.getPlayers());

  const {
    data: games = [], 
    error: gamesError,
    loading: gamesLoading,
    execute: refreshGames
  } = useAsync<Game[]>(() => db.getGames());

  const {
    data: leaderboard = [],
    error: leaderboardError,
    loading: leaderboardLoading,
    execute: refreshLeaderboard
  } = useAsync<LeaderboardEntry[]>(() => db.getLeaderboard());

  // Prediction states
  const [selectedPlayer, setSelectedPlayer] = useState<string>('');
  const [currentPrediction, setCurrentPrediction] = useState<Prediction | null>(null);
  const [predicting, setPredicting] = useState(false);
  const [predictionError, setPredictionError] = useState<string>('');

  // Random greeting
  const [userGreeting] = useState(() => {
    const greetings = [
      "🏒 [user] is on the ice!",
      "⚡ [user] just hit the rink!",
      "🥅 Look who's in the crease - it's [user]!",
      "🎯 [user] is ready to snipe!",
      "🚨 [user] has entered the zone!",
      "💪 [user] is suited up!",
      "🌟 [user] is in the lineup!",
      "🏆 [user] is ready to play!",
      "⭐ [user] just hopped over the boards!",
      "🎮 [user] is in the game!"
    ];
    return greetings[Math.floor(Math.random() * greetings.length)];
  });

  // Auto-refresh leaderboard
  useInterval(() => {
    refreshLeaderboard();
  }, 5000);

  // Get current and next games
  const currentGame = games?.find(game => {
    if (!game?.game_time) return false;
    const gameTime = new Date(game.game_time);
    const gameEndTime = addHours(gameTime, 3);
    const now = new Date();
    return now >= gameTime && now <= gameEndTime;
  });

  const nextGame = games?.find(game => {
    if (!game?.game_time) return false;
    const gameTime = new Date(game.game_time);
    return gameTime > new Date();
  });

  const canPredict = nextGame && !isPast(new Date(nextGame.game_time));

  // Handle prediction submission
  const handlePrediction = async () => {
    if (!session?.user || !selectedPlayer || !nextGame) return;

    setPredicting(true);
    setPredictionError('');

    try {
      const prediction = await db.createPrediction(
        session.user.id,
        selectedPlayer,
        nextGame.id
      );
      setCurrentPrediction(prediction);
      setSelectedPlayer('');
      refreshGames();
    } catch (error) {
      console.error('Error submitting prediction:', error);
      setPredictionError(error instanceof Error ? error.message : 'Failed to submit prediction');
    } finally {
      setPredicting(false);
    }
  };

  // Handle sign out
  const handleSignOut = async () => {
    try {
      await signOut();
      window.location.reload();
    } catch (error) {
      console.error('Error signing out:', error);
      alert('Failed to sign out. Please try again.');
    }
  };

  // Show loading state
  if (playersLoading || gamesLoading || leaderboardLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner 
          size="lg" 
          message="Loading game data..." 
        />
      </div>
    );
  }

  // Show error state
  if (playersError || gamesError || leaderboardError) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <ErrorMessage 
          error={playersError || gamesError || leaderboardError || 'Failed to load data'} 
          onRetry={() => {
            refreshPlayers();
            refreshGames();
            refreshLeaderboard();
          }}
        />
      </div>
    );
  }

  // Show signed out screen
  if (!session) {
    return (
      <SignedOutScreen 
        onSignIn={() => { setIsSignUp(false); setShowAuth(true); }}
        onSignUp={() => { setIsSignUp(true); setShowAuth(true); }}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#6F263D] to-[#236192] text-white">
      <header className="bg-[#6F263D]/90 shadow-lg backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 md:py-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center space-x-3">
              <Hockey size={32} className="text-[#A2AAAD]" />
              <h1 className="text-xl md:text-2xl font-bold">#GoAvsGo First Goal Challenge 🏒</h1>
            </div>
            <div className="flex items-center space-x-3">
              <div className="text-[#A2AAAD] font-medium">
                {userGreeting.replace('[user]', username)}
              </div>
              <button
                onClick={() => setShowRules(true)}
                className="btn btn-secondary flex items-center space-x-2"
              >
                <Info size={20} />
                <span>Rules</span>
              </button>
              <button
                onClick={handleSignOut}
                className="btn btn-primary"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="grid md:grid-cols-2 gap-8">
          {isAdmin ? (
            <AdminPanel />
          ) : currentPrediction ? (
            <PredictionConfirmation 
              prediction={currentPrediction}
              onBack={() => setCurrentPrediction(null)}
            />
          ) : (
            <div className="bg-[#6F263D]/20 rounded-lg p-6 backdrop-blur-sm border border-white/10 animate-fade-in">
              <h2 className="text-xl font-semibold mb-4">Make Your Prediction 🎯</h2>

              {currentGame && (
                <div className="bg-white/5 p-4 rounded-lg mb-4">
                  <h3 className="text-lg font-semibold mb-2">Current Game 🏒</h3>
                  <p>
                    {currentGame.is_home ? 'vs' : '@'} {currentGame.opponent}
                  </p>
                  <p className="text-sm text-white/70">
                    {format(new Date(currentGame.game_time), 'h:mm aa')} - {currentGame.location}
                  </p>
                </div>
              )}

              {canPredict ? (
                <>
                  <select
                    value={selectedPlayer}
                    onChange={(e) => setSelectedPlayer(e.target.value)}
                    className="select w-full mb-4"
                    disabled={predicting}
                  >
                    <option value="">Select a player... ⭐</option>
                    {players.map((player) => (
                      <option key={player.id} value={player.id}>
                        #{player.number} - {player.last_name}, {player.first_name} ({player.position})
                      </option>
                    ))}
                  </select>
                  <button
                    onClick={handlePrediction}
                    disabled={predicting || !selectedPlayer}
                    className="btn btn-primary w-full"
                  >
                    {predicting ? (
                      <div className="flex items-center justify-center">
                        <LoadingSpinner size="sm" />
                        <span className="ml-2">Submitting...</span>
                      </div>
                    ) : (
                      'Submit Prediction 🚨'
                    )}
                  </button>

                  {predictionError && (
                    <div className="mt-4 bg-red-500/10 text-red-200 p-3 rounded-lg text-sm">
                      {predictionError}
                    </div>
                  )}
                </>
              ) : (
                <p className="text-white/70">
                  {nextGame ? 'Game has already started. Check back for the next game! ⏳' : 'No upcoming games available. Stay tuned! 📅'}
                </p>
              )}

              {nextGame && (
                <div className="mt-4 text-center text-sm text-white/70">
                  Next game: {nextGame.is_home ? 'vs' : '@'} {nextGame.opponent} - {format(new Date(nextGame.game_time), 'MMM d, h:mm aa')}
                </div>
              )}
            </div>
          )}

          <div className="bg-[#236192]/20 rounded-lg p-6 backdrop-blur-sm border border-white/10 animate-fade-in">
            <div className="flex items-center space-x-3 mb-4">
              <Trophy size={24} className="text-[#A2AAAD]" />
              <h2 className="text-xl font-semibold">Leaderboard 🏆</h2>
            </div>
            <div className="space-y-3">
              {leaderboard.map((entry, index) => (
                <div
                  key={entry.id}
                  className="flex items-center justify-between bg-white/5 p-3 rounded-lg border border-white/5 hover:bg-white/10 transition"
                >
                  <div className="flex items-center space-x-3">
                    <span className="text-lg font-bold">{index + 1}</span>
                    <span>{entry.username}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-[#A2AAAD] font-bold">{entry.points}</span>
                    <span className="text-white/70"> pts</span>
                  </div>
                </div>
              ))}
              {leaderboard.length === 0 && (
                <div className="text-center text-white/70 py-4">
                  No predictions verified yet. Check back after the next game! 🏒
                </div>
              )}
            </div>
          </div>
        </div>
      </main>

      <footer className="mt-8">
        <div className="container mx-auto px-4 py-6 text-center text-white">
          <p>
            Brought to you by{' '}
            <a href="https://www.avsfam.com" className="hover:underline" target="_blank" rel="noopener noreferrer">
              #AVFAM
            </a>
            {' '}and{' '}
            <span>#AVSLOOP</span>
          </p>
          <p className="mt-2">
            <a href="mailto:support@goavsgo.com" className="hover:underline">
              support@goavsgo.com
            </a>
            {' '}• © {new Date().getFullYear()}
          </p>
        </div>
      </footer>

      {showRules && <RulesPage onClose={() => setShowRules(false)} />}
      {showAuth && <AuthModal onClose={() => setShowAuth(false)} isSignUp={isSignUp} />}
    </div>
  );
}