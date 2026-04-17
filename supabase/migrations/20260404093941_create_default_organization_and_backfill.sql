/*
  # Create Default Organization and Backfill Existing Data

  1. Migration Steps
    - Create a default organization named "Default Organization"
    - Assign first super admin as owner
    - Set tier to 'enterprise' with unlimited users
    - Backfill all existing profiles with default organization_id
    - Create organization_members records for all profiles
    - Backfill all data tables with default organization_id

  2. Data Safety
    - Uses IF NOT EXISTS checks to prevent duplicate organizations
    - Safe for re-running if needed
    - All existing data preserved and associated with default org

  3. Notes
    - After this migration, all existing users are part of default organization
    - Super admin can later create additional organizations
    - Users can be moved to new organizations by super admin
*/

-- Create default organization
DO $$
DECLARE
  v_org_id uuid;
  v_owner_id uuid;
BEGIN
  -- Check if default organization already exists
  SELECT id INTO v_org_id FROM organizations WHERE slug = 'default-organization';
  
  IF v_org_id IS NULL THEN
    -- Find first user with hierarchy_level = 1 (super admin) to be the owner
    SELECT p.id INTO v_owner_id
    FROM profiles p
    JOIN roles r ON r.id = p.role_id
    WHERE r.hierarchy_level = 1
    ORDER BY p.created_at
    LIMIT 1;
    
    -- If no super admin exists, find hierarchy_level <= 2 (admin)
    IF v_owner_id IS NULL THEN
      SELECT p.id INTO v_owner_id
      FROM profiles p
      JOIN roles r ON r.id = p.role_id
      WHERE r.hierarchy_level <= 2
      ORDER BY p.created_at
      LIMIT 1;
    END IF;
    
    -- Create default organization
    INSERT INTO organizations (
      name,
      slug,
      owner_id,
      status,
      tier,
      max_users
    ) VALUES (
      'Default Organization',
      'default-organization',
      v_owner_id,
      'active',
      'enterprise',
      NULL  -- Unlimited users
    )
    RETURNING id INTO v_org_id;
    
    RAISE NOTICE 'Created default organization with id: %', v_org_id;
  ELSE
    RAISE NOTICE 'Default organization already exists with id: %', v_org_id;
  END IF;
  
  -- Backfill profiles with organization_id
  UPDATE profiles
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  RAISE NOTICE 'Updated % profiles with organization_id', (SELECT COUNT(*) FROM profiles WHERE organization_id = v_org_id);
  
  -- Create organization_members records for all profiles
  INSERT INTO organization_members (organization_id, profile_id, role_id, joined_at)
  SELECT 
    v_org_id,
    p.id,
    p.role_id,
    p.created_at
  FROM profiles p
  WHERE NOT EXISTS (
    SELECT 1 FROM organization_members om
    WHERE om.profile_id = p.id
  )
  ON CONFLICT (profile_id) DO NOTHING;
  
  RAISE NOTICE 'Created organization_members records';
  
  -- Backfill leads with organization_id
  UPDATE leads
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill teams with organization_id
  UPDATE teams
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill followups with organization_id
  UPDATE followups
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill calls with organization_id
  UPDATE calls
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill notes with organization_id
  UPDATE notes
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill lead_sources with organization_id
  UPDATE lead_sources
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill lead_statuses with organization_id
  UPDATE lead_statuses
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill message_templates with organization_id
  UPDATE message_templates
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill assignment_rules with organization_id
  UPDATE assignment_rules
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill bulk_download_history with organization_id
  UPDATE bulk_download_history
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill bulk_upload_jobs with organization_id
  UPDATE bulk_upload_jobs
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill time_tracking_sessions with organization_id
  UPDATE time_tracking_sessions
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill lead_activity_log with organization_id
  UPDATE lead_activity_log
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  -- Backfill filter_presets with organization_id
  UPDATE filter_presets
  SET organization_id = v_org_id
  WHERE organization_id IS NULL;
  
  RAISE NOTICE 'Backfilled all data tables with organization_id';
END $$;