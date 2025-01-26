import React from 'react';
import { X } from 'lucide-react';
import { Rule } from '../lib/types';
import { supabase } from '../lib/supabase';

interface RulesPageProps {
  onClose: () => void;
}

export function RulesPage({ onClose }: RulesPageProps) {
  const [rules] = React.useState<Rule[]>([
    {
      id: '1',
      title: 'How to Play',
      content: 'Predict which Avalanche player will score the team\'s first goal in each game. Only Avalanche goals count!',
      order_number: 1,
      created_at: new Date().toISOString()
    },
    {
      id: '2',
      title: 'Scoring',
      content: 'Earn 10 points for correct predictions and lose 5 points for incorrect ones. Your total score determines your position on the leaderboard.',
      order_number: 2,
      created_at: new Date().toISOString()
    },
    {
      id: '3',
      title: 'Game Schedule',
      content: 'Predictions can be made up until the game starts. Once a game begins, predictions are locked.',
      order_number: 3,
      created_at: new Date().toISOString()
    },
    {
      id: '4',
      title: 'Multiple Predictions',
      content: 'You can change your prediction as many times as you want before the game starts. Only your last prediction counts.',
      order_number: 4,
      created_at: new Date().toISOString()
    },
    {
      id: '5',
      title: 'Results',
      content: 'Game results are verified by admins after each game. Points are awarded once the first Avalanche goal scorer is confirmed.',
      order_number: 5,
      created_at: new Date().toISOString()
    },
    {
      id: '6',
      title: 'Leaderboard',
      content: 'The leaderboard shows the top performers. Keep making correct predictions to climb the rankings!',
      order_number: 6,
      created_at: new Date().toISOString()
    }
  ]);

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div className="bg-white text-gray-900 rounded-lg p-6 w-full max-w-2xl relative max-h-[90vh] overflow-y-auto">
        <button
          onClick={onClose}
          className="absolute right-4 top-4 text-gray-500 hover:text-gray-700"
        >
          <X size={20} />
        </button>

        <h2 className="text-2xl font-bold mb-6">Game Rules 📋</h2>

        <div className="space-y-6">
          {rules.map((rule) => (
            <div key={rule.id} className="border-b border-gray-200 pb-4 last:border-0">
              <h3 className="text-lg font-semibold mb-2">{rule.title}</h3>
              <p className="text-gray-600">{rule.content}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}