export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type OrganizationStatus = 'active' | 'suspended'
export type InvitationStatus = 'pending' | 'accepted' | 'expired' | 'cancelled'
export type UserStatus = 'pending' | 'active' | 'disabled'
export type OrganizationTier = 'starter' | 'pro' | 'enterprise' | 'custom'

export interface Database {
  public: {
    Tables: {
      organizations: {
        Row: {
          id: string
          name: string
          slug: string
          owner_id: string | null
          status: OrganizationStatus
          tier: OrganizationTier
          max_users: number | null
          logo_url: string | null
          settings: Json
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          slug: string
          owner_id?: string | null
          status?: OrganizationStatus
          tier?: OrganizationTier
          max_users?: number | null
          logo_url?: string | null
          settings?: Json
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          slug?: string
          owner_id?: string | null
          status?: OrganizationStatus
          tier?: OrganizationTier
          max_users?: number | null
          logo_url?: string | null
          settings?: Json
          created_at?: string
          updated_at?: string
        }
      }
      organization_members: {
        Row: {
          id: string
          organization_id: string
          profile_id: string
          role_id: string
          invited_by: string | null
          joined_at: string
          created_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          profile_id: string
          role_id: string
          invited_by?: string | null
          joined_at?: string
          created_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          profile_id?: string
          role_id?: string
          invited_by?: string | null
          joined_at?: string
          created_at?: string
        }
      }
      invitations: {
        Row: {
          id: string
          organization_id: string
          email: string
          role_id: string
          invited_by: string
          token: string
          status: InvitationStatus
          expires_at: string
          accepted_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          email: string
          role_id: string
          invited_by: string
          token?: string
          status?: InvitationStatus
          expires_at?: string
          accepted_at?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          email?: string
          role_id?: string
          invited_by?: string
          token?: string
          status?: InvitationStatus
          expires_at?: string
          accepted_at?: string | null
          created_at?: string
        }
      }
      profiles: {
        Row: {
          id: string
          email: string
          full_name: string
          role_id: string | null
          team_id: string | null
          manager_id: string | null
          organization_id: string | null
          status: UserStatus
          is_active: boolean | null
          last_login_at: string | null
          avatar_url: string | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id: string
          email: string
          full_name: string
          role_id?: string | null
          team_id?: string | null
          manager_id?: string | null
          organization_id?: string | null
          status?: UserStatus
          is_active?: boolean | null
          last_login_at?: string | null
          avatar_url?: string | null
          created_at?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          email?: string
          full_name?: string
          role_id?: string | null
          team_id?: string | null
          manager_id?: string | null
          organization_id?: string | null
          status?: UserStatus
          is_active?: boolean | null
          last_login_at?: string | null
          avatar_url?: string | null
          created_at?: string | null
          updated_at?: string | null
        }
      }
      roles: {
        Row: {
          id: string
          role_name: string
          hierarchy_level: number
          is_global: boolean
          is_active: boolean | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id?: string
          role_name: string
          hierarchy_level: number
          is_global?: boolean
          is_active?: boolean | null
          created_at?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          role_name?: string
          hierarchy_level?: number
          is_global?: boolean
          is_active?: boolean | null
          created_at?: string | null
          updated_at?: string | null
        }
      }
      permissions: {
        Row: {
          id: string
          module_name: string
          action_name: string
          permission_key: string
          description: string
          created_at: string | null
        }
        Insert: {
          id?: string
          module_name: string
          action_name: string
          permission_key: string
          description: string
          created_at?: string | null
        }
        Update: {
          id?: string
          module_name?: string
          action_name?: string
          permission_key?: string
          description?: string
          created_at?: string | null
        }
      }
      role_permissions: {
        Row: {
          id: string
          role_id: string
          permission_id: string
          created_at: string | null
        }
        Insert: {
          id?: string
          role_id: string
          permission_id: string
          created_at?: string | null
        }
        Update: {
          id?: string
          role_id?: string
          permission_id?: string
          created_at?: string | null
        }
      }
      teams: {
        Row: {
          id: string
          team_name: string
          team_lead_id: string | null
          organization_id: string | null
          is_active: boolean | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id?: string
          team_name: string
          team_lead_id?: string | null
          organization_id?: string | null
          is_active?: boolean | null
          created_at?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          team_name?: string
          team_lead_id?: string | null
          organization_id?: string | null
          is_active?: boolean | null
          created_at?: string | null
          updated_at?: string | null
        }
      }
      leads: {
        Row: {
          id: string
          name: string
          email: string | null
          company: string | null
          lead_value: number | null
          source_id: string | null
          status_id: string | null
          assigned_to: string | null
          created_by: string | null
          organization_id: string | null
          tags: string[] | null
          created_at: string | null
          updated_at: string | null
          mobile_number: string | null
          current_lead_owner: string | null
          previous_lead_owner: string | null
          channel: string | null
          campaign_name: string | null
          country: string | null
          city: string | null
          call_count: number
          is_re_enquired: boolean
          original_enquiry_date: string | null
          sub_status_id: string | null
          first_name: string | null
          last_name: string | null
          university: string | null
          course: string | null
          specialization: string | null
          father_name: string | null
          mother_name: string | null
          address_line1: string | null
          address_line2: string | null
          state: string | null
          pincode: string | null
          campaign_id: string | null
          adgroup_id: string | null
          keyword: string | null
        }
        Insert: {
          id?: string
          name: string
          email?: string | null
          company?: string | null
          lead_value?: number | null
          source_id?: string | null
          status_id?: string | null
          assigned_to?: string | null
          created_by?: string | null
          organization_id?: string | null
          tags?: string[] | null
          created_at?: string | null
          updated_at?: string | null
          mobile_number?: string | null
          current_lead_owner?: string | null
          previous_lead_owner?: string | null
          channel?: string | null
          campaign_name?: string | null
          country?: string | null
          city?: string | null
          call_count?: number
          is_re_enquired?: boolean
          original_enquiry_date?: string | null
          sub_status_id?: string | null
          first_name?: string | null
          last_name?: string | null
          university?: string | null
          course?: string | null
          specialization?: string | null
          father_name?: string | null
          mother_name?: string | null
          address_line1?: string | null
          address_line2?: string | null
          state?: string | null
          pincode?: string | null
          campaign_id?: string | null
          adgroup_id?: string | null
          keyword?: string | null
        }
        Update: {
          id?: string
          name?: string
          email?: string | null
          company?: string | null
          lead_value?: number | null
          source_id?: string | null
          status_id?: string | null
          assigned_to?: string | null
          created_by?: string | null
          organization_id?: string | null
          tags?: string[] | null
          created_at?: string | null
          updated_at?: string | null
          mobile_number?: string | null
          current_lead_owner?: string | null
          previous_lead_owner?: string | null
          channel?: string | null
          campaign_name?: string | null
          country?: string | null
          city?: string | null
          call_count?: number
          is_re_enquired?: boolean
          original_enquiry_date?: string | null
          sub_status_id?: string | null
          first_name?: string | null
          last_name?: string | null
          university?: string | null
          course?: string | null
          specialization?: string | null
          father_name?: string | null
          mother_name?: string | null
          address_line1?: string | null
          address_line2?: string | null
          state?: string | null
          pincode?: string | null
          campaign_id?: string | null
          adgroup_id?: string | null
          keyword?: string | null
        }
      }
      followups: {
        Row: {
          id: string
          lead_id: string
          user_id: string
          organization_id: string | null
          next_action_date: string
          next_action_time: string
          followup_remarks: string
          status: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          lead_id: string
          user_id: string
          organization_id?: string | null
          next_action_date: string
          next_action_time: string
          followup_remarks: string
          status?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          lead_id?: string
          user_id?: string
          organization_id?: string | null
          next_action_date?: string
          next_action_time?: string
          followup_remarks?: string
          status?: string
          created_at?: string
          updated_at?: string
        }
      }
      calls: {
        Row: {
          id: string
          lead_id: string | null
          user_id: string | null
          organization_id: string | null
          call_date: string | null
          duration_minutes: number | null
          outcome: string | null
          notes: string | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id?: string
          lead_id?: string | null
          user_id?: string | null
          organization_id?: string | null
          call_date?: string | null
          duration_minutes?: number | null
          outcome?: string | null
          notes?: string | null
          created_at?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          lead_id?: string | null
          user_id?: string | null
          organization_id?: string | null
          call_date?: string | null
          duration_minutes?: number | null
          outcome?: string | null
          notes?: string | null
          created_at?: string | null
          updated_at?: string | null
        }
      }
      notes: {
        Row: {
          id: string
          lead_id: string | null
          user_id: string | null
          organization_id: string | null
          content: string
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id?: string
          lead_id?: string | null
          user_id?: string | null
          organization_id?: string | null
          content: string
          created_at?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          lead_id?: string | null
          user_id?: string | null
          organization_id?: string | null
          content?: string
          created_at?: string | null
          updated_at?: string | null
        }
      }
      lead_sources: {
        Row: {
          id: string
          name: string
          organization_id: string | null
          color: string | null
          is_active: boolean | null
          created_at: string | null
        }
        Insert: {
          id?: string
          name: string
          organization_id?: string | null
          color?: string | null
          is_active?: boolean | null
          created_at?: string | null
        }
        Update: {
          id?: string
          name?: string
          organization_id?: string | null
          color?: string | null
          is_active?: boolean | null
          created_at?: string | null
        }
      }
      lead_statuses: {
        Row: {
          id: string
          name: string
          display_name: string
          organization_id: string | null
          color: string | null
          order_index: number
          is_active: boolean | null
          created_at: string | null
          parent_status_id: string | null
          status_type: string | null
          requires_sub_status: boolean | null
        }
        Insert: {
          id?: string
          name: string
          display_name: string
          organization_id?: string | null
          color?: string | null
          order_index: number
          is_active?: boolean | null
          created_at?: string | null
          parent_status_id?: string | null
          status_type?: string | null
          requires_sub_status?: boolean | null
        }
        Update: {
          id?: string
          name?: string
          display_name?: string
          organization_id?: string | null
          color?: string | null
          order_index?: number
          is_active?: boolean | null
          created_at?: string | null
          parent_status_id?: string | null
          status_type?: string | null
          requires_sub_status?: boolean | null
        }
      }
      message_templates: {
        Row: {
          id: string
          name: string
          template_type: string
          subject: string | null
          message_content: string
          organization_id: string | null
          available_variables: string[] | null
          is_active: boolean
          created_by: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          template_type: string
          subject?: string | null
          message_content: string
          organization_id?: string | null
          available_variables?: string[] | null
          is_active?: boolean
          created_by: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          template_type?: string
          subject?: string | null
          message_content?: string
          organization_id?: string | null
          available_variables?: string[] | null
          is_active?: boolean
          created_by?: string
          created_at?: string
          updated_at?: string
        }
      }
      filter_presets: {
        Row: {
          id: string
          user_id: string
          organization_id: string | null
          preset_name: string
          filter_criteria: Json
          is_default: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          organization_id?: string | null
          preset_name: string
          filter_criteria?: Json
          is_default?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          organization_id?: string | null
          preset_name?: string
          filter_criteria?: Json
          is_default?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      webhook_configurations: {
        Row: {
          id: string
          organization_id: string
          webhook_name: string
          hmac_secret: string
          api_key: string
          is_enabled: boolean
          allowed_ip_addresses: string[] | null
          rate_limit_per_minute: number
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          webhook_name: string
          hmac_secret: string
          api_key: string
          is_enabled?: boolean
          allowed_ip_addresses?: string[] | null
          rate_limit_per_minute?: number
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          webhook_name?: string
          hmac_secret?: string
          api_key?: string
          is_enabled?: boolean
          allowed_ip_addresses?: string[] | null
          rate_limit_per_minute?: number
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      webhook_sources: {
        Row: {
          id: string
          organization_id: string
          source_name: string
          source_type: string
          field_mappings: Json
          is_active: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          source_name: string
          source_type: string
          field_mappings?: Json
          is_active?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          source_name?: string
          source_type?: string
          field_mappings?: Json
          is_active?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      integration_endpoints: {
        Row: {
          id: string
          organization_id: string
          endpoint_name: string
          endpoint_type: string
          endpoint_url: string
          authentication_type: string
          authentication_config: Json
          is_active: boolean
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          endpoint_name: string
          endpoint_type: string
          endpoint_url: string
          authentication_type?: string
          authentication_config?: Json
          is_active?: boolean
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          endpoint_name?: string
          endpoint_type?: string
          endpoint_url?: string
          authentication_type?: string
          authentication_config?: Json
          is_active?: boolean
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      webhook_delivery_queue: {
        Row: {
          id: string
          organization_id: string
          lead_id: string | null
          endpoint_id: string
          event_type: string
          payload: Json
          status: string
          retry_count: number
          max_retries: number
          next_retry_at: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          lead_id?: string | null
          endpoint_id: string
          event_type: string
          payload: Json
          status?: string
          retry_count?: number
          max_retries?: number
          next_retry_at?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          lead_id?: string | null
          endpoint_id?: string
          event_type?: string
          payload?: Json
          status?: string
          retry_count?: number
          max_retries?: number
          next_retry_at?: string
          created_at?: string
          updated_at?: string
        }
      }
      webhook_delivery_log: {
        Row: {
          id: string
          queue_id: string | null
          organization_id: string
          endpoint_id: string | null
          event_type: string
          request_payload: Json | null
          response_status: number | null
          response_body: string | null
          error_message: string | null
          duration_ms: number | null
          created_at: string
        }
        Insert: {
          id?: string
          queue_id?: string | null
          organization_id: string
          endpoint_id?: string | null
          event_type: string
          request_payload?: Json | null
          response_status?: number | null
          response_body?: string | null
          error_message?: string | null
          duration_ms?: number | null
          created_at?: string
        }
        Update: {
          id?: string
          queue_id?: string | null
          organization_id?: string
          endpoint_id?: string | null
          event_type?: string
          request_payload?: Json | null
          response_status?: number | null
          response_body?: string | null
          error_message?: string | null
          duration_ms?: number | null
          created_at?: string
        }
      }
      webhook_event_subscriptions: {
        Row: {
          id: string
          organization_id: string
          endpoint_id: string
          event_type: string
          filter_criteria: Json
          is_active: boolean
          created_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          endpoint_id: string
          event_type: string
          filter_criteria?: Json
          is_active?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          endpoint_id?: string
          event_type?: string
          filter_criteria?: Json
          is_active?: boolean
          created_at?: string
        }
      }
      webhook_request_log: {
        Row: {
          id: string
          organization_id: string | null
          request_path: string
          request_method: string
          request_headers: Json | null
          request_body: Json | null
          response_status: number | null
          error_message: string | null
          ip_address: string | null
          user_agent: string | null
          duration_ms: number | null
          created_at: string
        }
        Insert: {
          id?: string
          organization_id?: string | null
          request_path: string
          request_method: string
          request_headers?: Json | null
          request_body?: Json | null
          response_status?: number | null
          error_message?: string | null
          ip_address?: string | null
          user_agent?: string | null
          duration_ms?: number | null
          created_at?: string
        }
        Update: {
          id?: string
          organization_id?: string | null
          request_path?: string
          request_method?: string
          request_headers?: Json | null
          request_body?: Json | null
          response_status?: number | null
          error_message?: string | null
          ip_address?: string | null
          user_agent?: string | null
          duration_ms?: number | null
          created_at?: string
        }
      }
      webhook_health_metrics: {
        Row: {
          id: string
          organization_id: string
          metric_type: string
          endpoint_id: string | null
          count: number
          total_duration_ms: number
          hour_bucket: string
          created_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          metric_type: string
          endpoint_id?: string | null
          count?: number
          total_duration_ms?: number
          hour_bucket: string
          created_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          metric_type?: string
          endpoint_id?: string | null
          count?: number
          total_duration_ms?: number
          hour_bucket?: string
          created_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      validate_invitation_token: {
        Args: { p_token: string }
        Returns: {
          invitation_id: string
          organization_id: string
          organization_name: string
          email: string
          role_id: string
          role_name: string
          invited_by_name: string
          expires_at: string
          is_valid: boolean
          error_message: string | null
        }[]
      }
      is_organization_at_limit: {
        Args: { org_uuid: string }
        Returns: boolean
      }
      get_user_organization_id: {
        Args: { user_uuid: string }
        Returns: string
      }
      is_super_admin: {
        Args: { user_uuid: string }
        Returns: boolean
      }
      can_access_organization: {
        Args: { user_uuid: string; org_uuid: string }
        Returns: boolean
      }
      upsert_webhook_health_metric: {
        Args: {
          p_organization_id: string
          p_metric_type: string
          p_endpoint_id: string | null
          p_count: number
          p_duration_ms: number
          p_hour_bucket: string
        }
        Returns: void
      }
    }
    Enums: {
      organization_status: 'active' | 'suspended'
      invitation_status: 'pending' | 'accepted' | 'expired' | 'cancelled'
      user_status: 'pending' | 'active' | 'disabled'
    }
  }
}
