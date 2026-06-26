import { createClient } from '@supabase/supabase-js';
import type { Database } from '../../src/lib/database.types';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

// Issue #32 fix: Friendly startup error instead of a module-level throw that crashes the app
if (!supabaseUrl || !supabaseAnonKey) {
  console.error(
    '[supabaseClient] EXPO_PUBLIC_SUPABASE_URL or EXPO_PUBLIC_SUPABASE_ANON_KEY is missing.\n' +
    'Create a .env file with these values. The app will not function without them.'
  );
}

export const mobileSupabase = createClient<Database>(
  supabaseUrl ?? 'https://placeholder.supabase.co',
  supabaseAnonKey ?? 'placeholder-key',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
    },
  }
);
