import { useState, useEffect } from 'react';
import { Webhook, Plus, Copy, Check, RotateCw, Eye, EyeOff, Trash2, Play, Settings } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { AddWebhookConfigModal } from './AddWebhookConfigModal';
import { AddIntegrationEndpointModal } from './AddIntegrationEndpointModal';
import { WebhookLogsViewer } from './WebhookLogsViewer';

interface WebhookConfig {
  id: string;
  webhook_name: string;
  api_key: string;
  hmac_secret: string;
  is_enabled: boolean;
  rate_limit_per_minute: number;
  created_at: string;
}

interface IntegrationEndpoint {
  id: string;
  endpoint_name: string;
  endpoint_type: string;
  endpoint_url: string;
  is_active: boolean;
  created_at: string;
}

interface WebhookSource {
  id: string;
  source_name: string;
  source_type: string;
  is_active: boolean;
  created_at: string;
}

type ActiveView = 'incoming' | 'outgoing' | 'sources' | 'logs';

export function WebhookIntegrations() {
  const [activeView, setActiveView] = useState<ActiveView>('incoming');
  const [webhookConfigs, setWebhookConfigs] = useState<WebhookConfig[]>([]);
  const [endpoints, setEndpoints] = useState<IntegrationEndpoint[]>([]);
  const [sources, setSources] = useState<WebhookSource[]>([]);
  const [loading, setLoading] = useState(false);
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [revealedSecrets, setRevealedSecrets] = useState<Set<string>>(new Set());
  const [showAddConfigModal, setShowAddConfigModal] = useState(false);
  const [showAddEndpointModal, setShowAddEndpointModal] = useState(false);

  const webhookInboundUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/webhook-inbound`;

  useEffect(() => {
    fetchWebhookConfigs();
    fetchIntegrationEndpoints();
    fetchWebhookSources();
  }, []);

  const fetchWebhookConfigs = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('webhook_configurations')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setWebhookConfigs(data || []);
    } catch (error) {
      console.error('Error fetching webhook configs:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchIntegrationEndpoints = async () => {
    try {
      const { data, error } = await supabase
        .from('integration_endpoints')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setEndpoints(data || []);
    } catch (error) {
      console.error('Error fetching endpoints:', error);
    }
  };

  const fetchWebhookSources = async () => {
    try {
      const { data, error } = await supabase
        .from('webhook_sources')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setSources(data || []);
    } catch (error) {
      console.error('Error fetching sources:', error);
    }
  };

  const copyToClipboard = async (text: string, fieldId: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedField(fieldId);
      setTimeout(() => setCopiedField(null), 2000);
    } catch (error) {
      console.error('Failed to copy:', error);
    }
  };

  const toggleSecretVisibility = (configId: string) => {
    const newRevealed = new Set(revealedSecrets);
    if (newRevealed.has(configId)) {
      newRevealed.delete(configId);
    } else {
      newRevealed.add(configId);
    }
    setRevealedSecrets(newRevealed);
  };

  const toggleConfigStatus = async (configId: string, currentStatus: boolean) => {
    try {
      const { error } = await supabase
        .from('webhook_configurations')
        .update({ is_enabled: !currentStatus })
        .eq('id', configId);

      if (error) throw error;
      await fetchWebhookConfigs();
    } catch (error) {
      console.error('Error toggling config status:', error);
    }
  };

  const toggleEndpointStatus = async (endpointId: string, currentStatus: boolean) => {
    try {
      const { error } = await supabase
        .from('integration_endpoints')
        .update({ is_active: !currentStatus })
        .eq('id', endpointId);

      if (error) throw error;
      await fetchIntegrationEndpoints();
    } catch (error) {
      console.error('Error toggling endpoint status:', error);
    }
  };

  const deleteConfig = async (configId: string) => {
    if (!confirm('Are you sure you want to delete this webhook configuration?')) return;

    try {
      const { error } = await supabase
        .from('webhook_configurations')
        .delete()
        .eq('id', configId);

      if (error) throw error;
      await fetchWebhookConfigs();
    } catch (error) {
      console.error('Error deleting config:', error);
    }
  };

  const deleteEndpoint = async (endpointId: string) => {
    if (!confirm('Are you sure you want to delete this integration endpoint?')) return;

    try {
      const { error } = await supabase
        .from('integration_endpoints')
        .delete()
        .eq('id', endpointId);

      if (error) throw error;
      await fetchIntegrationEndpoints();
    } catch (error) {
      console.error('Error deleting endpoint:', error);
    }
  };

  const testWebhook = async () => {
    alert('Webhook test functionality will trigger a test payload to your configured endpoints.');
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Webhook Integrations</h2>
          <p className="text-sm text-gray-600 mt-1">
            Configure incoming webhooks and outgoing integrations for lead automation
          </p>
        </div>
      </div>

      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveView('incoming')}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeView === 'incoming'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Incoming Webhooks
          </button>
          <button
            onClick={() => setActiveView('outgoing')}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeView === 'outgoing'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Outgoing Integrations
          </button>
          <button
            onClick={() => setActiveView('sources')}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeView === 'sources'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Lead Sources
          </button>
          <button
            onClick={() => setActiveView('logs')}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeView === 'logs'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Webhook Logs
          </button>
        </nav>
      </div>

      {activeView === 'incoming' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">Incoming Webhook Configuration</h3>
            <button
              onClick={() => setShowAddConfigModal(true)}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              <Plus className="w-4 h-4" />
              Add Configuration
            </button>
          </div>

          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <Webhook className="w-5 h-5 text-blue-600 mt-0.5" />
              <div className="flex-1">
                <h4 className="font-medium text-blue-900 mb-2">Webhook Endpoint URL</h4>
                <div className="flex items-center gap-2 bg-white p-3 rounded border border-blue-200">
                  <code className="text-sm text-gray-700 flex-1 break-all">{webhookInboundUrl}</code>
                  <button
                    onClick={() => copyToClipboard(webhookInboundUrl, 'webhook-url')}
                    className="p-2 hover:bg-gray-100 rounded"
                  >
                    {copiedField === 'webhook-url' ? (
                      <Check className="w-4 h-4 text-green-600" />
                    ) : (
                      <Copy className="w-4 h-4 text-gray-600" />
                    )}
                  </button>
                </div>
                <p className="text-sm text-blue-700 mt-2">
                  Use this URL to receive leads from external sources. Each configuration below provides unique credentials.
                </p>
              </div>
            </div>
          </div>

          {loading ? (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
            </div>
          ) : webhookConfigs.length === 0 ? (
            <div className="text-center py-12 bg-gray-50 rounded-lg border border-gray-200">
              <Webhook className="w-12 h-12 text-gray-400 mx-auto mb-3" />
              <p className="text-gray-600">No webhook configurations yet</p>
              <button
                onClick={() => setShowAddConfigModal(true)}
                className="mt-4 text-blue-600 hover:text-blue-700 font-medium"
              >
                Create your first configuration
              </button>
            </div>
          ) : (
            <div className="space-y-4">
              {webhookConfigs.map((config) => (
                <div key={config.id} className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <div className={`w-2 h-2 rounded-full ${config.is_enabled ? 'bg-green-500' : 'bg-gray-400'}`}></div>
                      <h4 className="font-semibold text-gray-900">{config.webhook_name}</h4>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => toggleConfigStatus(config.id, config.is_enabled)}
                        className={`px-3 py-1 text-sm rounded ${
                          config.is_enabled
                            ? 'bg-green-100 text-green-700 hover:bg-green-200'
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                      >
                        {config.is_enabled ? 'Enabled' : 'Disabled'}
                      </button>
                      <button
                        onClick={() => deleteConfig(config.id)}
                        className="p-2 text-red-600 hover:bg-red-50 rounded"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
                      <div className="flex items-center gap-2 bg-gray-50 p-2 rounded border border-gray-200">
                        <code className="text-sm text-gray-700 flex-1 truncate">{config.api_key}</code>
                        <button
                          onClick={() => copyToClipboard(config.api_key, `api-key-${config.id}`)}
                          className="p-1 hover:bg-gray-200 rounded"
                        >
                          {copiedField === `api-key-${config.id}` ? (
                            <Check className="w-4 h-4 text-green-600" />
                          ) : (
                            <Copy className="w-4 h-4 text-gray-600" />
                          )}
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">HMAC Secret</label>
                      <div className="flex items-center gap-2 bg-gray-50 p-2 rounded border border-gray-200">
                        <code className="text-sm text-gray-700 flex-1 truncate">
                          {revealedSecrets.has(config.id) ? config.hmac_secret : '••••••••••••••••'}
                        </code>
                        <button
                          onClick={() => toggleSecretVisibility(config.id)}
                          className="p-1 hover:bg-gray-200 rounded"
                        >
                          {revealedSecrets.has(config.id) ? (
                            <EyeOff className="w-4 h-4 text-gray-600" />
                          ) : (
                            <Eye className="w-4 h-4 text-gray-600" />
                          )}
                        </button>
                        {revealedSecrets.has(config.id) && (
                          <button
                            onClick={() => copyToClipboard(config.hmac_secret, `hmac-${config.id}`)}
                            className="p-1 hover:bg-gray-200 rounded"
                          >
                            {copiedField === `hmac-${config.id}` ? (
                              <Check className="w-4 h-4 text-green-600" />
                            ) : (
                              <Copy className="w-4 h-4 text-gray-600" />
                            )}
                          </button>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="mt-3 flex items-center justify-between text-sm text-gray-600">
                    <span>Rate Limit: {config.rate_limit_per_minute} requests/minute</span>
                    <span>Created: {new Date(config.created_at).toLocaleDateString()}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {activeView === 'outgoing' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">Outgoing Integration Endpoints</h3>
            <button
              onClick={() => setShowAddEndpointModal(true)}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              <Plus className="w-4 h-4" />
              Add Endpoint
            </button>
          </div>

          {endpoints.length === 0 ? (
            <div className="text-center py-12 bg-gray-50 rounded-lg border border-gray-200">
              <Settings className="w-12 h-12 text-gray-400 mx-auto mb-3" />
              <p className="text-gray-600">No integration endpoints configured</p>
              <button
                onClick={() => setShowAddEndpointModal(true)}
                className="mt-4 text-blue-600 hover:text-blue-700 font-medium"
              >
                Add your first endpoint
              </button>
            </div>
          ) : (
            <div className="space-y-4">
              {endpoints.map((endpoint) => (
                <div key={endpoint.id} className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div className={`w-2 h-2 rounded-full ${endpoint.is_active ? 'bg-green-500' : 'bg-gray-400'}`}></div>
                      <div>
                        <h4 className="font-semibold text-gray-900">{endpoint.endpoint_name}</h4>
                        <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-blue-100 text-blue-700 mt-1">
                          {endpoint.endpoint_type}
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => toggleEndpointStatus(endpoint.id, endpoint.is_active)}
                        className={`px-3 py-1 text-sm rounded ${
                          endpoint.is_active
                            ? 'bg-green-100 text-green-700 hover:bg-green-200'
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                      >
                        {endpoint.is_active ? 'Active' : 'Inactive'}
                      </button>
                      <button
                        onClick={() => deleteEndpoint(endpoint.id)}
                        className="p-2 text-red-600 hover:bg-red-50 rounded"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  <div className="bg-gray-50 p-3 rounded border border-gray-200">
                    <p className="text-sm text-gray-700 font-mono break-all">{endpoint.endpoint_url}</p>
                  </div>

                  <div className="mt-3 text-sm text-gray-600">
                    Created: {new Date(endpoint.created_at).toLocaleDateString()}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {activeView === 'sources' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">Lead Sources</h3>
            <p className="text-sm text-gray-600">Manage lead source configurations and field mappings</p>
          </div>

          {sources.length === 0 ? (
            <div className="text-center py-12 bg-gray-50 rounded-lg border border-gray-200">
              <p className="text-gray-600">No lead sources configured</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {sources.map((source) => (
                <div key={source.id} className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-semibold text-gray-900">{source.source_name}</h4>
                    <div className={`w-2 h-2 rounded-full ${source.is_active ? 'bg-green-500' : 'bg-gray-400'}`}></div>
                  </div>
                  <p className="text-sm text-gray-600">{source.source_type}</p>
                  <p className="text-xs text-gray-500 mt-2">
                    Created: {new Date(source.created_at).toLocaleDateString()}
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {activeView === 'logs' && <WebhookLogsViewer />}

      {showAddConfigModal && (
        <AddWebhookConfigModal
          onClose={() => setShowAddConfigModal(false)}
          onSuccess={() => {
            fetchWebhookConfigs();
            setShowAddConfigModal(false);
          }}
        />
      )}

      {showAddEndpointModal && (
        <AddIntegrationEndpointModal
          onClose={() => setShowAddEndpointModal(false)}
          onSuccess={() => {
            fetchIntegrationEndpoints();
            setShowAddEndpointModal(false);
          }}
        />
      )}
    </div>
  );
}
