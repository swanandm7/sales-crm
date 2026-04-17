import { useState, useRef, useEffect } from 'react';
import { ChevronDown, Download, UserPlus, CreditCard as Edit, Trash2, Tag, FileDown } from 'lucide-react';

interface BulkActionsMenuProps {
  selectedCount: number;
  onExport: () => void;
  onDownload: () => void;
  onAssign: () => void;
  onChangeStatus: () => void;
  onDelete: () => void;
  onAddTags?: () => void;
}

export function BulkActionsMenu({
  selectedCount,
  onExport,
  onDownload,
  onAssign,
  onChangeStatus,
  onDelete,
  onAddTags
}: BulkActionsMenuProps) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleAction = (action: () => void) => {
    action();
    setIsOpen(false);
  };

  return (
    <div ref={dropdownRef} className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="px-4 py-2 bg-[#1E293B] text-white rounded-lg hover:bg-slate-700 transition font-medium flex items-center gap-2"
      >
        Bulk Actions
        {selectedCount > 0 && (
          <span className="px-2 py-0.5 bg-white text-slate-800 rounded-full text-xs font-bold">
            {selectedCount}
          </span>
        )}
        <ChevronDown className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-56 bg-white border border-slate-200 rounded-lg shadow-lg overflow-hidden z-50">
          <div className="py-1">
            <button
              onClick={() => handleAction(onDownload)}
              className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-orange-50 hover:text-orange-700 flex items-center gap-3 transition"
            >
              <FileDown className="w-4 h-4" />
              Download Leads
            </button>

            <button
              onClick={() => handleAction(onExport)}
              className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-orange-50 hover:text-orange-700 flex items-center gap-3 transition"
            >
              <Download className="w-4 h-4" />
              Export to CSV
            </button>

            <button
              onClick={() => handleAction(onAssign)}
              className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-orange-50 hover:text-orange-700 flex items-center gap-3 transition"
            >
              <UserPlus className="w-4 h-4" />
              Assign to User
            </button>

            <button
              onClick={() => handleAction(onChangeStatus)}
              className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-orange-50 hover:text-orange-700 flex items-center gap-3 transition"
            >
              <Edit className="w-4 h-4" />
              Change Status
            </button>

            {onAddTags && (
              <button
                onClick={() => handleAction(onAddTags)}
                className="w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-orange-50 hover:text-orange-700 flex items-center gap-3 transition"
              >
                <Tag className="w-4 h-4" />
                Add Tags
              </button>
            )}

            <div className="border-t border-slate-200 my-1"></div>

            <button
              onClick={() => handleAction(onDelete)}
              className="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-3 transition"
            >
              <Trash2 className="w-4 h-4" />
              Delete Leads
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
