-- Add Email Webhook Trigger

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Function to trigger the email queue edge function
CREATE OR REPLACE FUNCTION public.trigger_email_queue_webhook()
RETURNS trigger AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://hhbdhvuzjpegcglreukz.supabase.co/functions/v1/process-email-queue',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoYmRodnV6anBlZ2NnbHJldWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4ODY4MzQsImV4cCI6MjA5MDQ2MjgzNH0.MJQBW4bildOAq5vJ-8Jpho0MkMky84s-CHuqxsTNi0Q'
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', row_to_json(NEW)
    ),
    timeout_milliseconds := 5000
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to listen for new emails
DROP TRIGGER IF EXISTS on_email_queue_insert ON public.email_queue;
CREATE TRIGGER on_email_queue_insert
  AFTER INSERT ON public.email_queue
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_email_queue_webhook();
