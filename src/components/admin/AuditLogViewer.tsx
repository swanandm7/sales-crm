import { useState, useEffect } from 'react';
import { Shield, Download, Filter, Calendar, User, Activity } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface AuditLogEntry {
  id: string;
  actor_user_id: string;
  action_type: string;
  target_user_id: string | null;
  target_organization_id: string | null;
  old_value: string | null;
  new_value: string | null;
  metadata: any;
  notes: string | null;
  created_at: string;
  actor?: {
    full_name: string;
    email: string;
  };
  target_user?: {
    full_name: string;
    email: string;
  };
}

export function AuditLogViewer() {
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterAction, setFilterAction] = useState<string>('all');
  const [filterDateRange, setFilterDateRange] = useState<string>('7');
  const [searchTerm, setSearchTerm] = useState('');

  const actionTypes = [
    'all',
    'user_created',
    'user_updated',
    'user_disabled',
    'user_enabled',
    'user_invited',
    'invite_accepted',
    'invite_resent',
    'invite_cancelled',
    'role_changed',
    'organization_created',
    'organization_updated',
    'organization_suspended',
    'organization_activated',
  ];

  useEffect(() => {
    loadAuditLogs();
  }, [filterAction, filterDateRange]);

  const loadAuditLogs = async () => {
    try {
      setLoading(true);

      const dateThreshold = new Date();
      dateThreshold.setDate(dateThreshold.getDate() - parseInt(filterDateRange));

      let query = supabase
        .from('audit_log')
        .select(`
          *,
          actor:profiles!actor_user_id(full_name, email),
          target_user:profiles!target_user_id(full_name, email)
        `)
        .gte('created_at', dateThreshold.toISOString())
        .order('created_at', { ascending: false })
        .limit(500);

      if (filterAction !== 'all') {
        query = query.eq('action_type', filterAction);
      }

      const { data, error } = await query;

      if (error) throw error;
      setLogs(data || []);
    } catch (error) {
      console.error('Error loading audit logs:', error);
    } finally {
      setLoading(false);
    }
  };

  const exportToCSV = () => {
    const headers = ['Date', 'Actor', 'Action', 'Target', 'Details', 'Notes'];
    const rows = filteredLogs.map(log => [
      new Date(log.created_at).toLocaleString(),
      log.actor?.full_name || 'System',
      log.action_type,
      log.target_user?.full_name || '-',
      `${log.old_value || ''} → ${log.new_value || ''}`.trim() || '-',
      log.notes || '-',
    ]);

    const csv = [
      headers.join(','),
      ...rows.map(row => row.map(cell => `"${cell}"`).join(',')),
    ].join('\n');

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `audit-log-${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
  };

  const filteredLogs = logs.filter(log => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return (
      log.actor?.full_name?.toLowerCase().includes(term) ||
      log.actor?.email?.toLowerCase().includes(term) ||
      log.target_user?.full_name?.toLowerCase().includes(term) ||
      log.action_type.toLowerCase().includes(term)
    );
  });

  const getActionIcon = (actionType: string) => {
    if (actionType.includes('user')) return <User className="w-4 h-4" />;
    if (actionType.includes('organization')) return <Shield className="w-4 h-4" />;
    return <Activity className="w-4 h-4" />;
  };

  const getActionColor = (actionType: string) => {
    if (actionType.includes('created') || actionType.includes('enabled') || actionType.includes('activated')) {
      return 'bg-green-100 text-green-800';
    }
    if (actionType.includes('disabled') || actionType.includes('suspended') || actionType.includes('cancelled')) {
      return 'bg-red-100 text-red-800';
    }
    if (actionType.includes('updated') || actionType.includes('resent')) {
      return 'bg-blue-100 text-blue-800';
    }
    return 'bg-gray-100 text-gray-800';
  };

  const formatActionType = (actionType: string) => {
    return actionType
      .split('_')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading audit logs...</div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Shield className="w-6 h-6 text-blue-600" />
            <h2 className="text-2xl font-bold text-gray-900">Audit Log</h2>
          </div>
          <button
            onClick={exportToCSV}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Download className="w-4 h-4" />
            Export CSV
          </button>
        </div>

        <div className="flex flex-col sm:flex-row gap-4 mb-4">
          <div className="flex-1 relative">
            <input
              type="text"
              placeholder="Search by user or action..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <div className="flex gap-3">
            <div className="relative">
              <Filter className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <select
                value={filterAction}
                onChange={(e) => setFilterAction(e.target.value)}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
              >
                {actionTypes.map((action) => (
                  <option key={action} value={action}>
                    {action === 'all' ? 'All Actions' : formatActionType(action)}
                  </option>
                ))}
              </select>
            </div>

            <div className="relative">
              <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <select
                value={filterDateRange}
                onChange={(e) => setFilterDateRange(e.target.value)}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
              >
                <option value="1">Last 24 hours</option>
                <option value="7">Last 7 days</option>
                <option value="30">Last 30 days</option>
                <option value="90">Last 90 days</option>
                <option value="365">Last year</option>
              </select>
            </div>
          </div>
        </div>

        <div className="text-sm text-gray-600">
          Showing {filteredLogs.length} of {logs.length} entries
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Timestamp
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actor
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Target
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Details
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Notes
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredLogs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 text-sm text-gray-900 whitespace-nowrap">
                    {new Date(log.created_at).toLocaleString()}
                  </td>
                  <td className="px-6 py-4 text-sm">
                    <div className="font-medium text-gray-900">
                      {log.actor?.full_name || 'System'}
                    </div>
                    <div className="text-gray-500 text-xs">{log.actor?.email}</div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full ${getActionColor(log.action_type)}`}>
                      {getActionIcon(log.action_type)}
                      {formatActionType(log.action_type)}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-900">
                    {log.target_user?.full_name || '-'}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {log.old_value && log.new_value ? (
                      <div className="flex items-center gap-2">
                        <span className="line-through text-gray-400">{log.old_value}</span>
                        <span>→</span>
                        <span className="font-medium">{log.new_value}</span>
                      </div>
                    ) : (
                      <span>-</span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600 max-w-xs truncate">
                    {log.notes || '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {filteredLogs.length === 0 && (
            <div className="text-center py-12 text-gray-500">
              No audit logs found matching your filters
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
