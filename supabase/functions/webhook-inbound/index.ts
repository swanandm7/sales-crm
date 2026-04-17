import { createClient } from 'npm:@supabase/supabase-js@2.57.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey, X-Webhook-Signature, X-Webhook-Timestamp, X-API-Key',
};

interface WebhookConfig {
  id: string;
  organization_id: string;
  hmac_secret: string;
  is_enabled: boolean;
  allowed_ip_addresses: string[] | null;
  rate_limit_per_minute: number;
}

interface WebhookSource {
  id: string;
  field_mappings: Record<string, string>;
}

async function verifyHmacSignature(
  secret: string,
  timestamp: string,
  payload: string,
  signature: string
): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const data = encoder.encode(`${timestamp}.${payload}`);
  const signatureBuffer = await crypto.subtle.sign('HMAC', key, data);
  const computedSignature = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  return computedSignature === signature;
}

function validateTimestamp(timestamp: string, maxAgeSeconds = 300): boolean {
  const now = Math.floor(Date.now() / 1000);
  const requestTime = parseInt(timestamp, 10);

  if (isNaN(requestTime)) return false;

  const age = now - requestTime;
  return age >= 0 && age <= maxAgeSeconds;
}

function applyFieldMapping(
  sourceData: Record<string, unknown>,
  mappings: Record<string, string>
): Record<string, unknown> {
  const mapped: Record<string, unknown> = {};

  for (const [targetField, sourceField] of Object.entries(mappings)) {
    if (sourceField in sourceData) {
      mapped[targetField] = sourceData[sourceField];
    }
  }

  return mapped;
}

async function checkDuplicateLead(
  supabase: any,
  organizationId: string,
  email: string | null,
  mobileNumber: string | null
): Promise<string | null> {
  if (!email && !mobileNumber) return null;

  let query = supabase
    .from('leads')
    .select('id')
    .eq('organization_id', organizationId);

  if (email && mobileNumber) {
    query = query.or(`email.eq.${email},mobile_number.eq.${mobileNumber}`);
  } else if (email) {
    query = query.eq('email', email);
  } else if (mobileNumber) {
    query = query.eq('mobile_number', mobileNumber);
  }

  const { data } = await query.maybeSingle();
  return data?.id || null;
}

async function logWebhookRequest(
  supabase: any,
  organizationId: string | null,
  request: Request,
  requestBody: any,
  responseStatus: number,
  errorMessage: string | null,
  durationMs: number
) {
  const headers: Record<string, string> = {};
  request.headers.forEach((value, key) => {
    if (!key.toLowerCase().includes('secret') && !key.toLowerCase().includes('authorization')) {
      headers[key] = value;
    }
  });

  await supabase.from('webhook_request_log').insert({
    organization_id: organizationId,
    request_path: new URL(request.url).pathname,
    request_method: request.method,
    request_headers: headers,
    request_body: requestBody,
    response_status: responseStatus,
    error_message: errorMessage,
    ip_address: request.headers.get('cf-connecting-ip') || request.headers.get('x-forwarded-for'),
    user_agent: request.headers.get('user-agent'),
    duration_ms: durationMs,
  });
}

async function updateHealthMetrics(
  supabase: any,
  organizationId: string,
  metricType: string,
  durationMs: number
) {
  const hourBucket = new Date();
  hourBucket.setMinutes(0, 0, 0);

  await supabase.rpc('upsert_webhook_health_metric', {
    p_organization_id: organizationId,
    p_metric_type: metricType,
    p_endpoint_id: null,
    p_count: 1,
    p_duration_ms: durationMs,
    p_hour_bucket: hourBucket.toISOString(),
  });
}

