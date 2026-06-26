-- Fix handle_new_user to assign the correct role and organization from pending invitations
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_org_id  uuid;
  v_role_id uuid;
BEGIN
  -- First, check if there is a pending invitation for this email
  SELECT organization_id, role_id INTO v_org_id, v_role_id
  FROM public.invitations
  WHERE email = NEW.email AND status = 'pending'
  ORDER BY created_at DESC
  LIMIT 1;

  -- If no invitation, fallback to the first/default organization
  IF v_org_id IS NULL THEN
    SELECT id INTO v_org_id
    FROM public.organizations
    ORDER BY created_at ASC
    LIMIT 1;
  END IF;

  -- If no invitation role, fallback to Sales Representative (lowest privilege)
  IF v_role_id IS NULL THEN
    SELECT id INTO v_role_id
    FROM public.roles
    WHERE role_name = 'Sales Representative'
    LIMIT 1;
  END IF;

  -- Ultimate fallback for role
  IF v_role_id IS NULL THEN
    SELECT id INTO v_role_id
    FROM public.roles
    ORDER BY hierarchy_level DESC NULLS LAST
    LIMIT 1;
  END IF;

  -- Create profile (ON CONFLICT: Supabase can occasionally fire trigger twice)
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    first_name,
    last_name,
    organization_id,
    role_id,
    status
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NULLIF(TRIM(
        COALESCE(NEW.raw_user_meta_data->>'first_name', '') ||
        ' ' ||
        COALESCE(NEW.raw_user_meta_data->>'last_name', '')
      ), ''),
      NEW.email
    ),
    NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'first_name', '')), ''),
    NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'last_name', '')), ''),
    v_org_id,
    v_role_id,
    'active'
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create organization membership immediately
  IF v_org_id IS NOT NULL AND v_role_id IS NOT NULL THEN
    INSERT INTO public.organization_members (
      organization_id,
      profile_id,
      role_id,
      joined_at
    )
    VALUES (
      v_org_id,
      NEW.id,
      v_role_id,
      now()
    )
    ON CONFLICT (organization_id, profile_id) DO UPDATE
    SET role_id = EXCLUDED.role_id;
  END IF;

  RETURN NEW;
END;
$$;
