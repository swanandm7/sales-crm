/*
  # Lead Activity Tracking System

  1. New Tables
    - `activity_templates`
      - `id` (uuid, primary key)
      - `activity_type` (text)
      - `template` (text) - Template string with placeholders
      - `description` (text) - Human-readable description
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `lead_activity_log`
      - `id` (uuid, primary key)
      - `lead_id` (uuid, foreign key to leads) - CASCADE DELETE
      - `user_id` (uuid, foreign key to profiles)
      - `activity_type` (text) - Type of activity
      - `activity_description` (text) - Human-readable description
      - `field_name` (text, nullable) - Field that was changed
      - `old_value` (text, nullable) - Previous value
      - `new_value` (text, nullable) - New value
      - `metadata` (jsonb, nullable) - Additional structured data
      - `is_pinned` (boolean) - Whether activity is pinned
      - `created_at` (timestamptz)

  2. Indexes
    - Index on lead_id for fast lead activity queries
    - Index on user_id for user activity queries
    - Index on activity_type for filtering
    - Index on is_pinned for pinned activities
    - Composite index on (lead_id, created_at DESC) for timeline queries
    - Index on created_at for date range filtering

  3. Security
    - Enable RLS on both tables
    - Users can view activity logs for leads they have access to
    - Users can create activity logs
    - Users can update is_pinned on their own activities or if they have lead access
    - Only authenticated users can access activity logs
*/

-- Create activity_templates table
CREATE TABLE IF NOT EXISTS activity_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_type text NOT NULL,
  template text NOT NULL,
  description text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create lead_activity_log table
CREATE TABLE IF NOT EXISTS lead_activity_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id),
  activity_type text NOT NULL,
  activity_description text NOT NULL,
  field_name text,
  old_value text,
  new_value text,
  metadata jsonb,
  is_pinned boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for optimal query performance
CREATE INDEX IF NOT EXISTS idx_lead_activity_log_lead_id ON lead_activity_log(lead_id);
CREATE INDEX IF NOT EXISTS idx_lead_activity_log_user_id ON lead_activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_lead_activity_log_activity_type ON lead_activity_log(activity_type);
CREATE INDEX IF NOT EXISTS idx_lead_activity_log_is_pinned ON lead_activity_log(is_pinned);
CREATE INDEX IF NOT EXISTS idx_lead_activity_log_lead_created ON lead_activity_log(lead_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lead_activity_log_created_at ON lead_activity_log(created_at);

-- Enable RLS
ALTER TABLE activity_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_activity_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for activity_templates (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view activity templates"
  ON activity_templates FOR SELECT
  TO authenticated
  USING (true);

-- RLS Policies for lead_activity_log
CREATE POLICY "Users can view activity logs for accessible leads"
  ON lead_activity_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = lead_activity_log.lead_id
      AND (leads.assigned_to = auth.uid() OR leads.created_by = auth.uid())
    )
  );

CREATE POLICY "Users can create activity logs"
  ON lead_activity_log FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update pinned status on activities"
  ON lead_activity_log FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = lead_activity_log.lead_id
      AND (leads.assigned_to = auth.uid() OR leads.created_by = auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = lead_activity_log.lead_id
      AND (leads.assigned_to = auth.uid() OR leads.created_by = auth.uid())
    )
  );

-- Insert default activity templates
INSERT INTO activity_templates (activity_type, template, description) VALUES
  ('lead_created', '{{user_name}} created this lead', 'Lead creation'),
  ('lead_created_bulk', '{{user_name}} created this lead via bulk upload (Job #{{job_id}})', 'Bulk lead creation'),
  ('lead_edited', '{{user_name}} changed {{field_name}} from "{{old_value}}" to "{{new_value}}"', 'Field edit'),
  ('status_changed', '{{user_name}} changed status from {{old_value}} to {{new_value}}', 'Status change'),
  ('sub_status_changed', '{{user_name}} changed sub-status from {{old_value}} to {{new_value}}', 'Sub-status change'),
  ('ownership_transferred', '{{user_name}} transferred lead from {{old_value}} to {{new_value}}', 'Ownership transfer'),
  ('lead_referred', '{{user_name}} referred this lead to {{new_owner}}', 'Lead referral'),
  ('comment_added', '{{user_name}} added a comment', 'Comment added'),
  ('followup_created', '{{user_name}} scheduled a follow-up for {{followup_date}}', 'Follow-up scheduled'),
  ('call_logged', '{{user_name}} logged a {{call_outcome}} call ({{call_duration}})', 'Call logged'),
  ('email_sent', '{{user_name}} sent an email: "{{email_subject}}"', 'Email sent'),
  ('whatsapp_sent', '{{user_name}} sent a WhatsApp message', 'WhatsApp message'),
  ('lead_deleted', '{{user_name}} deleted this lead', 'Lead deleted')
ON CONFLICT DO NOTHING;

-- Function to count pinned activities per lead (for validation)
CREATE OR REPLACE FUNCTION count_pinned_activities(p_lead_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  pin_count integer;
BEGIN
  SELECT COUNT(*) INTO pin_count
  FROM lead_activity_log
  WHERE lead_id = p_lead_id AND is_pinned = true;
  
  RETURN pin_count;
END;
$$;

-- Function to get activity statistics for a lead
CREATE OR REPLACE FUNCTION get_lead_activity_stats(p_lead_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total_activities', COUNT(*),
    'pinned_count', COUNT(*) FILTER (WHERE is_pinned = true),
    'activities_last_24h', COUNT(*) FILTER (WHERE created_at > now() - interval '24 hours'),
    'most_active_user', (
      SELECT jsonb_build_object(
        'user_id', user_id,
        'activity_count', COUNT(*)
      )
      FROM lead_activity_log
      WHERE lead_id = p_lead_id
      GROUP BY user_id
      ORDER BY COUNT(*) DESC
      LIMIT 1
    ),
    'activity_type_breakdown', (
      SELECT jsonb_object_agg(activity_type, count)
      FROM (
        SELECT activity_type, COUNT(*) as count
        FROM lead_activity_log
        WHERE lead_id = p_lead_id
        GROUP BY activity_type
      ) breakdown
    )
  ) INTO result
  FROM lead_activity_log
  WHERE lead_id = p_lead_id;
  
  RETURN result;
END;
$$;