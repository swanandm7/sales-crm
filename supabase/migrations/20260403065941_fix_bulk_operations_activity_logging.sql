/*
  # Fix Bulk Operations Activity Logging

  ## Problem
  Current bulk operations (status change, assignment) create individual activity logs
  for each lead, causing:
  1. Performance issues with large batches
  2. Incorrect counts in bulk action history tabs
  3. Database bloat with redundant log entries

  ## Solution
  Modify RPC functions to create a SINGLE summary activity log entry per bulk operation
  instead of individual entries per lead. The summary includes:
  - Total count of affected leads
  - Metadata with lead IDs array
  - Clear description of bulk action performed

  ## Changes
  1. Updated `bulk_change_lead_status` to log single summary entry
  2. Updated `bulk_assign_leads` to log single summary entry
  3. Both functions now include `affected_count` in metadata
*/

-- Drop and recreate bulk_change_lead_status with improved logging
DROP FUNCTION IF EXISTS bulk_change_lead_status(UUID[], UUID, UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION bulk_change_lead_status(
  p_lead_ids UUID[],
  p_status_id UUID,
  p_sub_status_id UUID DEFAULT NULL,
  p_user_id UUID DEFAULT NULL,
  p_user_name TEXT DEFAULT 'Unknown User'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_affected_count INTEGER;
  v_new_status_name TEXT;
  v_new_substatus_name TEXT;
  v_status_changed_count INTEGER := 0;
  v_substatus_changed_count INTEGER := 0;
BEGIN
  -- Validate inputs
  IF p_lead_ids IS NULL OR array_length(p_lead_ids, 1) = 0 THEN
    RETURN json_build_object(
      'success', false,
      'error', 'No lead IDs provided',
      'affected_count', 0
    );
  END IF;

  IF p_status_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Status ID is required',
      'affected_count', 0
    );
  END IF;

  -- Get new status names for logging
  SELECT display_name INTO v_new_status_name
  FROM lead_statuses
  WHERE id = p_status_id;

  IF p_sub_status_id IS NOT NULL THEN
    SELECT display_name INTO v_new_substatus_name
    FROM lead_statuses
    WHERE id = p_sub_status_id;
  END IF;

  -- Count how many leads will actually have status changed
  SELECT COUNT(*) INTO v_status_changed_count
  FROM leads
  WHERE id = ANY(p_lead_ids)
    AND status_id IS DISTINCT FROM p_status_id;

  -- Count how many leads will actually have sub-status changed
  IF p_sub_status_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_substatus_changed_count
    FROM leads
    WHERE id = ANY(p_lead_ids)
      AND sub_status_id IS DISTINCT FROM p_sub_status_id;
  END IF;

  -- Bulk update all leads in a single operation
  UPDATE leads
  SET 
    status_id = p_status_id,
    sub_status_id = p_sub_status_id,
    updated_at = NOW()
  WHERE id = ANY(p_lead_ids);

  GET DIAGNOSTICS v_affected_count = ROW_COUNT;

  -- Create a SINGLE summary activity log for status change
  IF v_status_changed_count > 0 THEN
    INSERT INTO lead_activity_log (
      lead_id,
      user_id,
      activity_type,
      activity_description,
      new_value,
      metadata
    ) VALUES (
      p_lead_ids[1], -- Use first lead ID as reference
      p_user_id,
      'status_changed',
      p_user_name || ' changed status to ' || COALESCE(v_new_status_name, 'Unknown') || 
        ' for ' || v_status_changed_count || ' lead' || 
        CASE WHEN v_status_changed_count > 1 THEN 's' ELSE '' END,
      COALESCE(v_new_status_name, 'Unknown'),
      json_build_object(
        'affected_count', v_status_changed_count,
        'lead_ids', p_lead_ids,
        'is_bulk_operation', true,
        'operation_type', 'bulk_status_change'
      )
    );
  END IF;

  -- Create a SINGLE summary activity log for sub-status change
  IF v_substatus_changed_count > 0 THEN
    INSERT INTO lead_activity_log (
      lead_id,
      user_id,
      activity_type,
      activity_description,
      new_value,
      metadata
    ) VALUES (
      p_lead_ids[1], -- Use first lead ID as reference
      p_user_id,
      'sub_status_changed',
      p_user_name || ' changed sub-status to ' || COALESCE(v_new_substatus_name, 'None') || 
        ' for ' || v_substatus_changed_count || ' lead' || 
        CASE WHEN v_substatus_changed_count > 1 THEN 's' ELSE '' END,
      COALESCE(v_new_substatus_name, 'None'),
      json_build_object(
        'affected_count', v_substatus_changed_count,
        'lead_ids', p_lead_ids,
        'is_bulk_operation', true,
        'operation_type', 'bulk_substatus_change'
      )
    );
  END IF;

  -- Return success response
  RETURN json_build_object(
    'success', true,
    'affected_count', v_affected_count,
    'status_changed_count', v_status_changed_count,
    'substatus_changed_count', v_substatus_changed_count
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM,
      'affected_count', 0
    );
END;
$$;

-- Drop and recreate bulk_assign_leads with improved logging
DROP FUNCTION IF EXISTS bulk_assign_leads(UUID[], UUID, TEXT, UUID, TEXT);

CREATE OR REPLACE FUNCTION bulk_assign_leads(
  p_lead_ids UUID[],
  p_new_owner_id UUID,
  p_new_owner_name TEXT,
  p_assigned_by_id UUID,
  p_assigned_by_name TEXT DEFAULT 'Unknown User'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_affected_count INTEGER;
  v_ownership_history JSON[];
  v_lead RECORD;
  v_leads_with_ownership_change INTEGER := 0;
BEGIN
  -- Validate inputs
  IF p_lead_ids IS NULL OR array_length(p_lead_ids, 1) = 0 THEN
    RETURN json_build_object(
      'success', false,
      'error', 'No lead IDs provided',
      'affected_count', 0
    );
  END IF;

  IF p_new_owner_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'New owner ID is required',
      'affected_count', 0
    );
  END IF;

  -- Initialize array
  v_ownership_history := ARRAY[]::JSON[];

  -- Process each lead and prepare ownership history
  FOR v_lead IN
    SELECT 
      l.id,
      l.current_lead_owner AS old_owner_id,
      old_owner.full_name AS old_owner_name
    FROM leads l
    LEFT JOIN profiles old_owner ON l.current_lead_owner = old_owner.id
    WHERE l.id = ANY(p_lead_ids)
  LOOP
    -- Only create records if ownership is actually changing
    IF v_lead.old_owner_id IS DISTINCT FROM p_new_owner_id THEN
      v_leads_with_ownership_change := v_leads_with_ownership_change + 1;
      
      -- Prepare ownership history record
      v_ownership_history := array_append(
        v_ownership_history,
        json_build_object(
          'lead_id', v_lead.id,
          'from_owner_id', v_lead.old_owner_id,
          'to_owner_id', p_new_owner_id,
          'changed_by', p_assigned_by_id
        )
      );
    END IF;
  END LOOP;

  -- Bulk update all leads in a single operation
  UPDATE leads
  SET 
    current_lead_owner = p_new_owner_id,
    assigned_to = p_new_owner_id,
    updated_at = NOW()
  WHERE id = ANY(p_lead_ids);

  GET DIAGNOSTICS v_affected_count = ROW_COUNT;

  -- Bulk insert ownership history records if any exist
  IF array_length(v_ownership_history, 1) > 0 THEN
    INSERT INTO lead_ownership_history (
      lead_id,
      from_owner_id,
      to_owner_id,
      changed_by
    )
    SELECT 
      (record->>'lead_id')::UUID,
      (record->>'from_owner_id')::UUID,
      (record->>'to_owner_id')::UUID,
      (record->>'changed_by')::UUID
    FROM unnest(v_ownership_history) AS record;
  END IF;

  -- Create a SINGLE summary activity log for bulk assignment
  IF v_leads_with_ownership_change > 0 THEN
    INSERT INTO lead_activity_log (
      lead_id,
      user_id,
      activity_type,
      activity_description,
      new_value,
      metadata
    ) VALUES (
      p_lead_ids[1], -- Use first lead ID as reference
      p_assigned_by_id,
      'ownership_transferred',
      p_assigned_by_name || ' assigned ' || v_leads_with_ownership_change || 
        ' lead' || CASE WHEN v_leads_with_ownership_change > 1 THEN 's' ELSE '' END || 
        ' to ' || p_new_owner_name,
      p_new_owner_name,
      json_build_object(
        'affected_count', v_leads_with_ownership_change,
        'lead_ids', p_lead_ids,
        'is_bulk_operation', true,
        'operation_type', 'bulk_assign',
        'new_owner_id', p_new_owner_id
      )
    );
  END IF;

  -- Return success response
  RETURN json_build_object(
    'success', true,
    'affected_count', v_affected_count,
    'ownership_records_created', array_length(v_ownership_history, 1),
    'leads_with_ownership_change', v_leads_with_ownership_change
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM,
      'affected_count', 0
    );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION bulk_change_lead_status TO authenticated;
GRANT EXECUTE ON FUNCTION bulk_assign_leads TO authenticated;