import { useState } from 'react';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { LeadManager } from '../leads/LeadManager';
import { BasicSettings } from '../settings/BasicSettings';
import { FollowupsManager } from '../followups/FollowupsManager';
import { AdminAnalytics } from '../../pages/AdminAnalytics';
import { BulkActionsModule } from '../../pages/BulkActionsModule';
import { AdminDashboard } from '../../pages/AdminDashboard';
import { SuperAdminDashboard } from '../../pages/SuperAdminDashboard';
import { ReminderProvider } from '../../contexts/ReminderContext';
import { FollowupReminderToast } from '../notifications/FollowupReminderToast';

export function MainLayout() {
  const [activeSection, setActiveSection] = useState('leads');
  const [showAddLead, setShowAddLead] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeSearchQuery, setActiveSearchQuery] = useState('');
  const [selectedFollowupId, setSelectedFollowupId] = useState<string | null>(null);

  const handleSearch = () => {
    setActiveSearchQuery(searchQuery);
  };

  const handleClearSearch = () => {
    setSearchQuery('');
    setActiveSearchQuery('');
  };

  const handleViewFollowup = (followupId: string) => {
    setSelectedFollowupId(followupId);
    setActiveSection('followups');
  };

  const renderContent = () => {
    switch (activeSection) {
      case 'leads':
        return <LeadManager onAddLead={() => setShowAddLead(true)} showAddLead={showAddLead} onCloseAddLead={() => setShowAddLead(false)} searchQuery={activeSearchQuery} />;
      case 'dashboard':
        return <div className="p-6"><h2 className="text-2xl font-bold text-slate-800">Analytics Dashboard</h2><p className="text-slate-600 mt-2">Coming soon...</p></div>;
      case 'analytics':
        return <AdminAnalytics />;
      case 'settings':
        return <BasicSettings />;
      case 'followups':
        return <FollowupsManager selectedFollowupId={selectedFollowupId} onFollowupViewed={() => setSelectedFollowupId(null)} />;
      case 'bulk-actions':
        return <BulkActionsModule />;
      case 'super-admin':
        return <SuperAdminDashboard />;
      case 'admin':
        return <AdminDashboard />;
      default:
        return (
          <div className="p-6">
            <h2 className="text-2xl font-bold text-slate-800 capitalize">
              {activeSection.replace('-', ' ')}
            </h2>
            <p className="text-slate-600 mt-2">This section is under development.</p>
          </div>
        );
    }
  };

  return (
    <ReminderProvider onViewFollowup={handleViewFollowup}>
      <div className="flex h-screen bg-slate-100">
        <Sidebar activeSection={activeSection} onSectionChange={setActiveSection} />

        <div className="flex-1 flex flex-col overflow-hidden">
          <Header
            onAddLead={() => setShowAddLead(true)}
            searchQuery={searchQuery}
            onSearchChange={setSearchQuery}
            onSearch={handleSearch}
            onClearSearch={handleClearSearch}
          />

          <main className="flex-1 overflow-auto">
            {renderContent()}
          </main>
        </div>
      </div>
      <FollowupReminderToast />
    </ReminderProvider>
  );
}
