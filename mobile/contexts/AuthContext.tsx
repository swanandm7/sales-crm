import React, { createContext, useContext, useState, useEffect, useRef } from 'react';
import { Alert, Modal, Text, TouchableOpacity, View } from 'react-native';
import { Session, User } from '@supabase/supabase-js';
import { splitFullName } from '../lib/leadQueue';
import { mobileSupabase } from '../lib/supabaseClient';

interface Profile {
  id: string;
  email: string;
  full_name: string;
  first_name: string;
  last_name: string;
  mobile_number: string | null;
  role_id: string | null;
  role_name: string;
  hierarchy_level: number;
  team_id: string | null;
  manager_id: string | null;
  organization_id: string | null;
  organization_name: string;
}

interface AuthContextType {
  user: User | null;
  profile: Profile | null;
  session: Session | null;
  loading: boolean;
  sessionExpired: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, fullName: string) => Promise<any>;
  resetPassword: (email: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  profile: null,
  session: null,
  loading: true,
  sessionExpired: false,
  signIn: async () => {},
  signUp: async () => {},
  resetPassword: async () => {},
  signOut: async () => {},
});

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [sessionExpired, setSessionExpired] = useState(false);

  // Guard against concurrent loadProfile calls (race condition fix — Issue #8)
  const loadingProfileRef = useRef(false);

  useEffect(() => {
    mobileSupabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        loadProfile(session.user.id);
      } else {
        setLoading(false);
      }
    });

    const {
      data: { subscription },
    } = mobileSupabase.auth.onAuthStateChange((event, session) => {
      setSession(session);
      setUser(session?.user ?? null);

      if (event === 'SIGNED_OUT') {
        // Session expired or user signed out remotely — show session expired modal
        setProfile(null);
        setSessionExpired(true);
        setLoading(false);
        return;
      }

      if (event === 'TOKEN_REFRESHED') {
        // Token refreshed successfully — clear any expired state
        setSessionExpired(false);
      }

      if (session?.user) {
        loadProfile(session.user.id);
      } else {
        setProfile(null);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const loadProfile = async (userId: string) => {
    // Prevent concurrent loadProfile calls (race condition fix — Issue #8)
    if (loadingProfileRef.current) return;
    loadingProfileRef.current = true;

    try {
      const { data, error } = await mobileSupabase
        .from('profiles')
        .select('id, email, full_name, mobile_number, role_id, team_id, manager_id, organization_id')
        .eq('id', userId)
        .single();

      if (error) throw error;

      if (data) {
        const [{ data: roleData }, { data: organizationData }] = await Promise.all([
          data.role_id
            ? mobileSupabase.from('roles').select('role_name').eq('id', data.role_id).single()
            : Promise.resolve({ data: null }),
          data.organization_id
            ? mobileSupabase.from('organizations').select('name').eq('id', data.organization_id).single()
            : Promise.resolve({ data: null }),
        ]);

        // Fetch hierarchy level for proper role-gating (fixes Issue #13 — string matching)
        let hierarchyLevel = 5; // default: lowest level (rep)
        try {
          const { data: levelData } = await mobileSupabase.rpc('get_user_hierarchy_level', { p_user_id: userId });
          if (typeof levelData === 'number') hierarchyLevel = levelData;
        } catch {
          // Non-critical — fall back to default
        }

        const { firstName, lastName } = splitFullName(data.full_name);
        setProfile({
          id: data.id,
          email: data.email,
          full_name: data.full_name,
          first_name: firstName,
          last_name: lastName,
          mobile_number: data.mobile_number,
          role_id: data.role_id,
          role_name: roleData?.role_name || 'User',
          hierarchy_level: hierarchyLevel,
          team_id: data.team_id,
          manager_id: data.manager_id,
          organization_id: data.organization_id,
          organization_name: organizationData?.name || 'Unknown',
        });
      }
    } catch (error) {
      console.error('Error loading profile:', error);
      // If profile fails to load AND we have a session, the session may be stale
      // Show a non-blocking retry rather than crashing
    } finally {
      setLoading(false);
      loadingProfileRef.current = false;
    }
  };

  const signIn = async (email: string, password: string) => {
    const { error } = await mobileSupabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    // DO NOT navigate here — let _layout.tsx handle it via user state change (Issue #9 fix)
    setSessionExpired(false);
  };

  const signUp = async (email: string, password: string, fullName: string) => {
    const { data, error } = await mobileSupabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
        },
      },
    });
    if (error) throw error;
    return data;
  };

  const resetPassword = async (email: string) => {
    const { error } = await mobileSupabase.auth.resetPasswordForEmail(email, {
      // Redirect to the web app reset page — mobile deep links handled separately
      redirectTo: process.env.EXPO_PUBLIC_APP_URL
        ? `${process.env.EXPO_PUBLIC_APP_URL}/reset-password`
        : undefined,
    });
    if (error) throw error;
  };

  const signOut = async () => {
    const { error } = await mobileSupabase.auth.signOut();
    if (error) throw error;
    setUser(null);
    setProfile(null);
    setSession(null);
    setSessionExpired(false);
  };

  const handleSessionExpiredReLogin = async () => {
    setSessionExpired(false);
    setUser(null);
    setProfile(null);
    setSession(null);
    // _layout.tsx will redirect to login automatically
    await mobileSupabase.auth.signOut().catch(() => {});
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        profile,
        session,
        loading,
        sessionExpired,
        signIn,
        signUp,
        resetPassword,
        signOut,
      }}
    >
      {children}

      {/* Session Expired Modal — shown when token expires mid-session */}
      <Modal visible={sessionExpired} transparent animationType="fade">
        <View
          style={{
            flex: 1,
            backgroundColor: 'rgba(0,0,0,0.75)',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 32,
          }}
        >
          <View
            style={{
              backgroundColor: '#17171a',
              borderRadius: 20,
              padding: 28,
              width: '100%',
              maxWidth: 360,
              alignItems: 'center',
              borderWidth: 1,
              borderColor: '#2a2a2f',
            }}
          >
            <Text style={{ fontSize: 36, marginBottom: 14 }}>🔐</Text>
            <Text
              style={{
                color: '#f5f5f7',
                fontSize: 20,
                fontWeight: '900',
                textAlign: 'center',
                letterSpacing: -0.4,
              }}
            >
              Session expired
            </Text>
            <Text
              style={{
                color: '#a3a3a8',
                fontSize: 14,
                textAlign: 'center',
                marginTop: 10,
                lineHeight: 21,
              }}
            >
              Your login session has timed out. Please sign in again to continue working.
            </Text>
            <TouchableOpacity
              onPress={handleSessionExpiredReLogin}
              style={{
                marginTop: 24,
                backgroundColor: '#F26A1F',
                borderRadius: 14,
                paddingVertical: 14,
                paddingHorizontal: 32,
                width: '100%',
                alignItems: 'center',
              }}
            >
              <Text style={{ color: '#fff', fontSize: 15, fontWeight: '900' }}>Sign in again</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </AuthContext.Provider>
  );
};
