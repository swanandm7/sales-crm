# Multi-Tenant CRM System Guide

This guide explains the complete multi-tenant organization management system implemented in the ExtraEdge CRM.

## Overview

The system supports multiple organizations (tenants) with complete data isolation, role-based access control, and flexible user management through invitations.

## Key Features

### 1. Organization Management (Super Admin)
- Create and manage multiple organizations
- Set organization tiers (Starter, Business, Enterprise)
- Configure user capacity limits per organization
- Activate/deactivate organizations
- Switch between organizations to manage data

### 2. User Invitation System (Regular Admin)
- Send email invitations to new users
- Assign roles and teams during invitation
- Track invitation status (pending, accepted, expired)
- Respect organization capacity limits
- Copy invitation links for sharing
- Resend or revoke invitations

### 3. Data Isolation
- All data (leads, follow-ups, teams, etc.) is scoped to organizations
- Users can only see data from their assigned organization
- Super Admins can switch organizations to manage different tenants

## User Roles

### Super Admin (Hierarchy Level 1)
**Access:**
- View and manage all organizations
- Switch between organizations
- Full access to all admin features
- Global user overview across organizations

**Admin Dashboard Tabs:**
- Organizations
- Global Users
- Role & Permissions
- Team Management

### Admin (Hierarchy Level 2)
**Access:**
- Manage users within their organization
- Send invitations (respecting capacity limits)
- Manage teams and roles
- Limited to their organization's data

**Admin Dashboard Tabs:**
- User Management
- Invitations
- Role & Permissions
- Team Management

### Team Lead (Hierarchy Level 3)
- Manage team members
- Access lead management features
- View team analytics

### Agent (Hierarchy Level 4)
- Basic CRM access
- Manage assigned leads
- Create follow-ups

## Accessing the Admin Dashboard

### For Super Admins:
1. Login with a Super Admin account
2. Click "Admin Dashboard" in the sidebar (Shield icon)
3. You'll see the "Super Admin Dashboard" with organization management
4. Use the Organization Switcher in the header to switch between tenants

### For Regular Admins:
1. Login with an Admin account
2. Click "Admin Dashboard" in the sidebar (Shield icon)
3. You'll see the "Admin Dashboard" with user and invitation management
4. Check capacity limits before sending invitations

## Organization Management

### Creating an Organization (Super Admin Only)

1. Navigate to Admin Dashboard
2. Click "Organizations" tab
3. Click "Create Organization" button
4. Fill in the form:
   - **Name**: Organization display name (e.g., "Acme Corporation")
   - **Slug**: URL-friendly identifier (auto-generated, e.g., "acme-corporation")
   - **Tier**: Select starter, business, or enterprise
   - **Max Users**: Leave empty for unlimited, or set a number (e.g., 10)
   - **Active**: Check to make organization active
5. Click "Create"

### Editing an Organization

1. Find the organization in the list
2. Click the three-dot menu
3. Select "Edit Organization"
4. Update fields as needed
5. Click "Update"

### Switching Organizations (Super Admin Only)

1. Look for the organization switcher in the header (next to the search bar)
2. Click the current organization name
3. Select a different organization from the dropdown
4. The page will reload with data from the new organization

## Invitation Management

### Sending an Invitation (Admin Only)

1. Navigate to Admin Dashboard
2. Click "Invitations" tab
3. Check the capacity banner at the top
4. If capacity allows, click "Invite User"
5. Fill in the invitation form:
   - **Email**: User's email address
   - **Role**: Select the user's role
   - **Team**: Optionally assign to a team
6. Click "Send Invitation"

### Managing Invitations

**Copy Invitation Link:**
- Click the copy icon next to a pending invitation
- Share the link with the invitee

**Resend Invitation:**
- Click the refresh icon to extend the expiration date
- Status changes back to "pending"

**Revoke Invitation:**
- Click the trash icon to delete an invitation
- Confirm the action

### Invitation Status

- **Pending**: Invitation sent, waiting for user to accept
- **Accepted**: User has accepted and created an account
- **Expired**: Invitation expired (7 days after creation)

## Database Structure

### Key Tables

**organizations**
- Stores organization details
- Fields: name, slug, tier, max_users, is_active

**organization_members**
- Junction table linking users to organizations
- Tracks membership status and roles
- Fields: user_id, organization_id, is_active

**organization_invitations**
- Tracks pending and accepted invitations
- Fields: email, role_id, team_id, status, expires_at

**profiles**
- User profiles with organization_id reference
- Filtered by organization in all queries

### Key Functions

**get_organization_capacity()**
- Returns current user count and capacity info
- Used to check if new invitations can be sent

**can_send_invitation()**
- Validates if an invitation can be sent
- Checks capacity limits and duplicate emails

**accept_invitation(invitation_id, user_id)**
- Processes invitation acceptance
- Creates organization membership
- Updates user's organization_id

## Row Level Security (RLS)

All data tables have RLS policies that:
1. Filter data by organization_id
2. Respect role hierarchy for access control
3. Allow Super Admins to see all data when needed
4. Prevent cross-organization data access

## Best Practices

### For Super Admins:
- Set appropriate user limits based on organization tier
- Regularly review organization status and usage
- Use organization switcher to manage different tenants
- Monitor capacity across organizations

### For Regular Admins:
- Check capacity before sending invitations
- Include role and team in invitations for better onboarding
- Revoke unused invitations to free up capacity
- Monitor invitation status regularly

### For All Users:
- Data is isolated by organization automatically
- Users cannot access data from other organizations
- Role hierarchy determines permissions within organization

## Troubleshooting

### "Cannot send invitation: user capacity limit reached"
- Your organization has reached its maximum user limit
- Contact Super Admin to increase capacity
- Deactivate inactive users to free up slots

### "An invitation for this email already exists"
- Check the Invitations tab for existing invitation
- Revoke the old invitation if needed
- Resend the existing invitation instead

### Organization switcher not visible
- Only Super Admins can see the organization switcher
- Check your role in the user menu
- Contact Super Admin if you need this access

### Cannot see Admin Dashboard
- Admin Dashboard requires Admin or Super Admin role
- Check with your organization administrator
- Verify your role in the user profile menu

## Security Notes

- All invitations expire after 7 days
- Organization data is completely isolated
- RLS policies enforce access control
- Super Admins can switch organizations but all actions are audited
- Invitation links are secure and single-use

## Future Enhancements

Potential improvements to consider:
- Email delivery for invitations (currently manual link sharing)
- Organization-specific branding
- Billing integration based on user count
- Organization usage analytics
- Bulk user import with organization assignment
- Custom role creation per organization
