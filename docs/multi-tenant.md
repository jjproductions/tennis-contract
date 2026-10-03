# Enterprise Multi-Tenant Architecture Plan

## Goal Description
Convert `winter-tennis` from a single-tenant application into a secure, commercial, multi-tenant SaaS. This requires establishing strict data isolation (Row Level Security), separating identity/authentication from domain logic (using an `organization_members` table), establishing a hierarchy to support multiple seasons (`Organizations` -> `Seasons`), and namespacing application routes to prevent collisions.

> [!IMPORTANT]
> **User Review Required**
> - **Data Migration:** Migrating to a 3-tier hierarchy (`Organization` -> `Season` -> `Player`) means we will create a "Legacy Organization" and a default "2025/2026 Season" for all existing data. Does this default naming work for you?
> - **Intake Links:** Players will use a link like `app.com/org/legacy-tennis/intake` to sign up. Is this URL structure acceptable?

---

## Proposed Changes

### 1. Database Schema Updates (Supabase Migration)
We will introduce `organizations`, `organization_members`, and `seasons` tables. Domain tables (`players`, `matches`, `league_settings`) will belong to a `season_id`.

#### [NEW] `supabase/migrations/20261001_enterprise_saas.sql`
```sql
-- 1. Create Core Multi-Tenant Tables
CREATE TABLE public.organizations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TYPE org_role AS ENUM ('owner', 'admin', 'member');

CREATE TABLE public.organization_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role org_role DEFAULT 'member',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organization_id, user_id)
);

-- 2. Create Seasons Hierarchy (Allows rolling over year-to-year)
CREATE TABLE public.seasons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g., "Winter 2026-2027"
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Modify Domain Tables (Attach to Season, not just Org)
ALTER TABLE public.players ADD COLUMN season_id UUID REFERENCES public.seasons(id) ON DELETE CASCADE;
ALTER TABLE public.matches ADD COLUMN season_id UUID REFERENCES public.seasons(id) ON DELETE CASCADE;
ALTER TABLE public.match_slots ADD COLUMN season_id UUID REFERENCES public.seasons(id) ON DELETE CASCADE;
ALTER TABLE public.swap_logs ADD COLUMN season_id UUID REFERENCES public.seasons(id) ON DELETE CASCADE;

-- League settings become season settings
ALTER TABLE public.league_settings DROP CONSTRAINT league_settings_pkey;
ALTER TABLE public.league_settings ADD COLUMN season_id UUID REFERENCES public.seasons(id) ON DELETE CASCADE;
ALTER TABLE public.league_settings ADD CONSTRAINT league_settings_pkey PRIMARY KEY (season_id, key);

-- 4. Data Migration for Existing Data
DO $$
DECLARE
    default_org_id UUID;
    default_season_id UUID;
BEGIN
    INSERT INTO public.organizations (name, slug) 
    VALUES ('Legacy Tennis Club', 'legacy-tennis') 
    RETURNING id INTO default_org_id;

    INSERT INTO public.seasons (organization_id, name, is_active)
    VALUES (default_org_id, 'Winter 2025/2026', true)
    RETURNING id INTO default_season_id;

    UPDATE public.players SET season_id = default_season_id;
    UPDATE public.matches SET season_id = default_season_id;
    UPDATE public.match_slots SET season_id = default_season_id;
    UPDATE public.swap_logs SET season_id = default_season_id;
    UPDATE public.league_settings SET season_id = default_season_id;
END $$;

-- 5. Enforce Constraints
ALTER TABLE public.players ALTER COLUMN season_id SET NOT NULL;
ALTER TABLE public.matches ALTER COLUMN season_id SET NOT NULL;
ALTER TABLE public.league_settings ALTER COLUMN season_id SET NOT NULL;

-- Unique constraints per season
ALTER TABLE public.players DROP CONSTRAINT players_email_key;
ALTER TABLE public.players DROP CONSTRAINT players_full_name_key;
ALTER TABLE public.players ADD CONSTRAINT players_season_email_key UNIQUE (season_id, email);
ALTER TABLE public.players ADD CONSTRAINT players_season_name_key UNIQUE (season_id, full_name);
```

