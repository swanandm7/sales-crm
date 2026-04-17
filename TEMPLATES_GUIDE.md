# Message Templates System Guide

## Overview

The Message Templates system allows admins to create reusable email and WhatsApp message templates with dynamic variables. Templates require admin approval before users can access them, ensuring consistent and professional communication.

## Key Features

- **Template Creation**: Create email and WhatsApp templates with dynamic variables
- **Admin Approval Workflow**: Templates must be approved before users can access them
- **Variable Substitution**: Automatically replace placeholders with actual lead and counselor data
- **User Assignment**: Control which users can see and use specific templates
- **Usage Tracking**: Track when and how templates are used, including edit detection
- **Template Preview**: Preview templates with sample data before saving

## Available Variables

The following variables can be used in templates and will be automatically replaced with actual data:

### Counselor Variables
- `{{counselor_name}}` - Full name of the counselor
- `{{counselor_first_name}}` - First name of the counselor
- `{{counselor_last_name}}` - Last name of the counselor
- `{{counselor_mobile}}` - Counselor's mobile number
- `{{counselor_email}}` - Counselor's email address

### Lead Variables
- `{{lead_name}}` - Full name of the lead
- `{{lead_first_name}}` - First name of the lead
- `{{lead_mobile}}` - Lead's mobile number
- `{{lead_email}}` - Lead's email address
- `{{university}}` - University the lead is interested in
- `{{course}}` - Course the lead is interested in

## How to Create a Template (Admin Only)

1. Navigate to **Settings > Email Templates** or **WhatsApp Templates**
2. Click **Create Template** button
3. Fill in the template details:
   - **Template Name**: A unique, descriptive name
   - **Template Type**: Email or WhatsApp (cannot be changed after creation)
   - **Subject**: (Email only) Email subject line with optional variables
   - **Message Content**: Template body with variables
   - **Assign to Users**: Select which users can access this template
4. Use the variable picker on the right to insert dynamic fields
5. Preview the template with sample data
6. Choose save option:
   - **Save as Draft**: Save without submitting for approval
   - **Submit for Approval**: Submit to admin for approval
   - **Save and Approve**: (Admin only) Immediately approve the template

## Admin Approval Workflow

### For Template Creators
1. Create template and submit for approval
2. Wait for admin approval
3. Once approved, template becomes available to assigned users

### For Admins
1. Navigate to Email/WhatsApp Templates tab
2. Filter by "Pending Approval" to see templates awaiting review
3. Click the three-dot menu on a pending template
4. Choose **Approve** or **Reject**
5. Approved templates immediately become available to assigned users

## Using Templates in Lead Communications

### Email Templates
1. Open a lead card and click the **Email** icon
2. In the email modal, find the "Use Template" dropdown at the top
3. Select a template from the list
4. The subject and message fields will auto-populate with personalized content
5. Edit the content if needed (edits are tracked)
6. Click **Log Email** to send

### WhatsApp Templates
1. Open a lead card and click the **WhatsApp** icon
2. In the WhatsApp modal, find the "Use Template" dropdown at the top
3. Select a template from the list
4. The message field will auto-populate with personalized content
5. Edit the content if needed (edits are tracked)
6. Click **Log WhatsApp** to send

## Template Management

### Edit Template
- Only admins can edit templates
- Click the three-dot menu and select **Edit**
- Make changes and save
- If template was approved, it remains approved

### Duplicate Template
- Click the three-dot menu and select **Duplicate**
- Creates a copy with "(Copy)" suffix
- New template requires approval

### Activate/Deactivate
- Admins can toggle template status
- Inactive templates are hidden from users but data is preserved
- Can be reactivated at any time

### Delete Template
- Only admins can delete templates
- Deletion is permanent but usage logs are preserved
- Confirmation required

## Usage Tracking

The system automatically logs:
- Which template was used
- For which lead
- By which user
- When it was used
- Whether the template was edited before sending
- The original template content vs. actual content sent

This data helps identify:
- Most popular templates
- Templates that frequently need editing (may need improvement)
- Template usage patterns

## Best Practices

### Creating Effective Templates

1. **Use Clear Names**: Make template names descriptive (e.g., "Welcome Email - New Students" instead of "Template 1")

2. **Leverage Variables**: Use variables to personalize messages and save time

3. **Keep It Concise**: Especially for WhatsApp (recommended under 1000 characters)

4. **Test Before Approving**: Always preview templates with sample data before approval

5. **Regular Reviews**: Periodically review template usage and update underperforming templates

### Variable Usage Tips

- Always use the variable picker to insert variables (prevents typos)
- Preview templates to ensure variables display correctly
- Handle optional fields gracefully (e.g., "Hello {{lead_first_name}}" works even if first name is empty)

### Template Organization

- Create templates for common scenarios (welcome, follow-up, reminder, etc.)
- Assign templates to appropriate user groups
- Keep inactive templates for reference or seasonal use

## Database Schema

### Tables Created

1. **message_templates**: Stores template data
   - template_name, template_type, subject, body_content
   - is_approved, is_active, is_draft
   - created_by, approved_by, timestamps

2. **message_template_users**: Controls template visibility
   - template_id, user_id (junction table)

3. **message_template_usage_log**: Tracks template usage
   - template_id, lead_id, user_id
   - template_content_used, actual_content_sent, was_edited
   - used_at timestamp

## Security

- Row Level Security (RLS) is enabled on all template tables
- Admins have full access to all templates
- Regular users can only view approved templates assigned to them
- All users can log their own template usage
- Template content is validated before saving

## Troubleshooting

### Template Not Appearing in Dropdown
- Verify template is approved (not draft or pending)
- Verify template is active
- Verify you're assigned to the template
- Check correct template type (email vs. WhatsApp)

### Variables Not Replacing
- Ensure variable syntax is correct: `{{variable_name}}`
- Check that lead has data for the variable
- Variables are case-sensitive

### Can't Edit Template
- Only admins can edit templates
- Contact your admin to request changes

### Template Deleted Accidentally
- Contact system administrator
- Usage logs are preserved but template cannot be recovered
- Create new template from scratch

## Support

For additional help with the templates system, contact your system administrator.
