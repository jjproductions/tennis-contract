-- Migration: 20261006_sub_karma_rule.sql
-- Description: Adds the is_owed_match Karma calculation to sub_request_rankings and updates process_auto_draft

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

    RETURN jsonb_build_object('success', true, 'message', 'Auto-draft executed', 'assigned', v_assigned_count);
END;
$$;
