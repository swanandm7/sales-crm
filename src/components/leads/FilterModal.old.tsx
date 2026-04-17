import { useState, useEffect } from 'react';
import { X, Filter } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { Database } from '../../lib/database.types';

type LeadSource = Database['public']['Tables']['lead_sources']['Row'];
type Profile = Database['public']['Tables']['profiles']['Row'];

interface FilterModalProps {
  onClose: () => void;
  onApplyFilters: (filters: FilterCriteria) => void;
  currentFilters: FilterCriteria;
}

export interface FilterCriteria {
  stages: string[];
  channels: string[];
  sources: string[];
  cities: string[];
  countries: string[];
  currentOwners: string[];
  previousOwners: string[];
  isReEnquired?: boolean | null;
  callCountMin?: number;
  callCountMax?: number;
  leadAgeMin?: number;
  leadAgeMax?: number;
  dateFrom?: string;
  dateTo?: string;
}

const STAGES = ['New', 'Contacted', 'Qualified', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost'];
const CHANNELS = ['Digital Marketing', 'Publishers', 'Referrals', 'Walk-in', 'Direct', 'Partner'];
const COUNTRIES = ['India', 'USA', 'UK', 'UAE', 'Singapore', 'Other'];
const INDIAN_CITIES = [
  'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai', 'Kolkata',
  'Pune', 'Ahmedabad', 'Surat', 'Jaipur', 'Lucknow', 'Kanpur', 'Other'
];

export function FilterModal({ onClose, onApplyFilters, currentFilters }: FilterModalProps) {
  const [filters, setFilters] = useState<FilterCriteria>(currentFilters);
  const [sources, setSources] = useState<LeadSource[]>([]);
  const [users, setUsers] = useState<Profile[]>([]);

  useEffect(() => {
    loadOptions();
  }, []);

  const loadOptions = async () => {
    const [sourcesRes, usersRes] = await Promise.all([
      supabase.from('lead_sources').select('*').eq('is_active', true),
      supabase.from('profiles').select('*'),
    ]);

    if (sourcesRes.data) setSources(sourcesRes.data);
    if (usersRes.data) setUsers(usersRes.data);
  };

  const toggleArrayFilter = (key: keyof FilterCriteria, value: string) => {
    const currentArray = (filters[key] as string[]) || [];
    const newArray = currentArray.includes(value)
      ? currentArray.filter(v => v !== value)
      : [...currentArray, value];
    setFilters({ ...filters, [key]: newArray });
  };

  const clearAll = () => {
    setFilters({
      stages: [],
      channels: [],
      sources: [],
      cities: [],
      countries: [],
      currentOwners: [],
      previousOwners: [],
    });
  };

  const handleApply = () => {
    onApplyFilters(filters);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-auto">
        <div className="sticky top-0 bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-orange-100 rounded-lg">
              <Filter className="w-5 h-5 text-orange-600" />
            </div>
            <h2 className="text-2xl font-bold text-slate-800">Advanced Filters</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-100 rounded-lg transition"
          >
            <X className="w-5 h-5 text-slate-600" />
          </button>
        </div>

        <div className="p-6 space-y-6">
          <div>
            <h3 className="font-semibold text-slate-800 mb-3">Stage</h3>
            <div className="flex flex-wrap gap-2">
              {STAGES.map((stage) => (
                <button
                  key={stage}
                  onClick={() => toggleArrayFilter('stages', stage)}
                  className={`px-3 py-1.5 text-sm rounded-lg font-medium transition ${
                    filters.stages?.includes(stage)
                      ? 'bg-blue-100 text-blue-700 border-2 border-blue-500'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {stage}
                </button>
              ))}
            </div>
          </div>

          <div>
            <h3 className="font-semibold text-slate-800 mb-3">Channel</h3>
            <div className="flex flex-wrap gap-2">
              {CHANNELS.map((channel) => (
                <button
                  key={channel}
                  onClick={() => toggleArrayFilter('channels', channel)}
                  className={`px-3 py-1.5 text-sm rounded-lg font-medium transition ${
                    filters.channels?.includes(channel)
                      ? 'bg-green-100 text-green-700 border-2 border-green-500'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {channel}
                </button>
              ))}
            </div>
          </div>

          <div>
            <h3 className="font-semibold text-slate-800 mb-3">Lead Source</h3>
            <div className="flex flex-wrap gap-2">
              {sources.map((source) => (
                <button
                  key={source.id}
                  onClick={() => toggleArrayFilter('sources', source.id)}
                  className={`px-3 py-1.5 text-sm rounded-lg font-medium transition ${
                    filters.sources?.includes(source.id)
                      ? 'bg-orange-100 text-orange-700 border-2 border-orange-500'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {source.name}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-6">
            <div>
              <h3 className="font-semibold text-slate-800 mb-3">Country</h3>
              <div className="space-y-2">
                {COUNTRIES.map((country) => (
                  <label key={country} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={filters.countries?.includes(country)}
                      onChange={() => toggleArrayFilter('countries', country)}
                      className="w-4 h-4 rounded border-slate-300 text-orange-500"
                    />
                    <span className="text-sm text-slate-700">{country}</span>
                  </label>
                ))}
              </div>
            </div>

            <div>
              <h3 className="font-semibold text-slate-800 mb-3">City</h3>
              <div className="space-y-2 max-h-48 overflow-y-auto">
                {INDIAN_CITIES.map((city) => (
                  <label key={city} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={filters.cities?.includes(city)}
                      onChange={() => toggleArrayFilter('cities', city)}
                      className="w-4 h-4 rounded border-slate-300 text-orange-500"
                    />
                    <span className="text-sm text-slate-700">{city}</span>
                  </label>
                ))}
              </div>
            </div>
          </div>

          <div>
            <h3 className="font-semibold text-slate-800 mb-3">Current Owner</h3>
            <div className="flex flex-wrap gap-2">
              {users.map((user) => (
                <button
                  key={user.id}
                  onClick={() => toggleArrayFilter('currentOwners', user.id)}
                  className={`px-3 py-1.5 text-sm rounded-lg font-medium transition ${
                    filters.currentOwners?.includes(user.id)
                      ? 'bg-purple-100 text-purple-700 border-2 border-purple-500'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {user.full_name}
                </button>
              ))}
            </div>
          </div>

          <div>
            <h3 className="font-semibold text-slate-800 mb-3">Re-enquired Status</h3>
            <div className="flex gap-2">
              <button
                onClick={() => setFilters({ ...filters, isReEnquired: true })}
                className={`px-4 py-2 text-sm rounded-lg font-medium transition ${
                  filters.isReEnquired === true
                    ? 'bg-purple-100 text-purple-700 border-2 border-purple-500'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                Re-enquired Only
              </button>
              <button
                onClick={() => setFilters({ ...filters, isReEnquired: false })}
                className={`px-4 py-2 text-sm rounded-lg font-medium transition ${
                  filters.isReEnquired === false
                    ? 'bg-slate-200 text-slate-700 border-2 border-slate-500'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                New Only
              </button>
              <button
                onClick={() => setFilters({ ...filters, isReEnquired: null })}
                className={`px-4 py-2 text-sm rounded-lg font-medium transition ${
                  filters.isReEnquired === null || filters.isReEnquired === undefined
                    ? 'bg-slate-200 text-slate-700 border-2 border-slate-500'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                All
              </button>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-6">
            <div>
              <h3 className="font-semibold text-slate-800 mb-3">Call Count Range</h3>
              <div className="flex gap-2 items-center">
                <input
                  type="number"
                  min="0"
                  placeholder="Min"
                  value={filters.callCountMin || ''}
                  onChange={(e) => setFilters({ ...filters, callCountMin: e.target.value ? parseInt(e.target.value) : undefined })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent outline-none"
                />
                <span className="text-slate-500">to</span>
                <input
                  type="number"
                  min="0"
                  placeholder="Max"
                  value={filters.callCountMax || ''}
                  onChange={(e) => setFilters({ ...filters, callCountMax: e.target.value ? parseInt(e.target.value) : undefined })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent outline-none"
                />
              </div>
            </div>

            <div>
              <h3 className="font-semibold text-slate-800 mb-3">Lead Age (Days)</h3>
              <div className="flex gap-2 items-center">
                <input
                  type="number"
                  min="0"
                  placeholder="Min"
                  value={filters.leadAgeMin || ''}
                  onChange={(e) => setFilters({ ...filters, leadAgeMin: e.target.value ? parseInt(e.target.value) : undefined })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent outline-none"
                />
                <span className="text-slate-500">to</span>
                <input
                  type="number"
                  min="0"
                  placeholder="Max"
                  value={filters.leadAgeMax || ''}
                  onChange={(e) => setFilters({ ...filters, leadAgeMax: e.target.value ? parseInt(e.target.value) : undefined })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent outline-none"
                />
              </div>
            </div>
          </div>

          <div>
            <h3 className="font-semibold text-slate-800 mb-3">Date Range</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-slate-600 mb-1">From</label>
                <input
                  type="date"
                  value={filters.dateFrom || ''}
                  onChange={(e) => setFilters({ ...filters, dateFrom: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent outline-none"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-600 mb-1">To</label>
                <input
                  type="date"
                  value={filters.dateTo || ''}
                  onChange={(e) => setFilters({ ...filters, dateTo: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent outline-none"
                />
              </div>
            </div>
          </div>
        </div>

        <div className="sticky bottom-0 bg-white border-t border-slate-200 px-6 py-4 flex gap-3">
          <button
            onClick={clearAll}
            className="px-6 py-3 border border-slate-300 text-slate-700 rounded-lg font-semibold hover:bg-slate-50 transition"
          >
            Clear All
          </button>
          <button
            onClick={onClose}
            className="flex-1 px-6 py-3 border border-slate-300 text-slate-700 rounded-lg font-semibold hover:bg-slate-50 transition"
          >
            Cancel
          </button>
          <button
            onClick={handleApply}
            className="flex-1 px-6 py-3 bg-orange-500 text-white rounded-lg font-semibold hover:bg-orange-600 transition"
          >
            Apply Filters
          </button>
        </div>
      </div>
    </div>
  );
}
