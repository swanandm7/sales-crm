/*
  # Fix Bulk Refer to Always Log Activity

  ## Changes
  - Modified `bulk_assign_leads` RPC function to ALWAYS create an activity log entry
  - Activity log is created even when ownership doesn't change (e.g., referring to the same owner)
  - This ensures bulk refer operations always appear in the Bulk Refer tab
  
  ## Rationale
  - Users expect to see ALL bulk refer operations in the history
  - Even if leads are already assigned to the target user, the referral action itself is meaningful
  - This maintains consistency with other bulk operations (status change, uploads, etc.)
*/

CREATE OR REPLACE FUNCTION public.bulk_assign_leads(
  p_lead_ids uuid[],
  p_new_owner_id uuid,
  p_new_owner_name text,
  p_assigned_by_id uuid,
  p_assigned_by_name text DEFAULT 'Unknown User'
)
RETURNS json
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
    -- Only create ownership history records if ownership is actually changing
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

  -- ALWAYS create an activity log for bulk referral operations
  -- This ensures they appear in the Bulk Refer tab even when ownership doesn't change
  INSERT INTO lead_activity_log (
    lead_id,
    user_id,
    activity_type,
    activity_description,
    new_value,
    metadata
  ) VALUES (
    p_lead_ids[1],
    p_assigned_by_id,
    'ownership_transferred',
    p_assigned_by_name || ' referred ' || v_affected_count || 
    ' lead' || CASE WHEN v_affected_count > 1 THEN 's' ELSE '' END || 
    ' to ' || p_new_owner_name ||
    CASE 
      WHEN v_leads_with_ownership_change = 0 THEN ' (already assigned)'
      WHEN v_leads_with_ownership_change < v_affected_count THEN 
        ' (' || v_leads_with_ownership_change || ' ownership changed)'
      ELSE ''
    END,
    p_new_owner_name,
    json_build_object(
      'affected_count', v_affected_count,
      'lead_ids', p_lead_ids,
      'is_bulk_operation', true,
      'operation_type', 'bulk_assign',
      'new_owner_id', p_new_owner_id,
      'ownership_changes', v_leads_with_ownership_change
    )
  );

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