---

### 2. Secure Row Level Security (RLS) & RPC for Intake
Absolute security relies on the backend, not the frontend UI queries.

#### [NEW] `supabase/migrations/20261001_secure_rls.sql`
```sql
-- Security Definer Function for Public Intake
-- Allows users to submit their intake securely without exposing the `players` table to public INSERT access.
CREATE OR REPLACE FUNCTION submit_player_intake(
  p_season_id UUID,
  p_full_name TEXT,
  p_email TEXT,
  p_singles_share NUMERIC,
  p_doubles_share NUMERIC,
  p_blackout_weeks INT[],
  p_blackout_days TEXT[]
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER -- Runs as Postgres superuser securely
AS $$
DECLARE
  new_player_id UUID;
BEGIN
  INSERT INTO public.players (season_id, full_name, email, singles_share, doubles_share, blackout_weeks, blackout_days, approved)
  VALUES (p_season_id, p_full_name, p_email, p_singles_share, p_doubles_share, p_blackout_weeks, p_blackout_days, false)
  RETURNING id INTO new_player_id;
  RETURN new_player_id;
END;
$$;

-- RLS: Organizations & Members
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Read orgs if member" ON public.organizations 
FOR SELECT USING (id IN (SELECT organization_id FROM public.organization_members WHERE user_id = auth.uid()));

CREATE POLICY "Public can read orgs" ON public.organizations
FOR SELECT USING (true); -- Required to validate org slugs on the intake page URL

-- RLS: Players
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read players" ON public.players
FOR SELECT USING (
  season_id IN (
    SELECT s.id FROM public.seasons s 
    JOIN public.organization_members om ON s.organization_id = om.organization_id
    WHERE om.user_id = auth.uid()
  )
);

CREATE POLICY "Admins can update players" ON public.players
FOR UPDATE USING (
  season_id IN (
    SELECT s.id FROM public.seasons s 
    JOIN public.organization_members om ON s.organization_id = om.organization_id
    WHERE om.user_id = auth.uid() AND om.role IN ('owner', 'admin')
  )
);
```

---

### 3. Frontend Architecture & Namespaced Routing
We will use Vue Router to safely namespace the application.

#### [MODIFY] `src/router/index.ts`
```typescript
import { createRouter, createWebHistory } from 'vue-router'
import GlobalDashboard from '../views/GlobalDashboard.vue' // SaaS Landing / App Portal
import OrgLayout from '../layouts/OrgLayout.vue' // Loads Context
import MatchScheduleView from '../components/MatchScheduleView.vue'
import PlayerIntake from '../components/PlayerIntake.vue'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    // Global Namespaces
    { path: '/', component: GlobalDashboard },
    { path: '/login', component: GlobalDashboard },
    
    // Tenant Namespaces (Isolated by /org/)
    { 
      path: '/org/:orgSlug', 
      component: OrgLayout,
      children: [
        { path: '', component: MatchScheduleView },
        { path: 'intake', component: PlayerIntake }
      ]
    }
  ]
})
```

#### [MODIFY] Frontend Supabase Queries
All database calls in Vue components will be updated to:
1. Extract `season_id` from the loaded context rather than making global requests.
2. Use `.eq('season_id', activeSeason.value)` for reads.
3. Call the `rpc('submit_player_intake')` for signups rather than `.from('players').insert()`.

## Verification Plan

### Automated Verification
TypeScript compiler validation to ensure all database interfaces match the new schema layout (specifically the shift to `season_id`).

### Manual Verification
1. **Public Intake Security:** Navigate to `/org/legacy-tennis/intake` in an incognito window. Verify that submitting the form successfully calls the secure RPC function. Attempt to run `supabase.from('players').insert()` from the DevTools console and verify it is rejected with a 403 Forbidden.
2. **Tenant Isolation:** Log in as a user attached to a specific organization. Verify the API requests correctly return data scoped to that organization and that modifying the URL to another slug returns empty arrays or 401 Unauthorized.
3. **Data Integrity:** Run the database migration and verify all legacy players, schedules, and settings are preserved under the newly created "Winter 2025/2026" season entity.
