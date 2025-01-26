import React, { useState } from 'react';
import { Pocket as Hockey } from 'lucide-react';
import { AuthModal } from './AuthModal';

interface SignedOutScreenProps {
  onSignIn: () => void;
  onSignUp: () => void;
}

export function SignedOutScreen({ onSignIn, onSignUp }: SignedOutScreenProps) {
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [isSignUp, setIsSignUp] = useState(false);

  const handleSignIn = () => {
    setIsSignUp(false);
    setShowAuthModal(true);
  };

  const handleSignUp = () => {
    setIsSignUp(true);
    setShowAuthModal(true);
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#6F263D] to-[#236192] text-white flex flex-col">
      <div className="flex-1 flex flex-col items-center justify-center p-8">
        <div className="max-w-2xl w-full space-y-8 text-center">
          <div className="flex items-center justify-center space-x-4">
            <Hockey size={48} className="text-[#A2AAAD]" />
            <h1 className="text-4xl font-bold">#GoAvsGo</h1>
          </div>
          
          <h2 className="text-2xl font-semibold">First Avalanche Goal Challenge</h2>
          
          <p className="text-xl text-white/80">
            Join the excitement! Predict which Avalanche player will score the team's first goal in each game.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <button
              onClick={handleSignIn}
              className="w-full sm:w-auto bg-white/10 px-8 py-3 rounded-lg hover:bg-white/20 transition text-lg"
            >
              Sign In
            </button>
            <button
              onClick={handleSignUp}
              className="w-full sm:w-auto bg-white text-[#6F263D] px-8 py-3 rounded-lg hover:bg-white/90 transition text-lg font-semibold"
            >
              Sign Up
            </button>
          </div>

          <div className="grid md:grid-cols-3 gap-6 mt-12">
            <div className="bg-white/5 p-6 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">Make Predictions</h3>
              <p className="text-white/70">Pick which Avalanche player will light the lamp first for the team</p>
            </div>
            <div className="bg-white/5 p-6 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">Earn Points</h3>
              <p className="text-white/70">Get 10 points for correct predictions, climb the leaderboard</p>
            </div>
            <div className="bg-white/5 p-6 rounded-lg">
              <h3 className="text-lg font-semibold mb-2">Join the Community</h3>
              <p className="text-white/70">Connect with other Avs fans and share your predictions</p>
            </div>
          </div>
        </div>
      </div>

      <footer className="text-center py-6">
        <p className="text-white/70">
          Brought to you by #AVFAM and #AVSLOOP
        </p>
      </footer>

      {showAuthModal && (
        <AuthModal
          isSignUp={isSignUp}
          onClose={() => setShowAuthModal(false)}
        />
      )}
    </div>
  );
}