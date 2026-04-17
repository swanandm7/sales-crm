import { CheckCircle, XCircle, AlertCircle, Loader2 } from 'lucide-react';
import { ProcessingProgress } from '../../lib/bulkUploadProcessor';

interface UploadProgressProps {
  progress: ProcessingProgress;
  isComplete: boolean;
}

export default function UploadProgress({ progress, isComplete }: UploadProgressProps) {
  const percentage = Math.round((progress.processedRows / progress.totalRows) * 100);

  const formatTime = (ms: number): string => {
    const seconds = Math.floor(ms / 1000);
    if (seconds < 60) return `${seconds}s`;
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}m ${remainingSeconds}s`;
  };

  return (
    <div className="space-y-6">
      <div className="text-center">
        {isComplete ? (
          <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-4">
            <CheckCircle className="w-10 h-10 text-green-600" />
          </div>
        ) : (
          <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-4">
            <Loader2 className="w-10 h-10 text-blue-600 animate-spin" />
          </div>
        )}

        <h3 className="text-xl font-semibold text-gray-900 mb-2">
          {isComplete ? 'Upload Complete!' : 'Processing Upload...'}
        </h3>
        <p className="text-gray-600">
          {isComplete
            ? `Successfully processed ${progress.totalRows} rows`
            : `Processing batch ${progress.currentBatch} of ${progress.totalBatches}`}
        </p>
      </div>

      <div className="space-y-2">
        <div className="flex justify-between text-sm text-gray-700">
          <span className="font-medium">Overall Progress</span>
          <span className="font-medium">{percentage}%</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
          <div
            className={`h-full rounded-full transition-all duration-300 ${
              isComplete ? 'bg-green-600' : 'bg-blue-600'
            }`}
            style={{ width: `${percentage}%` }}
          />
        </div>
        <div className="flex justify-between text-xs text-gray-500">
          <span>
            {progress.processedRows} / {progress.totalRows} rows
          </span>
          {!isComplete && progress.estimatedTimeRemaining && (
            <span>~{formatTime(progress.estimatedTimeRemaining)} remaining</span>
          )}
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="flex items-center gap-3">
            <div className="flex-shrink-0">
              <CheckCircle className="w-6 h-6 text-green-600" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-green-900">Successful</p>
              <p className="text-2xl font-bold text-green-700">{progress.successfulRows}</p>
            </div>
          </div>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center gap-3">
            <div className="flex-shrink-0">
              <AlertCircle className="w-6 h-6 text-yellow-600" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-yellow-900">Skipped</p>
              <p className="text-2xl font-bold text-yellow-700">{progress.skippedRows}</p>
            </div>
          </div>
        </div>

        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-3">
            <div className="flex-shrink-0">
              <XCircle className="w-6 h-6 text-red-600" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-red-900">Failed</p>
              <p className="text-2xl font-bold text-red-700">{progress.failedRows}</p>
            </div>
          </div>
        </div>
      </div>

      {isComplete && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <CheckCircle className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
            <div className="flex-1">
              <p className="font-medium text-blue-900 mb-1">Processing Summary</p>
              <ul className="text-sm text-blue-800 space-y-1">
                <li>
                  {progress.successfulRows} leads were successfully imported to the system
                </li>
                {progress.skippedRows > 0 && (
                  <li>{progress.skippedRows} duplicate leads were skipped as per your selection</li>
                )}
                {progress.failedRows > 0 && (
                  <li>
                    {progress.failedRows} leads failed validation and were not imported. Download
                    the error report for details.
                  </li>
                )}
              </ul>
            </div>
          </div>
        </div>
      )}

      {!isComplete && (
        <div className="text-center">
          <p className="text-sm text-gray-500">
            Please keep this window open while the upload is being processed...
          </p>
        </div>
      )}
    </div>
  );
}
