


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."court_type" AS ENUM (
    'SINGLES',
    'DOUBLES'
);


ALTER TYPE "public"."court_type" OWNER TO "postgres";


CREATE TYPE "public"."match_day" AS ENUM (
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY'
);


ALTER TYPE "public"."match_day" OWNER TO "postgres";


CREATE TYPE "public"."slot_status" AS ENUM (
    'CONFIRMED',
    'OPEN_SUB'
);


ALTER TYPE "public"."slot_status" OWNER TO "postgres";


CREATE TYPE "public"."sub_request_status" AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED'
);


ALTER TYPE "public"."sub_request_status" OWNER TO "postgres";


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

    -- Constraint: Check if player already has a match on this exact day (prevents Tuesday double-bookings)
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


ALTER FUNCTION "public"."claim_sub_slot"("target_slot_id" "uuid", "claiming_player_id" "uuid") OWNER TO "postgres";


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


ALTER FUNCTION "public"."approve_sub_request"("request_id" "uuid") OWNER TO "postgres";


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
        ORDER BY is_owed_match DESC, times_subbed ASC, requested_at ASC
        LIMIT 1;

        IF FOUND THEN
            PERFORM approve_sub_request(v_best_request.request_id);
            v_assigned_count := v_assigned_count + 1;
        END IF;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'message', format('Processed auto-draft. Assigned %s slot(s).', v_assigned_count), 'assigned', v_assigned_count);
END;
$$;


ALTER FUNCTION "public"."process_auto_draft"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."direct_swap_slots"("slot_id_a" "uuid", "slot_id_b" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    p_a UUID;
    p_b UUID;
BEGIN
    SELECT player_id INTO p_a FROM match_slots WHERE id = slot_id_a FOR UPDATE;
    SELECT player_id INTO p_b FROM match_slots WHERE id = slot_id_b FOR UPDATE;

    IF p_a IS NULL OR p_b IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Both slots must have an assigned player.');
    END IF;

    UPDATE match_slots SET player_id = p_b, status = 'CONFIRMED', updated_at = NOW() WHERE id = slot_id_a;
    UPDATE match_slots SET player_id = p_a, status = 'CONFIRMED', updated_at = NOW() WHERE id = slot_id_b;

    INSERT INTO swap_logs (slot_id, action, from_player_id, to_player_id)
    VALUES (slot_id_a, 'DIRECT_SWAP', p_a, p_b), (slot_id_b, 'DIRECT_SWAP', p_b, p_a);

    RETURN jsonb_build_object('success', true, 'message', 'Direct swap executed!');
END;
$$;


ALTER FUNCTION "public"."direct_swap_slots"("slot_id_a" "uuid", "slot_id_b" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."league_settings" (
    "key" "text" NOT NULL,
    "value" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."league_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."match_slots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "match_id" "uuid" NOT NULL,
    "player_id" "uuid",
    "original_player_id" "uuid",
    "status" "public"."slot_status" DEFAULT 'CONFIRMED'::"public"."slot_status" NOT NULL,
    "slot_position" integer NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."match_slots" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."matches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "week_number" integer NOT NULL,
    "day_of_week" "public"."match_day" NOT NULL,
    "match_date" "date" NOT NULL,
    "court_number" integer NOT NULL,
    "type" "public"."court_type" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "matches_week_number_check" CHECK ((("week_number" >= 1) AND ("week_number" <= 24)))
);


ALTER TABLE "public"."matches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."players" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text",
    "singles_share" numeric(4,3) DEFAULT 0.00 NOT NULL,
    "doubles_share" numeric(4,3) DEFAULT 0.00 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "blackout_weeks" integer[] DEFAULT '{}'::integer[],
    "approved" boolean DEFAULT true,
    "is_admin" boolean DEFAULT false,
    "blackout_days" "text"[] DEFAULT '{}'::"text"[]
);


ALTER TABLE "public"."players" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."registration_totals" AS
 SELECT "count"(*) AS "total_registered",
    COALESCE("sum"("singles_share"), (0)::numeric) AS "total_singles_shares",
    COALESCE("sum"("doubles_share"), (0)::numeric) AS "total_doubles_shares"
   FROM "public"."players";


ALTER VIEW "public"."registration_totals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."swap_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slot_id" "uuid" NOT NULL,
    "action" "text" NOT NULL,
    "from_player_id" "uuid",
    "to_player_id" "uuid",
    "logged_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."swap_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sub_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL PRIMARY KEY,
    "slot_id" "uuid" NOT NULL REFERENCES "public"."match_slots"("id") ON DELETE CASCADE,
    "requesting_player_id" "uuid" NOT NULL REFERENCES "public"."players"("id") ON DELETE CASCADE,
    "status" "public"."sub_request_status" DEFAULT 'PENDING'::"public"."sub_request_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sub_requests_slot_player_unique" UNIQUE ("slot_id", "requesting_player_id")
);


ALTER TABLE "public"."sub_requests" OWNER TO "postgres";


DROP VIEW IF EXISTS "public"."sub_request_rankings";
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
    -- Check if the requester owes the slot owner a match of the same type
    (
        (SELECT COUNT(*) FROM match_slots ms_owed JOIN matches m_owed ON ms_owed.match_id = m_owed.id
         WHERE ms_owed.player_id = sr.requesting_player_id 
         AND ms_owed.original_player_id = ms_target.player_id 
         AND m_owed.type = m_target.type AND ms_owed.status = 'CONFIRMED')
        >
        (SELECT COUNT(*) FROM match_slots ms_owed_back JOIN matches m_owed_back ON ms_owed_back.match_id = m_owed_back.id
         WHERE ms_owed_back.player_id = ms_target.player_id 
         AND ms_owed_back.original_player_id = sr.requesting_player_id 
         AND m_owed_back.type = m_target.type AND ms_owed_back.status = 'CONFIRMED')
    ) AS is_owed_match,
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


