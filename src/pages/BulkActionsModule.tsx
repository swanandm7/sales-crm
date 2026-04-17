import { useState } from 'react';
import { Upload, Download, CreditCard as Edit, UserPlus } from 'lucide-react';
import { BulkUploadTab } from '../components/bulkActions/BulkUploadTab';
import { DataDownloadTab } from '../components/bulkActions/DataDownloadTab';
import { BulkStatusChangeTab } from '../components/bulkActions/BulkStatusChangeTab';
import { BulkReferTab } from '../components/bulkActions/BulkReferTab';

type TabId = 'bulk-upload' | 'data-download' | 'bulk-status-change' | 'bulk-refer';

interface Tab {
  id: TabId;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
}

const tabs: Tab[] = [
  { id: 'bulk-upload', label: 'Bulk Upload', icon: Upload },
  { id: 'data-download', label: 'Data Download', icon: Download },
  { id: 'bulk-status-change', label: 'Bulk Status Change', icon: Edit },
  { id: 'bulk-refer', label: 'Bulk Refer', icon: UserPlus },
];

export function BulkActionsModule() {
  const [activeTab, setActiveTab] = useState<TabId>('bulk-upload');

  const renderTabContent = () => {
    switch (activeTab) {
      case 'bulk-upload':
        return <BulkUploadTab />;
      case 'data-download':
        return <DataDownloadTab />;
      case 'bulk-status-change':
        return <BulkStatusChangeTab />;
      case 'bulk-refer':
        return <BulkReferTab />;
      default:
        return <BulkUploadTab />;
    }
  };

  return (
    <div className="h-full flex flex-col bg-white">
      <div className="border-b border-slate-200">
        <div className="flex items-center">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;

            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-6 py-4 font-medium text-sm border-b-2 transition-colors ${
                  isActive
                    ? 'border-orange-500 text-orange-600 bg-orange-50'
                    : 'border-transparent text-slate-600 hover:text-slate-900 hover:bg-slate-50'
                }`}
              >
                <Icon className="w-4 h-4" />
                {tab.label}
              </button>
            );
          })}
        </div>
      </div>

      <div className="flex-1 overflow-hidden">
        {renderTabContent()}
      </div>
    </div>
  );
}
