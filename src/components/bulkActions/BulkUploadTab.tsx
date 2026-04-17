import { useState, useEffect } from 'react';
import { Download, FileText, CheckCircle, XCircle, AlertCircle, Clock, Loader2, RefreshCw, Search } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { downloadCSV } from '../../lib/csvUtils';

interface BulkUploadJob {
  id: string;
  filename: string;
  file_size_bytes: number;
  total_rows: number;
  processed_rows: number;
  successful_rows: number;
  failed_rows: number;
  skipped_rows: number;
  duplicate_handling_strategy: string;
  status: string;
  error_log: any[];
  uploaded_at: string;
  completed_at: string | null;
  user_id: string;
  profiles?: { full_name: string };
}

export function BulkUploadTab() {
  const [jobs, setJobs] = useState<BulkUploadJob[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    loadUploadHistory();
  }, []);

  const loadUploadHistory = async () => {
    setIsLoading(true);
    try {
      const { data, error } = await supabase
        .from('bulk_upload_jobs')
        .select('*, profiles:user_id(full_name)')
        .order('uploaded_at', { ascending: false })
        .limit(100);

      if (error) throw error;

      setJobs(data || []);
    } catch (error) {
      console.error('Error loading upload history:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      completed: 'bg-green-100 text-green-800',
      failed: 'bg-red-100 text-red-800',
      processing: 'bg-blue-100 text-blue-800',
      validating: 'bg-yellow-100 text-yellow-800',
      cancelled: 'bg-slate-100 text-slate-800',
    };

    return (
      <span className={`px-3 py-1 text-xs font-medium rounded-full ${styles[status as keyof typeof styles] || 'bg-slate-100 text-slate-800'}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    );
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const handleDownloadErrorReport = (job: BulkUploadJob) => {
    if (job.error_log && job.error_log.length > 0) {
      const errorData = job.error_log.map((err: any) => ({
        'Row Number': err.rowNumber,
        ...err.data,
        Errors: err.errors.join('; '),
      }));

      const headers = Object.keys(errorData[0]);
      const csvContent = [
        headers.join(','),
        ...errorData.map((row: any) =>
          headers.map((h) => `"${(row[h] || '').toString().replace(/"/g, '""')}"`).join(',')
        ),
      ].join('\n');

      downloadCSV(csvContent, `upload_errors_${job.id}_${new Date().toISOString().split('T')[0]}.csv`);
    }
  };

  const filteredJobs = jobs.filter(job =>
    job.filename.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="h-full flex flex-col bg-slate-50">
      <div className="bg-white border-b border-slate-200 p-4">
        <div className="flex items-center justify-between gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search by file name..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
            />
          </div>
          <button
            onClick={loadUploadHistory}
            className="flex items-center gap-2 px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg transition"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-auto p-6">
        {isLoading ? (
          <div className="flex items-center justify-center h-64">
            <Loader2 className="w-8 h-8 text-orange-500 animate-spin" />
          </div>
        ) : filteredJobs.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-center">
            <FileText className="w-16 h-16 text-slate-300 mb-4" />
            <h3 className="text-lg font-medium text-slate-900 mb-2">No Upload History</h3>
            <p className="text-slate-600">
              {searchQuery ? 'No uploads found matching your search.' : 'You haven\'t performed any bulk uploads yet.'}
            </p>
          </div>
        ) : (
          <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      File Name
                    </th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Upload Date
                    </th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Uploaded By
                    </th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Total
                    </th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Successful
                    </th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Failed
                    </th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Skipped
                    </th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Success Rate
                    </th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Stage
                    </th>
                    <th className="text-center px-4 py-3 text-xs font-semibold text-slate-600 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200">
                  {filteredJobs.map((job) => {
                    const successRate = job.total_rows > 0
                      ? Math.round((job.successful_rows / job.total_rows) * 100)
                      : 0;
                    const hasErrors = job.error_log && job.error_log.length > 0;

                    return (
                      <tr key={job.id} className="hover:bg-slate-50 transition">
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-2">
                            <FileText className="w-4 h-4 text-slate-400" />
                            <span className="text-sm text-slate-900 font-medium">{job.filename}</span>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-sm text-slate-600">
                          {formatDate(job.uploaded_at)}
                        </td>
                        <td className="px-4 py-4 text-sm text-slate-600">
                          {job.profiles?.full_name || 'Unknown'}
                        </td>
                        <td className="px-4 py-4 text-center">
                          <span className="text-sm font-semibold text-slate-900">{job.total_rows}</span>
                        </td>
                        <td className="px-4 py-4 text-center">
                          <div className="flex items-center justify-center gap-1">
                            <CheckCircle className="w-4 h-4 text-green-600" />
                            <span className="text-sm font-semibold text-green-700">{job.successful_rows}</span>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-center">
                          <div className="flex items-center justify-center gap-1">
                            <XCircle className="w-4 h-4 text-red-600" />
                            <span className="text-sm font-semibold text-red-700">{job.failed_rows}</span>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-center">
                          <div className="flex items-center justify-center gap-1">
                            <AlertCircle className="w-4 h-4 text-yellow-600" />
                            <span className="text-sm font-semibold text-yellow-700">{job.skipped_rows}</span>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-center">
                          <div className="flex flex-col items-center gap-1">
                            <span className="text-sm font-semibold text-slate-900">{successRate}%</span>
                            <div className="w-16 bg-slate-200 rounded-full h-1.5">
                              <div
                                className={`h-1.5 rounded-full transition-all ${
                                  successRate >= 90 ? 'bg-green-600' :
                                  successRate >= 70 ? 'bg-yellow-600' : 'bg-red-600'
                                }`}
                                style={{ width: `${successRate}%` }}
                              />
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-center">
                          {getStatusBadge(job.status)}
                        </td>
                        <td className="px-4 py-4 text-center">
                          <div className="flex items-center justify-center gap-2">
                            {hasErrors && (
                              <button
                                onClick={() => handleDownloadErrorReport(job)}
                                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition"
                                title="Download Error Report"
                              >
                                <Download className="w-4 h-4" />
                              </button>
                            )}
                            {!hasErrors && job.status === 'completed' && (
                              <span className="text-slate-400 text-xs">No errors</span>
                            )}
                            {job.status === 'processing' && (
                              <Clock className="w-4 h-4 text-blue-500 animate-pulse" />
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
