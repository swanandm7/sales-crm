# Webhook Integration Guide

## Overview

This CRM system provides a comprehensive webhook integration system that allows you to:
- Receive leads from external sources via incoming webhooks
- Push lead data to external systems via outgoing webhooks
- Integrate with Slack for real-time notifications
- Track webhook activity and monitor health

## Table of Contents

1. [Incoming Webhooks](#incoming-webhooks)
2. [Outgoing Webhooks](#outgoing-webhooks)
3. [Slack Integration](#slack-integration)
4. [Lead Source Configuration](#lead-source-configuration)
5. [Security](#security)
6. [Monitoring & Logs](#monitoring--logs)
7. [Troubleshooting](#troubleshooting)

---

## Incoming Webhooks

### Setup

1. Navigate to **Settings → Webhook Integrations → Incoming Webhooks**
2. Click **Add Configuration** to create a new webhook configuration
3. Provide a descriptive name (e.g., "Facebook Ads Webhook")
4. Set your desired rate limit (default: 60 requests/minute)
5. Save the configuration

After creation, you'll receive:
- **API Key**: Used to identify your organization
- **HMAC Secret**: Used to sign requests for security
- **Webhook URL**: The endpoint to send leads to

### Webhook Endpoint

```
POST {SUPABASE_URL}/functions/v1/webhook-inbound
```

### Required Headers

```
X-API-Key: your_api_key
X-Webhook-Signature: hmac_sha256_signature
X-Webhook-Timestamp: unix_timestamp
Content-Type: application/json
```

### Request Payload

```json
{
  "source": "Facebook Lead Ads",
  "lead": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "mobile_number": "+1234567890",
    "company": "Acme Corp",
    "course": "MBA",
    "specialization": "Marketing",
    "city": "New York",
    "state": "NY",
    "country": "USA",
    "campaign_name": "Fall 2024 Campaign",
    "campaign_id": "123456",
    "adgroup_id": "789012"
  }
}
```

### HMAC Signature Generation

The HMAC signature ensures request authenticity. Generate it as follows:

**JavaScript/Node.js:**
```javascript
const crypto = require('crypto');

function generateHmacSignature(secret, timestamp, payload) {
  const data = `${timestamp}.${JSON.stringify(payload)}`;
  return crypto
    .createHmac('sha256', secret)
    .update(data)
    .digest('hex');
}

// Usage
const timestamp = Math.floor(Date.now() / 1000).toString();
const payload = { source: "...", lead: {...} };
const signature = generateHmacSignature(hmacSecret, timestamp, payload);
```

**Python:**
```python
import hmac
import hashlib
import json
import time

def generate_hmac_signature(secret, timestamp, payload):
    data = f"{timestamp}.{json.dumps(payload)}"
    return hmac.new(
        secret.encode('utf-8'),
        data.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

# Usage
timestamp = str(int(time.time()))
payload = {"source": "...", "lead": {...}}
signature = generate_hmac_signature(hmac_secret, timestamp, payload)
```

**cURL Example:**
```bash
TIMESTAMP=$(date +%s)
PAYLOAD='{"source":"Website","lead":{"name":"John Doe","email":"john@example.com"}}'
SIGNATURE=$(echo -n "${TIMESTAMP}.${PAYLOAD}" | openssl dgst -sha256 -hmac "YOUR_HMAC_SECRET" | sed 's/^.* //')

curl -X POST https://your-project.supabase.co/functions/v1/webhook-inbound \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "X-Webhook-Signature: $SIGNATURE" \
  -H "X-Webhook-Timestamp: $TIMESTAMP" \
  -d "$PAYLOAD"
```

### Response Codes

- **201 Created**: Lead created successfully
- **200 OK**: Duplicate lead detected (skipped)
- **401 Unauthorized**: Invalid API key or HMAC signature
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server error

### Response Format

**Success (New Lead):**
```json
{
  "success": true,
  "message": "Lead created successfully",
  "lead_id": "uuid-here",
  "action": "created"
}
```

**Success (Duplicate):**
```json
{
  "success": true,
  "message": "Duplicate lead detected",
  "lead_id": "existing-uuid",
  "action": "skipped"
}
```

**Error:**
```json
{
  "success": false,
  "error": "Invalid HMAC signature"
}
```

---

## Outgoing Webhooks

### Setup

1. Navigate to **Settings → Webhook Integrations → Outgoing Integrations**
2. Click **Add Endpoint** to create a new integration
3. Configure:
   - **Endpoint Name**: Descriptive name
   - **Endpoint Type**: webhook, slack, or custom
   - **Endpoint URL**: Your webhook receiver URL
   - **Authentication**: Choose none, API key, HMAC, or Bearer token
   - **Event Subscriptions**: Select which events trigger webhooks

### Supported Events

- **lead.created**: Triggered when a new lead is created and assigned
- **lead.reassigned**: Triggered when a lead is reassigned to a different user

### Outbound Payload Format

**Lead Created Event:**
```json
{
  "event_type": "lead.created",
  "event_id": "unique-event-id",
  "timestamp": "2024-04-05T12:00:00Z",
  "organization_id": "org-uuid",
  "lead": {
    "id": "lead-uuid",
    "name": "John Doe",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "mobile_number": "+1234567890",
    "company": "Acme Corp",
    "course": "MBA",
    "specialization": "Marketing",
    "channel": "Facebook Ads",
    "campaign_name": "Fall 2024",
    "created_at": "2024-04-05T12:00:00Z"
  },
  "assignment": {
    "assigned_to_id": "user-uuid",
    "assigned_to_name": "Sarah Johnson",
    "assigned_to_email": "sarah@example.com",
    "assigned_at": "2024-04-05T12:00:00Z"
  }
}
```

### Outbound Headers

```
Content-Type: application/json
X-Webhook-Timestamp: unix_timestamp
X-Event-Type: lead.created
X-Organization-Id: org-uuid
X-Webhook-Signature: hmac_signature (if HMAC auth enabled)
X-API-Key: your_api_key (if API key auth enabled)
Authorization: Bearer token (if Bearer auth enabled)
```

### Retry Logic

Failed webhook deliveries are automatically retried with exponential backoff:
- **1st retry**: 5 minutes after failure
- **2nd retry**: 10 minutes after 1st retry
- **3rd retry**: 20 minutes after 2nd retry
- **After 3 failures**: Marked as permanently failed

---

## Slack Integration

### Setup

1. Create a Slack Incoming Webhook in your Slack workspace:
   - Go to Slack App Directory
   - Search for "Incoming Webhooks"
   - Add to your workspace and select a channel
   - Copy the webhook URL

2. In the CRM:
   - Navigate to **Settings → Webhook Integrations → Outgoing Integrations**
   - Click **Add Endpoint**
   - Set **Endpoint Type** to "Slack"
   - Paste your Slack webhook URL
   - Subscribe to desired events (lead.created, lead.reassigned)
   - Save

### Slack Message Format

New leads are sent to Slack with rich formatting including:
- Lead name and contact information
- Course and specialization details
- Marketing channel and campaign
- Assigned counselor information
- Lead ID and creation timestamp

---

## Lead Source Configuration

### Preset Templates

The system includes pre-configured templates for popular lead sources:
- Facebook Lead Ads
- Google Ads
- Website Contact Forms
- LinkedIn Lead Gen
- HubSpot
- Zoho CRM

### Field Mapping

Each source template defines how incoming fields map to your CRM schema:

```json
{
  "name": "full_name",
  "first_name": "first_name",
  "last_name": "last_name",
  "email": "email",
  "mobile_number": "phone_number",
  "company": "company_name"
}
```

**Left side**: Your CRM field name
**Right side**: Incoming webhook field name

### Creating Custom Sources

1. Navigate to **Settings → Webhook Integrations → Lead Sources**
2. Create a new source or edit existing
3. Define field mappings for your specific needs

---

## Security

### HMAC Signature Verification

All incoming webhooks **must** include a valid HMAC signature:
- Signature is computed over `timestamp.payload`
- Uses SHA-256 algorithm
- Prevents replay attacks (timestamps expire after 5 minutes)
- Constant-time comparison prevents timing attacks

### IP Whitelisting (Optional)

You can restrict webhook access to specific IP addresses:
1. Edit your webhook configuration
2. Add allowed IP addresses
3. Only requests from these IPs will be accepted

### API Key Rotation

To rotate your API keys:
1. Create a new webhook configuration
2. Update external systems to use new credentials
3. Delete old configuration after migration

### Rate Limiting

Each webhook configuration has a configurable rate limit (default 60 req/min) to prevent abuse.

---

## Monitoring & Logs

### Webhook Activity Logs

View all webhook activity in **Settings → Webhook Integrations → Webhook Logs**:
- Filter by incoming/outgoing/all
- Search by event type or error message
- View request/response payloads
- Track response times and status codes

### Health Metrics

Monitor webhook health with aggregated metrics:
- Success/failure rates
- Average response times
- Request volume over time
- Endpoint-specific performance

### Alerts

Configure alerts for:
- Failed webhook deliveries
- Rate limit violations
- Repeated authentication failures

---

## Troubleshooting

### Common Issues

**401 Unauthorized - Invalid API Key**
- Verify you're using the correct API key
- Check that the configuration is enabled
- Ensure API key matches your organization

**401 Unauthorized - Invalid HMAC Signature**
- Verify HMAC secret is correct
- Check signature generation algorithm
- Ensure timestamp is current (within 5 minutes)
- Verify payload is not modified after signing

**401 Unauthorized - Invalid or Expired Timestamp**
- Ensure system clocks are synchronized
- Timestamp must be within 5 minutes of current time
- Use Unix timestamp in seconds (not milliseconds)

**429 Too Many Requests**
- You've exceeded the rate limit
- Wait before sending more requests
- Consider increasing rate limit in configuration

**Duplicate Lead Detected**
- Lead with same email or phone already exists
- This is expected behavior to prevent duplicates
- Returns existing lead ID in response

**Lead Not Assigned to Counselor**
- Check assignment rules are configured
- Verify rules match the lead criteria
- Ensure counselors are available for assignment

**Outbound Webhook Not Firing**
- Verify endpoint is active
- Check event subscription is enabled
- Confirm lead was actually assigned (required for lead.created)
- Review webhook delivery queue for pending items

### Testing Webhooks

Use the built-in test functionality:
1. Navigate to webhook configuration
2. Click "Test Webhook"
3. Review response and logs

Or use tools like:
- [Webhook.site](https://webhook.site) - Inspect incoming webhooks
- [Postman](https://www.postman.com) - Test API calls
- [RequestBin](https://requestbin.com) - Debug webhook deliveries

### Support

For additional help:
- Check the webhook activity logs for detailed error messages
- Review the health metrics dashboard
- Contact your system administrator

---

## Best Practices

1. **Always verify HMAC signatures** on incoming webhooks
2. **Handle duplicate leads gracefully** in your integration
3. **Implement idempotency** in your webhook receivers
4. **Monitor webhook health** regularly
5. **Set appropriate rate limits** based on your traffic
6. **Use retry logic** for outbound webhooks
7. **Log all webhook activity** for troubleshooting
8. **Rotate credentials** periodically for security
9. **Test thoroughly** before going live
10. **Keep field mappings** up to date with your sources

---

## API Reference Quick Links

- Incoming Webhook Endpoint: `POST /functions/v1/webhook-inbound`
- Outbound Processor: `POST /functions/v1/webhook-outbound` (internal use)
- Database Tables: See schema in migrations

## Change Log

- **2024-04-05**: Initial webhook system implementation
  - HMAC-secured incoming webhooks
  - Outbound webhook delivery with retry logic
  - Slack integration
  - Lead source templates
  - Activity logging and monitoring
