/*
  # Create Round-Robin and Rule Matching Functions

  1. Functions
    - `get_next_counselor_round_robin` - Get next counselor for a specific rule
    - `get_next_system_counselor` - Get next counselor from global pool (fallback)
    - `match_assignment_rule_for_lead` - Find matching rule for a lead
    - `evaluate_criteria_match` - Helper function to evaluate criteria matching

  2. Purpose
    - Implement round-robin distribution per rule
    - Implement global fallback round-robin
    - Match leads to assignment rules based on criteria
*/

-- Function to get next counselor for a specific rule (per-rule round-robin)
CREATE OR REPLACE FUNCTION get_next_counselor_round_robin(p_rule_id uuid)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_counselor_id uuid;
  v_last_assigned_id uuid;
  v_counselor_count integer;
BEGIN
  -- Get count of counselors for this rule
  SELECT COUNT(*) INTO v_counselor_count
  FROM assignment_rule_counselors
  WHERE rule_id = p_rule_id
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = assignment_rule_counselors.counselor_id
    );

  -- If no counselors, return null
  IF v_counselor_count = 0 THEN
    RETURN NULL;
  END IF;

  -- Get the last assigned counselor for this rule
  SELECT counselor_id INTO v_last_assigned_id
  FROM assignment_rule_counselors
  WHERE rule_id = p_rule_id
    AND last_assigned_at IS NOT NULL
  ORDER BY last_assigned_at DESC
  LIMIT 1;

  -- If no one has been assigned yet, get the first counselor
  IF v_last_assigned_id IS NULL THEN
    SELECT counselor_id INTO v_counselor_id
    FROM assignment_rule_counselors
    WHERE rule_id = p_rule_id
      AND EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = assignment_rule_counselors.counselor_id
      )
    ORDER BY assignment_order ASC, created_at ASC
    LIMIT 1;
  ELSE
    -- Get the next counselor in order (circular)
    SELECT counselor_id INTO v_counselor_id
    FROM assignment_rule_counselors
    WHERE rule_id = p_rule_id
      AND assignment_order > (
        SELECT assignment_order
        FROM assignment_rule_counselors
        WHERE rule_id = p_rule_id AND counselor_id = v_last_assigned_id
      )
      AND EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = assignment_rule_counselors.counselor_id
      )
    ORDER BY assignment_order ASC
    LIMIT 1;

    -- If no next counselor (end of list), wrap around to first
    IF v_counselor_id IS NULL THEN
      SELECT counselor_id INTO v_counselor_id
      FROM assignment_rule_counselors
      WHERE rule_id = p_rule_id
        AND EXISTS (
          SELECT 1 FROM profiles
          WHERE profiles.id = assignment_rule_counselors.counselor_id
        )
      ORDER BY assignment_order ASC, created_at ASC
      LIMIT 1;
    END IF;
  END IF;

  -- Update last_assigned_at for the selected counselor
  IF v_counselor_id IS NOT NULL THEN
    UPDATE assignment_rule_counselors
    SET last_assigned_at = now()
    WHERE rule_id = p_rule_id AND counselor_id = v_counselor_id;
  END IF;

  RETURN v_counselor_id;
END;
$$;

-- Function to get next counselor from global system pool (fallback round-robin)
CREATE OR REPLACE FUNCTION get_next_system_counselor()
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_counselor_id uuid;
  v_last_assigned_id uuid;
  v_counselor_count integer;
BEGIN
  -- Get count of active counselors
  SELECT COUNT(*) INTO v_counselor_count
  FROM profiles
  WHERE id IN (SELECT id FROM auth.users);

  -- If no counselors, return null
  IF v_counselor_count = 0 THEN
    RETURN NULL;
  END IF;

  -- Get the last assigned counselor from system state
  SELECT last_assigned_counselor_id INTO v_last_assigned_id
  FROM system_round_robin_state
  LIMIT 1;

  -- If no one has been assigned yet, get the first counselor
  IF v_last_assigned_id IS NULL THEN
    SELECT id INTO v_counselor_id
    FROM profiles
    WHERE id IN (SELECT id FROM auth.users)
    ORDER BY created_at ASC
    LIMIT 1;
  ELSE
    -- Get the next counselor in order (circular by created_at)
    SELECT id INTO v_counselor_id
    FROM profiles
    WHERE id IN (SELECT id FROM auth.users)
      AND created_at > (
        SELECT created_at FROM profiles WHERE id = v_last_assigned_id
      )
    ORDER BY created_at ASC
    LIMIT 1;

    -- If no next counselor (end of list), wrap around to first
    IF v_counselor_id IS NULL THEN
      SELECT id INTO v_counselor_id
      FROM profiles
      WHERE id IN (SELECT id FROM auth.users)
      ORDER BY created_at ASC
      LIMIT 1;
    END IF;
  END IF;

  -- Update system round robin state
  IF v_counselor_id IS NOT NULL THEN
    UPDATE system_round_robin_state
    SET last_assigned_counselor_id = v_counselor_id,
        updated_at = now();
  END IF;

  RETURN v_counselor_id;
