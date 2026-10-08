-- Migration: Sub Request System (Admin Assists and Maintenance Free flows)

-- 1. Create sub_request_status enum if not exists
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sub_request_status') THEN 
    CREATE TYPE "public"."sub_request_status" AS ENUM (
      'PENDING',
      'APPROVED',
      'REJECTED',
      'CANCELLED'
    ); 
  END IF; 
END $$;

-- 2. Create sub_requests table
CREATE TABLE IF NOT EXISTS "public"."sub_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL PRIMARY KEY,
    "slot_id" "uuid" NOT NULL REFERENCES "public"."match_slots"("id") ON DELETE CASCADE,
    "requesting_player_id" "uuid" NOT NULL REFERENCES "public"."players"("id") ON DELETE CASCADE,
    "status" "public"."sub_request_status" DEFAULT 'PENDING'::"public"."sub_request_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sub_requests_slot_player_unique" UNIQUE ("slot_id", "requesting_player_id")
);

-- 3. RLS Policies
ALTER TABLE "public"."sub_requests" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to sub_requests" ON "public"."sub_requests";
CREATE POLICY "Allow public read access to sub_requests" 
    ON "public"."sub_requests" FOR SELECT 
    TO "authenticated", "anon" 
    USING (true);

DROP POLICY IF EXISTS "Allow public insert access to sub_requests" ON "public"."sub_requests";
CREATE POLICY "Allow public insert access to sub_requests" 
    ON "public"."sub_requests" FOR INSERT 
    TO "authenticated", "anon" 
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update access to sub_requests" ON "public"."sub_requests";
CREATE POLICY "Allow public update access to sub_requests" 
    ON "public"."sub_requests" FOR UPDATE 
    TO "authenticated", "anon" 
    USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public delete access to sub_requests" ON "public"."sub_requests";
CREATE POLICY "Allow public delete access to sub_requests" 
    ON "public"."sub_requests" FOR DELETE 
    TO "authenticated", "anon" 
    USING (true);

