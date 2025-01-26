import { useState, useEffect } from 'react';
import { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

export function useAuth() {
  const [session, setSession] = useState<Session | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [username, setUsername] = useState('');

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      checkAdminStatus(session?.user?.id);
      if (session?.user) {
        fetchUsername(session.user.id);
      }
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      checkAdminStatus(session?.user?.id);
      if (session?.user) {
        fetchUsername(session.user.id);
      } else {
        setUsername('');
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const checkAdminStatus = async (userId?: string) => {
    if (!userId) {
      setIsAdmin(false);
      return;
    }

    const { data: { user } } = await supabase.auth.getUser();
    setIsAdmin(user?.email === 'info@avsfam.com');
  };

  const fetchUsername = async (userId: string) => {
    try {
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('username')
        .eq('user_id', userId)
        .limit(1)
        .maybeSingle();
        
      if (!profileError && profileData?.username) {
        setUsername(profileData.username);
        return;
      }

      const { data: { user } } = await supabase.auth.getUser();
      if (user?.email) {
        const baseUsername = user.email.split('@')[0];
        
        const { data: rpcData, error: rpcError } = await supabase.rpc(
          'create_user_profile',
          {
            p_user_id: userId,
            p_desired_username: baseUsername
          }
        );

        if (rpcError) {
          console.error('Error creating profile:', rpcError);
          setUsername('Anonymous Player');
        } else {
          setUsername(rpcData || 'Anonymous Player');
        }
      } else {
        setUsername('Anonymous Player');
      }
    } catch (error) {
      console.error('Error fetching username:', error);
      setUsername('Anonymous Player');
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setSession(null);
    setUsername('');
    setIsAdmin(false);
  };

  return {
    session,
    isAdmin,
    username,
    signOut
  };
}