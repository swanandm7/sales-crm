/*
  # Add Organization ID to All Data Tables

  1. Changes
    - Add `organization_id` column to:
      - profiles
      - leads
      - teams
      - followups
      - calls
      - notes
      - lead_sources
      - lead_statuses
      - message_templates
      - assignment_rules
      - bulk_download_history
      - bulk_upload_jobs
      - time_tracking_sessions
      - lead_activity_log
      - filter_presets
      - audit_log (if exists)

  2. Notes
    - Columns are NULLABLE initially for data migration
    - Foreign key constraints added with CASCADE delete
    - Indexes created for performance
    - Will be made NOT NULL after backfill migration
*/

-- Add organization_id to profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE profiles ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_profiles_organization_id ON profiles(organization_id);
  END IF;
END $$;

-- Add organization_id to leads
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'leads' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE leads ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_leads_organization_id ON leads(organization_id);
  END IF;
END $$;

-- Add organization_id to teams
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'teams' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE teams ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_teams_organization_id ON teams(organization_id);
  END IF;
END $$;

-- Add organization_id to followups
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'followups' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE followups ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_followups_organization_id ON followups(organization_id);
  END IF;
END $$;

-- Add organization_id to calls
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'calls' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE calls ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_calls_organization_id ON calls(organization_id);
  END IF;
END $$;

-- Add organization_id to notes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'notes' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE notes ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_notes_organization_id ON notes(organization_id);
  END IF;
END $$;

-- Add organization_id to lead_sources
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'lead_sources' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE lead_sources ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_lead_sources_organization_id ON lead_sources(organization_id);
  END IF;
END $$;

-- Add organization_id to lead_statuses
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'lead_statuses' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE lead_statuses ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_lead_statuses_organization_id ON lead_statuses(organization_id);
  END IF;
END $$;

-- Add organization_id to message_templates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'message_templates' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE message_templates ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_message_templates_organization_id ON message_templates(organization_id);
  END IF;
END $$;

-- Add organization_id to assignment_rules
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assignment_rules' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE assignment_rules ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_assignment_rules_organization_id ON assignment_rules(organization_id);
  END IF;
END $$;

-- Add organization_id to bulk_download_history
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bulk_download_history' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE bulk_download_history ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_bulk_download_history_organization_id ON bulk_download_history(organization_id);
  END IF;
END $$;

-- Add organization_id to bulk_upload_jobs
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bulk_upload_jobs' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE bulk_upload_jobs ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_bulk_upload_jobs_organization_id ON bulk_upload_jobs(organization_id);
  END IF;
END $$;

-- Add organization_id to time_tracking_sessions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'time_tracking_sessions' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE time_tracking_sessions ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_time_tracking_sessions_organization_id ON time_tracking_sessions(organization_id);
  END IF;
END $$;

-- Add organization_id to lead_activity_log
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'lead_activity_log' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE lead_activity_log ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_lead_activity_log_organization_id ON lead_activity_log(organization_id);
  END IF;
END $$;

-- Add organization_id to filter_presets
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'filter_presets' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE filter_presets ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_filter_presets_organization_id ON filter_presets(organization_id);
  END IF;
END $$;