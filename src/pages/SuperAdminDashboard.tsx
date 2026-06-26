import { useState, useEffect } from 'react';
import { Users, Shield, UsersRound, Building2 } from 'lucide-react';
import { UserManagement } from '../components/admin/UserManagement';
import { RolePermissionsMatrix } from '../components/admin/RolePermissionsMatrix';
import { TeamManagement } from '../components/admin/TeamManagement';
import { OrganizationManagement } from '../components/admin/OrganizationManagement';
import { useAuth } from '../contexts/AuthContext';

type TabType = 'organizations' | 'users' | 'permissions' | 'teams';

export function SuperAdminDashboard() {
  const [activeTab, setActiveTab] = useState<TabType>('organizations');
  const { profile } = useAuth();
  const [selectedOrgId, setSelectedOrgId] = useState<string | null>(null);

  useEffect(() => {
    if (profile?.organization_id) {
      setSelectedOrgId(profile.organization_id);
    }
  }, [profile?.organization_id]);

  const tabs = [
    { id: 'organizations' as TabType, label: 'Organizations', icon: Building2 },
    { id: 'users' as TabType, label: 'Global Users', icon: Users },
    { id: 'permissions' as TabType, label: 'Roles & Permissions', icon: Shield },
    { id: 'teams' as TabType, label: 'Global Teams', icon: UsersRound },
  ];

  return (
    <div className="h-full flex flex-col bg-gray-50">
      <div className="bg-white border-b border-gray-200">
        <div className="px-6 py-4">
          <h1 className="text-2xl font-semibold text-gray-900">Super Admin Dashboard</h1>
          <p className="text-sm text-gray-600 mt-1">
            Manage organizations, users, roles, and permissions across the entire platform
          </p>
        </div>

        <div className="px-6">
          <div className="flex gap-1 border-b border-gray-200">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  type="button"
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
        {activeTab === 'organizations' && <OrganizationManagement />}
        {activeTab === 'users' && <UserManagement isSuperAdminView={true} organizationId={selectedOrgId} />}
        {activeTab === 'permissions' && <RolePermissionsMatrix />}
        {activeTab === 'teams' && <TeamManagement isSuperAdminView={true} organizationId={selectedOrgId} />}
      </div>
    </div>
  );
}
