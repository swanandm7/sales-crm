/*
  # Create Email Notification System

  1. New Tables
    - email_templates: Reusable email templates
    - email_queue: Queue for pending emails
    - email_logs: History of all sent emails

  2. Email Templates
    - Support for dynamic variables
    - HTML and plain text versions
    - Template categories

  3. Email Queue
    - Retry logic
    - Priority levels
    - Status tracking

  4. Security
    - Enable RLS on all tables
    - Restrict access to admins
*/

-- Create email_templates table
CREATE TABLE IF NOT EXISTS email_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id),
  template_key text NOT NULL UNIQUE,
  template_name text NOT NULL,
  subject text NOT NULL,
  body_html text NOT NULL,
  body_text text,
  category text DEFAULT 'general' CHECK (category IN ('invitation', 'notification', 'security', 'system', 'general')),
  variables jsonb DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT NOW(),
  updated_at timestamptz DEFAULT NOW()
);

ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage email templates"
  ON email_templates FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level = 1
      )
    )
  );

-- Create email_queue table
CREATE TABLE IF NOT EXISTS email_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id),
  to_email text NOT NULL,
  cc_emails text[],
  bcc_emails text[],
  subject text NOT NULL,
  body_html text NOT NULL,
  body_text text,
  template_id uuid REFERENCES email_templates(id),
  template_data jsonb DEFAULT '{}'::jsonb,
  priority integer DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'sent', 'failed', 'cancelled')),
  retry_count integer DEFAULT 0,
  max_retries integer DEFAULT 3,
  error_message text,
  scheduled_at timestamptz DEFAULT NOW(),
  sent_at timestamptz,
  created_at timestamptz DEFAULT NOW(),
  updated_at timestamptz DEFAULT NOW()
);

ALTER TABLE email_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their email queue"
  ON email_queue FOR SELECT
  TO authenticated
  USING (
    to_email IN (
      SELECT email FROM profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level <= 2
      )
    )
  );

-- Create email_logs table
CREATE TABLE IF NOT EXISTS email_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id),
  queue_id uuid REFERENCES email_queue(id),
  to_email text NOT NULL,
  subject text NOT NULL,
  status text NOT NULL CHECK (status IN ('sent', 'failed', 'bounced', 'delivered', 'opened', 'clicked')),
  provider_id text,
  provider_response jsonb,
  error_message text,
  sent_at timestamptz DEFAULT NOW(),
  delivered_at timestamptz,
  opened_at timestamptz,
  clicked_at timestamptz,
  created_at timestamptz DEFAULT NOW()
);

ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their email logs"
  ON email_logs FOR SELECT
  TO authenticated
  USING (
    to_email IN (
      SELECT email FROM profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role_id IN (
        SELECT id FROM roles WHERE hierarchy_level <= 2
      )
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_email_queue_status ON email_queue(status);
CREATE INDEX IF NOT EXISTS idx_email_queue_scheduled_at ON email_queue(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_email_queue_priority ON email_queue(priority DESC);
CREATE INDEX IF NOT EXISTS idx_email_logs_to_email ON email_logs(to_email);
CREATE INDEX IF NOT EXISTS idx_email_logs_sent_at ON email_logs(sent_at DESC);

-- Seed default email templates
INSERT INTO email_templates (template_key, template_name, subject, body_html, body_text, category, variables)
VALUES 
  (
    'invitation_sent',
    'Invitation to Join',
    'You''ve been invited to join {{organization_name}}',
    '<h1>Welcome to {{organization_name}}!</h1><p>You''ve been invited to join as a {{role_name}}.</p><p><a href="{{invite_link}}">Accept Invitation</a></p><p>This invitation expires in 48 hours.</p>',
    'Welcome to {{organization_name}}! You''ve been invited to join as a {{role_name}}. Click the link to accept: {{invite_link}}. This invitation expires in 48 hours.',
    'invitation',
    '["organization_name", "role_name", "invite_link", "inviter_name"]'::jsonb
  ),
  (
    'invite_accepted',
    'Invitation Accepted',
    '{{user_name}} accepted your invitation',
    '<h1>Great news!</h1><p>{{user_name}} has accepted your invitation and joined {{organization_name}}.</p>',
    '{{user_name}} has accepted your invitation and joined {{organization_name}}.',
    'notification',
    '["user_name", "organization_name"]'::jsonb
  ),
  (
    'invite_expired',
    'Invitation Expired',
    'Your invitation to {{organization_name}} has expired',
    '<h1>Invitation Expired</h1><p>Your invitation to join {{organization_name}} has expired. Please contact your administrator for a new invitation.</p>',
    'Your invitation to join {{organization_name}} has expired. Please contact your administrator for a new invitation.',
    'notification',
    '["organization_name"]'::jsonb
  ),
  (
    'account_disabled',
    'Account Disabled',
    'Your account has been disabled',
    '<h1>Account Status Update</h1><p>Your account at {{organization_name}} has been disabled. Please contact your administrator for more information.</p>',
    'Your account at {{organization_name}} has been disabled. Please contact your administrator for more information.',
    'security',
    '["organization_name"]'::jsonb
  ),
  (
    'welcome_email',
    'Welcome to the Platform',
    'Welcome to {{organization_name}}!',
    '<h1>Welcome aboard!</h1><p>Your account setup is complete. You can now access all features available to your role.</p>',
    'Welcome aboard! Your account setup is complete. You can now access all features available to your role.',
    'notification',
    '["organization_name", "user_name"]'::jsonb
  )
ON CONFLICT (template_key) DO NOTHING;
