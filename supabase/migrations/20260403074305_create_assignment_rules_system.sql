/*
  # Create Assignment Rules System

  1. New Tables
    - `assignment_rules`
      - `id` (uuid, primary key)
      - `rule_name` (text, unique)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
      
    - `assignment_rule_criteria`
      - `id` (uuid, primary key)
      - `rule_id` (uuid, foreign key to assignment_rules)
      - `criteria_type` (text: 'channel', 'source', 'specialization')
      - `condition_type` (text: 'includes', 'excludes', 'any')
      - `criteria_values` (text array)
      
    - `assignment_rule_counselors`
      - `id` (uuid, primary key)
      - `rule_id` (uuid, foreign key to assignment_rules)
      - `counselor_id` (uuid, foreign key to profiles)
      - `assignment_order` (integer)
      - `last_assigned_at` (timestamptz)
      
    - `assignment_rule_execution_log`
      - `id` (uuid, primary key)
      - `lead_id` (uuid, foreign key to leads)
      - `rule_id` (uuid, foreign key to assignment_rules, nullable)
      - `assigned_counselor_id` (uuid, foreign key to profiles)
      - `assignment_type` (text: 'rule_based', 'fallback_round_robin')
      - `matched_at` (timestamptz)
      
    - `system_round_robin_state`
      - `id` (uuid, primary key)
      - `last_assigned_counselor_id` (uuid, foreign key to profiles)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create assignment_rules table
CREATE TABLE IF NOT EXISTS assignment_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_name text UNIQUE NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE assignment_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assignment rules"
  ON assignment_rules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage assignment rules"
  ON assignment_rules FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create assignment_rule_criteria table
CREATE TABLE IF NOT EXISTS assignment_rule_criteria (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id uuid NOT NULL REFERENCES assignment_rules(id) ON DELETE CASCADE,
  criteria_type text NOT NULL CHECK (criteria_type IN ('channel', 'source', 'specialization')),
  condition_type text NOT NULL CHECK (condition_type IN ('includes', 'excludes', 'any')),
  criteria_values text[] DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE assignment_rule_criteria ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view rule criteria"
  ON assignment_rule_criteria FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage rule criteria"
  ON assignment_rule_criteria FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create assignment_rule_counselors table
CREATE TABLE IF NOT EXISTS assignment_rule_counselors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id uuid NOT NULL REFERENCES assignment_rules(id) ON DELETE CASCADE,
  counselor_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  assignment_order integer NOT NULL DEFAULT 0,
  last_assigned_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(rule_id, counselor_id)
);

ALTER TABLE assignment_rule_counselors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view rule counselors"
  ON assignment_rule_counselors FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage rule counselors"
  ON assignment_rule_counselors FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create assignment_rule_execution_log table
CREATE TABLE IF NOT EXISTS assignment_rule_execution_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  rule_id uuid REFERENCES assignment_rules(id) ON DELETE SET NULL,
  assigned_counselor_id uuid NOT NULL REFERENCES profiles(id),
  assignment_type text NOT NULL CHECK (assignment_type IN ('rule_based', 'fallback_round_robin', 'manual')),
  matched_at timestamptz DEFAULT now()
);

ALTER TABLE assignment_rule_execution_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assignment execution logs"
  ON assignment_rule_execution_log FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert assignment logs"
  ON assignment_rule_execution_log FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create system_round_robin_state table
CREATE TABLE IF NOT EXISTS system_round_robin_state (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  last_assigned_counselor_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE system_round_robin_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view round robin state"
  ON system_round_robin_state FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can update round robin state"
  ON system_round_robin_state FOR ALL
  TO authenticated
  WITH CHECK (true);

-- Initialize system round robin state with a single row
INSERT INTO system_round_robin_state (id, last_assigned_counselor_id, updated_at)
VALUES (gen_random_uuid(), NULL, now())
ON CONFLICT DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_assignment_rules_active ON assignment_rules(is_active, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rule_criteria_rule_id ON assignment_rule_criteria(rule_id);
CREATE INDEX IF NOT EXISTS idx_rule_counselors_rule_id ON assignment_rule_counselors(rule_id);
CREATE INDEX IF NOT EXISTS idx_execution_log_lead_id ON assignment_rule_execution_log(lead_id);
CREATE INDEX IF NOT EXISTS idx_execution_log_rule_id ON assignment_rule_execution_log(rule_id);
