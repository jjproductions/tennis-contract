-- Migration: 20261007_fix_karma_rule_inequality.sql
-- Description: Fix the Karma logic inequality to prioritize players who owe the target a match.

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
    -- Check if the requester owes the slot owner a match of the same type.
    -- Target = ms_target.player_id (the person needing a sub)
    -- Candidate = sr.requesting_player_id (the person offering to sub)
    -- The Candidate owes the Target if the Target has subbed for the Candidate MORE TIMES than the Candidate has subbed for the Target.
    (
        -- Times Target subbed for Candidate
        (SELECT COUNT(*) FROM match_slots ms_owed JOIN matches m_owed ON ms_owed.match_id = m_owed.id
         WHERE ms_owed.player_id = ms_target.player_id 
         AND ms_owed.original_player_id = sr.requesting_player_id 
         AND m_owed.type = m_target.type AND ms_owed.status = 'CONFIRMED')
        >
        -- Times Candidate subbed for Target
        (SELECT COUNT(*) FROM match_slots ms_owed_back JOIN matches m_owed_back ON ms_owed_back.match_id = m_owed_back.id
         WHERE ms_owed_back.player_id = sr.requesting_player_id 
         AND ms_owed_back.original_player_id = ms_target.player_id 
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
