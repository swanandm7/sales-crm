export async function generateHmacSignature(
  secret: string,
  timestamp: string,
  payload: string
): Promise<string> {
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
  const signature = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  return signature;
}

export interface WebhookTestPayload {
  source?: string;
  lead: {
    name?: string;
    first_name?: string;
    last_name?: string;
    email?: string;
    mobile_number?: string;
    company?: string;
    course?: string;
    specialization?: string;
    city?: string;
    state?: string;
    country?: string;
    campaign_name?: string;
    campaign_id?: string;
    adgroup_id?: string;
    keyword?: string;
    [key: string]: any;
  };
}

export function generateTestLeadPayload(source: string = 'Test Source'): WebhookTestPayload {
  return {
    source,
    lead: {
      first_name: 'Test',
      last_name: 'User',
      name: 'Test User',
      email: `test.${Date.now()}@example.com`,
      mobile_number: `+1${Math.floor(Math.random() * 9000000000 + 1000000000)}`,
      company: 'Test Company',
      course: 'MBA',
      specialization: 'Marketing',
      city: 'New York',
      state: 'NY',
      country: 'USA',
      campaign_name: 'Test Campaign',
      campaign_id: 'test_campaign_123',
      adgroup_id: 'test_adgroup_456',
      keyword: 'test keyword',
    },
  };
}

export async function sendTestWebhook(
  webhookUrl: string,
  apiKey: string,
  hmacSecret: string,
  payload: WebhookTestPayload
): Promise<{ success: boolean; response: any; error?: string }> {
  try {
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const payloadString = JSON.stringify(payload);
    const signature = await generateHmacSignature(hmacSecret, timestamp, payloadString);

    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
        'X-Webhook-Signature': signature,
        'X-Webhook-Timestamp': timestamp,
      },
      body: payloadString,
    });

    const responseData = await response.json();

    return {
      success: response.ok,
      response: {
        status: response.status,
        statusText: response.statusText,
        data: responseData,
      },
    };
  } catch (error: any) {
    return {
      success: false,
      response: null,
      error: error.message || 'Unknown error occurred',
    };
  }
}

export const leadSourceExamples = {
  'Facebook Lead Ads': {
    source: 'Facebook Lead Ads',
    lead: {
      full_name: 'John Doe',
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@example.com',
      phone_number: '+1234567890',
      company_name: 'Acme Corporation',
      city: 'San Francisco',
      state: 'California',
      country: 'USA',
      course_of_interest: 'Data Science',
      specialization: 'Machine Learning',
      campaign_name: 'Fall 2024 Admissions',
      campaign_id: 'fb_123456',
      adset_id: 'fb_adset_789',
    },
  },
  'Google Ads': {
    source: 'Google Ads',
    lead: {
      Full_Name: 'Jane Smith',
      First_Name: 'Jane',
      Last_Name: 'Smith',
      Email: 'jane.smith@example.com',
      Phone_Number: '+1987654321',
      Company: 'Tech Innovations Inc',
      City: 'Austin',
      State: 'Texas',
      Country: 'USA',
      Course_Interest: 'MBA',
      Specialization: 'Finance',
      Campaign_Name: 'MBA Program 2024',
      Campaign_ID: 'gads_campaign_456',
      AdGroup_ID: 'gads_adgroup_123',
      Keyword: 'online mba programs',
    },
  },
  'Website Contact Form': {
    source: 'Website Contact Form',
    lead: {
      firstName: 'Michael',
      lastName: 'Johnson',
      name: 'Michael Johnson',
      email: 'michael.j@example.com',
      phone: '+1555123456',
      company: 'Global Enterprises',
      program: 'Executive MBA',
      specialization: 'Leadership',
      city: 'Chicago',
      state: 'Illinois',
      country: 'USA',
      address: '123 Main Street',
    },
  },
  'LinkedIn Lead Gen': {
    source: 'LinkedIn Lead Gen',
    lead: {
      FirstName: 'Sarah',
      LastName: 'Williams',
      Email: 'sarah.w@example.com',
      PhoneNumber: '+1444555666',
      Company: 'Professional Services Co',
      City: 'Boston',
      State: 'Massachusetts',
      Country: 'USA',
      CampaignName: 'Professional Development 2024',
    },
  },
};

export function getExamplePayloadForSource(sourceName: string): WebhookTestPayload | null {
  return leadSourceExamples[sourceName as keyof typeof leadSourceExamples] || null;
}

export function validateWebhookPayload(payload: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!payload.lead) {
    errors.push('Missing "lead" object in payload');
    return { valid: false, errors };
  }

  const lead = payload.lead;

  if (!lead.name && (!lead.first_name || !lead.last_name)) {
    errors.push('Lead must have either "name" or both "first_name" and "last_name"');
  }

  if (!lead.email && !lead.mobile_number) {
    errors.push('Lead must have at least one of "email" or "mobile_number"');
  }

  if (lead.email && !isValidEmail(lead.email)) {
    errors.push('Invalid email format');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function formatWebhookResponse(response: any): string {
  if (!response) return 'No response received';

  return `Status: ${response.status} ${response.statusText}\n\n${JSON.stringify(response.data, null, 2)}`;
}