END;
$$;

-- Helper function to evaluate if a lead matches criteria
CREATE OR REPLACE FUNCTION evaluate_criteria_match(
  p_lead_value text,
  p_condition_type text,
  p_criteria_values text[]
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
  -- Handle 'any' condition - always matches
  IF p_condition_type = 'any' THEN
    RETURN true;
  END IF;

  -- Handle null lead values
  IF p_lead_value IS NULL THEN
    RETURN p_condition_type = 'excludes';
  END IF;

  -- Handle 'includes' condition
  IF p_condition_type = 'includes' THEN
    RETURN p_lead_value = ANY(p_criteria_values);
  END IF;

  -- Handle 'excludes' condition
  IF p_condition_type = 'excludes' THEN
    RETURN NOT (p_lead_value = ANY(p_criteria_values));
  END IF;

  RETURN false;
END;
$$;

-- Function to match assignment rule for a lead (most recent rule takes precedence)
CREATE OR REPLACE FUNCTION match_assignment_rule_for_lead(
  p_channel text,
  p_source text,
  p_specialization text
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_rule record;
  v_channel_match boolean;
  v_source_match boolean;
  v_specialization_match boolean;
  v_channel_criteria record;
  v_source_criteria record;
  v_specialization_criteria record;
BEGIN
  -- Loop through active rules ordered by most recent first
  FOR v_rule IN
    SELECT id, rule_name
    FROM assignment_rules
    WHERE is_active = true
    ORDER BY created_at DESC
  LOOP
    -- Get channel criteria for this rule
    SELECT condition_type, criteria_values INTO v_channel_criteria
    FROM assignment_rule_criteria
    WHERE rule_id = v_rule.id AND criteria_type = 'channel'
    LIMIT 1;

    -- Get source criteria for this rule
    SELECT condition_type, criteria_values INTO v_source_criteria
    FROM assignment_rule_criteria
    WHERE rule_id = v_rule.id AND criteria_type = 'source'
    LIMIT 1;

    -- Get specialization criteria for this rule
    SELECT condition_type, criteria_values INTO v_specialization_criteria
    FROM assignment_rule_criteria
    WHERE rule_id = v_rule.id AND criteria_type = 'specialization'
    LIMIT 1;

    -- Evaluate channel match (default to true if no criteria)
    IF v_channel_criteria IS NULL THEN
      v_channel_match := true;
    ELSE
      v_channel_match := evaluate_criteria_match(
        p_channel,
        v_channel_criteria.condition_type,
        v_channel_criteria.criteria_values
      );
    END IF;

    -- Evaluate source match (default to true if no criteria)
    IF v_source_criteria IS NULL THEN
      v_source_match := true;
    ELSE
      v_source_match := evaluate_criteria_match(
        p_source,
        v_source_criteria.condition_type,
        v_source_criteria.criteria_values
      );
    END IF;

    -- Evaluate specialization match (default to true if no criteria)
    IF v_specialization_criteria IS NULL THEN
      v_specialization_match := true;
    ELSE
      v_specialization_match := evaluate_criteria_match(
        p_specialization,
        v_specialization_criteria.condition_type,
        v_specialization_criteria.criteria_values
      );
    END IF;

    -- If all criteria match, return this rule
    IF v_channel_match AND v_source_match AND v_specialization_match THEN
      RETURN v_rule.id;
    END IF;
  END LOOP;

  -- No matching rule found
  RETURN NULL;
END;
$$;
