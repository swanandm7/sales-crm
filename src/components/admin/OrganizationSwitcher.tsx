import { useState, useEffect } from 'react';
import { Building2, Check, ChevronDown } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface Organization {
  id: string;
  name: string;
  slug: string;
  status: 'active' | 'suspended';
}

interface OrganizationSwitcherProps {
  currentOrgId: string | null;
  onOrgChange: (orgId: string) => void;
}

export function OrganizationSwitcher({ currentOrgId, onOrgChange }: OrganizationSwitcherProps) {
  const [organizations, setOrganizations] = useState<Organization[]>([]);
  const [showDropdown, setShowDropdown] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadOrganizations();
  }, []);

  const loadOrganizations = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('organizations')
        .select('id, name, slug, status')
        .eq('status', 'active')
        .order('name');

      if (error) throw error;
      setOrganizations(data || []);
    } catch (error) {
      console.error('Error loading organizations:', error);
    } finally {
      setLoading(false);
    }
  };

  const currentOrg = organizations.find(org => org.id === currentOrgId);

  if (loading) {
    return (
      <div className="flex items-center gap-2 px-3 py-2 bg-slate-600 rounded-lg text-sm">
        <Building2 className="w-4 h-4" />
        <span>Loading...</span>
      </div>
    );
  }

  return (
    <div className="relative">
      <button
        onClick={() => setShowDropdown(!showDropdown)}
        className="flex items-center gap-2 px-3 py-2 bg-slate-600 hover:bg-slate-500 rounded-lg transition-colors text-sm"
      >
        <Building2 className="w-4 h-4" />
        <span className="max-w-[150px] truncate">
          {currentOrg?.name || 'Select Organization'}
        </span>
        <ChevronDown className="w-4 h-4" />
      </button>

      {showDropdown && (
        <>
          <div
            className="fixed inset-0 z-40"
            onClick={() => setShowDropdown(false)}
          />
          <div className="absolute top-full left-0 mt-2 w-64 bg-white rounded-lg shadow-xl border border-gray-200 py-2 z-50 max-h-96 overflow-y-auto">
            <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase border-b border-gray-200">
              Switch Organization
            </div>
            {organizations.map((org) => (
              <button
                key={org.id}
                onClick={() => {
                  onOrgChange(org.id);
                  setShowDropdown(false);
                }}
                className={`w-full flex items-center justify-between px-3 py-2 text-sm hover:bg-gray-50 transition-colors ${
                  currentOrgId === org.id ? 'bg-blue-50 text-blue-700' : 'text-gray-700'
                }`}
              >
                <div className="flex items-center gap-2 flex-1 min-w-0">
                  <Building2 className="w-4 h-4 flex-shrink-0" />
                  <div className="flex-1 min-w-0 text-left">
                    <div className="font-medium truncate">{org.name}</div>
                    <div className="text-xs text-gray-500 truncate">{org.slug}</div>
                  </div>
                </div>
                {currentOrgId === org.id && (
                  <Check className="w-4 h-4 flex-shrink-0 text-blue-700" />
                )}
              </button>
            ))}
            {organizations.length === 0 && (
              <div className="px-3 py-4 text-sm text-gray-500 text-center">
                No active organizations found
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