-- 4. Update claim_sub_slot to preserve/track original_player_id
CREATE OR REPLACE FUNCTION "public"."claim_sub_slot"("target_slot_id" "uuid", "claiming_player_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_match_id UUID;
    v_match_date DATE;
    v_status slot_status;
    v_current_player_id UUID;
    v_conflict_count INT;
BEGIN
    -- Lock target slot for update
    SELECT ms.match_id, ms.status, ms.player_id, m.match_date
    INTO v_match_id, v_status, v_current_player_id, v_match_date
    FROM match_slots ms
    JOIN matches m ON ms.match_id = m.id
    WHERE ms.id = target_slot_id
    FOR UPDATE;

    IF v_status <> 'OPEN_SUB' THEN
        RETURN jsonb_build_object('success', false, 'message', 'Slot is no longer available.');
    END IF;

    IF v_current_player_id = claiming_player_id THEN
        RETURN jsonb_build_object('success', false, 'message', 'You already own this slot.');
    END IF;

    -- Constraint: Check if player already has a match on this exact day (prevents same-day double bookings)
    SELECT COUNT(*)
    INTO v_conflict_count
    FROM match_slots ms
    JOIN matches m ON ms.match_id = m.id
    WHERE m.match_date = v_match_date
      AND ms.player_id = claiming_player_id;

    IF v_conflict_count > 0 THEN
        RETURN jsonb_build_object('success', false, 'message', 'Conflict: You are already playing on this date.');
    END IF;

    -- Update Slot
    UPDATE match_slots
    SET player_id = claiming_player_id,
        original_player_id = COALESCE(original_player_id, v_current_player_id),
        status = 'CONFIRMED',
        updated_at = NOW()
    WHERE id = target_slot_id;

    -- Audit Log
    INSERT INTO swap_logs (slot_id, action, from_player_id, to_player_id)
    VALUES (target_slot_id, 'CLAIMED_SUB', v_current_player_id, claiming_player_id);

    RETURN jsonb_build_object('success', true, 'message', 'Slot claimed successfully!');
END;
$$;

-- 5. RPC: Admin Approves a Sub Request
CREATE OR REPLACE FUNCTION "public"."approve_sub_request"("request_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_slot_id uuid;
    v_player_id uuid;
    v_result jsonb;
BEGIN
    SELECT slot_id, requesting_player_id INTO v_slot_id, v_player_id 
    FROM sub_requests WHERE id = request_id AND status = 'PENDING';
    
    IF NOT FOUND THEN 
        RETURN jsonb_build_object('success', false, 'message', 'Request not found or already processed'); 
    END IF;

    v_result := claim_sub_slot(v_slot_id, v_player_id);

    IF (v_result->>'success')::boolean = true THEN
        UPDATE sub_requests SET status = 'APPROVED' WHERE id = request_id;
        UPDATE sub_requests SET status = 'REJECTED' WHERE slot_id = v_slot_id AND status = 'PENDING';
    END IF;

    RETURN v_result;
END;
$$;

-- 6. View: Algorithmic Sub Ranking
CREATE OR REPLACE VIEW "public"."sub_request_rankings" AS
SELECT 
    sr.id AS request_id,
    sr.slot_id,
    sr.requesting_player_id,
    p.full_name,
    p.email,
    (
        SELECT COUNT(*) FROM match_slots ms 
        WHERE ms.player_id = p.id AND ms.original_player_id IS NOT NULL
    ) AS times_subbed,
    -- 0 means eligible. Negative numbers mean ineligible due to a specific rule.
    CASE 
        -- Rule 1: Max 1 match per day
        WHEN (
            SELECT COUNT(*) FROM match_slots ms2 JOIN matches m2 ON ms2.match_id = m2.id
            WHERE ms2.player_id = p.id AND m2.match_date = m_target.match_date
        ) > 0 THEN -1
        -- Rule 2: Max 2 matches per week
        WHEN (
            SELECT COUNT(*) FROM match_slots ms2 JOIN matches m2 ON ms2.match_id = m2.id
            WHERE ms2.player_id = p.id AND m2.week_number = m_target.week_number
        ) >= 2 THEN -2
        ELSE 0 
    END AS rule_penalty,
    m_target.id AS match_id,
    m_target.match_date,
    m_target.week_number,
    m_target.day_of_week,
    m_target.type,
    m_target.court_number,
    orig_p.full_name AS original_player_name,
    sr.created_at AS requested_at
FROM sub_requests sr
JOIN players p ON sr.requesting_player_id = p.id
JOIN match_slots ms_target ON sr.slot_id = ms_target.id
JOIN matches m_target ON ms_target.match_id = m_target.id
LEFT JOIN players orig_p ON orig_p.id = COALESCE(ms_target.original_player_id, ms_target.player_id)
WHERE sr.status = 'PENDING';

-- 7. RPC: Auto-Draft (Maintenance Free Mode)
CREATE OR REPLACE FUNCTION "public"."process_auto_draft"() RETURNS jsonb
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_flow text;
    v_slot RECORD;
    v_best_request RECORD;
    v_assigned_count int := 0;
BEGIN
    -- Check league configuration setting (defaults to maintenance_free if unset)
    SELECT (value->>'sub_request_flow') INTO v_flow 
    FROM league_settings WHERE key = 'league_configuration';
    
    IF v_flow IS NOT NULL AND v_flow = 'admin_assists' THEN
        RETURN jsonb_build_object('success', false, 'message', 'League is configured for Admin Assists mode. Auto-draft skipped.', 'assigned', 0);
    END IF;

    -- Find OPEN_SUB slots that are scheduled within the next 24 hours (or match_date <= CURRENT_DATE + INTERVAL '1 day')
    FOR v_slot IN 
        SELECT DISTINCT ms.id AS slot_id
        FROM match_slots ms
        JOIN matches m ON ms.match_id = m.id
        WHERE ms.status = 'OPEN_SUB'
          AND m.match_date <= (CURRENT_DATE + INTERVAL '1 day')
    LOOP
        -- Find the highest-ranked eligible request for this slot
        SELECT request_id INTO v_best_request
        FROM sub_request_rankings
        WHERE slot_id = v_slot.slot_id
          AND rule_penalty = 0
        ORDER BY times_subbed ASC, requested_at ASC
        LIMIT 1;

        IF FOUND THEN
            PERFORM approve_sub_request(v_best_request.request_id);
            v_assigned_count := v_assigned_count + 1;
        END IF;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'message', format('Processed auto-draft. Assigned %s slot(s).', v_assigned_count), 'assigned', v_assigned_count);
END;
$$;

-- 8. Grants
GRANT ALL ON TABLE "public"."sub_requests" TO "anon", "authenticated", "service_role";
GRANT ALL ON TABLE "public"."sub_request_rankings" TO "anon", "authenticated", "service_role";
GRANT ALL ON FUNCTION "public"."approve_sub_request"("uuid") TO "anon", "authenticated", "service_role";
GRANT ALL ON FUNCTION "public"."process_auto_draft"() TO "anon", "authenticated", "service_role";

-- 9. Default configuration row in league_settings
INSERT INTO public.league_settings (key, value, updated_at)
VALUES (
  'league_configuration',
  '{"sub_request_flow": "maintenance_free"}'::jsonb,
  now()
)
ON CONFLICT (key) DO NOTHING;
