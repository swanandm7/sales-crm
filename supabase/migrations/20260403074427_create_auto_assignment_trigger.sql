/*
  # Create Automated Lead Assignment Trigger

  1. Functions
    - `auto_assign_lead` - Main function to assign leads based on rules or fallback
    - Trigger function that fires on lead insert

  2. Purpose
    - Automatically assign leads when created (except bulk uploads)
    - Use assignment rules first, fallback to round-robin if no match
    - Log all assignments for audit trail
    - Update lead owner fields automatically

  3. Important Notes
    - Skips leads created via bulk upload (has assigned_to already set)
    - Uses most recent matching rule
    - Falls back to system-wide round-robin if no rules match
*/

-- Main function to auto-assign a lead
CREATE OR REPLACE FUNCTION auto_assign_lead()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_matched_rule_id uuid;
  v_assigned_counselor_id uuid;
  v_assignment_type text;
  v_source_name text;
BEGIN
  -- Skip if lead already has an assigned owner (bulk upload case)
  -- Bulk uploads pre-assign leads, so we don't override
  IF NEW.assigned_to IS NOT NULL THEN
    RETURN NEW;
  END IF;

  -- Get source name for matching
  SELECT name INTO v_source_name
  FROM lead_sources
  WHERE id = NEW.source_id;

  -- Try to match an assignment rule
  v_matched_rule_id := match_assignment_rule_for_lead(
    NEW.channel,
    v_source_name,
    NEW.specialization
  );

  -- If a rule matched, get next counselor from that rule's round-robin
  IF v_matched_rule_id IS NOT NULL THEN
    v_assigned_counselor_id := get_next_counselor_round_robin(v_matched_rule_id);
    v_assignment_type := 'rule_based';
  END IF;

  -- If no rule matched or rule has no counselors, use system fallback
  IF v_assigned_counselor_id IS NULL THEN
    v_assigned_counselor_id := get_next_system_counselor();
    v_assignment_type := 'fallback_round_robin';
    v_matched_rule_id := NULL;
  END IF;

  -- If we got a counselor, assign the lead
  IF v_assigned_counselor_id IS NOT NULL THEN
    NEW.assigned_to := v_assigned_counselor_id;
    NEW.current_lead_owner := v_assigned_counselor_id;
    
    -- Only set previous_lead_owner if it's null
    IF NEW.previous_lead_owner IS NULL THEN
      NEW.previous_lead_owner := v_assigned_counselor_id;
    END IF;

    -- Log the assignment in execution log (will be inserted after lead is created)
    -- We'll use a separate trigger for this to avoid issues with NEW.id
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger to auto-assign leads on insert
DROP TRIGGER IF EXISTS trigger_auto_assign_lead ON leads;
CREATE TRIGGER trigger_auto_assign_lead
  BEFORE INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_lead();

-- Function to log assignment after lead is created
CREATE OR REPLACE FUNCTION log_lead_assignment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_matched_rule_id uuid;
  v_assignment_type text;
  v_source_name text;
  v_user_full_name text;
BEGIN
  -- Only log if lead was auto-assigned (not manually created with assignment)
  IF NEW.assigned_to IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get source name
  SELECT name INTO v_source_name
  FROM lead_sources
  WHERE id = NEW.source_id;

  -- Determine which rule matched (if any)
  v_matched_rule_id := match_assignment_rule_for_lead(
    NEW.channel,
    v_source_name,
    NEW.specialization
  );

  IF v_matched_rule_id IS NOT NULL THEN
    v_assignment_type := 'rule_based';
  ELSE
    v_assignment_type := 'fallback_round_robin';
  END IF;

  -- Insert execution log
  INSERT INTO assignment_rule_execution_log (
    lead_id,
    rule_id,
    assigned_counselor_id,
    assignment_type,
    matched_at
  ) VALUES (
    NEW.id,
    v_matched_rule_id,
    NEW.assigned_to,
    v_assignment_type,
    now()
  );

  -- Get assigned user's name for activity log
  SELECT full_name INTO v_user_full_name
  FROM profiles
  WHERE id = NEW.assigned_to;

  -- Log activity
  INSERT INTO lead_activity_log (
    lead_id,
    user_id,
    activity_type,
    activity_description,
    field_name,
    new_value,
    metadata
  ) VALUES (
    NEW.id,
    NEW.assigned_to,
    'assignment_rule_applied',
    CASE 
      WHEN v_assignment_type = 'rule_based' THEN
        'Lead automatically assigned via assignment rule'
      ELSE
        'Lead automatically assigned via round-robin distribution'
    END,
    'assigned_to',
    v_user_full_name,
    jsonb_build_object(
      'rule_id', v_matched_rule_id,
      'assignment_type', v_assignment_type
    )
  );

  RETURN NEW;
END;
$$;

-- Trigger to log assignment after lead insert
DROP TRIGGER IF EXISTS trigger_log_lead_assignment ON leads;
CREATE TRIGGER trigger_log_lead_assignment
  AFTER INSERT ON leads
  FOR EACH ROW
  EXECUTE FUNCTION log_lead_assignment();
