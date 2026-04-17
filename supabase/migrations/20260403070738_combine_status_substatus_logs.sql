/*
  # Combine Status and Sub-Status Changes into Single Log Entry

  ## Problem
  When bulk changing both status and sub-status, the system creates two separate
  activity log entries, causing duplicate rows in the history table.

  ## Solution
  Modify the RPC function to create a single combined log entry when both
  status and sub-status are changed together.

  ## Changes
  - Updated `bulk_change_lead_status` to combine status/sub-status into one log
  - Description shows both changes in a single entry
  - Only creates one activity log record per bulk operation
*/

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
  v_description TEXT;
  v_new_value TEXT;
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

  -- Create a SINGLE combined activity log entry
  IF v_status_changed_count > 0 OR v_substatus_changed_count > 0 THEN
    -- Build description based on what changed
    IF v_status_changed_count > 0 AND v_substatus_changed_count > 0 THEN
      -- Both changed
      v_description := p_user_name || ' changed status to ' || 
        COALESCE(v_new_status_name, 'Unknown') || 
        ' and sub-status to ' || COALESCE(v_new_substatus_name, 'None') ||
        ' for ' || GREATEST(v_status_changed_count, v_substatus_changed_count) || 
        ' lead' || CASE WHEN GREATEST(v_status_changed_count, v_substatus_changed_count) > 1 THEN 's' ELSE '' END;
      v_new_value := COALESCE(v_new_status_name, 'Unknown') || ' → ' || COALESCE(v_new_substatus_name, 'None');
    ELSIF v_status_changed_count > 0 THEN
      -- Only status changed
      v_description := p_user_name || ' changed status to ' || 
        COALESCE(v_new_status_name, 'Unknown') || 
        ' for ' || v_status_changed_count || 
        ' lead' || CASE WHEN v_status_changed_count > 1 THEN 's' ELSE '' END;
      v_new_value := COALESCE(v_new_status_name, 'Unknown');
    ELSE
      -- Only sub-status changed
      v_description := p_user_name || ' changed sub-status to ' || 
        COALESCE(v_new_substatus_name, 'None') || 
        ' for ' || v_substatus_changed_count || 
        ' lead' || CASE WHEN v_substatus_changed_count > 1 THEN 's' ELSE '' END;
      v_new_value := COALESCE(v_new_substatus_name, 'None');
    END IF;

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
      v_description,
      v_new_value,
      json_build_object(
        'affected_count', v_affected_count,
        'lead_ids', p_lead_ids,
        'is_bulk_operation', true,
        'operation_type', 'bulk_status_change',
        'status_changed_count', v_status_changed_count,
        'substatus_changed_count', v_substatus_changed_count,
        'new_status', v_new_status_name,
        'new_substatus', v_new_substatus_name
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION bulk_change_lead_status TO authenticated;