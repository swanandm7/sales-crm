CREATE OR REPLACE FUNCTION public.mobile_log_call_outcome(
  p_lead_id UUID,
  p_outcome TEXT,
  p_talk_time_secs INTEGER DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_next_followup TIMESTAMPTZ DEFAULT NULL,
  p_called_at TIMESTAMPTZ DEFAULT now(),
  p_status_id UUID DEFAULT NULL,
  p_sub_status_id UUID DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_lead public.leads%ROWTYPE;
  v_log public.call_logs%ROWTYPE;
  v_status_name text;
  v_sub_status_name text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_lead FROM public.leads WHERE id = p_lead_id LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lead not found';
  END IF;

  IF p_status_id IS NOT NULL THEN
    SELECT display_name INTO v_status_name FROM public.lead_statuses WHERE id = p_status_id;
  END IF;
  IF p_sub_status_id IS NOT NULL THEN
    SELECT display_name INTO v_sub_status_name FROM public.lead_statuses WHERE id = p_sub_status_id;
  END IF;

  INSERT INTO public.call_logs (
    lead_id, agent_id, called_at, outcome, talk_time_secs, notes, next_followup
  ) VALUES (
    p_lead_id, auth.uid(), COALESCE(p_called_at, now()), p_outcome, p_talk_time_secs, p_notes, p_next_followup
  ) RETURNING * INTO v_log;

  UPDATE public.leads
  SET 
    total_dials = COALESCE(total_dials, 0) + 1,
    connected_calls = COALESCE(connected_calls, 0) + CASE WHEN p_outcome = 'connected' THEN 1 ELSE 0 END,
    last_called_at = v_log.called_at,
    last_call_outcome = p_outcome,
    call_count = COALESCE(call_count, 0) + 1,
    status_id = COALESCE(p_status_id, status_id),
    sub_status_id = CASE WHEN p_status_id IS NOT NULL THEN p_sub_status_id ELSE COALESCE(p_sub_status_id, sub_status_id) END,
    updated_at = now()
  WHERE id = p_lead_id;
  
  IF p_next_followup IS NOT NULL THEN
     INSERT INTO public.followups (
       lead_id, user_id, organization_id, next_action_date, next_action_time, followup_remarks, status
     ) VALUES (
       p_lead_id, auth.uid(), v_lead.organization_id,
       (p_next_followup AT TIME ZONE 'UTC')::date,
       (p_next_followup AT TIME ZONE 'UTC')::time,
       COALESCE(NULLIF(trim(p_notes), ''), 'Callback requested via dialer'),
       'pending'
     );
  END IF;

  INSERT INTO public.lead_activity_log (
    lead_id, user_id, organization_id, activity_type, activity_description, metadata
  ) VALUES (
    p_lead_id, auth.uid(), v_lead.organization_id,
    'call_logged',
    'User logged a call: ' || p_outcome,
    jsonb_build_object('talk_time', p_talk_time_secs, 'notes', p_notes, 'source', 'native_dialer')
  );

  IF p_status_id IS NOT NULL THEN
    INSERT INTO public.lead_activity_log (
      lead_id, user_id, organization_id, activity_type, activity_description, new_value, metadata
    ) VALUES (
      p_lead_id, auth.uid(), v_lead.organization_id,
      'status_changed',
      'User updated status from mobile',
      COALESCE(v_status_name, 'Updated'),
      jsonb_build_object('sub_status', v_sub_status_name, 'source', 'native_dialer')
    );
  END IF;

  RETURN jsonb_build_object('success', true, 'log_id', v_log.id);
END;
$$;