Deno.serve(async (req: Request) => {
  const startTime = Date.now();

  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  let organizationId: string | null = null;
  let requestBody: any = null;

  try {
    if (req.method !== 'POST') {
      throw new Error('Method not allowed');
    }

    const apiKey = req.headers.get('X-API-Key');
    const signature = req.headers.get('X-Webhook-Signature');
    const timestamp = req.headers.get('X-Webhook-Timestamp');

    if (!apiKey) {
      throw new Error('Missing API key');
    }

    if (!signature || !timestamp) {
      throw new Error('Missing HMAC signature or timestamp');
    }

    const { data: webhookConfig, error: configError } = await supabase
      .from('webhook_configurations')
      .select('id, organization_id, hmac_secret, is_enabled, allowed_ip_addresses, rate_limit_per_minute')
      .eq('api_key', apiKey)
      .eq('is_enabled', true)
      .maybeSingle<WebhookConfig>();

    if (configError || !webhookConfig) {
      throw new Error('Invalid API key');
    }

    organizationId = webhookConfig.organization_id;

    if (!validateTimestamp(timestamp)) {
      throw new Error('Invalid or expired timestamp');
    }

    const rawBody = await req.text();
    requestBody = JSON.parse(rawBody);

    const isValidSignature = await verifyHmacSignature(
      webhookConfig.hmac_secret,
      timestamp,
      rawBody,
      signature
    );

    if (!isValidSignature) {
      throw new Error('Invalid HMAC signature');
    }

    if (webhookConfig.allowed_ip_addresses && webhookConfig.allowed_ip_addresses.length > 0) {
      const clientIp = req.headers.get('cf-connecting-ip') || req.headers.get('x-forwarded-for');
      if (!clientIp || !webhookConfig.allowed_ip_addresses.includes(clientIp)) {
        throw new Error('IP address not allowed');
      }
    }

    const sourceName = requestBody.source || 'default';
    const { data: webhookSource } = await supabase
      .from('webhook_sources')
      .select('id, field_mappings')
      .eq('organization_id', organizationId)
      .eq('source_name', sourceName)
      .eq('is_active', true)
      .maybeSingle<WebhookSource>();

    let leadData: Record<string, unknown> = requestBody.lead || requestBody;

    if (webhookSource?.field_mappings) {
      leadData = applyFieldMapping(leadData, webhookSource.field_mappings);
    }

    const email = leadData.email as string | null;
    const mobileNumber = leadData.mobile_number as string | null;

    const duplicateLeadId = await checkDuplicateLead(
      supabase,
      organizationId,
      email,
      mobileNumber
    );

    if (duplicateLeadId) {
      const durationMs = Date.now() - startTime;
      await logWebhookRequest(supabase, organizationId, req, requestBody, 200, null, durationMs);
      await updateHealthMetrics(supabase, organizationId, 'incoming_success', durationMs);

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Duplicate lead detected',
          lead_id: duplicateLeadId,
          action: 'skipped',
        }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    const { data: newLead, error: leadError } = await supabase
      .from('leads')
      .insert({
        organization_id: organizationId,
        name: leadData.name || `${leadData.first_name || ''} ${leadData.last_name || ''}`.trim(),
        first_name: leadData.first_name,
        last_name: leadData.last_name,
        email: leadData.email,
        mobile_number: leadData.mobile_number,
        company: leadData.company,
        lead_value: leadData.lead_value,
        channel: leadData.channel || sourceName,
        campaign_name: leadData.campaign_name,
        campaign_id: leadData.campaign_id,
        adgroup_id: leadData.adgroup_id,
        keyword: leadData.keyword,
        country: leadData.country,
        city: leadData.city,
        state: leadData.state,
        pincode: leadData.pincode,
        address_line1: leadData.address_line1,
        address_line2: leadData.address_line2,
        university: leadData.university,
        course: leadData.course,
        specialization: leadData.specialization,
        tags: leadData.tags as string[] | null,
      })
      .select()
      .single();

    if (leadError) {
      throw new Error(`Failed to create lead: ${leadError.message}`);
    }

    const durationMs = Date.now() - startTime;
    await logWebhookRequest(supabase, organizationId, req, requestBody, 201, null, durationMs);
    await updateHealthMetrics(supabase, organizationId, 'incoming_success', durationMs);

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Lead created successfully',
        lead_id: newLead.id,
        action: 'created',
      }),
      {
        status: 201,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  } catch (error: any) {
    const durationMs = Date.now() - startTime;
    const errorMessage = error.message || 'Unknown error';
    const status = error.message.includes('Method not allowed') ? 405 :
                   error.message.includes('Missing') || error.message.includes('Invalid') ? 401 : 500;

    await logWebhookRequest(supabase, organizationId, req, requestBody, status, errorMessage, durationMs);

    if (organizationId) {
      await updateHealthMetrics(supabase, organizationId, 'incoming_failed', durationMs);
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
      }),
      {
        status,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  }
});
