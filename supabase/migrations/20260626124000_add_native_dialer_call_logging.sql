-- Phase 1: Database & Backend Schema Additions

-- 1. Create call_logs table
CREATE TABLE public.call_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id         UUID NOT NULL REFERENCES public.leads(id),
  agent_id        UUID NOT NULL REFERENCES public.profiles(id),
  called_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  outcome         TEXT NOT NULL CHECK (outcome IN (
                    'connected',
                    'not_connected_busy',
                    'not_connected_no_answer',
                    'not_connected_switched_off',
                    'callback_requested',
                    'wrong_number'
                  )),
  talk_time_secs  INTEGER,
  notes           TEXT,
  next_followup   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- Index for fast per-lead and per-agent queries
CREATE INDEX idx_call_logs_lead_id  ON public.call_logs(lead_id);
CREATE INDEX idx_call_logs_agent_id ON public.call_logs(agent_id);
CREATE INDEX idx_call_logs_called_at ON public.call_logs(called_at);

-- Set RLS on call_logs
ALTER TABLE public.call_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view call_logs in their organization"
ON public.call_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.leads l
    WHERE l.id = call_logs.lead_id
    AND l.organization_id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
  )
);

CREATE POLICY "Users can insert their own call_logs"
ON public.call_logs FOR INSERT
TO authenticated
WITH CHECK (agent_id = auth.uid());


-- 2. Add counters to leads table
ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS total_dials INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS connected_calls INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_called_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_call_outcome TEXT;


-- 3. RPC to log call outcome and update leads atomically
CREATE OR REPLACE FUNCTION public.mobile_log_call_outcome(
  p_lead_id UUID,
  p_outcome TEXT,
  p_talk_time_secs INTEGER DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_next_followup TIMESTAMPTZ DEFAULT NULL,
  p_called_at TIMESTAMPTZ DEFAULT now()
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_lead public.leads%ROWTYPE;
  v_log public.call_logs%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Ensure lead belongs to user's org
  SELECT * INTO v_lead FROM public.leads WHERE id = p_lead_id LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lead not found';
  END IF;

  -- Insert call log
  INSERT INTO public.call_logs (
    lead_id, agent_id, called_at, outcome, talk_time_secs, notes, next_followup
  ) VALUES (
    p_lead_id, auth.uid(), COALESCE(p_called_at, now()), p_outcome, p_talk_time_secs, p_notes, p_next_followup
  ) RETURNING * INTO v_log;

  -- Update lead counters
  UPDATE public.leads
  SET 
    total_dials = COALESCE(total_dials, 0) + 1,
    connected_calls = COALESCE(connected_calls, 0) + CASE WHEN p_outcome = 'connected' THEN 1 ELSE 0 END,
    last_called_at = v_log.called_at,
    last_call_outcome = p_outcome,
    call_count = COALESCE(call_count, 0) + 1 -- maintain old counter just in case
  WHERE id = p_lead_id;
  
  -- Create follow-up if requested
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

  -- Activity Log
  INSERT INTO public.lead_activity_log (
    lead_id, user_id, organization_id, activity_type, activity_description, metadata
  ) VALUES (
    p_lead_id, auth.uid(), v_lead.organization_id,
    'call_logged',
    'User logged a call: ' || p_outcome,
    jsonb_build_object('talk_time', p_talk_time_secs, 'notes', p_notes, 'source', 'native_dialer')
  );

  RETURN jsonb_build_object('success', true, 'log_id', v_log.id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.mobile_log_call_outcome(UUID, TEXT, INTEGER, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;


-- 4. RPC to get agent call summary for manager dashboard
CREATE OR REPLACE FUNCTION public.get_agent_call_summary(
  p_organization_id UUID,
  p_agent_id UUID DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL,
  p_to_date TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE (
  agent_id UUID,
  agent_name TEXT,
  total_dials BIGINT,
  total_talk_time_secs BIGINT,
  unique_leads_dialed BIGINT,
  connected BIGINT,
  not_connected BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cl.agent_id,
    p.full_name AS agent_name,
    COUNT(*) AS total_dials,
    COALESCE(SUM(cl.talk_time_secs), 0) AS total_talk_time_secs,
    COUNT(DISTINCT cl.lead_id) AS unique_leads_dialed,
    SUM(CASE WHEN cl.outcome = 'connected' THEN 1 ELSE 0 END) AS connected,
    SUM(CASE WHEN cl.outcome LIKE 'not_connected%' THEN 1 ELSE 0 END) AS not_connected
  FROM public.call_logs cl
  JOIN public.profiles p ON cl.agent_id = p.id
  JOIN public.leads l ON cl.lead_id = l.id
  WHERE l.organization_id = p_organization_id
    AND (p_agent_id IS NULL OR cl.agent_id = p_agent_id)
    AND (p_from_date IS NULL OR cl.called_at >= p_from_date)
    AND (p_to_date IS NULL OR cl.called_at <= p_to_date)
  GROUP BY cl.agent_id, p.full_name
  ORDER BY total_dials DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_agent_call_summary(UUID, UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
