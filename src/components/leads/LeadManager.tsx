import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import type { Database } from '../../lib/database.types';
import { useAuth } from '../../contexts/AuthContext';
import { LeadList } from './LeadList';
import { AddLeadModal } from './AddLeadModal';
import { FilterModal, type FilterCriteria } from './FilterModal';
import { ReferLeadsModal } from './ReferLeadsModal';
import { ConfirmationDialog } from './ConfirmationDialog';
import { ChangeStageModal } from './ChangeStageModal';
import BulkUploadModal from './BulkUploadModal';
import { BulkActionsMenu } from './BulkActionsMenu';
import { BulkAssignModal } from './BulkAssignModal';
import { exportLeadsToCSV, type LeadExportData } from '../../lib/csvExport';
import { RefreshCw, Filter, Upload } from 'lucide-react';

type LeadStatus = Database['public']['Tables']['lead_statuses']['Row'];
type Lead = Database['public']['Tables']['leads']['Row'] & {
  lead_statuses: LeadStatus | null;
  sub_status: LeadStatus | null;
  profiles: { full_name: string } | null;
  lead_sources: { name: string; color: string } | null;
};

interface LeadManagerProps {
  onAddLead: () => void;
  showAddLead: boolean;
  onCloseAddLead: () => void;
  searchQuery?: string;
}

