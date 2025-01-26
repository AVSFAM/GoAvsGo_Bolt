import React, { useState } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface AuthModalProps {
  onClose: () => void;
  isSignUp: boolean;
}

export function AuthModal({ onClose, isSignUp: initialIsSignUp }: AuthModalProps) {
  const [isSignUp, setIsSignUp] = useState(initialIsSignUp);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const validateForm = () => {
    if (!email || !password) {
      setError('Please fill in all fields');
      return false;
    }

    if (isSignUp && !username) {
      setError('Please enter a username');
      return false;
    }

    if (isSignUp && username.length < 3) {
      setError('Username must be at least 3 characters long');
      return false;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters long');
      return false;
    }

    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!validateForm()) return;

    setLoading(true);

    try {
      if (isSignUp) {
        // Sign up the user first
        const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
          email: email.trim(),
          password,
        });

        if (signUpError) {
          if (signUpError.message.includes('User already registered')) {
            throw new Error('This email is already registered. Please sign in instead.');
          }
          throw signUpError;
        }
        
        if (!signUpData.user) throw new Error('Failed to create user');

        try {
          // Create profile using RPC function with corrected parameter names
          const { data: profileData, error: profileError } = await supabase.rpc(
            'create_user_profile',
            {
              p_user_id: signUpData.user.id,
              p_desired_username: username.trim()
            }
          );

          if (profileError) throw profileError;
          if (!profileData) throw new Error('Failed to create profile');

        } catch (profileError: any) {
          // Clean up auth user if profile creation fails
          await supabase.auth.signOut();
          throw new Error(profileError.message || 'Failed to create profile. Please try again.');
        }

      } else {
        // Sign in
        const { error: signInError } = await supabase.auth.signInWithPassword({
          email: email.trim(),
          password
        });

        if (signInError) {
          if (signInError.message.includes('Invalid')) {
            throw new Error('Invalid email or password');
          }
          throw signInError;
        }
      }

      onClose();
    } catch (err: any) {
      console.error('Auth error:', err);
      setError(err.message || 'An error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div className="bg-white text-gray-900 rounded-lg p-6 w-full max-w-md relative">
        <button
          onClick={onClose}
          className="absolute right-4 top-4 text-gray-500 hover:text-gray-700"
        >
          <X size={20} />
        </button>

        <h2 className="text-2xl font-bold mb-6">
          {isSignUp ? 'Create Account' : 'Welcome Back'}
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          {isSignUp && (
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-700">
                Username
              </label>
              <input
                type="text"
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value.trim())}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-[#6F263D] focus:outline-none focus:ring-1 focus:ring-[#6F263D]"
                required
                minLength={3}
                pattern="[a-zA-Z0-9_-]+"
                title="Only letters, numbers, underscores, and hyphens are allowed"
                disabled={loading}
              />
              <p className="mt-1 text-sm text-gray-500">
                At least 3 characters. Only letters, numbers, underscores, and hyphens allowed.
              </p>
            </div>
          )}

          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700">
              Email
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-[#6F263D] focus:outline-none focus:ring-1 focus:ring-[#6F263D]"
              required
              disabled={loading}
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700">
              Password
            </label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-[#6F263D] focus:outline-none focus:ring-1 focus:ring-[#6F263D]"
              required
              minLength={6}
              disabled={loading}
            />
            <p className="mt-1 text-sm text-gray-500">
              At least 6 characters
            </p>
          </div>

          {error && (
            <div className="bg-red-50 text-red-600 p-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#6F263D] text-white py-2 px-4 rounded-lg hover:bg-[#6F263D]/90 transition disabled:opacity-50"
          >
            {loading ? 'Please wait...' : (isSignUp ? 'Create Account' : 'Sign In')}
          </button>
        </form>

        <div className="mt-4 text-center">
          <button
            onClick={() => {
              setIsSignUp(!isSignUp);
              setError('');
              setEmail('');
              setPassword('');
              setUsername('');
            }}
            className="text-sm text-[#6F263D] hover:underline"
            disabled={loading}
          >
            {isSignUp ? 'Already have an account? Sign in' : 'Need an account? Sign up'}
          </button>
        </div>
      </div>
    </div>
  );
}