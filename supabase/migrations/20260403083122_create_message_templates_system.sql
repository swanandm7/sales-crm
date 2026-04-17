/*
  # Create Message Templates System

  1. New Tables
    - `message_templates`
      - Core template data including name, type, content
      - Approval workflow fields (is_approved, approved_by, approved_at)
      - Status management (is_active, is_draft)
      - Audit fields (created_by, created_at, updated_at)
    
    - `message_template_users`
      - Junction table linking templates to authorized users
      - Controls visibility and access to templates
    
    - `message_template_usage_log`
      - Tracks when and how templates are used
      - Records if template was edited after insertion
      - Links to lead, user, and template for analytics

  2. Security
    - Enable RLS on all tables
    - Admins can view and manage all templates
    - Regular users can only view approved templates assigned to them
    - All authenticated users can log template usage

  3. Important Notes
    - Template types are 'email' or 'whatsapp'
    - Templates must be approved before users can use them
    - Variable placeholders use {{variable_name}} syntax
    - WhatsApp templates should warn if over 1000 characters
*/

-- Create message_templates table
CREATE TABLE IF NOT EXISTS message_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_name text UNIQUE NOT NULL,
  template_type text NOT NULL CHECK (template_type IN ('email', 'whatsapp')),
  subject text,
  body_content text NOT NULL,
  created_by uuid NOT NULL REFERENCES profiles(id),
  is_approved boolean DEFAULT false,
  approved_by uuid REFERENCES profiles(id),
  approved_at timestamptz,
  is_active boolean DEFAULT true,
  is_draft boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create message_template_users junction table
CREATE TABLE IF NOT EXISTS message_template_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id uuid NOT NULL REFERENCES message_templates(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(template_id, user_id)
);

-- Create message_template_usage_log table
CREATE TABLE IF NOT EXISTS message_template_usage_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id uuid NOT NULL REFERENCES message_templates(id),
  lead_id uuid NOT NULL REFERENCES leads(id),
  user_id uuid NOT NULL REFERENCES profiles(id),
  template_content_used text NOT NULL,
  actual_content_sent text NOT NULL,
  was_edited boolean DEFAULT false,
  used_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE message_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_template_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_template_usage_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for message_templates

-- Admins can view all templates
CREATE POLICY "Admins can view all templates"
  ON message_templates FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Regular users can view approved templates assigned to them
CREATE POLICY "Users can view assigned approved templates"
  ON message_templates FOR SELECT
  TO authenticated
  USING (
    is_approved = true
    AND is_active = true
    AND EXISTS (
      SELECT 1 FROM message_template_users
      WHERE message_template_users.template_id = message_templates.id
      AND message_template_users.user_id = auth.uid()
    )
  );

-- Admins can insert templates
CREATE POLICY "Admins can create templates"
  ON message_templates FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Users can create their own templates (as drafts)
CREATE POLICY "Users can create draft templates"
  ON message_templates FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by = auth.uid()
    AND is_draft = true
    AND is_approved = false
  );

-- Admins can update all templates
CREATE POLICY "Admins can update all templates"
  ON message_templates FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Users can update their own draft templates
CREATE POLICY "Users can update own draft templates"
  ON message_templates FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid()
    AND is_draft = true
  )
  WITH CHECK (
    created_by = auth.uid()
    AND is_draft = true
  );

-- Admins can delete templates
CREATE POLICY "Admins can delete templates"
  ON message_templates FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- RLS Policies for message_template_users

-- Admins can view all template-user assignments
CREATE POLICY "Admins can view all template users"
  ON message_template_users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Users can view their own template assignments
CREATE POLICY "Users can view own template assignments"
  ON message_template_users FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Admins can manage template-user assignments
CREATE POLICY "Admins can insert template users"
  ON message_template_users FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can delete template users"
  ON message_template_users FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- RLS Policies for message_template_usage_log

-- Admins can view all usage logs
CREATE POLICY "Admins can view all template usage"
  ON message_template_usage_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Users can view their own usage logs
CREATE POLICY "Users can view own template usage"
  ON message_template_usage_log FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- All authenticated users can log template usage
CREATE POLICY "Users can log template usage"
  ON message_template_usage_log FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_message_templates_type ON message_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_message_templates_approved ON message_templates(is_approved, is_active);
CREATE INDEX IF NOT EXISTS idx_message_template_users_template ON message_template_users(template_id);
CREATE INDEX IF NOT EXISTS idx_message_template_users_user ON message_template_users(user_id);
CREATE INDEX IF NOT EXISTS idx_message_template_usage_template ON message_template_usage_log(template_id);
CREATE INDEX IF NOT EXISTS idx_message_template_usage_user ON message_template_usage_log(user_id);

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_message_templates_updated_at ON message_templates;
CREATE TRIGGER update_message_templates_updated_at
  BEFORE UPDATE ON message_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
