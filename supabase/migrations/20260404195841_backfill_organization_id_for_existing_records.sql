/*
  # Backfill organization_id for existing records

  1. Purpose
    - Sets organization_id for all records that currently have NULL organization_id
    - Ensures data integrity and proper multi-tenant isolation

  2. Strategy
    - For leads: Use the creator's organization_id or default organization
    - For teams: Use the team lead's organization_id or default organization
    - For activity logs, calls, notes, followups: Use the related lead's organization_id
    - For templates, filter presets, downloads, uploads: Use the user's organization_id
    - For time tracking: Use the user's organization_id

  3. Default Organization
    - Creates a default organization if none exists
    - Uses first available organization as fallback

  4. Notes
    - This is a one-time data migration
    - All NULL values will be replaced with appropriate organization_id
    - Only processes tables that have organization_id column
*/

-- Step 1: Ensure at least one default organization exists
DO $$
DECLARE
  default_org_id uuid;
BEGIN
  SELECT id INTO default_org_id
  FROM organizations
  WHERE status = 'active'
  ORDER BY created_at
  LIMIT 1;

  IF default_org_id IS NULL THEN
    INSERT INTO organizations (name, status)
    VALUES ('Default Organization', 'active')
    RETURNING id INTO default_org_id;
  END IF;

  CREATE TEMP TABLE IF NOT EXISTS temp_default_org (org_id uuid);
  DELETE FROM temp_default_org;
  INSERT INTO temp_default_org VALUES (default_org_id);
END $$;

-- Step 2: Backfill leads table
UPDATE leads
SET organization_id = COALESCE(
  (SELECT organization_id FROM profiles WHERE profiles.id = leads.created_by),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 3: Backfill teams table
UPDATE teams
SET organization_id = COALESCE(
  (SELECT organization_id FROM profiles WHERE profiles.id = teams.team_lead_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 4: Backfill followups table (use lead's organization)
UPDATE followups
SET organization_id = COALESCE(
  (SELECT organization_id FROM leads WHERE leads.id = followups.lead_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 5: Backfill calls table (use lead's organization)
UPDATE calls
SET organization_id = COALESCE(
  (SELECT organization_id FROM leads WHERE leads.id = calls.lead_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 6: Backfill lead_activity_log table (use lead's organization)
UPDATE lead_activity_log
SET organization_id = COALESCE(
  (SELECT organization_id FROM leads WHERE leads.id = lead_activity_log.lead_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 7: Backfill notes table (use lead's organization)
UPDATE notes
SET organization_id = COALESCE(
  (SELECT organization_id FROM leads WHERE leads.id = notes.lead_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 8: Backfill message_templates table (use creator's organization)
UPDATE message_templates
SET organization_id = COALESCE(
  (SELECT organization_id FROM profiles WHERE profiles.id = message_templates.created_by),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 9: Backfill filter_presets table (use user's organization)
UPDATE filter_presets
SET organization_id = COALESCE(
  (SELECT organization_id FROM profiles WHERE profiles.id = filter_presets.user_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 10: Backfill bulk_upload_jobs table (use user's organization)
UPDATE bulk_upload_jobs
SET organization_id = COALESCE(
  (SELECT organization_id FROM profiles WHERE profiles.id = bulk_upload_jobs.user_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 11: Backfill bulk_download_history table (use user's organization)
UPDATE bulk_download_history
SET organization_id = COALESCE(
  (SELECT organization_id FROM profiles WHERE profiles.id = bulk_download_history.user_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 12: Backfill time_tracking_sessions table (use user's organization)
UPDATE time_tracking_sessions
SET organization_id = COALESCE(
  (SELECT organization_id FROM profiles WHERE profiles.id = time_tracking_sessions.user_id),
  (SELECT org_id FROM temp_default_org)
)
WHERE organization_id IS NULL;

-- Step 13: Backfill lead_sources and lead_statuses (use default organization)
UPDATE lead_sources
SET organization_id = (SELECT org_id FROM temp_default_org)
WHERE organization_id IS NULL;

UPDATE lead_statuses
SET organization_id = (SELECT org_id FROM temp_default_org)
WHERE organization_id IS NULL;

-- Step 14: Backfill assignment_rules (use default organization)
UPDATE assignment_rules
SET organization_id = (SELECT org_id FROM temp_default_org)
WHERE organization_id IS NULL;

-- Clean up temporary table
DROP TABLE IF EXISTS temp_default_org;
