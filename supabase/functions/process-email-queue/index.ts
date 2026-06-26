import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const SENDER_EMAIL = 'Degreebaba <sde@degreebaba.com>';

serve(async (req) => {
  try {
    // Basic auth check if we set up a webhook secret
    const url = new URL(req.url);
    const webhookSecret = url.searchParams.get('secret');
    if (webhookSecret && webhookSecret !== Deno.env.get('WEBHOOK_SECRET')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }

    const payload = await req.json();
    
    // We only care about INSERTs on the email_queue table
    if (payload.type !== 'INSERT' || !payload.record) {
      return new Response(JSON.stringify({ message: 'Not an insert event' }), { status: 200 });
    }

    const record = payload.record;

    if (!RESEND_API_KEY) {
      console.error('RESEND_API_KEY is not set');
      return new Response(JSON.stringify({ error: 'Server misconfiguration' }), { status: 500 });
    }

    // Call Resend API
    const resendReq = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: SENDER_EMAIL,
        to: record.to_email,
        cc: record.cc_emails || undefined,
        bcc: record.bcc_emails || undefined,
        subject: record.subject,
        html: record.body_html,
        text: record.body_text || undefined,
      }),
    });

    const resendRes = await resendReq.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    if (resendReq.ok) {
      // Mark as sent
      await supabase
        .from('email_queue')
        .update({ 
          status: 'sent', 
          sent_at: new Date().toISOString(),
          error_message: null
        })
        .eq('id', record.id);
      
      return new Response(JSON.stringify({ success: true, id: resendRes.id }), { status: 200 });
    } else {
      // Mark as failed
      console.error('Resend API Error:', resendRes);
      await supabase
        .from('email_queue')
        .update({ 
          status: 'failed', 
          error_message: JSON.stringify(resendRes)
        })
        .eq('id', record.id);

      return new Response(JSON.stringify({ error: resendRes }), { status: 400 });
    }

  } catch (err: any) {
    console.error('Webhook error:', err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
