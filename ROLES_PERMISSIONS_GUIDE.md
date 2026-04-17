# Role-Based Access Control System Guide

## Overview

The CRM system now includes a comprehensive role-based access control (RBAC) system with four hierarchical roles, granular permissions, and team-based organization.

## Role Hierarchy

1. **Super Admin** (Level 1) - Full system access
2. **Admin** (Level 2) - Full operational access
3. **Team Lead** (Level 3) - Team management access
4. **Sales Representative** (Level 4) - Limited to own leads

## Database Schema

### New Tables

- **roles**: Stores role definitions with hierarchy levels
- **permissions**: Stores all available permissions in the system
- **role_permissions**: Junction table mapping roles to permissions
- **teams**: Stores team definitions with optional team leads
- **audit_log**: Tracks all role, permission, and team changes

### Updated Tables

- **profiles**: Added `role_id`, `team_id`, `manager_id`, `is_active`, `last_login_at` columns

## Permission Structure

Permissions are organized by modules with specific actions:

### Leads Module
- `leads.view_own` - View own leads only
- `leads.view_team` - View team leads
- `leads.view_all` - View all leads
- `leads.create` - Create new leads
- `leads.edit_own` - Edit own leads
- `leads.edit_team` - Edit team leads
- `leads.edit_all` - Edit all leads
- `leads.delete` - Delete leads
- `leads.assign` - Assign leads to users
- `leads.export` - Export lead data

### Analytics Module
- `analytics.view_own` - View own analytics
- `analytics.view_team` - View team analytics
- `analytics.view_all` - View all analytics
- `analytics.export_reports` - Export analytics reports

### Bulk Actions Module
- `bulk_actions.upload` - Bulk upload leads
- `bulk_actions.download` - Bulk download data
- `bulk_actions.mass_update` - Mass update records
- `bulk_actions.delete` - Bulk delete records

### Settings Module
- `settings.manage_statuses` - Manage lead statuses
- `settings.manage_sources` - Manage lead sources
- `settings.manage_rules` - Manage assignment rules
- `settings.manage_templates` - Manage message templates
- `settings.view` - View settings

### Users Module
- `users.view` - View user list
- `users.create` - Create new users
- `users.edit` - Edit user details
- `users.delete` - Delete users
- `users.change_roles` - Change user roles
- `users.manage_teams` - Manage user teams

### Follow-ups Module
- `followups.view_own` - View own follow-ups
- `followups.view_team` - View team follow-ups
- `followups.view_all` - View all follow-ups
- `followups.create` - Create follow-ups
- `followups.edit` - Edit follow-ups
- `followups.delete` - Delete follow-ups

### Templates Module
- `templates.view` - View templates
- `templates.create` - Create templates
- `templates.edit` - Edit templates
- `templates.delete` - Delete templates
- `templates.approve` - Approve templates

### Teams Module
- `teams.view` - View teams
- `teams.create` - Create teams
- `teams.edit` - Edit teams
- `teams.delete` - Delete teams
- `teams.manage_members` - Manage team members

### Admin Module
- `admin.access_dashboard` - Access admin dashboard
- `admin.view_audit_log` - View audit log

## Default Role Permissions

### Super Admin
- Has ALL permissions in the system

### Admin
- Has ALL permissions (same as Super Admin for now)

### Team Lead
- Can view and edit team leads
- Can view team analytics
- Can manage team follow-ups
- Can view and create templates
- Can view teams
- Can view settings

### Sales Representative
- Can view and edit only own leads
- Can view own analytics
- Can create and manage own follow-ups
- Can view templates
- Can view settings

## Admin Dashboard

The Admin Dashboard is only visible to users with Admin or Super Admin roles. It includes three main tabs:

### 1. User Management
- View all users with filtering by role, team, and status
- Search users by name or email
- Create new users with email and password
- Edit user details (name, role, team)
- Activate/deactivate users
- Delete users
- View user statistics by role

### 2. Role & Permissions Matrix
- Interactive grid showing all roles and permissions
- Click checkboxes to grant/revoke permissions instantly
- "Select All" and "Clear All" buttons for bulk operations
- Visual permission count per role
- Changes are saved immediately

### 3. Team Management
- View all teams with member counts
- Create new teams with optional team lead
- Edit team details
- Delete teams
- Add/remove team members
- View available users (not assigned to any team)

## Permission Enforcement

### Frontend (UI Level)
- Sidebar menu items are hidden based on permissions
- Action buttons are conditionally rendered
- The `usePermissions` hook provides:
  - `hasPermission(key)` - Check single permission
  - `hasAnyPermission([keys])` - Check if user has any of the permissions
  - `hasAllPermissions([keys])` - Check if user has all permissions
  - `isAdmin` - Check if user is Admin or Super Admin
  - `isSuperAdmin` - Check if user is Super Admin
  - `isTeamLead` - Check if user is Team Lead
  - `hierarchyLevel` - Get user's hierarchy level (1-4)

### Backend (Database Level)
- Row Level Security (RLS) policies enforce data access
- Sales Reps can only see their own leads
- Team Leads can see their team's leads
- Admins can see all leads
- Helper functions:
  - `get_user_hierarchy_level(user_id)` - Get hierarchy level
  - `is_same_team(user_id, target_user_id)` - Check team membership
  - `user_has_permission(user_id, permission_key)` - Check permission

## Team-Based Access Control

### How Teams Work
- Users can be assigned to one team
- Each team can have one team lead
- Team leads must have Team Lead, Admin, or Super Admin role
- Team leads can view and manage their team members' leads
- Users without a team are shown in "Available Users"

### Lead Visibility
- **Sales Representative**: Only their own leads
- **Team Lead**: Their own leads + all team members' leads
- **Admin/Super Admin**: All leads in the system

## Audit Log

All administrative actions are logged:
- User creation, updates, and deletion
- Role changes
- Permission changes
- Team member additions/removals
- Team creation and deletion

Audit log entries include:
- Who performed the action
- When it was performed
- What changed (old and new values)
- Additional metadata

## Using the Permissions System

### In React Components

```typescript
import { usePermissions } from '../contexts/PermissionsContext';

function MyComponent() {
  const { hasPermission, isAdmin, userProfile } = usePermissions();

  // Check single permission
  if (hasPermission('leads.delete')) {
    // Show delete button
  }

  // Check multiple permissions
  if (hasAnyPermission(['leads.edit_own', 'leads.edit_team'])) {
    // Show edit button
  }

  // Check admin status
  if (isAdmin) {
    // Show admin features
  }

  // Access user's team
  const teamId = userProfile?.team_id;
}
```

### In Database Queries

The RLS policies automatically filter data based on the user's role and team. You don't need to add manual filters in most cases.

## Migration from Old System

Existing users have been automatically migrated:
- Users with `role = 'admin'` → Admin role
- Users with `role = 'sales_rep'` → Sales Representative role
- All users set to active by default
- Old `role` column is preserved for backward compatibility

## Next Steps

1. Assign roles to all users via the User Management interface
2. Organize users into teams via the Team Management interface
3. Customize role permissions if needed via the Role & Permissions Matrix
4. Review and adjust permissions as your organization grows
