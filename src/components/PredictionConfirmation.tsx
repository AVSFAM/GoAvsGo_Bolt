import React from 'react';
import { ArrowLeft } from 'lucide-react';
import { format } from 'date-fns';
import type { Prediction } from '../lib/types';

interface PredictionConfirmationProps {
  prediction: Prediction;
  onBack: () => void;
}

export function PredictionConfirmation({ prediction, onBack }: PredictionConfirmationProps) {
  return (
    <div className="bg-[#6F263D]/20 rounded-lg p-6 backdrop-blur-sm border border-white/10">
      <div className="flex items-center space-x-3 mb-6">
        <button
          onClick={onBack}
          className="text-white/70 hover:text-white transition flex items-center space-x-2"
        >
          <ArrowLeft size={20} />
          <span>Back</span>
        </button>
      </div>

      <div className="text-center space-y-6">
        <h2 className="text-xl font-semibold">Bold Prediction! 🎯</h2>

        <div className="bg-white/5 p-4 rounded-lg">
          <p className="text-lg mb-2">
            You predicted <span className="font-bold">{prediction.player.name}</span>!
          </p>
          <p className="text-white/70">
            {prediction.game.is_home ? 'vs' : '@'} {prediction.game.opponent}
          </p>
          <p className="text-sm text-white/70">
            {format(new Date(prediction.game.game_time), 'MMM d, h:mm aa')} - {prediction.game.location}
          </p>
        </div>

        <p className="text-white/70">
          Good luck! Check back after the game to see if you were right.
        </p>
      </div>
    </div>
  );
}