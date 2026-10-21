-- Migration: 20261007_auto_reject_sub_requests.sql
-- Description: Automatically reject pending sub requests when a slot is claimed or reclaimed

-- 1. Trigger function to automatically reject pending sub requests
-- when a slot's status changes from OPEN_SUB to CONFIRMED.
CREATE OR REPLACE FUNCTION "public"."auto_reject_sub_requests_fn"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'CONFIRMED' AND OLD.status = 'OPEN_SUB' THEN
        -- The slot was open for subs but is now confirmed (claimed or reclaimed)
        -- Reject any PENDING requests for this slot
        UPDATE sub_requests
        SET status = 'REJECTED'
        WHERE slot_id = NEW.id AND status = 'PENDING';
    END IF;
    RETURN NEW;
END;
$$;

-- 2. Drop the trigger if it already exists to ensure idempotency
DROP TRIGGER IF EXISTS tr_auto_reject_sub_requests ON match_slots;

-- 3. Create the trigger
CREATE TRIGGER tr_auto_reject_sub_requests
AFTER UPDATE OF status ON match_slots
FOR EACH ROW
EXECUTE FUNCTION "public"."auto_reject_sub_requests_fn"();

-- 4. Retroactively fix any current bad state:
-- Reject all pending sub requests for slots that are already CONFIRMED.
UPDATE sub_requests sr
SET status = 'REJECTED'
FROM match_slots ms
WHERE sr.slot_id = ms.id
  AND sr.status = 'PENDING'
  AND ms.status = 'CONFIRMED';
