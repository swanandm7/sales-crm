import React, { Component } from 'react';
import { Slot, useRouter, useSegments } from 'expo-router';
import { useEffect } from 'react';
import { Platform, Text, TouchableOpacity, View } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import '../global.css';
import { Warning } from '../mobile/components/icons';
import { AuthProvider, useAuth } from '../mobile/contexts/AuthContext';
import { MobilePreferencesProvider, useMobilePreferences } from '../mobile/contexts/MobilePreferencesContext';
import { useFrameworkReady } from '../hooks/useFrameworkReady';

// ─── Error Boundary (Issue #21) ──────────────────────────────────────────────
interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

class AppErrorBoundary extends Component<
  { children: React.ReactNode },
  ErrorBoundaryState
> {
  constructor(props: { children: React.ReactNode }) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('[AppErrorBoundary] Uncaught error:', error, info);
  }

  render() {
    if (this.state.hasError) {
      return (
        <View
          style={{
            flex: 1,
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: '#0e0e10',
            padding: 32,
          }}
        >
          <Warning size={48} color={theme.danger} strokeWidth={1.5} />
          <View style={{ marginBottom: 16 }} />
          <Text
            style={{
              color: '#f5f5f7',
              fontSize: 20,
              fontWeight: '900',
              textAlign: 'center',
              letterSpacing: -0.4,
              marginBottom: 10,
            }}
          >
            Something went wrong
          </Text>
          <Text
            style={{
              color: '#a3a3a8',
              fontSize: 13,
              textAlign: 'center',
              lineHeight: 20,
              marginBottom: 28,
            }}
          >
            {this.state.error?.message || 'An unexpected error occurred. Please restart the app.'}
          </Text>
          <TouchableOpacity
            onPress={() => this.setState({ hasError: false, error: null })}
            style={{
              backgroundColor: '#F26A1F',
              borderRadius: 14,
              paddingVertical: 14,
              paddingHorizontal: 32,
            }}
          >
            <Text style={{ color: '#fff', fontSize: 15, fontWeight: '900' }}>Try again</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return this.props.children;
  }
}

// ─── No Organization Gate (Issue #3) ─────────────────────────────────────────
function NoOrganizationScreen() {
  const { signOut } = useAuth();
  const { theme } = useMobilePreferences();

  return (
    <View
      style={{
        flex: 1,
        backgroundColor: theme.bg,
        alignItems: 'center',
        justifyContent: 'center',
        padding: 32,
      }}
    >
      <Text style={{ fontSize: 56, marginBottom: 20 }}>🏢</Text>
      <Text
        style={{
          color: theme.text,
          fontSize: 22,
          fontWeight: '900',
          textAlign: 'center',
          letterSpacing: -0.5,
          marginBottom: 12,
        }}
      >
        Not assigned to an organization
      </Text>
      <Text
        style={{
          color: theme.textDim,
          fontSize: 14,
          textAlign: 'center',
          lineHeight: 22,
          marginBottom: 32,
        }}
      >
        Your account exists, but you haven't been added to any organization yet.{'\n\n'}
        Please contact your admin or team lead to invite you to the workspace.
      </Text>
      <View
        style={{
          backgroundColor: theme.surface,
          borderRadius: 14,
          borderWidth: 1,
          borderColor: theme.border,
          padding: 16,
          width: '100%',
          marginBottom: 24,
        }}
      >
        <Text style={{ color: theme.textMute, fontSize: 11, fontWeight: '800', letterSpacing: 0.8, marginBottom: 6 }}>
          WHAT TO DO
        </Text>
        <Text style={{ color: theme.text, fontSize: 13, lineHeight: 20 }}>
          {'1. Ask your admin to send you an invitation email\n'}
          {'2. Open the invitation link on this device\n'}
          {'3. Refresh the app once added'}
        </Text>
      </View>
      <TouchableOpacity
        onPress={() => signOut().catch(() => {})}
        style={{
          paddingVertical: 14,
          paddingHorizontal: 32,
          borderRadius: 14,
          borderWidth: 1,
          borderColor: theme.border,
          backgroundColor: theme.surface,
        }}
      >
        <Text style={{ color: theme.textDim, fontSize: 14, fontWeight: '800' }}>
          🚪 Sign out
        </Text>
      </TouchableOpacity>
    </View>
  );
}

// ─── Auth Gate + Navigation (Issue #9 — single source of navigation) ─────────
function RootLayoutNav() {
  const { user, profile, loading } = useAuth();
  const segments = useSegments();
  const router = useRouter();
  const isWeb = Platform.OS === 'web';
  const { theme } = useMobilePreferences();

  useEffect(() => {
    if (loading) return;

    const inAuthGroup = segments[0] === '(auth)';

    if (!user && !inAuthGroup) {
      // Not signed in → go to login
      router.replace('/(auth)/login');
    } else if (user && inAuthGroup) {
      // Signed in → go to main app
      // Only navigate if profile is loaded (or we know org is null)
      router.replace('/(tabs)');
    }
    // Note: login.tsx no longer calls router.replace() — this is the single source of truth
  }, [isWeb, user, loading, segments]);

  // If user is signed in but has no org, show the onboarding gate screen
  // Profile null check: loading=false means profile load completed
  if (!loading && user && profile && profile.organization_id === null) {
    return <NoOrganizationScreen />;
  }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: theme.bg }} edges={['top']}>
      <Slot />
    </SafeAreaView>
  );
}

export default function RootLayout() {
  useFrameworkReady();
  return (
    <AppErrorBoundary>
      <SafeAreaProvider>
        <MobilePreferencesProvider>
          <AuthProvider>
            <RootLayoutNav />
          </AuthProvider>
        </MobilePreferencesProvider>
      </SafeAreaProvider>
    </AppErrorBoundary>
  );
}
