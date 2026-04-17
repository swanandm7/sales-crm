# Enterprise CRM Platform

A comprehensive, multi-tenant CRM platform built with React, TypeScript, Vite, and Supabase. Features include lead management, role-based permissions, team collaboration, automated assignment rules, webhook integrations, and communication tracking.

## Features

### Core Functionality
- **Lead Management**: Complete lead lifecycle tracking with customizable statuses and sub-statuses
- **Multi-Tenant Support**: Organization-based data isolation with member management
- **Role-Based Access Control**: Hierarchical permissions system (Super Admin, Admin, Team Lead, Sales Rep)
- **Team Collaboration**: Team-based workflows with manager hierarchies
- **Follow-up Management**: Scheduled reminders with browser notifications
- **Activity Tracking**: Comprehensive audit logs for all lead interactions

### Advanced Features
- **Automated Assignment Rules**: Round-robin and criteria-based lead distribution
- **Bulk Operations**: Mass upload, status changes, and lead assignments
- **Message Templates**: Reusable email, WhatsApp, and call script templates
- **Webhook Integrations**: Inbound/outbound webhook support for external systems
- **Communication Tracking**: Email, WhatsApp, and call interaction logging
- **Analytics Dashboard**: Real-time metrics and performance insights
- **Filter Presets**: Save and reuse complex filter combinations
- **Time Tracking**: Session-based activity monitoring

## Tech Stack

- **Frontend**: React 18, TypeScript, Vite
- **Styling**: Tailwind CSS
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Icons**: Lucide React
- **CSV Processing**: PapaParse

## Prerequisites

- Node.js 18+ and npm
- Supabase account and project
- Modern web browser with notification support

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**

   Create a `.env` file in the root directory:
   ```bash
   cp .env.example .env
   ```

   Update the `.env` file with your Supabase credentials:
   ```
   VITE_SUPABASE_URL=your_supabase_project_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Database Setup**

   All migrations are located in `supabase/migrations/`. Apply them in order:
   ```bash
   # Ensure you have Supabase CLI installed
   npm install -g supabase

   # Link to your project
   supabase link --project-ref your-project-ref

   # Apply migrations
   supabase db push
   ```

5. **Run Development Server**
   ```bash
   npm run dev
   ```

   The application will be available at `http://localhost:5173`

## Building for Production

```bash
npm run build
```

The production-ready files will be in the `dist/` directory.

### Production Deployment

1. **Build the application**
   ```bash
   npm run build
   ```

2. **Deploy to your hosting provider**

   The platform can be deployed to:
   - Vercel
   - Netlify
   - AWS Amplify
   - Cloudflare Pages
   - Any static hosting service

3. **Environment Variables**

   Ensure your production environment has these variables configured:
   ```
   VITE_SUPABASE_URL=your_production_supabase_url
   VITE_SUPABASE_ANON_KEY=your_production_anon_key
   ```

4. **Supabase Edge Functions**

   Deploy the webhook edge functions:
   ```bash
   supabase functions deploy webhook-inbound
   supabase functions deploy webhook-outbound
   ```

## First-Time Setup

### Creating the First Super Admin

1. Sign up through the login page
2. The first user is automatically assigned Super Admin role
3. Complete the first-time setup form with your details
4. You can now create organizations, invite users, and configure the system

### Organization Setup

1. Navigate to Admin Dashboard > Organization Management
2. Create your organization
3. Invite team members via email
4. Assign roles and teams to users
5. Configure assignment rules and templates

## User Roles & Permissions

- **Super Admin**: Full system access, multi-organization management
- **Admin**: Organization-level administration, user management
- **Team Lead**: Team management, lead oversight, reporting
- **Sales Rep**: Lead management, follow-ups, communication

## Key Modules

### Lead Management
- Create, edit, and track leads through customizable pipelines
- Bulk import/export via CSV
- Advanced filtering and search
- Activity timeline for each lead

### Follow-ups
- Schedule follow-up tasks with reminders
- Browser notifications for upcoming/overdue tasks
- Filter by status, priority, and assigned user
- Bulk reschedule and completion

### Templates
- Email, WhatsApp, and call script templates
- Variable substitution ({{lead_name}}, {{company}}, etc.)
- Approval workflow for pending templates
- Usage tracking

### Webhooks
- Inbound webhooks for lead creation from external sources
- Outbound webhooks for real-time event notifications
- Health monitoring and retry logic
- Template-based payload transformation

### Analytics
- Lead conversion metrics
- Team performance tracking
- Activity heatmaps
- Communication metrics

## Configuration Files

- `vite.config.ts` - Vite configuration
- `tailwind.config.js` - Tailwind CSS settings
- `tsconfig.json` - TypeScript configuration
- `.env` - Environment variables (never commit this file)

## Browser Notifications

To enable follow-up reminders:

1. Click "Allow" when prompted for notification permissions
2. Or manually enable in browser settings for your domain
3. Notifications check runs every 5 minutes while app is open

## CSV Import Format

See template files:
- `src/lib/csvTemplates.ts` for format definitions
- Download templates from Bulk Actions module
- Supports leads, contacts, and custom field imports

## Security Features

- Row Level Security (RLS) on all database tables
- Organization-based data isolation
- Role-based permissions enforcement
- Soft deletes for user accounts
- Audit logging for sensitive operations
- Secure webhook signatures (planned)

## Troubleshooting

### Common Issues

**Login not working**
- Verify Supabase URL and anon key in `.env`
- Check browser console for errors
- Ensure email confirmation is disabled in Supabase Auth settings

**Permissions not loading**
- Hard refresh the browser (Ctrl+Shift+R)
- Check that user has assigned role in database
- Verify role_permissions table is populated

**Bulk upload failing**
- Check CSV format matches template
- Ensure required fields are present
- Look for validation errors in preview

**Webhooks not triggering**
- Verify edge functions are deployed
- Check webhook logs in settings
- Ensure endpoint URLs are accessible

## Development

### Project Structure
```
src/
├── components/       # React components
│   ├── admin/       # Admin panel components
│   ├── auth/        # Authentication components
│   ├── leads/       # Lead management components
│   ├── settings/    # Settings and configuration
│   └── common/      # Reusable UI components
├── contexts/        # React contexts (Auth, Permissions, Reminders)
├── hooks/           # Custom React hooks
├── lib/             # Utility functions and services
├── pages/           # Page components
├── services/        # Business logic and API calls
└── utils/           # Helper utilities
```

### Code Style
- TypeScript strict mode enabled
- ESLint for code quality
- Tailwind for styling
- Follow existing component patterns

## Documentation

Additional guides available:
- `ROLES_PERMISSIONS_GUIDE.md` - Detailed permissions matrix
- `ASSIGNMENT_RULES_GUIDE.md` - Automated lead assignment
- `TEMPLATES_GUIDE.md` - Template system usage
- `WEBHOOK_INTEGRATION_GUIDE.md` - Webhook setup and testing
- `MULTI_TENANT_GUIDE.md` - Multi-tenancy architecture
- `FOLLOWUP_REMINDERS_GUIDE.md` - Reminder system details

## Support

For issues and questions:
1. Check the documentation guides
2. Review troubleshooting section
3. Check Supabase logs for backend errors
4. Review browser console for frontend errors

## License

Proprietary - All rights reserved

## Version

1.0.0 - Production Ready