ALTER VIEW "public"."sub_request_rankings" OWNER TO "postgres";


ALTER TABLE ONLY "public"."league_settings"
    ADD CONSTRAINT "league_settings_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."match_slots"
    ADD CONSTRAINT "match_slots_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."players"
    ADD CONSTRAINT "players_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."players"
    ADD CONSTRAINT "players_full_name_key" UNIQUE ("full_name");



ALTER TABLE ONLY "public"."players"
    ADD CONSTRAINT "players_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."swap_logs"
    ADD CONSTRAINT "swap_logs_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_players_approved" ON "public"."players" USING "btree" ("approved");



ALTER TABLE ONLY "public"."match_slots"
    ADD CONSTRAINT "match_slots_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_slots"
    ADD CONSTRAINT "match_slots_original_player_id_fkey" FOREIGN KEY ("original_player_id") REFERENCES "public"."players"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."match_slots"
    ADD CONSTRAINT "match_slots_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."players"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."swap_logs"
    ADD CONSTRAINT "swap_logs_from_player_id_fkey" FOREIGN KEY ("from_player_id") REFERENCES "public"."players"("id");



ALTER TABLE ONLY "public"."swap_logs"
    ADD CONSTRAINT "swap_logs_slot_id_fkey" FOREIGN KEY ("slot_id") REFERENCES "public"."match_slots"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."swap_logs"
    ADD CONSTRAINT "swap_logs_to_player_id_fkey" FOREIGN KEY ("to_player_id") REFERENCES "public"."players"("id");



CREATE POLICY "Allow delete match_slots" ON "public"."match_slots" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow delete matches" ON "public"."matches" FOR DELETE TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow insert match_slots" ON "public"."match_slots" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow insert matches" ON "public"."matches" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow public insert access to players" ON "public"."players" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow public insert access to swap_logs" ON "public"."swap_logs" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow public read access on league_settings" ON "public"."league_settings" FOR SELECT USING (true);



CREATE POLICY "Allow public read access to match_slots" ON "public"."match_slots" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow public read access to matches" ON "public"."matches" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow public read access to players" ON "public"."players" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow public read access to swap_logs" ON "public"."swap_logs" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow public update access to match_slots" ON "public"."match_slots" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow public update access to players" ON "public"."players" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow public write access on league_settings" ON "public"."league_settings" USING (true) WITH CHECK (true);



CREATE POLICY "Allow select match_slots" ON "public"."match_slots" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow select matches" ON "public"."matches" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow update match_slots" ON "public"."match_slots" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow update matches" ON "public"."matches" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow public read access to sub_requests" ON "public"."sub_requests" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Allow public insert access to sub_requests" ON "public"."sub_requests" FOR INSERT TO "authenticated", "anon" WITH CHECK (true);



CREATE POLICY "Allow public update access to sub_requests" ON "public"."sub_requests" FOR UPDATE TO "authenticated", "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow public delete access to sub_requests" ON "public"."sub_requests" FOR DELETE TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."league_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."match_slots" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."matches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."players" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."swap_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sub_requests" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."claim_sub_slot"("target_slot_id" "uuid", "claiming_player_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."claim_sub_slot"("target_slot_id" "uuid", "claiming_player_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_sub_slot"("target_slot_id" "uuid", "claiming_player_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."direct_swap_slots"("slot_id_a" "uuid", "slot_id_b" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."direct_swap_slots"("slot_id_a" "uuid", "slot_id_b" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."direct_swap_slots"("slot_id_a" "uuid", "slot_id_b" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";


















GRANT ALL ON TABLE "public"."league_settings" TO "anon";
GRANT ALL ON TABLE "public"."league_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."league_settings" TO "service_role";



GRANT ALL ON TABLE "public"."match_slots" TO "anon";
GRANT ALL ON TABLE "public"."match_slots" TO "authenticated";
GRANT ALL ON TABLE "public"."match_slots" TO "service_role";



GRANT ALL ON TABLE "public"."matches" TO "anon";
GRANT ALL ON TABLE "public"."matches" TO "authenticated";
GRANT ALL ON TABLE "public"."matches" TO "service_role";



GRANT ALL ON TABLE "public"."players" TO "anon";
GRANT ALL ON TABLE "public"."players" TO "authenticated";
GRANT ALL ON TABLE "public"."players" TO "service_role";



GRANT ALL ON TABLE "public"."registration_totals" TO "anon";
GRANT ALL ON TABLE "public"."registration_totals" TO "authenticated";
GRANT ALL ON TABLE "public"."registration_totals" TO "service_role";



GRANT ALL ON TABLE "public"."swap_logs" TO "anon";
GRANT ALL ON TABLE "public"."swap_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."swap_logs" TO "service_role";



GRANT ALL ON TABLE "public"."sub_requests" TO "anon";
GRANT ALL ON TABLE "public"."sub_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."sub_requests" TO "service_role";



GRANT ALL ON TABLE "public"."sub_request_rankings" TO "anon";
GRANT ALL ON TABLE "public"."sub_request_rankings" TO "authenticated";
GRANT ALL ON TABLE "public"."sub_request_rankings" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































