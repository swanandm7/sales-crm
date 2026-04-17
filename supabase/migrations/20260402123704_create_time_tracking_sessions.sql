-- Create Time Tracking Sessions Table
--
-- 1. New Tables
--    - time_tracking_sessions
--      - id (uuid, primary key) - Unique session identifier
--      - user_id (uuid, foreign key) - References auth.users
--      - login_time (timestamptz) - When user logged in
--      - logout_time (timestamptz, nullable) - When user logged out (null if still active)
--      - total_seconds (integer) - Total logged time in seconds
--      - is_active (boolean) - Whether session is currently active
--      - created_at (timestamptz) - Record creation timestamp
--      - updated_at (timestamptz) - Record update timestamp
--
-- 2. Security
--    - Enable RLS on time_tracking_sessions table
--    - Users can view their own time tracking sessions
--    - Users can insert their own time tracking sessions
--    - Users can update their own time tracking sessions
--
-- 3. Indexes
--    - Index on user_id for faster queries
--    - Index on is_active for filtering active sessions

CREATE TABLE IF NOT EXISTS time_tracking_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  login_time timestamptz NOT NULL DEFAULT now(),
  logout_time timestamptz,
  total_seconds integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE time_tracking_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own time tracking sessions"
  ON time_tracking_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own time tracking sessions"
  ON time_tracking_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own time tracking sessions"
  ON time_tracking_sessions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_time_tracking_user_id ON time_tracking_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_time_tracking_is_active ON time_tracking_sessions(is_active);