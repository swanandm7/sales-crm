# Assignment Rules Engine - User Guide

## Overview

The Assignment Rules Engine automatically distributes incoming leads to counselors based on configurable criteria. This eliminates manual assignment and ensures fair distribution through round-robin allocation.

## How It Works

### 1. Rule-Based Assignment

When a new lead is created (except via bulk upload), the system:

1. Evaluates all active assignment rules in order of **most recent first**
2. Checks if the lead matches the rule's criteria (Channel, Source, Specialization)
3. Assigns the lead to the next counselor in that rule's round-robin rotation
4. Logs the assignment for audit trail

### 2. Fallback Round-Robin

If no assignment rule matches the lead:

- The system assigns the lead using global round-robin across **all users**
- This ensures no lead goes unassigned
- Distribution remains fair across the entire team

### 3. Bulk Upload Exception

Leads imported via bulk upload:
- **Skip** the assignment rule engine entirely
- Use the counselor specified in the CSV file
- This prevents overriding intentional bulk assignments

## Creating Assignment Rules

### Rule Components

Each rule has three criteria that work together with AND logic:

1. **Channel Criteria**
   - Includes: Match specific channels (e.g., "Digital Marketing")
   - Any: Match all channels

2. **Source Criteria**
   - Includes: Match specific sources (e.g., "Google Ads", "Facebook Ads")
   - Any: Match all sources

3. **Specialization Criteria**
   - Includes: Match specific specializations (e.g., "MBA", "Engineering")
   - Any: Match all specializations

4. **Assigned Counselors**
   - Select one or more counselors
   - Multiple counselors = round-robin distribution among them
   - At least one counselor is required

### Example Rules

**Rule 1: Google Ads MBA Leads**
```
Channel: Includes "Digital Marketing"
Source: Includes "Google Ads"
Specialization: Includes "MBA"
Counselors: John Doe, Jane Smith
```
→ MBA leads from Google Ads rotate between John and Jane

**Rule 2: All Facebook Leads**
```
Channel: Any
Source: Includes "Facebook Ads"
Specialization: Any
Counselors: Sarah Johnson
```
→ All Facebook leads go to Sarah

## Rule Priority

- **Most recent rule** takes precedence
- If a lead matches multiple rules, the newest rule wins
- Use this to override older, more general rules with specific ones

## Round-Robin Distribution

### Per-Rule Round-Robin

Each rule maintains its own round-robin sequence:
- Counselors are cycled in order
- Fair distribution within each rule
- Independent from other rules

### Global Fallback Round-Robin

When no rules match:
- All active users are included
- Cycles through users by creation date
- Ensures team-wide load balancing

## Managing Rules

### Create a Rule

1. Navigate to Settings → Assignment Rules
2. Click "Add Rule"
3. Enter rule name
4. Configure criteria (Channel, Source, Specialization)
5. Select counselor(s)
6. Click "Add Rule"

### Edit a Rule

1. Click the edit icon on a rule
2. Modify criteria or counselors
3. Click "Save Changes"

### Disable/Enable a Rule

1. Click the three-dot menu on a rule
2. Select "Disable Rule" or "Enable Rule"
3. Disabled rules are skipped during matching

### Delete a Rule

1. Click the three-dot menu on a rule
2. Select "Delete Rule"
3. Confirm deletion
4. Note: Assignment history is preserved

## Monitoring & Analytics

Each rule displays:
- **Total Assignments**: Number of leads assigned via this rule
- **Last Assignment Date**: When the rule last assigned a lead
- **Status**: Active or Inactive

View assignment logs in the lead activity timeline:
- Shows which rule assigned the lead
- Displays assignment type (rule-based or fallback)
- Includes counselor details

## Best Practices

1. **Start Specific, Then General**
   - Create specific rules first (e.g., "Google Ads MBA")
   - Add broader rules later (e.g., "All Digital Marketing")
   - Newer specific rules will override older general ones

2. **Test with Sample Leads**
   - Create test leads to verify rule matching
   - Check the activity log to confirm correct assignment

3. **Balance Counselor Workload**
   - Use multiple counselors per rule for even distribution
   - Monitor total assignments per counselor

4. **Regular Review**
   - Review inactive rules periodically
   - Delete obsolete rules to keep the system clean

5. **Document Rule Purpose**
   - Use descriptive rule names
   - Include context (e.g., "Q1-2026-Google-Campaign")

## Troubleshooting

### Lead Not Assigned to Expected Counselor

- Check if a newer rule also matches the lead
- Verify the rule is active
- Ensure counselor is still active in the system

### No Assignment Happening

- Verify at least one rule exists or fallback users are available
- Check that lead was not created via bulk upload
- Review database trigger status

### Uneven Distribution

- Check if some counselors are in multiple overlapping rules
- Verify round-robin state is updating correctly
- Review assignment logs for patterns

## Technical Details

### Database Tables

- `assignment_rules`: Rule definitions
- `assignment_rule_criteria`: Channel/Source/Specialization criteria
- `assignment_rule_counselors`: Counselor assignments with round-robin tracking
- `assignment_rule_execution_log`: Complete audit trail
- `system_round_robin_state`: Global fallback state

### Functions

- `match_assignment_rule_for_lead()`: Find matching rule
- `get_next_counselor_round_robin()`: Per-rule distribution
- `get_next_system_counselor()`: Global fallback distribution
- `auto_assign_lead()`: Main trigger function

### Triggers

- Fires on `leads` table BEFORE INSERT
- Skips if `assigned_to` is already set (bulk uploads)
- Logs assignment in activity log automatically

## API Integration

External systems can create leads via API:

```javascript
const { data, error } = await supabase
  .from('leads')
  .insert({
    name: 'John Doe',
    mobile_number: '+1234567890',
    email: 'john@example.com',
    channel: 'Digital Marketing',
    source_id: '<source-uuid>',
    specialization: 'MBA'
    // Do NOT set assigned_to - let rules handle it
  });
```

The assignment engine will automatically:
1. Evaluate the lead against all rules
2. Assign to appropriate counselor
3. Log the assignment
4. Return the lead with `assigned_to` populated

## Support

For technical issues or questions:
1. Check the assignment_rule_execution_log table
2. Review lead_activity_log for assignment events
3. Verify rule configuration in Settings
