/*
  # Create CRUD Operations for Assignment Rules

  1. Functions
    - `create_assignment_rule` - Create a new rule with criteria and counselors
    - `update_assignment_rule` - Update existing rule
    - `delete_assignment_rule` - Delete a rule
    - `toggle_assignment_rule_status` - Activate/deactivate a rule
    - `get_assignment_rules_with_details` - Fetch rules with all related data

  2. Purpose
    - Provide transactional operations for managing assignment rules
    - Ensure data consistency across related tables
    - Support UI operations
*/

-- Function to create a new assignment rule
CREATE OR REPLACE FUNCTION create_assignment_rule(
  p_rule_name text,
  p_channel_condition_type text,
  p_channel_values text[],
  p_source_condition_type text,
  p_source_values text[],
  p_specialization_condition_type text,
  p_specialization_values text[],
  p_counselor_ids uuid[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rule_id uuid;
  v_counselor_id uuid;
  v_order_index integer;
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can create assignment rules';
  END IF;

  -- Insert the rule
  INSERT INTO assignment_rules (rule_name, is_active)
  VALUES (p_rule_name, true)
  RETURNING id INTO v_rule_id;

  -- Insert channel criteria
  INSERT INTO assignment_rule_criteria (
    rule_id, criteria_type, condition_type, criteria_values
  ) VALUES (
    v_rule_id, 'channel', p_channel_condition_type, p_channel_values
  );

  -- Insert source criteria
  INSERT INTO assignment_rule_criteria (
    rule_id, criteria_type, condition_type, criteria_values
  ) VALUES (
    v_rule_id, 'source', p_source_condition_type, p_source_values
  );

  -- Insert specialization criteria
  INSERT INTO assignment_rule_criteria (
    rule_id, criteria_type, condition_type, criteria_values
  ) VALUES (
    v_rule_id, 'specialization', p_specialization_condition_type, p_specialization_values
  );

  -- Insert counselors with order
  v_order_index := 0;
  FOREACH v_counselor_id IN ARRAY p_counselor_ids
  LOOP
    INSERT INTO assignment_rule_counselors (
      rule_id, counselor_id, assignment_order
    ) VALUES (
      v_rule_id, v_counselor_id, v_order_index
    );
    v_order_index := v_order_index + 1;
  END LOOP;

  RETURN v_rule_id;
END;
$$;

-- Function to update an existing assignment rule
CREATE OR REPLACE FUNCTION update_assignment_rule(
  p_rule_id uuid,
  p_rule_name text,
  p_channel_condition_type text,
  p_channel_values text[],
  p_source_condition_type text,
  p_source_values text[],
  p_specialization_condition_type text,
  p_specialization_values text[],
  p_counselor_ids uuid[]
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_counselor_id uuid;
  v_order_index integer;
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can update assignment rules';
  END IF;

  -- Update the rule
  UPDATE assignment_rules
  SET rule_name = p_rule_name,
      updated_at = now()
  WHERE id = p_rule_id;

  -- Delete and recreate criteria
  DELETE FROM assignment_rule_criteria WHERE rule_id = p_rule_id;

  INSERT INTO assignment_rule_criteria (
    rule_id, criteria_type, condition_type, criteria_values
  ) VALUES
    (p_rule_id, 'channel', p_channel_condition_type, p_channel_values),
    (p_rule_id, 'source', p_source_condition_type, p_source_values),
    (p_rule_id, 'specialization', p_specialization_condition_type, p_specialization_values);

  -- Delete and recreate counselors
  DELETE FROM assignment_rule_counselors WHERE rule_id = p_rule_id;

  v_order_index := 0;
  FOREACH v_counselor_id IN ARRAY p_counselor_ids
  LOOP
    INSERT INTO assignment_rule_counselors (
      rule_id, counselor_id, assignment_order
    ) VALUES (
      p_rule_id, v_counselor_id, v_order_index
    );
    v_order_index := v_order_index + 1;
  END LOOP;

  RETURN true;
END;
$$;

-- Function to delete an assignment rule
CREATE OR REPLACE FUNCTION delete_assignment_rule(p_rule_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can delete assignment rules';
  END IF;

  -- Delete the rule (cascade will handle related records)
  DELETE FROM assignment_rules WHERE id = p_rule_id;

  RETURN true;
END;
$$;

-- Function to toggle assignment rule status
CREATE OR REPLACE FUNCTION toggle_assignment_rule_status(
  p_rule_id uuid,
  p_is_active boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can change assignment rule status';
  END IF;

  UPDATE assignment_rules
  SET is_active = p_is_active,
      updated_at = now()
  WHERE id = p_rule_id;

  RETURN true;
END;
$$;

-- Create a view for easy fetching of assignment rules with details
CREATE OR REPLACE VIEW assignment_rules_detailed AS
SELECT 
  ar.id,
  ar.rule_name,
  ar.is_active,
  ar.created_at,
  ar.updated_at,
  
  -- Channel criteria
  (SELECT jsonb_build_object(
    'condition_type', condition_type,
    'values', criteria_values
  ) FROM assignment_rule_criteria 
   WHERE rule_id = ar.id AND criteria_type = 'channel'
   LIMIT 1) as channel_criteria,
  
  -- Source criteria
  (SELECT jsonb_build_object(
    'condition_type', condition_type,
    'values', criteria_values
  ) FROM assignment_rule_criteria 
   WHERE rule_id = ar.id AND criteria_type = 'source'
   LIMIT 1) as source_criteria,
  
  -- Specialization criteria
  (SELECT jsonb_build_object(
    'condition_type', condition_type,
    'values', criteria_values
  ) FROM assignment_rule_criteria 
   WHERE rule_id = ar.id AND criteria_type = 'specialization'
   LIMIT 1) as specialization_criteria,
  
  -- Counselors
  (SELECT jsonb_agg(
    jsonb_build_object(
      'id', p.id,
      'full_name', p.full_name,
      'email', p.email
    ) ORDER BY arc.assignment_order
  ) FROM assignment_rule_counselors arc
   JOIN profiles p ON p.id = arc.counselor_id
   WHERE arc.rule_id = ar.id) as counselors,
  
  -- Assignment stats
  (SELECT COUNT(*) 
   FROM assignment_rule_execution_log 
   WHERE rule_id = ar.id) as total_assignments,
  
  (SELECT MAX(matched_at)
   FROM assignment_rule_execution_log
   WHERE rule_id = ar.id) as last_assignment_date

FROM assignment_rules ar
ORDER BY ar.created_at DESC;

-- Grant access to the view
GRANT SELECT ON assignment_rules_detailed TO authenticated;
