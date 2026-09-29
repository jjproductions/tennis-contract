DROP VIEW IF EXISTS "public"."registration_totals";

ALTER TABLE "public"."players" 
ALTER COLUMN "singles_share" TYPE numeric(4,3),
ALTER COLUMN "doubles_share" TYPE numeric(4,3);

CREATE OR REPLACE VIEW "public"."registration_totals" AS
 SELECT "count"(*) AS "total_registered",
    COALESCE("sum"("singles_share"), (0)::numeric) AS "total_singles_shares",
    COALESCE("sum"("doubles_share"), (0)::numeric) AS "total_doubles_shares"
   FROM "public"."players";

GRANT ALL ON TABLE "public"."registration_totals" TO "anon";
GRANT ALL ON TABLE "public"."registration_totals" TO "authenticated";
GRANT ALL ON TABLE "public"."registration_totals" TO "service_role";
