// @ts-nocheck
import { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import { logEmailSent } from '../../services/activityLogger';
import { openEmailClient } from '../../lib/communicationUtils'; // Kept for reference or other uses if needed
import { TemplateSelectionModal } from '../common/TemplateSelectionModal';

interface EmailInteractionModalProps {
  leadId: string;
  leadName: string;
  leadEmail: string;
  leadData: any;
  onClose: () => void;
  onSuccess: () => void;
}

export function EmailInteractionModal({
  leadId,
  leadName,
  leadEmail,
  leadData,
  onClose,
  onSuccess,
}: EmailInteractionModalProps) {
  const { user } = useAuth();
  const { showError, showSuccess } = useToast();
  const [loading, setLoading] = useState(false);

  async function handleTemplateConfirm(
    template: any,
    personalizedContent: { subject?: string; body: string }
  ) {
    if (!user) return;

    setLoading(true);

    try {
      const { data: lead } = await supabase
        .from('leads')
        .select('organization_id')
        .eq('id', leadId)
        .single();

      if (!lead?.organization_id) {
        throw new Error('Organization not found for this lead.');
      }

      const bodyHtml = `<p>${personalizedContent.body.replace(/\n/g, '<br/>')}</p>`;

      const { error: queueError } = await supabase.from('email_queue').insert({
        organization_id: lead.organization_id,
        to_email: leadEmail,
        subject: personalizedContent.subject || 'No Subject',
        body_text: personalizedContent.body,
        body_html: bodyHtml,
        template_id: null, // Avoid FK violation since these are message_templates, not system email_templates
        status: 'pending'
      });

      if (queueError) {
        throw queueError;
      }

      await supabase.from('lead_interactions').insert({
        lead_id: leadId,
        user_id: user.id,
        interaction_type: 'email',
        interaction_notes: null,
        interaction_metadata: {
          subject: personalizedContent.subject,
          message: personalizedContent.body,
          template_id: template.id === 'custom-blank-template' ? null : template.id,
          template_name: template.id === 'custom-blank-template' ? 'Custom Email' : template.template_name,
        },
      });

      const { data: profile } = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .single();

      await logEmailSent(
        leadId,
        user.id,
        profile?.full_name || 'Unknown User',
        personalizedContent.subject || '',
        personalizedContent.body
      );

      if (template.id !== 'custom-blank-template') {
        await supabase.from('message_template_usage_log').insert({
          template_id: template.id,
          lead_id: leadId,
          user_id: user.id,
          template_content_used: `${template.subject || ''}\n\n${template.body_content}`,
          actual_content_sent: `${personalizedContent.subject || ''}\n\n${personalizedContent.body}`,
          was_edited: false,
        });
      }

      setLoading(false);
      showSuccess('Email queued successfully!');
      onSuccess();
      onClose();
    } catch (err: any) {
      console.error('Error queuing email:', err);
      setLoading(false);
      showError('Failed to queue email. Please try again.');
    }
  }

  return (
    <TemplateSelectionModal
      type="email"
      leadData={leadData}
      onClose={onClose}
      onConfirm={handleTemplateConfirm}
      title={
        <div className="flex flex-col">
          <span>Send Email - {leadName}</span>
          <span className="text-sm font-normal text-slate-500 mt-1">To: {leadEmail}</span>
        </div>
      }
      confirmButtonText="Send Email"
    />
  );
}