export function LeadManager({ onAddLead, showAddLead, onCloseAddLead, searchQuery = '' }: LeadManagerProps) {
  const { profile } = useAuth();
  const [leads, setLeads] = useState<Lead[]>([]);
  const [statuses, setStatuses] = useState<LeadStatus[]>([]);
  const [activeStatus, setActiveStatus] = useState<string>('all');
  const [loading, setLoading] = useState(true);
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [appliedFilters, setAppliedFilters] = useState<FilterCriteria>({
    assignedTo: [],
    campaignNames: [],
    channels: [],
    sources: [],
    statuses: [],
    subStatuses: [],
    cities: [],
    countries: [],
    currentOwners: [],
    previousOwners: [],
  });
  const [selectedLeadIds, setSelectedLeadIds] = useState<Set<string>>(new Set());
  const [showReferModal, setShowReferModal] = useState(false);
  const [showBulkAssignModal, setShowBulkAssignModal] = useState(false);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);
  const [showDeleteConfirmDialog, setShowDeleteConfirmDialog] = useState(false);
  const [showDeleteAllConfirmDialog, setShowDeleteAllConfirmDialog] = useState(false);
  const [showChangeStageModal, setShowChangeStageModal] = useState(false);
  const [showChangeStageConfirmDialog, setShowChangeStageConfirmDialog] = useState(false);
  const [showBulkUploadModal, setShowBulkUploadModal] = useState(false);

  useEffect(() => {
    if (profile?.organization_id) {
      loadStatuses();
      loadLeads();
    }
  }, [profile?.organization_id]);

  const loadStatuses = async () => {
    const { data } = await supabase
      .from('lead_statuses')
      .select('*')
      .eq('is_active', true)
      .eq('status_type', 'main')
      .order('order_index');

    if (data) {
      setStatuses(data);
    }
  };

  const loadLeads = async () => {
    if (!profile?.organization_id) {
      setLoading(false);
      return;
    }

    setLoading(true);
    const { data } = await supabase
      .from('leads')
      .select(`
        *,
        lead_statuses:status_id (*),
        sub_status:sub_status_id (*),
        profiles:current_lead_owner (full_name),
        previous_owner_profile:previous_lead_owner (full_name),
        lead_sources (name, color)
      `)
      .eq('organization_id', profile.organization_id)
      .order('created_at', { ascending: false });

    if (data) {
      setLeads(data as Lead[]);
    }
    setLoading(false);
  };

  const applySearchFilter = (leads: Lead[]) => {
    if (!searchQuery || searchQuery.trim() === '') {
      return leads;
    }

    const query = searchQuery.toLowerCase().trim();

    return leads.filter(lead => {
      const fullName = `${lead.first_name || ''} ${lead.last_name || ''} ${lead.name || ''}`.toLowerCase();
      const email = (lead.email || '').toLowerCase();
      const mobile = (lead.mobile_number || '').toLowerCase();

      return fullName.includes(query) || email.includes(query) || mobile.includes(query);
    });
  };

  const applyAdvancedFilters = (leads: Lead[]) => {
    let filtered = [...leads];

    filtered = applySearchFilter(filtered);

    if (appliedFilters.assignedTo && appliedFilters.assignedTo.length > 0) {
      filtered = filtered.filter(lead => lead.current_lead_owner && appliedFilters.assignedTo.includes(lead.current_lead_owner));
    }

    if (appliedFilters.campaignNames && appliedFilters.campaignNames.length > 0) {
      filtered = filtered.filter(lead => lead.campaign_name && appliedFilters.campaignNames.includes(lead.campaign_name));
    }

    if (appliedFilters.channels && appliedFilters.channels.length > 0) {
      filtered = filtered.filter(lead => lead.channel && appliedFilters.channels.includes(lead.channel));
    }

    if (appliedFilters.sources && appliedFilters.sources.length > 0) {
      filtered = filtered.filter(lead => lead.source_id && appliedFilters.sources.includes(lead.source_id));
    }

    if (appliedFilters.statuses && appliedFilters.statuses.length > 0) {
      filtered = filtered.filter(lead => lead.status_id && appliedFilters.statuses.includes(lead.status_id));
    }

    if (appliedFilters.subStatuses && appliedFilters.subStatuses.length > 0) {
      filtered = filtered.filter(lead => lead.sub_status_id && appliedFilters.subStatuses.includes(lead.sub_status_id));
    }

    if (appliedFilters.dateAddedFrom) {
      filtered = filtered.filter(lead => new Date(lead.created_at) >= new Date(appliedFilters.dateAddedFrom!));
    }

    if (appliedFilters.dateAddedTo) {
      filtered = filtered.filter(lead => new Date(lead.created_at) <= new Date(appliedFilters.dateAddedTo!));
    }

    if (appliedFilters.dateEditedFrom) {
      filtered = filtered.filter(lead => new Date(lead.updated_at) >= new Date(appliedFilters.dateEditedFrom!));
    }

    if (appliedFilters.dateEditedTo) {
      filtered = filtered.filter(lead => new Date(lead.updated_at) <= new Date(appliedFilters.dateEditedTo!));
    }

    if (appliedFilters.leadAgeMin !== undefined) {
      filtered = filtered.filter(lead => {
        const age = Math.floor((Date.now() - new Date(lead.created_at).getTime()) / (1000 * 60 * 60 * 24));
        return age >= appliedFilters.leadAgeMin!;
      });
    }

    if (appliedFilters.leadAgeMax !== undefined) {
      filtered = filtered.filter(lead => {
        const age = Math.floor((Date.now() - new Date(lead.created_at).getTime()) / (1000 * 60 * 60 * 24));
        return age <= appliedFilters.leadAgeMax!;
      });
    }


    if (appliedFilters.cities && appliedFilters.cities.length > 0) {
      filtered = filtered.filter(lead => lead.city && appliedFilters.cities.includes(lead.city));
    }

    if (appliedFilters.countries && appliedFilters.countries.length > 0) {
      filtered = filtered.filter(lead => lead.country && appliedFilters.countries.includes(lead.country));
    }

    if (appliedFilters.currentOwners && appliedFilters.currentOwners.length > 0) {
      filtered = filtered.filter(lead => lead.current_lead_owner && appliedFilters.currentOwners.includes(lead.current_lead_owner));
    }

    if (appliedFilters.isReEnquired !== null && appliedFilters.isReEnquired !== undefined) {
      filtered = filtered.filter(lead => lead.is_re_enquired === appliedFilters.isReEnquired);
    }

    if (appliedFilters.callCountMin !== undefined) {
      filtered = filtered.filter(lead => lead.call_count >= appliedFilters.callCountMin!);
    }

    if (appliedFilters.callCountMax !== undefined) {
      filtered = filtered.filter(lead => lead.call_count <= appliedFilters.callCountMax!);
    }

    if (appliedFilters.dateFrom) {
      filtered = filtered.filter(lead => new Date(lead.created_at) >= new Date(appliedFilters.dateFrom!));
    }

    if (appliedFilters.dateTo) {
      filtered = filtered.filter(lead => new Date(lead.created_at) <= new Date(appliedFilters.dateTo!));
    }

    return filtered;
  };

  const getStatusCount = (statusName: string) => {
    const statusFiltered = statusName === 'all'
      ? leads
      : leads.filter(lead => lead.lead_statuses?.name === statusName);

    return applyAdvancedFilters(statusFiltered).length;
  };

  const filteredLeads = applyAdvancedFilters(
    activeStatus === 'all'
      ? leads
      : leads.filter(lead => lead.lead_statuses?.name === activeStatus)
  );

  const hasActiveFilters = () => {
    return (
      (searchQuery && searchQuery.trim() !== '') ||
      (appliedFilters.assignedTo && appliedFilters.assignedTo.length > 0) ||
      (appliedFilters.campaignNames && appliedFilters.campaignNames.length > 0) ||
      (appliedFilters.channels && appliedFilters.channels.length > 0) ||
      (appliedFilters.sources && appliedFilters.sources.length > 0) ||
      (appliedFilters.statuses && appliedFilters.statuses.length > 0) ||
      (appliedFilters.subStatuses && appliedFilters.subStatuses.length > 0) ||
      appliedFilters.dateAddedFrom !== undefined ||
      appliedFilters.dateAddedTo !== undefined ||
      appliedFilters.dateEditedFrom !== undefined ||
      appliedFilters.dateEditedTo !== undefined ||
      appliedFilters.leadAgeMin !== undefined ||
      appliedFilters.leadAgeMax !== undefined ||
      appliedFilters.leadNumberMin !== undefined ||
      appliedFilters.leadNumberMax !== undefined ||
      (appliedFilters.cities && appliedFilters.cities.length > 0) ||
      (appliedFilters.countries && appliedFilters.countries.length > 0) ||
      (appliedFilters.currentOwners && appliedFilters.currentOwners.length > 0) ||
      appliedFilters.isReEnquired !== null ||
      appliedFilters.callCountMin !== undefined ||
      appliedFilters.callCountMax !== undefined ||
      appliedFilters.dateFrom !== undefined ||
      appliedFilters.dateTo !== undefined
    );
  };

  const handleSelectChange = (leadId: string, selected: boolean) => {
    setSelectedLeadIds(prev => {
      const newSet = new Set(prev);
      if (selected) {
        newSet.add(leadId);
      } else {
        newSet.delete(leadId);
      }
      return newSet;
    });
  };

  const handleReferClick = () => {
    if (selectedLeadIds.size > 0) {
      setShowReferModal(true);
    } else {
      setShowConfirmDialog(true);
    }
  };

  const handleConfirmReferAll = () => {
    const allLeadIds = new Set(filteredLeads.map(lead => lead.id));
    setSelectedLeadIds(allLeadIds);
    setShowConfirmDialog(false);
    setShowReferModal(true);
  };

  const handleReferSuccess = () => {
    setShowReferModal(false);
    setSelectedLeadIds(new Set());
    loadLeads();
  };

  const handleDeleteClick = () => {
    if (selectedLeadIds.size > 0) {
      setShowDeleteConfirmDialog(true);
    } else {
      setShowDeleteAllConfirmDialog(true);
    }
  };

  const handleConfirmDelete = async () => {
    setShowDeleteConfirmDialog(false);
    const leadIdsToDelete = Array.from(selectedLeadIds);

    try {
      const { error } = await supabase
        .from('leads')
        .delete()
        .in('id', leadIdsToDelete);

      if (error) throw error;

      setSelectedLeadIds(new Set());
      loadLeads();
    } catch (err) {
      console.error('Failed to delete leads:', err);
    }
  };

  const handleConfirmDeleteAll = async () => {
    setShowDeleteAllConfirmDialog(false);
    const allLeadIds = filteredLeads.map(lead => lead.id);

    try {
      const { error } = await supabase
        .from('leads')
        .delete()
        .in('id', allLeadIds);

      if (error) throw error;

      setSelectedLeadIds(new Set());
      loadLeads();
    } catch (err) {
      console.error('Failed to delete leads:', err);
    }
  };

  const handleEditClick = () => {
    if (selectedLeadIds.size > 0) {
      setShowChangeStageModal(true);
    } else {
      setShowChangeStageConfirmDialog(true);
    }
  };

  const handleConfirmChangeStageAll = () => {
    const allLeadIds = new Set(filteredLeads.map(lead => lead.id));
    setSelectedLeadIds(allLeadIds);
    setShowChangeStageConfirmDialog(false);
    setShowChangeStageModal(true);
  };

  const handleChangeStageSuccess = () => {
    setShowChangeStageModal(false);
    setSelectedLeadIds(new Set());
    loadLeads();
  };

  const handleEditFromCard = (leadId: string) => {
    setSelectedLeadIds(new Set([leadId]));
    setShowChangeStageModal(true);
  };

  const handleExportLeads = async () => {
    const leadsToExport = selectedLeadIds.size > 0
      ? filteredLeads.filter(lead => selectedLeadIds.has(lead.id))
      : filteredLeads;

    const exportData = leadsToExport as LeadExportData[];
    const timestamp = new Date().toISOString().split('T')[0];
    exportLeadsToCSV(exportData, `leads_export_${timestamp}.csv`);
  };

  const handleBulkAssign = () => {
    if (selectedLeadIds.size === 0) {
      const allLeadIds = new Set(filteredLeads.map(lead => lead.id));
      setSelectedLeadIds(allLeadIds);
    }
    setShowBulkAssignModal(true);
  };

  const handleBulkAssignSuccess = () => {
    setShowBulkAssignModal(false);
    setSelectedLeadIds(new Set());
    loadLeads();
  };

  const handleBulkChangeStatus = () => {
    if (selectedLeadIds.size === 0) {
      const allLeadIds = new Set(filteredLeads.map(lead => lead.id));
      setSelectedLeadIds(allLeadIds);
    }
    setShowChangeStageModal(true);
  };

  const handleBulkDelete = () => {
    if (selectedLeadIds.size > 0) {
      setShowDeleteConfirmDialog(true);
    } else {
      setShowDeleteAllConfirmDialog(true);
    }
  };

  return (
    <div className="flex flex-col h-full bg-white">
      <div className="border-b border-slate-200">
        <div className="flex items-center gap-2 px-6 py-3 overflow-x-auto">
          <button
            onClick={() => setActiveStatus('all')}
            className={`px-4 py-2 rounded-lg font-medium text-sm whitespace-nowrap transition ${
              activeStatus === 'all'
                ? 'bg-orange-500 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            All ({getStatusCount('all')})
          </button>

          {statuses.map((status) => (
            <button
              key={status.id}
              onClick={() => setActiveStatus(status.name)}
              className={`px-4 py-2 rounded-lg font-medium text-sm whitespace-nowrap transition ${
                activeStatus === status.name
                  ? 'bg-orange-500 text-white'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {status.display_name} ({getStatusCount(status.name)})
            </button>
          ))}
        </div>
      </div>

      <div className="px-6 py-3 border-b border-slate-200 flex items-center justify-between">
        {searchQuery && searchQuery.trim() !== '' && (
          <div className="flex items-center gap-2 text-sm text-slate-600">
            <span className="font-medium">Search results:</span>
            <span className="px-2 py-1 bg-orange-100 text-orange-700 rounded-lg font-semibold">
              {filteredLeads.length} lead{filteredLeads.length !== 1 ? 's' : ''} found
            </span>
          </div>
        )}
        <div className={`flex items-center gap-2 ${!searchQuery || searchQuery.trim() === '' ? 'ml-auto' : ''}`}>
          <button
            onClick={() => setShowBulkUploadModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition font-medium"
            title="Bulk Upload"
          >
            <Upload className="w-5 h-5" />
            Bulk Upload
          </button>
          <div className="w-px h-6 bg-slate-200" />
          <BulkActionsMenu
            selectedCount={selectedLeadIds.size > 0 ? selectedLeadIds.size : filteredLeads.length}
            onExport={handleExportLeads}
            onDownload={handleExportLeads}
            onAssign={handleBulkAssign}
            onChangeStatus={handleBulkChangeStatus}
            onDelete={handleBulkDelete}
          />
          <button
            onClick={() => setShowFilterModal(true)}
            className={`p-2 hover:bg-slate-100 rounded-lg transition relative ${
              hasActiveFilters() ? 'bg-orange-50' : ''
            }`}
            title="Filter"
          >
            <Filter className="w-5 h-5 text-orange-500" />
            {hasActiveFilters() && (
              <span className="absolute -top-1 -right-1 w-4 h-4 bg-orange-500 text-white text-xs rounded-full flex items-center justify-center">
                !
              </span>
            )}
          </button>
          <button
            onClick={loadLeads}
            className="p-2 hover:bg-slate-100 rounded-lg transition"
            title="Refresh"
          >
            <RefreshCw className="w-5 h-5 text-orange-500" />
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-auto">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-4 border-orange-500 border-t-transparent"></div>
          </div>
        ) : (
          <LeadList
            leads={filteredLeads}
            onRefresh={loadLeads}
            selectedLeadIds={selectedLeadIds}
            onSelectChange={handleSelectChange}
            onEdit={handleEditFromCard}
          />
        )}
      </div>

      {showAddLead && (
        <AddLeadModal
          onClose={onCloseAddLead}
          onSuccess={() => {
            onCloseAddLead();
            loadLeads();
          }}
        />
      )}

      {showFilterModal && (
        <FilterModal
          onClose={() => setShowFilterModal(false)}
          currentFilters={appliedFilters}
          onApplyFilters={(filters) => setAppliedFilters(filters)}
        />
      )}

      {showReferModal && (
        <ReferLeadsModal
          leadIds={Array.from(selectedLeadIds)}
          onClose={() => setShowReferModal(false)}
          onSuccess={handleReferSuccess}
        />
      )}

      {showBulkAssignModal && (
        <BulkAssignModal
          leadIds={Array.from(selectedLeadIds)}
          onClose={() => setShowBulkAssignModal(false)}
          onSuccess={handleBulkAssignSuccess}
        />
      )}

      {showConfirmDialog && (
        <ConfirmationDialog
          title="Refer All Leads"
          message={`No leads are selected. Do you want to refer all ${filteredLeads.length} lead${filteredLeads.length !== 1 ? 's' : ''} in the current ${activeStatus === 'all' ? 'view' : activeStatus + ' status'}?`}
          confirmText="Refer All"
          onConfirm={handleConfirmReferAll}
          onCancel={() => setShowConfirmDialog(false)}
        />
      )}

      {showDeleteConfirmDialog && (
        <ConfirmationDialog
          title="Delete Leads"
          message={`Are you sure you want to delete ${selectedLeadIds.size} selected lead${selectedLeadIds.size !== 1 ? 's' : ''}? This action cannot be undone.`}
          confirmText="Delete"
          onConfirm={handleConfirmDelete}
          onCancel={() => setShowDeleteConfirmDialog(false)}
        />
      )}

      {showDeleteAllConfirmDialog && (
        <ConfirmationDialog
          title="Delete All Leads"
          message={`No leads are selected. Do you want to delete all ${filteredLeads.length} lead${filteredLeads.length !== 1 ? 's' : ''} in the current ${activeStatus === 'all' ? 'view' : activeStatus + ' status'}? This action cannot be undone.`}
          confirmText="Delete All"
          onConfirm={handleConfirmDeleteAll}
          onCancel={() => setShowDeleteAllConfirmDialog(false)}
        />
      )}

      {showChangeStageModal && (
        <ChangeStageModal
          leadIds={Array.from(selectedLeadIds)}
          onClose={() => setShowChangeStageModal(false)}
          onSuccess={handleChangeStageSuccess}
        />
      )}

      {showChangeStageConfirmDialog && (
        <ConfirmationDialog
          title="Change Stage for All Leads"
          message={`No leads are selected. Do you want to change the stage for all ${filteredLeads.length} lead${filteredLeads.length !== 1 ? 's' : ''} in the current ${activeStatus === 'all' ? 'view' : activeStatus + ' status'}?`}
          confirmText="Change All"
          onConfirm={handleConfirmChangeStageAll}
          onCancel={() => setShowChangeStageConfirmDialog(false)}
        />
      )}

      {showBulkUploadModal && (
        <BulkUploadModal
          onClose={() => setShowBulkUploadModal(false)}
          onSuccess={() => {
            loadLeads();
          }}
        />
      )}
    </div>
  );
}
