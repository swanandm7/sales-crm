/*
  # Initial CRM Schema Setup

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key, references auth.users)
      - `email` (text)
      - `full_name` (text)
      - `role` (text, default 'sales_rep') - either 'admin' or 'sales_rep'
      - `avatar_url` (text, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `lead_sources`
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `color` (text)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
    
    - `lead_statuses`
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `display_name` (text)
      - `color` (text)
      - `order_index` (integer)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz)
    
    - `leads`
      - `id` (uuid, primary key)
      - `name` (text)
      - `email` (text, nullable)
      - `phone` (text)
      - `company` (text, nullable)
      - `lead_value` (decimal, nullable)
      - `source_id` (uuid, references lead_sources)
      - `status_id` (uuid, references lead_statuses)
      - `assigned_to` (uuid, references profiles)
      - `created_by` (uuid, references profiles)
      - `tags` (text[], default empty array)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `calls`
      - `id` (uuid, primary key)
      - `lead_id` (uuid, references leads)
      - `user_id` (uuid, references profiles)
      - `call_date` (timestamptz)
      - `duration_minutes` (integer, nullable)
      - `outcome` (text) - 'connected', 'no_answer', 'voicemail', 'busy', 'wrong_number', 'callback_requested'
      - `notes` (text, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `notes`
      - `id` (uuid, primary key)
      - `lead_id` (uuid, references leads)
      - `user_id` (uuid, references profiles)
      - `content` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their data
    - Admins can see all data, sales reps can see their assigned leads
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email text NOT NULL,
  full_name text NOT NULL,
  role text DEFAULT 'sales_rep' CHECK (role IN ('admin', 'sales_rep')),
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Create lead_sources table
CREATE TABLE IF NOT EXISTS lead_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  color text DEFAULT '#3b82f6',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE lead_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view active lead sources"
  ON lead_sources FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage lead sources"
  ON lead_sources FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Insert default lead sources
INSERT INTO lead_sources (name, color) VALUES
  ('Website', '#3b82f6'),
  ('Referral', '#10b981'),
  ('Cold Call', '#f59e0b'),
  ('Social Media', '#8b5cf6'),
  ('Trade Show', '#ef4444'),
  ('Partner', '#06b6d4'),
  ('Other', '#6b7280')
ON CONFLICT (name) DO NOTHING;

-- Create lead_statuses table
CREATE TABLE IF NOT EXISTS lead_statuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  display_name text NOT NULL,
  color text DEFAULT '#3b82f6',
  order_index integer NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE lead_statuses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view active lead statuses"
  ON lead_statuses FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage lead statuses"
  ON lead_statuses FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Insert default lead statuses
INSERT INTO lead_statuses (name, display_name, color, order_index) VALUES
  ('raw_data', 'Raw Data', '#6b7280', 1),
  ('new_lead', 'New Lead', '#3b82f6', 2),
  ('no_response', 'No Response', '#f59e0b', 3),
  ('follow_up', 'Follow Up', '#8b5cf6', 4),
  ('interested', 'Interested', '#10b981', 5),
  ('registration_done', 'Registration Done', '#06b6d4', 6),
  ('admission_done', 'Admission Done', '#059669', 7),
  ('junk', 'Junk', '#dc2626', 8),
  ('closed', 'Closed', '#4b5563', 9),
  ('post_sales', 'Post Sales', '#14b8a6', 10),
  ('re_enquired', 'Re-enquired', '#f97316', 11)
ON CONFLICT (name) DO NOTHING;

-- Create leads table
CREATE TABLE IF NOT EXISTS leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text,
  phone text NOT NULL,
  company text,
  lead_value decimal,
  source_id uuid REFERENCES lead_sources(id),
  status_id uuid REFERENCES lead_statuses(id),
  assigned_to uuid REFERENCES profiles(id),
  created_by uuid REFERENCES profiles(id),
  tags text[] DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assigned leads or all if admin"
  ON leads FOR SELECT
  TO authenticated
  USING (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Users can insert leads"
  ON leads FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by = auth.uid()
  );

CREATE POLICY "Users can update assigned leads or all if admin"
  ON leads FOR UPDATE
  TO authenticated
  USING (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    assigned_to = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can delete leads"
  ON leads FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create calls table
CREATE TABLE IF NOT EXISTS calls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid REFERENCES leads(id) ON DELETE CASCADE,
  user_id uuid REFERENCES profiles(id),
  call_date timestamptz DEFAULT now(),
  duration_minutes integer,
  outcome text CHECK (outcome IN ('connected', 'no_answer', 'voicemail', 'busy', 'wrong_number', 'callback_requested')),
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE calls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view calls for their leads"
  ON calls FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = calls.lead_id
      AND (leads.assigned_to = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
      ))
    )
  );

CREATE POLICY "Users can insert calls"
  ON calls FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
  );

CREATE POLICY "Users can update own calls"
  ON calls FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own calls"
  ON calls FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid REFERENCES leads(id) ON DELETE CASCADE,
  user_id uuid REFERENCES profiles(id),
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view notes for their leads"
  ON notes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = notes.lead_id
      AND (leads.assigned_to = auth.uid() OR EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
      ))
    )
  );

CREATE POLICY "Users can insert notes"
  ON notes FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
  );

CREATE POLICY "Users can update own notes"
  ON notes FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own notes"
  ON notes FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_leads_assigned_to ON leads(assigned_to);
CREATE INDEX IF NOT EXISTS idx_leads_status_id ON leads(status_id);
CREATE INDEX IF NOT EXISTS idx_leads_source_id ON leads(source_id);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_lead_id ON calls(lead_id);
CREATE INDEX IF NOT EXISTS idx_calls_user_id ON calls(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_lead_id ON notes(lead_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_calls_updated_at BEFORE UPDATE ON calls
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();