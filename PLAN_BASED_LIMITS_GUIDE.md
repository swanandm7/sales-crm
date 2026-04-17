# Plan-Based User Limits Guide

## Overview

The CRM system now supports plan-based user limits, enabling SaaS monetization and controlled system usage.

## Organization Plans

Each organization has a `tier` and `max_users` setting that controls how many users can be added.

### Default Plan Tiers

| Plan | Max Users | Recommended For |
|------|-----------|-----------------|
| **Starter** | 5 | Small teams |
| **Growth** | 20 | Growing businesses |
| **Pro** | 100 | Large organizations |
| **Enterprise** | Unlimited (null) | Large enterprises |
| **Custom** | Configurable | Special requirements |

## Database Schema

### Organizations Table

```sql
-- Plan configuration fields
tier text DEFAULT 'starter'
max_users integer DEFAULT NULL
status organization_status DEFAULT 'active'
```

## Setting Plan Limits

### Update Organization Plan

```sql
UPDATE organizations
SET
  tier = 'pro',
  max_users = 100
WHERE id = 'org-uuid';
```

### Check Current Capacity

Use the `get_organization_capacity()` function:

```typescript
const { data } = await supabase.rpc('get_organization_capacity');

// Returns:
{
  current_users: 15,
  max_users: 20,
  can_invite: true,
  remaining_slots: 5
}
```

## User Interface

### Invitation Management

- Shows current capacity: "15 / 20 users"
- Displays remaining slots
- Blocks invite button when limit reached
- Shows upgrade message when at capacity

### Capacity Warnings

- **80% capacity**: Yellow warning banner
- **90% capacity**: Orange warning banner
- **100% capacity**: Red error banner with upgrade prompt

## Business Logic

### Invitation Blocking

When `current_users >= max_users`:
- Invite button is disabled
- Form submission is blocked
- Clear error message displayed
- Upgrade instructions shown

### Unlimited Plans

When `max_users IS NULL`:
- No capacity restrictions
- No warnings shown
- Unlimited invitations allowed

## Implementation Notes

### Counting Active Users

Active users are counted as:
```sql
SELECT COUNT(*) FROM organization_members
WHERE organization_id = 'org-uuid'
AND profile_id IN (
  SELECT id FROM profiles WHERE status != 'disabled'
)
```

### Enforcing Limits

Limits are enforced at:
1. **UI Level**: Disable invite button
2. **API Level**: Reject invitation creation
3. **Database Level**: Check constraint (optional)

## Upgrading Plans

### Admin Workflow

1. Admin receives capacity warning
2. Admin requests upgrade
3. Super Admin updates organization:
   - Change `tier` field
   - Increase `max_users` value
4. Users can now send invitations

### Automated Billing (Future)

```typescript
// Example integration with Stripe
async function upgradePlan(orgId: string, newPlan: string) {
  const planLimits = {
    starter: 5,
    growth: 20,
    pro: 100,
    enterprise: null,
  };

  await supabase
    .from('organizations')
    .update({
      tier: newPlan,
      max_users: planLimits[newPlan],
    })
    .eq('id', orgId);
}
```

## Best Practices

### 1. Regular Monitoring

- Track organization capacity usage
- Send proactive upgrade reminders
- Monitor disabled users (don't count toward limit)

### 2. Clear Communication

- Show current usage prominently
- Provide upgrade path early
- Explain benefits of higher tiers

### 3. Graceful Degradation

- Don't delete users when downgrading
- Mark as "over limit" but allow access
- Prompt for user removal or upgrade

## API Examples

### Check if Organization Can Invite

```typescript
async function canInviteUser(organizationId: string): Promise<boolean> {
  const { data } = await supabase.rpc('get_organization_capacity');
  return data?.can_invite || false;
}
```

### Get Plan Details

```typescript
async function getOrganizationPlan(orgId: string) {
  const { data } = await supabase
    .from('organizations')
    .select('tier, max_users, status')
    .eq('id', orgId)
    .single();

  return data;
}
```

### Enforce Limit on Backend

```typescript
// In invitation creation endpoint
const capacity = await supabase.rpc('get_organization_capacity');

if (!capacity.data?.can_invite) {
  throw new Error('Organization has reached user limit. Please upgrade your plan.');
}
```

## Troubleshooting

### Issue: Can't invite despite available slots

**Solution**: Check for disabled users not being excluded from count

### Issue: Unlimited plan showing limit

**Solution**: Ensure `max_users` is NULL, not 0

### Issue: Count mismatch

**Solution**: Verify organization_members and profiles are properly joined

## Related Features

- **Organization Status Control**: Suspend organizations for non-payment
- **Audit Logging**: Track all plan changes
- **Email Notifications**: Alert when approaching limits
- **User Management**: Disable instead of delete to preserve slots
