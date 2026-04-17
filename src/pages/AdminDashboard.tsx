import { useState, useEffect } from 'react';
import { Users, Shield, UsersRound, Mail, GitBranch, Webhook } from 'lucide-react';
import { UserManagement } from '../components/admin/UserManagement';
import { RolePermissionsMatrix } from '../components/admin/RolePermissionsMatrix';
import { TeamManagement } from '../components/admin/TeamManagement';
import { InvitationManagement } from '../components/admin/InvitationManagement';
import { AssignmentRulesManagement } from '../components/admin/AssignmentRulesManagement';
import { WebhookManagement } from '../components/admin/WebhookManagement';
import { usePermissions } from '../contexts/PermissionsContext';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';

type TabType = 'users' | 'permissions' | 'teams' | 'invitations' | 'assignmentRules' | 'webhooks';

export function AdminDashboard() {
  const { isSuperAdmin, userProfile } = usePermissions();
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState<TabType>('users');
  const [organizationId, setOrganizationId] = useState<string | null>(null);
  const [organizationName, setOrganizationName] = useState<string>('');

  useEffect(() => {
    loadOrganization();
  }, [profile?.organization_id]);

  const loadOrganization = async () => {
    try {
      const orgId = profile?.organization_id;
      if (!orgId) return;

      setOrganizationId(orgId);

      const { data: orgData, error: orgError } = await supabase
        .from('organizations')
        .select('name')
        .eq('id', orgId)
        .single();

      if (orgError) throw orgError;

      setOrganizationName(orgData?.name || 'Unknown Organization');
    } catch (error) {
      console.error('Error loading organization:', error);
    }
  };

  const tabs = [
    { id: 'users' as TabType, label: 'User Management', icon: Users },
    { id: 'invitations' as TabType, label: 'Invitations', icon: Mail },
    { id: 'permissions' as TabType, label: 'Roles & Permissions', icon: Shield },
    { id: 'teams' as TabType, label: 'Team Management', icon: UsersRound },
    { id: 'assignmentRules' as TabType, label: 'Assignment Rules', icon: GitBranch },
    { id: 'webhooks' as TabType, label: 'Webhook Integrations', icon: Webhook },
  ];

  return (
    <div className="h-full flex flex-col bg-gray-50">
      <div className="bg-white border-b border-gray-200">
        <div className="px-6 py-4">
          <h1 className="text-2xl font-semibold text-gray-900">Admin Dashboard</h1>
          <p className="text-sm text-gray-600 mt-1">
            Manage users, invitations, roles, and teams for{' '}
            <span className="font-medium text-orange-600">{organizationName}</span>
          </p>
        </div>

        <div className="px-6">
          <div className="flex gap-1 border-b border-gray-200">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`
                    flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors
                    ${
                      activeTab === tab.id
                        ? 'border-orange-600 text-orange-600'
                        : 'border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300'
                    }
                  `}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-auto">
        {activeTab === 'users' && <UserManagement organizationId={organizationId} isSuperAdminView={false} />}
        {activeTab === 'invitations' && <InvitationManagement />}
        {activeTab === 'permissions' && <RolePermissionsMatrix />}
        {activeTab === 'teams' && <TeamManagement organizationId={organizationId} isSuperAdminView={false} />}
        {activeTab === 'assignmentRules' && <AssignmentRulesManagement />}
        {activeTab === 'webhooks' && <WebhookManagement />}
      </div>
    </div>
  );
}
