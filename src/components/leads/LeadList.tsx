import { LeadCard } from './LeadCard';
import type { Database } from '../../lib/database.types';

type LeadStatus = Database['public']['Tables']['lead_statuses']['Row'];
type Lead = Database['public']['Tables']['leads']['Row'] & {
  lead_statuses: LeadStatus | null;
  sub_status: LeadStatus | null;
  profiles: { full_name: string } | null;
  lead_sources: { name: string; color: string } | null;
};

interface LeadListProps {
  leads: Lead[];
  onRefresh: () => void;
  selectedLeadIds?: Set<string>;
  onSelectChange?: (leadId: string, selected: boolean) => void;
  onEdit?: (leadId: string) => void;
}

export function LeadList({ leads, onRefresh, selectedLeadIds = new Set(), onSelectChange, onEdit }: LeadListProps) {
  if (leads.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-64 text-slate-400">
        <p className="text-lg font-medium">No leads found</p>
        <p className="text-sm">Add your first lead to get started</p>
      </div>
    );
  }

  return (
    <div className="divide-y divide-slate-200">
      {leads.map((lead) => (
        <LeadCard
          key={lead.id}
          lead={lead}
          onUpdate={onRefresh}
          isSelected={selectedLeadIds.has(lead.id)}
          onSelectChange={onSelectChange}
          onEdit={onEdit}
        />
      ))}
    </div>
  );
}
