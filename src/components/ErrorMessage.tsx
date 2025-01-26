import React from 'react';
import { AlertTriangle } from 'lucide-react';

interface ErrorMessageProps {
  error: Error | string;
  onRetry?: () => void;
}

export function ErrorMessage({ error, onRetry }: ErrorMessageProps) {
  const message = error instanceof Error ? error.message : error;

  return (
    <div className="bg-red-500/10 p-4 rounded-lg">
      <div className="flex items-center space-x-2 text-red-400">
        <AlertTriangle size={20} />
        <span className="font-medium">Error</span>
      </div>
      <p className="mt-2 text-white/70">{message}</p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-4 bg-white/10 px-4 py-2 rounded hover:bg-white/20 transition"
        >
          Try again
        </button>
      )}
    </div>
  );
}