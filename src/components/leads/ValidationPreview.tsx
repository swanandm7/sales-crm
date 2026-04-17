import { useState } from 'react';
import { CheckCircle, XCircle, AlertCircle, ChevronDown, ChevronUp } from 'lucide-react';

interface ValidationError {
  field: string;
  message: string;
}

interface ValidatedRow {
  rowNumber: number;
  data: Record<string, string>;
  isValid: boolean;
  isDuplicate: boolean;
  errors: ValidationError[];
  existingLeadId?: string;
}

interface ValidationPreviewProps {
  validatedRows: ValidatedRow[];
  columnMapping: Record<string, string>;
}

export default function ValidationPreview({
  validatedRows,
  columnMapping,
}: ValidationPreviewProps) {
  const [filter, setFilter] = useState<'all' | 'valid' | 'errors' | 'duplicates'>('all');
  const [expandedRows, setExpandedRows] = useState<Set<number>>(new Set());

  const validCount = validatedRows.filter((r) => r.isValid && !r.isDuplicate).length;
  const errorCount = validatedRows.filter((r) => !r.isValid).length;
  const duplicateCount = validatedRows.filter((r) => r.isDuplicate).length;

  const filteredRows = validatedRows.filter((row) => {
    if (filter === 'valid') return row.isValid && !row.isDuplicate;
    if (filter === 'errors') return !row.isValid;
    if (filter === 'duplicates') return row.isDuplicate;
    return true;
  });

  const displayedRows = filteredRows.slice(0, 100);

  const toggleRowExpansion = (rowNumber: number) => {
    const newExpanded = new Set(expandedRows);
    if (newExpanded.has(rowNumber)) {
      newExpanded.delete(rowNumber);
    } else {
      newExpanded.add(rowNumber);
    }
    setExpandedRows(newExpanded);
  };

  const getStatusIcon = (row: ValidatedRow) => {
    if (!row.isValid) {
      return <XCircle className="w-5 h-5 text-red-500" />;
    }
    if (row.isDuplicate) {
      return <AlertCircle className="w-5 h-5 text-yellow-500" />;
    }
    return <CheckCircle className="w-5 h-5 text-green-500" />;
  };

  const getStatusText = (row: ValidatedRow) => {
    if (!row.isValid) return 'Invalid';
    if (row.isDuplicate) return 'Duplicate';
    return 'Valid';
  };

  const getStatusColor = (row: ValidatedRow) => {
    if (!row.isValid) return 'text-red-600 bg-red-50';
    if (row.isDuplicate) return 'text-yellow-600 bg-yellow-50';
    return 'text-green-600 bg-green-50';
  };

  const reverseMapping = Object.entries(columnMapping).reduce((acc, [systemField, csvField]) => {
    acc[csvField] = systemField;
    return acc;
  }, {} as Record<string, string>);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-green-700 font-medium">Valid Rows</p>
              <p className="text-2xl font-bold text-green-900">{validCount}</p>
            </div>
            <CheckCircle className="w-8 h-8 text-green-500" />
          </div>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-yellow-700 font-medium">Duplicates</p>
              <p className="text-2xl font-bold text-yellow-900">{duplicateCount}</p>
            </div>
            <AlertCircle className="w-8 h-8 text-yellow-500" />
          </div>
        </div>

        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-red-700 font-medium">Errors</p>
              <p className="text-2xl font-bold text-red-900">{errorCount}</p>
            </div>
            <XCircle className="w-8 h-8 text-red-500" />
          </div>
        </div>
      </div>

      <div className="flex gap-2">
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            filter === 'all'
              ? 'bg-blue-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          }`}
        >
          All ({validatedRows.length})
        </button>
        <button
          onClick={() => setFilter('valid')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            filter === 'valid'
              ? 'bg-green-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          }`}
        >
          Valid ({validCount})
        </button>
        <button
          onClick={() => setFilter('duplicates')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            filter === 'duplicates'
              ? 'bg-yellow-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          }`}
        >
          Duplicates ({duplicateCount})
        </button>
        <button
          onClick={() => setFilter('errors')}
          className={`px-4 py-2 rounded-lg font-medium transition-colors ${
            filter === 'errors'
              ? 'bg-red-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          }`}
        >
          Errors ({errorCount})
        </button>
      </div>

      <div className="border border-gray-200 rounded-lg overflow-hidden">
        <div className="max-h-96 overflow-y-auto">
          <table className="w-full">
            <thead className="bg-gray-50 sticky top-0">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider w-16">
                  Row
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider w-32">
                  Status
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                  Data Preview
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider w-16"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {displayedRows.map((row) => (
                <>
                  <tr
                    key={row.rowNumber}
                    className="hover:bg-gray-50 cursor-pointer"
                    onClick={() => toggleRowExpansion(row.rowNumber)}
                  >
                    <td className="px-4 py-3 text-sm text-gray-900">{row.rowNumber}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        {getStatusIcon(row)}
                        <span className={`text-sm font-medium ${getStatusColor(row)} px-2 py-1 rounded`}>
                          {getStatusText(row)}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-900">
                      <div className="flex gap-4">
                        {Object.entries(columnMapping)
                          .slice(0, 3)
                          .map(([systemField, csvField]) => (
                            <div key={systemField}>
                              <span className="font-medium">{systemField}:</span>{' '}
                              {row.data[csvField] || '-'}
                            </div>
                          ))}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-500">
                      {expandedRows.has(row.rowNumber) ? (
                        <ChevronUp className="w-4 h-4" />
                      ) : (
                        <ChevronDown className="w-4 h-4" />
                      )}
                    </td>
                  </tr>
                  {expandedRows.has(row.rowNumber) && (
                    <tr>
                      <td colSpan={4} className="px-4 py-3 bg-gray-50">
                        <div className="space-y-3">
                          <div>
                            <h5 className="font-medium text-gray-900 mb-2">Full Data</h5>
                            <div className="grid grid-cols-2 gap-2">
                              {Object.entries(row.data).map(([key, value]) => (
                                <div key={key} className="text-sm">
                                  <span className="font-medium text-gray-700">
                                    {reverseMapping[key] || key}:
                                  </span>{' '}
                                  <span className="text-gray-900">{value || '-'}</span>
                                </div>
                              ))}
                            </div>
                          </div>

                          {row.errors.length > 0 && (
                            <div>
                              <h5 className="font-medium text-red-900 mb-2">Errors</h5>
                              <div className="space-y-1">
                                {row.errors.map((error, idx) => (
                                  <div key={idx} className="text-sm text-red-700">
                                    <span className="font-medium">{error.field}:</span> {error.message}
                                  </div>
                                ))}
                              </div>
                            </div>
                          )}

                          {row.isDuplicate && (
                            <div className="bg-yellow-50 border border-yellow-200 rounded p-2">
                              <p className="text-sm text-yellow-800">
                                This mobile number already exists in the system. The duplicate
                                handling strategy will be applied during import.
                              </p>
                            </div>
                          )}
                        </div>
                      </td>
                    </tr>
                  )}
                </>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {filteredRows.length > 100 && (
        <p className="text-sm text-gray-600 text-center">
          Showing first 100 of {filteredRows.length} rows. All rows will be processed during upload.
        </p>
      )}
    </div>
  );
}
