-- Fix: mobile_quick_update_lead should NOT increment call_count for manual_update dispositions
-- This prevents stats inflation when a rep updates status without making a call

CREATE OR REPLACE FUNCTION public.mobile_quick_update_lead(
  p_lead_id uuid,
  p_status_id uuid DEFAULT NULL,
  p_sub_status_id uuid DEFAULT NULL,
  p_note text DEFAULT NULL,
  p_next_followup_at timestamptz DEFAULT NULL,
  p_disposition text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_lead public.leads%ROWTYPE;
  v_user_name text;
  v_status_name text;
  v_sub_status_name text;
  v_followup_id uuid;
  -- Only increment call_count for real call dispositions, not manual edits
  v_is_real_call boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_lead_id IS NULL THEN
    RAISE EXCEPTION 'Lead is required';
  END IF;

  -- Determine if this is a real call outcome
  v_is_real_call := COALESCE(p_disposition, '') NOT IN ('manual_update', 'note_only', '');

  SELECT *
  INTO v_lead
  FROM public.leads
  WHERE id = p_lead_id
    AND (
      public.get_user_hierarchy_level(auth.uid()) <= 2
      OR current_lead_owner = auth.uid()
      OR assigned_to = auth.uid()
      OR public.is_same_team(auth.uid(), COALESCE(current_lead_owner, assigned_to))
    )
  LIMIT 1;

  IF v_lead.id IS NULL THEN
    RAISE EXCEPTION 'Lead not found or not accessible';
  END IF;

  SELECT full_name INTO v_user_name
  FROM public.profiles
  WHERE id = auth.uid();

  IF p_status_id IS NOT NULL THEN
    SELECT display_name INTO v_status_name
    FROM public.lead_statuses
    WHERE id = p_status_id;
  END IF;

  IF p_sub_status_id IS NOT NULL THEN
    SELECT display_name INTO v_sub_status_name
    FROM public.lead_statuses
    WHERE id = p_sub_status_id;
  END IF;

  UPDATE public.leads
  SET
    status_id = COALESCE(p_status_id, status_id),
    sub_status_id = CASE
      WHEN p_status_id IS NOT NULL THEN p_sub_status_id
      ELSE COALESCE(p_sub_status_id, sub_status_id)
    END,
    -- Only bump call_count when it's an actual call disposition (not manual status edits)
    call_count = COALESCE(call_count, 0) + CASE WHEN v_is_real_call THEN 1 ELSE 0 END,
    updated_at = now()
  WHERE id = p_lead_id;

  -- Log the call outcome in activity log (only for real calls)
  IF v_is_real_call AND COALESCE(trim(p_note), '') <> '' THEN
    INSERT INTO public.lead_activity_log (
      lead_id,
      user_id,
      organization_id,
      activity_type,
      activity_description,
      metadata
    ) VALUES (
      p_lead_id,
      auth.uid(),
      v_lead.organization_id,
      'call_logged',
      COALESCE(v_user_name, 'User') || ' logged a call: ' || COALESCE(p_disposition, 'outcome'),
      jsonb_build_object(
        'note', trim(p_note),
        'source', 'mobile_app',
        'disposition', p_disposition,
        'is_real_call', v_is_real_call
      )
    );
  ELSIF NOT v_is_real_call AND COALESCE(trim(p_note), '') <> '' THEN
    -- Manual update note
    INSERT INTO public.lead_activity_log (
      lead_id,
      user_id,
      organization_id,
      activity_type,
      activity_description,
      metadata
    ) VALUES (
      p_lead_id,
      auth.uid(),
      v_lead.organization_id,
      'comment_added',
      COALESCE(v_user_name, 'User') || ' added a note from mobile',
      jsonb_build_object(
        'note', trim(p_note),
        'source', 'mobile_app',
        'disposition', p_disposition
      )
    );
  END IF;

  IF p_status_id IS NOT NULL THEN
    INSERT INTO public.lead_activity_log (
      lead_id,
      user_id,
      organization_id,
      activity_type,
      activity_description,
      old_value,
      new_value,
      metadata
    ) VALUES (
      p_lead_id,
      auth.uid(),
      v_lead.organization_id,
      'status_changed',
      COALESCE(v_user_name, 'User') || ' updated status from mobile',
      NULL,
      COALESCE(v_status_name, 'Updated'),
      jsonb_build_object(
        'sub_status', v_sub_status_name,
        'disposition', p_disposition,
        'source', 'mobile_app',
        'is_real_call', v_is_real_call
      )
    );
  END IF;

  IF p_next_followup_at IS NOT NULL THEN
    INSERT INTO public.followups (
      lead_id,
      user_id,
      organization_id,
      next_action_date,
      next_action_time,
      followup_remarks,
      status
    ) VALUES (
      p_lead_id,
      auth.uid(),
      v_lead.organization_id,
      (p_next_followup_at AT TIME ZONE 'UTC')::date,
      ((p_next_followup_at AT TIME ZONE 'UTC')::time),
      COALESCE(NULLIF(trim(p_note), ''), COALESCE(p_disposition, 'Mobile follow-up')),
      'pending'
    )
    RETURNING id INTO v_followup_id;

    INSERT INTO public.lead_activity_log (
      lead_id,
      user_id,
      organization_id,
      activity_type,
      activity_description,
      metadata
    ) VALUES (
      p_lead_id,
      auth.uid(),
      v_lead.organization_id,
      'followup_created',
      COALESCE(v_user_name, 'User') || ' scheduled a mobile follow-up',
      jsonb_build_object(
        'followup_id', v_followup_id,
        'scheduled_at', p_next_followup_at,
        'source', 'mobile_app'
      )
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'lead_id', p_lead_id,
    'followup_id', v_followup_id,
    'status_id', COALESCE(p_status_id, v_lead.status_id),
    'sub_status_id', COALESCE(p_sub_status_id, v_lead.sub_status_id),
    'disposition', p_disposition,
    'call_counted', v_is_real_call,
    'queued_followup', p_next_followup_at IS NOT NULL
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.mobile_quick_update_lead(uuid, uuid, uuid, text, timestamptz, text) TO authenticated;
