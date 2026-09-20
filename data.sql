SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict 57zVnUTqyj2I0SN8pN6KOdKy2Lekj0W9bcLPWKuW668bBnI8jnInsEQOUbgfS8t

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;x
SET row_security = off;

--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."users" ("instance_id", "id", "aud", "role", "email", "encrypted_password", "email_confirmed_at", "invited_at", "confirmation_token", "confirmation_sent_at", "recovery_token", "recovery_sent_at", "email_change_token_new", "email_change", "email_change_sent_at", "last_sign_in_at", "raw_app_meta_data", "raw_user_meta_data", "is_super_admin", "created_at", "updated_at", "phone", "phone_confirmed_at", "phone_change", "phone_change_token", "phone_change_sent_at", "email_change_token_current", "email_change_confirm_status", "banned_until", "reauthentication_token", "reauthentication_sent_at", "is_sso_user", "deleted_at", "is_anonymous") VALUES
	('00000000-0000-0000-0000-000000000000', '32fabea0-b9d4-44d6-81af-4fa8e501358c', 'authenticated', 'authenticated', 'jdbagby@aol.com', '$2a$10$7uZTzgKTY1CA.BItWKi62esd.X20QCs5I3cuLvTWOviWZD1ncbqPO', '2026-09-12 19:32:09.639244+00', NULL, '', '2026-09-12 19:30:39.050318+00', '', '2026-09-12 22:39:39.982367+00', '', '', NULL, '2026-09-12 22:40:12.639663+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "32fabea0-b9d4-44d6-81af-4fa8e501358c", "email": "jdbagby@aol.com", "email_verified": true, "phone_verified": false}', NULL, '2026-09-12 19:30:38.99967+00', '2026-09-13 10:18:42.408566+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false),
	('00000000-0000-0000-0000-000000000000', 'b6f044b6-48d9-437a-b811-673a536b609b', 'authenticated', 'authenticated', 'jdbagby@gmail.com', '$2a$10$LgV1.iTDz2/c..ZufCeenuSKGsnzG9XuOnKEz80MI.7xKY/wVbtWi', '2026-09-14 00:27:20.687568+00', NULL, '', '2026-09-14 00:21:36.970253+00', '', NULL, '', '', NULL, '2026-09-14 02:44:08.143237+00', '{"provider": "email", "providers": ["email"]}', '{"sub": "b6f044b6-48d9-437a-b811-673a536b609b", "email": "jdbagby@gmail.com", "email_verified": true, "phone_verified": false}', NULL, '2026-09-14 00:21:36.935555+00', '2026-09-20 16:54:00.962568+00', NULL, NULL, '', '', NULL, '', 0, NULL, '', NULL, false, NULL, false);


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."identities" ("provider_id", "user_id", "identity_data", "provider", "last_sign_in_at", "created_at", "updated_at", "id") VALUES
	('32fabea0-b9d4-44d6-81af-4fa8e501358c', '32fabea0-b9d4-44d6-81af-4fa8e501358c', '{"sub": "32fabea0-b9d4-44d6-81af-4fa8e501358c", "email": "jdbagby@aol.com", "email_verified": true, "phone_verified": false}', 'email', '2026-09-12 19:30:39.033775+00', '2026-09-12 19:30:39.033833+00', '2026-09-12 19:30:39.033833+00', '295e1313-04f0-43be-86da-172d4c7f76b9'),
	('b6f044b6-48d9-437a-b811-673a536b609b', 'b6f044b6-48d9-437a-b811-673a536b609b', '{"sub": "b6f044b6-48d9-437a-b811-673a536b609b", "email": "jdbagby@gmail.com", "email_verified": true, "phone_verified": false}', 'email', '2026-09-14 00:21:36.959676+00', '2026-09-14 00:21:36.959723+00', '2026-09-14 00:21:36.959723+00', 'c4ba9033-8bcd-40bb-a78d-2fbfe797244c');


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."sessions" ("id", "user_id", "created_at", "updated_at", "factor_id", "aal", "not_after", "refreshed_at", "user_agent", "ip", "tag", "oauth_client_id", "refresh_token_hmac_key", "refresh_token_counter", "scopes") VALUES
	('e73cfd9d-b59e-4fbb-bec1-e23a1484cd2d', '32fabea0-b9d4-44d6-81af-4fa8e501358c', '2026-09-12 19:32:09.65708+00', '2026-09-12 19:32:09.65708+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.6.1 Mobile/15E148 Safari/604.1', '71.188.110.254', NULL, NULL, NULL, NULL, NULL),
	('acfa7bf1-7ee0-4a3e-8915-61c0ea6ff52d', '32fabea0-b9d4-44d6-81af-4fa8e501358c', '2026-09-12 19:36:26.508237+00', '2026-09-12 19:36:26.508237+00', NULL, 'aal1', NULL, NULL, 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', '71.188.110.254', NULL, NULL, NULL, NULL, NULL),
	('137e58e3-bf08-4e87-9a87-92c8568e247c', '32fabea0-b9d4-44d6-81af-4fa8e501358c', '2026-09-12 22:40:12.643012+00', '2026-09-13 10:18:42.425203+00', NULL, 'aal1', NULL, '2026-09-13 10:18:42.425091', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36', '71.188.110.254', NULL, NULL, NULL, NULL, NULL),
	('4cf6dec7-f693-4b0b-8d18-6f09f891e49b', 'b6f044b6-48d9-437a-b811-673a536b609b', '2026-09-14 00:27:20.704566+00', '2026-09-20 16:52:29.034382+00', NULL, 'aal1', NULL, '2026-09-20 16:52:29.033059', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '72.73.231.247', NULL, NULL, NULL, NULL, NULL),
	('9ab93afb-069a-434c-b015-458a611fd626', 'b6f044b6-48d9-437a-b811-673a536b609b', '2026-09-14 02:44:08.145253+00', '2026-09-20 16:54:00.976854+00', NULL, 'aal1', NULL, '2026-09-20 16:54:00.97622', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '72.73.231.247', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."mfa_amr_claims" ("session_id", "created_at", "updated_at", "authentication_method", "id") VALUES
	('e73cfd9d-b59e-4fbb-bec1-e23a1484cd2d', '2026-09-12 19:32:09.694791+00', '2026-09-12 19:32:09.694791+00', 'otp', 'ca583bdc-876f-4bdf-bfaa-a7b3582d0e4c'),
	('acfa7bf1-7ee0-4a3e-8915-61c0ea6ff52d', '2026-09-12 19:36:26.525138+00', '2026-09-12 19:36:26.525138+00', 'password', 'ef1a0c78-290f-4b32-825e-a85af5ac386f'),
	('137e58e3-bf08-4e87-9a87-92c8568e247c', '2026-09-12 22:40:12.663423+00', '2026-09-12 22:40:12.663423+00', 'otp', '17909bc4-3699-46db-9660-5e658d9438e0'),
	('4cf6dec7-f693-4b0b-8d18-6f09f891e49b', '2026-09-14 00:27:20.724567+00', '2026-09-14 00:27:20.724567+00', 'otp', '2f7014db-21bd-432a-8f8c-4c699eb86383'),
	('9ab93afb-069a-434c-b015-458a611fd626', '2026-09-14 02:44:08.205145+00', '2026-09-14 02:44:08.205145+00', 'password', '36c157c5-179c-459f-b863-dca4c381c081');


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_recovery_code_sets; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_recovery_codes; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

INSERT INTO "auth"."refresh_tokens" ("instance_id", "id", "token", "user_id", "revoked", "created_at", "updated_at", "parent", "session_id") VALUES
	('00000000-0000-0000-0000-000000000000', 50, 'nme2x5saibdn', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-20 13:39:14.386599+00', '2026-09-20 14:47:36.915692+00', '7gdwuculhoml', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 49, 'pid3px4paf6h', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-20 13:39:12.4583+00', '2026-09-20 14:47:56.817783+00', 'xj6ih3e4nehd', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 52, 'twanogqlkbli', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-20 14:47:56.82265+00', '2026-09-20 15:46:16.169701+00', 'pid3px4paf6h', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 53, 'c5qn6htf3fbr', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-20 15:46:16.176584+00', '2026-09-20 16:52:28.994837+00', 'twanogqlkbli', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 54, 'vx322xbbsqcg', 'b6f044b6-48d9-437a-b811-673a536b609b', false, '2026-09-20 16:52:29.01229+00', '2026-09-20 16:52:29.01229+00', 'c5qn6htf3fbr', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 51, 'gu7si4a7bgbf', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-20 14:47:36.930239+00', '2026-09-20 16:54:00.95149+00', 'nme2x5saibdn', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 55, 'wikxi4f2qfxb', 'b6f044b6-48d9-437a-b811-673a536b609b', false, '2026-09-20 16:54:00.957888+00', '2026-09-20 16:54:00.957888+00', 'gu7si4a7bgbf', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 10, 'e47ig45xnr7u', '32fabea0-b9d4-44d6-81af-4fa8e501358c', false, '2026-09-12 19:32:09.675297+00', '2026-09-12 19:32:09.675297+00', NULL, 'e73cfd9d-b59e-4fbb-bec1-e23a1484cd2d'),
	('00000000-0000-0000-0000-000000000000', 11, 'scrx3qz7lwa6', '32fabea0-b9d4-44d6-81af-4fa8e501358c', false, '2026-09-12 19:36:26.522121+00', '2026-09-12 19:36:26.522121+00', NULL, 'acfa7bf1-7ee0-4a3e-8915-61c0ea6ff52d'),
	('00000000-0000-0000-0000-000000000000', 15, 'gaxokau3ci3u', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-12 22:40:12.65263+00', '2026-09-12 23:38:13.985576+00', NULL, '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 16, 'fgm6lnahzbp6', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-12 23:38:14.000815+00', '2026-09-13 00:36:42.188689+00', 'gaxokau3ci3u', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 17, 'myo73rdph3va', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 00:36:42.200645+00', '2026-09-13 01:34:43.948076+00', 'fgm6lnahzbp6', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 18, 'pzaddtxecwom', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 01:34:43.958314+00', '2026-09-13 02:32:43.851179+00', 'myo73rdph3va', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 19, 'sn5cuelphtfq', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 02:32:43.855438+00', '2026-09-13 03:30:44.107498+00', 'pzaddtxecwom', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 20, 'pmu3gb6dwrma', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 03:30:44.125197+00', '2026-09-13 04:29:12.23474+00', 'sn5cuelphtfq', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 21, '72u2iynzj2qq', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 04:29:12.243404+00', '2026-09-13 05:27:14.076939+00', 'pmu3gb6dwrma', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 22, 'rwvkojn3cuo7', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 05:27:14.094618+00', '2026-09-13 06:25:42.274333+00', '72u2iynzj2qq', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 23, 'mcsor2sse7ta', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 06:25:42.283562+00', '2026-09-13 07:23:44.082596+00', 'rwvkojn3cuo7', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 24, 'fh43auvk3zaq', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 07:23:44.097874+00', '2026-09-13 08:22:12.529364+00', 'mcsor2sse7ta', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 25, 'qq2wo6y2lf6t', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 08:22:12.545106+00', '2026-09-13 09:20:14.34157+00', 'fh43auvk3zaq', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 26, 'bajynvppzmfk', '32fabea0-b9d4-44d6-81af-4fa8e501358c', true, '2026-09-13 09:20:14.346174+00', '2026-09-13 10:18:42.38232+00', 'qq2wo6y2lf6t', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 27, 'x2mkc7mhhh3x', '32fabea0-b9d4-44d6-81af-4fa8e501358c', false, '2026-09-13 10:18:42.402613+00', '2026-09-13 10:18:42.402613+00', 'bajynvppzmfk', '137e58e3-bf08-4e87-9a87-92c8568e247c'),
	('00000000-0000-0000-0000-000000000000', 28, 'njaqq2jz4x7h', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 00:27:20.711614+00', '2026-09-14 02:52:30.774273+00', NULL, '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 29, '2lj6fkoywniz', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 02:44:08.175468+00', '2026-09-14 03:42:22.594574+00', NULL, '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 31, 'enwmq6hahetz', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 03:42:22.605837+00', '2026-09-14 04:40:22.740814+00', '2lj6fkoywniz', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 32, 'yh7d333pmspa', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 04:40:22.75905+00', '2026-09-14 05:38:22.732949+00', 'enwmq6hahetz', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 33, 'qhrxwskren4n', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 05:38:22.745126+00', '2026-09-14 06:36:22.741463+00', 'yh7d333pmspa', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 34, '63fhczjyfu6s', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 06:36:22.755395+00', '2026-09-14 07:34:22.683541+00', 'qhrxwskren4n', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 35, 'rgko6oxuihau', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 07:34:22.689614+00', '2026-09-14 08:32:22.63655+00', '63fhczjyfu6s', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 36, 'fn6b7rysmcon', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 08:32:22.640693+00', '2026-09-14 09:30:28.732587+00', 'rgko6oxuihau', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 37, '6jyov7iqtvir', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 09:30:28.759752+00', '2026-09-14 10:28:53.906469+00', 'fn6b7rysmcon', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 38, 'ro3ne3sfzn34', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 10:28:53.911431+00', '2026-09-14 11:27:22.825363+00', '6jyov7iqtvir', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 39, '4iq7dvgl6atp', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 11:27:22.83604+00', '2026-09-14 12:25:22.788055+00', 'ro3ne3sfzn34', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 30, 'n7yxykzl4crd', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 02:52:30.783036+00', '2026-09-19 16:24:24.374603+00', 'njaqq2jz4x7h', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 40, 'za63dnk5pbas', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-14 12:25:22.79511+00', '2026-09-19 16:24:24.374333+00', '4iq7dvgl6atp', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 41, 'wen3w2b67oyj', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-19 16:24:24.393885+00', '2026-09-19 20:00:14.788122+00', 'n7yxykzl4crd', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 43, 'kzadrp2zkqjb', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-19 20:00:14.808367+00', '2026-09-19 20:58:42.387+00', 'wen3w2b67oyj', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 44, 'v3ocutbidfcc', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-19 20:58:42.398294+00', '2026-09-19 21:57:12.435968+00', 'kzadrp2zkqjb', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 42, 'hwbwk6b6k2wq', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-19 16:24:24.393909+00', '2026-09-19 22:25:11.145513+00', 'za63dnk5pbas', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 46, 'fqy4hq2yoy4h', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-19 22:25:11.154196+00', '2026-09-20 12:39:46.766524+00', 'hwbwk6b6k2wq', '9ab93afb-069a-434c-b015-458a611fd626'),
	('00000000-0000-0000-0000-000000000000', 45, 'bdss2ldfrqkf', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-19 21:57:12.454847+00', '2026-09-20 12:39:46.767345+00', 'v3ocutbidfcc', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 47, 'xj6ih3e4nehd', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-20 12:39:46.787516+00', '2026-09-20 13:39:12.436581+00', 'bdss2ldfrqkf', '4cf6dec7-f693-4b0b-8d18-6f09f891e49b'),
	('00000000-0000-0000-0000-000000000000', 48, '7gdwuculhoml', 'b6f044b6-48d9-437a-b811-673a536b609b', true, '2026-09-20 12:39:46.787514+00', '2026-09-20 13:39:14.385499+00', 'fqy4hq2yoy4h', '9ab93afb-069a-434c-b015-458a611fd626');


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: scim_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: scim_users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: league_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: matches; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."matches" ("id", "week_number", "day_of_week", "match_date", "court_number", "type", "created_at") VALUES
	('b49d1a96-21a5-4699-bb0e-7a61567c5c25', 1, 'MONDAY', '2026-10-19', 1, 'SINGLES', '2026-09-20 15:34:39.093061+00'),
	('e726701e-c23b-4c9c-9505-183158ad4988', 1, 'MONDAY', '2026-10-19', 2, 'DOUBLES', '2026-09-20 15:34:39.397681+00'),
	('740f492c-fa78-45b8-95c3-27d0841e9249', 1, 'TUESDAY', '2026-10-20', 1, 'DOUBLES', '2026-09-20 15:34:39.639798+00'),
	('e30201e6-53c5-4425-b50f-7571cc750f3a', 1, 'TUESDAY', '2026-10-20', 2, 'DOUBLES', '2026-09-20 15:34:39.941967+00'),
	('9d256ff9-90be-4e8b-bdd6-b94c0b70ada0', 1, 'WEDNESDAY', '2026-10-21', 1, 'SINGLES', '2026-09-20 15:34:40.164496+00'),
	('da1ab58b-823a-4fc5-9860-fef044336921', 2, 'MONDAY', '2026-10-26', 1, 'SINGLES', '2026-09-20 15:34:40.460868+00'),
	('e894960c-102b-4018-a492-08b058ec96d1', 2, 'MONDAY', '2026-10-26', 2, 'DOUBLES', '2026-09-20 15:34:40.687055+00'),
	('3ea81b2a-014f-4295-9482-0c5e3f5b70d1', 2, 'TUESDAY', '2026-10-27', 1, 'DOUBLES', '2026-09-20 15:34:40.98507+00'),
	('76fb63c3-e467-40f7-bc48-46da3e9a8102', 2, 'TUESDAY', '2026-10-27', 2, 'DOUBLES', '2026-09-20 15:34:41.221839+00'),
	('e623e3ea-764e-4ab7-ab01-c7eaa0c81354', 2, 'WEDNESDAY', '2026-10-28', 1, 'SINGLES', '2026-09-20 15:34:41.4986+00'),
	('f7696afc-9369-4748-8a1d-d4c812d61b15', 3, 'MONDAY', '2026-11-02', 1, 'SINGLES', '2026-09-20 15:34:41.737516+00'),
	('a2ae4d72-08a9-44a3-8ff7-fabca847efc9', 3, 'MONDAY', '2026-11-02', 2, 'DOUBLES', '2026-09-20 15:34:42.021144+00'),
	('afb5f45a-c0fd-4a6d-abc6-8fc080583081', 3, 'TUESDAY', '2026-11-03', 1, 'DOUBLES', '2026-09-20 15:34:42.261878+00'),
	('9a66895d-e6f6-428e-8f8b-a4616201e6b8', 3, 'TUESDAY', '2026-11-03', 2, 'DOUBLES', '2026-09-20 15:34:42.549833+00'),
	('38907462-41e6-4e81-a647-fe02d9b104ad', 3, 'WEDNESDAY', '2026-11-04', 1, 'SINGLES', '2026-09-20 15:34:42.77192+00'),
	('cee91519-8e44-454c-8736-991a0c7b9432', 4, 'MONDAY', '2026-11-09', 1, 'SINGLES', '2026-09-20 15:34:43.083275+00'),
	('899205ca-3e78-4d47-a19a-dd11e5a5b860', 4, 'MONDAY', '2026-11-09', 2, 'DOUBLES', '2026-09-20 15:34:43.301947+00'),
	('889d6938-57fe-4faa-beea-6a4e105afced', 4, 'TUESDAY', '2026-11-10', 1, 'DOUBLES', '2026-09-20 15:34:43.685642+00'),
	('84dcffe7-4544-449e-a56f-9919e331837a', 4, 'TUESDAY', '2026-11-10', 2, 'DOUBLES', '2026-09-20 15:34:43.917599+00'),
	('4d366266-62bc-4776-88ab-410ba5c3e5dc', 4, 'WEDNESDAY', '2026-11-11', 1, 'SINGLES', '2026-09-20 15:34:44.225325+00'),
	('77c8f68d-8299-487e-9ee7-db0e2ce004ec', 5, 'MONDAY', '2026-11-16', 1, 'SINGLES', '2026-09-20 15:34:44.469787+00'),
	('2cb088fa-87f6-4382-be84-f96d906042d5', 5, 'MONDAY', '2026-11-16', 2, 'DOUBLES', '2026-09-20 15:34:44.769728+00'),
	('bb0df7e6-c0ad-42c0-9f22-973e0ae02d66', 5, 'TUESDAY', '2026-11-17', 1, 'DOUBLES', '2026-09-20 15:34:44.977819+00'),
	('1d851557-a880-4080-be2e-e098d2250899', 5, 'TUESDAY', '2026-11-17', 2, 'DOUBLES', '2026-09-20 15:34:45.292325+00'),
	('9fcf2b42-6535-4618-8b8f-9f298f7c3b0c', 5, 'WEDNESDAY', '2026-11-18', 1, 'SINGLES', '2026-09-20 15:34:45.501182+00'),
	('689abbf0-c5cc-42d3-924b-7f404e44ffd5', 6, 'MONDAY', '2026-11-23', 1, 'SINGLES', '2026-09-20 15:34:45.800941+00'),
	('75916de4-9e99-4ffa-939e-500c8736adcc', 6, 'MONDAY', '2026-11-23', 2, 'DOUBLES', '2026-09-20 15:34:46.02852+00'),
	('109dc18f-c6aa-4dbb-a6e7-e5b6725453d1', 6, 'TUESDAY', '2026-11-24', 1, 'DOUBLES', '2026-09-20 15:34:46.33959+00'),
	('8ce5a4f6-f56a-4b2a-b169-d823b163643a', 6, 'TUESDAY', '2026-11-24', 2, 'DOUBLES', '2026-09-20 15:34:46.55319+00'),
	('b75e8e88-c1d3-4f38-8972-6963d753ef56', 6, 'WEDNESDAY', '2026-11-25', 1, 'SINGLES', '2026-09-20 15:34:46.864982+00'),
	('c85b980e-db4f-400a-96e6-c6982d0960cd', 7, 'MONDAY', '2026-11-30', 1, 'SINGLES', '2026-09-20 15:34:47.072344+00'),
	('65fb6cdd-8ef7-47bc-a037-9d7a5869cd31', 7, 'MONDAY', '2026-11-30', 2, 'DOUBLES', '2026-09-20 15:34:47.378277+00'),
	('efaa9992-6fd8-4241-b321-170132b8382c', 7, 'TUESDAY', '2026-12-01', 1, 'DOUBLES', '2026-09-20 15:34:47.594515+00'),
	('df3c69c9-adc6-41aa-910b-b21d207c39ae', 7, 'TUESDAY', '2026-12-01', 2, 'DOUBLES', '2026-09-20 15:34:47.903478+00'),
	('05165895-3197-4700-941f-a2feaa2b9a8d', 7, 'WEDNESDAY', '2026-12-02', 1, 'SINGLES', '2026-09-20 15:34:48.127774+00'),
	('f15fea5c-c548-4acb-9ce0-834b7558066c', 8, 'MONDAY', '2026-12-07', 1, 'SINGLES', '2026-09-20 15:34:48.428975+00'),
	('d33d5606-39b0-4779-b4aa-05ec6f930182', 8, 'MONDAY', '2026-12-07', 2, 'DOUBLES', '2026-09-20 15:34:48.649936+00'),
	('f1746010-670f-4373-a91c-259886e6884b', 8, 'TUESDAY', '2026-12-08', 1, 'DOUBLES', '2026-09-20 15:34:48.949589+00'),
	('b2232217-338d-4cf0-97a8-9ed2c0e41492', 8, 'TUESDAY', '2026-12-08', 2, 'DOUBLES', '2026-09-20 15:34:49.173586+00'),
	('ea8ca30a-84c4-4e60-82a3-3b5123f9dcc2', 8, 'WEDNESDAY', '2026-12-09', 1, 'SINGLES', '2026-09-20 15:34:49.469858+00'),
	('ca8e05a5-d207-4306-a0e5-fa541ed7da40', 9, 'MONDAY', '2026-12-14', 1, 'SINGLES', '2026-09-20 15:34:49.692824+00'),
	('d0014b5e-de9e-4e6e-9dc1-d20b2e17613f', 9, 'MONDAY', '2026-12-14', 2, 'DOUBLES', '2026-09-20 15:34:50.001186+00'),
	('38d384c8-e5fa-403d-b621-5f9e64ada360', 9, 'TUESDAY', '2026-12-15', 1, 'DOUBLES', '2026-09-20 15:34:50.232822+00'),
	('6ba725ab-e2c9-4071-9218-f11230963c3a', 9, 'TUESDAY', '2026-12-15', 2, 'DOUBLES', '2026-09-20 15:34:50.538013+00'),
	('96350eb1-50a2-4c68-816a-81e2e9a5b7e1', 9, 'WEDNESDAY', '2026-12-16', 1, 'SINGLES', '2026-09-20 15:34:50.748641+00'),
	('71be01bc-4275-42ec-abb8-b682f49392ad', 10, 'MONDAY', '2026-12-21', 1, 'SINGLES', '2026-09-20 15:34:51.045775+00'),
	('530682c0-61b8-47da-a8fc-7266229177d8', 10, 'MONDAY', '2026-12-21', 2, 'DOUBLES', '2026-09-20 15:34:51.277206+00'),
	('d8632333-a12a-4fab-ac6b-1b1ae8b2eb30', 10, 'TUESDAY', '2026-12-22', 1, 'DOUBLES', '2026-09-20 15:34:51.571082+00'),
	('4ec4fa95-aca1-4d03-96eb-136d56b87409', 10, 'TUESDAY', '2026-12-22', 2, 'DOUBLES', '2026-09-20 15:34:51.799393+00'),
	('132a61ad-f88f-4165-9e90-2c263d4bb36f', 10, 'WEDNESDAY', '2026-12-23', 1, 'SINGLES', '2026-09-20 15:34:52.100284+00'),
	('f447c2eb-eacd-4d11-b895-26dca791b30d', 11, 'MONDAY', '2026-12-28', 1, 'SINGLES', '2026-09-20 15:34:52.321847+00'),
	('81921172-cd6e-49c2-9d3f-ac1bfec46cfd', 11, 'MONDAY', '2026-12-28', 2, 'DOUBLES', '2026-09-20 15:34:52.614726+00'),
	('0e08629c-996e-4806-839e-4ba39e54191d', 11, 'TUESDAY', '2026-12-29', 1, 'DOUBLES', '2026-09-20 15:34:52.845552+00'),
	('4b4b9151-a7aa-44fd-b9a6-058a775bc344', 11, 'TUESDAY', '2026-12-29', 2, 'DOUBLES', '2026-09-20 15:34:53.140018+00'),
	('62c6713b-6688-47a4-b11f-b3e9d45628e1', 11, 'WEDNESDAY', '2026-12-30', 1, 'SINGLES', '2026-09-20 15:34:53.372923+00'),
	('ec70a75d-40ae-440e-a60b-d2778feb5c54', 12, 'MONDAY', '2027-01-04', 1, 'SINGLES', '2026-09-20 15:34:53.67348+00'),
	('3bd38447-8ecc-4b7b-9b3b-46d2130c967a', 12, 'MONDAY', '2027-01-04', 2, 'DOUBLES', '2026-09-20 15:34:53.90337+00'),
	('aa5dbeb6-09f6-49e8-8285-6521199f7797', 12, 'TUESDAY', '2027-01-05', 1, 'DOUBLES', '2026-09-20 15:34:54.193846+00'),
	('cab45aff-2613-45a4-96ab-143f68698a79', 12, 'TUESDAY', '2027-01-05', 2, 'DOUBLES', '2026-09-20 15:34:54.424008+00'),
	('a52f4b4c-fe15-4832-830d-9614a3ac4214', 12, 'WEDNESDAY', '2027-01-06', 1, 'SINGLES', '2026-09-20 15:34:54.724649+00'),
	('f747a0ec-f689-447e-866f-4011b1cf5ceb', 13, 'MONDAY', '2027-01-11', 1, 'SINGLES', '2026-09-20 15:34:54.944631+00'),
	('13180c10-fda4-4c65-bd86-5d056a15e781', 13, 'MONDAY', '2027-01-11', 2, 'DOUBLES', '2026-09-20 15:34:55.257513+00'),
	('40d371c6-cc54-4eda-bc60-338aa36f8735', 13, 'TUESDAY', '2027-01-12', 1, 'DOUBLES', '2026-09-20 15:34:55.47174+00'),
	('0624c292-7d4e-4105-b12e-550010cd13d5', 13, 'TUESDAY', '2027-01-12', 2, 'DOUBLES', '2026-09-20 15:34:55.770422+00'),
	('2209ef31-ea5a-4bda-a12a-efc62ef4e846', 13, 'WEDNESDAY', '2027-01-13', 1, 'SINGLES', '2026-09-20 15:34:55.998721+00'),
	('8a83b2b8-7881-4e4e-af54-8d0f9f1a7f7e', 14, 'MONDAY', '2027-01-18', 1, 'SINGLES', '2026-09-20 15:34:56.29759+00'),
	('cfdc1463-b9ca-42cb-b0c9-053b4733fd12', 14, 'MONDAY', '2027-01-18', 2, 'DOUBLES', '2026-09-20 15:34:56.505787+00'),
	('b0ef3e8b-13a8-4f66-90ac-1926989126f3', 14, 'TUESDAY', '2027-01-19', 1, 'DOUBLES', '2026-09-20 15:34:56.825689+00'),
	('03f1600b-ede0-4932-98a8-44e85e23eeeb', 14, 'TUESDAY', '2027-01-19', 2, 'DOUBLES', '2026-09-20 15:34:57.037521+00'),
	('d67aacf0-1de3-4b91-b082-f90987cbf932', 14, 'WEDNESDAY', '2027-01-20', 1, 'SINGLES', '2026-09-20 15:34:57.337086+00'),
	('cab061b3-0b62-41ab-bcfd-838596d1a558', 15, 'MONDAY', '2027-01-25', 1, 'SINGLES', '2026-09-20 15:34:57.562412+00'),
	('8ee2487b-3d0b-471c-ad5b-9fb2ffc07d07', 15, 'MONDAY', '2027-01-25', 2, 'DOUBLES', '2026-09-20 15:34:57.862656+00'),
	('5651791b-265a-4436-ac9b-a00b38b071e3', 15, 'TUESDAY', '2027-01-26', 1, 'DOUBLES', '2026-09-20 15:34:58.082798+00'),
	('468dbe12-cd04-4754-93d4-7725205b5d3d', 15, 'TUESDAY', '2027-01-26', 2, 'DOUBLES', '2026-09-20 15:34:58.403133+00'),
	('f62dbad9-bc5a-476f-a412-20428a2399fa', 15, 'WEDNESDAY', '2027-01-27', 1, 'SINGLES', '2026-09-20 15:34:58.629928+00'),
	('6d1e089d-3f69-4e34-8a57-eb291754a1f8', 16, 'MONDAY', '2027-02-01', 1, 'SINGLES', '2026-09-20 15:34:58.912597+00'),
	('6a28091e-cdf9-40db-aa13-4ec151423227', 16, 'MONDAY', '2027-02-01', 2, 'DOUBLES', '2026-09-20 15:34:59.140202+00'),
	('98b71466-45b5-4449-9580-f075a974f2da', 16, 'TUESDAY', '2027-02-02', 1, 'DOUBLES', '2026-09-20 15:34:59.441025+00'),
	('557e741c-c792-41ce-8ded-f07a81fad60f', 16, 'TUESDAY', '2027-02-02', 2, 'DOUBLES', '2026-09-20 15:34:59.665459+00'),
	('546e8734-a23a-483b-8262-b7911fb72fcb', 16, 'WEDNESDAY', '2027-02-03', 1, 'SINGLES', '2026-09-20 15:34:59.963286+00'),
	('3987d72f-4879-4e3f-8d0c-139036f74ea8', 17, 'MONDAY', '2027-02-08', 1, 'SINGLES', '2026-09-20 15:35:00.197326+00'),
	('93961fc3-ba24-4025-8cae-4579b2445997', 17, 'MONDAY', '2027-02-08', 2, 'DOUBLES', '2026-09-20 15:35:00.497562+00'),
	('4e1f1db2-d661-49b6-897f-90f12493bdd0', 17, 'TUESDAY', '2027-02-09', 1, 'DOUBLES', '2026-09-20 15:35:00.71639+00'),
	('123d6358-dba4-491a-bff8-0368571d9262', 17, 'TUESDAY', '2027-02-09', 2, 'DOUBLES', '2026-09-20 15:35:01.01559+00'),
	('fb4b3885-6592-4642-bb83-4dd4ef3c9b0c', 17, 'WEDNESDAY', '2027-02-10', 1, 'SINGLES', '2026-09-20 15:35:01.253701+00'),
	('4f97fb07-b16b-43a5-b0e2-b40f1e7ae53f', 18, 'MONDAY', '2027-02-15', 1, 'SINGLES', '2026-09-20 15:35:01.525513+00'),
	('3a54084f-30f9-4d92-8cad-ff24bd9cb6b1', 18, 'MONDAY', '2027-02-15', 2, 'DOUBLES', '2026-09-20 15:35:01.754795+00'),
	('85a39639-7b93-4358-8263-ff84ce7ba261', 18, 'TUESDAY', '2027-02-16', 1, 'DOUBLES', '2026-09-20 15:35:02.063063+00'),
	('024fc99a-7812-4f37-996f-22df107b06dc', 18, 'TUESDAY', '2027-02-16', 2, 'DOUBLES', '2026-09-20 15:35:02.286476+00'),
	('f3ff48f6-09e3-4dad-a10c-cd481aa77f66', 18, 'WEDNESDAY', '2027-02-17', 1, 'SINGLES', '2026-09-20 15:35:02.5784+00'),
	('7a7c21a3-3df0-4110-8285-d25e1458e440', 19, 'MONDAY', '2027-02-22', 1, 'SINGLES', '2026-09-20 15:35:02.846798+00'),
	('a9df7202-0c6c-4a12-b4b2-732e0e9a2929', 19, 'MONDAY', '2027-02-22', 2, 'DOUBLES', '2026-09-20 15:35:03.119299+00'),
	('ee05cb8c-4fec-4231-9213-48c6ee2d700e', 19, 'TUESDAY', '2027-02-23', 1, 'DOUBLES', '2026-09-20 15:35:03.339808+00'),
	('c8e311f0-7986-4258-b10d-a92070101578', 19, 'TUESDAY', '2027-02-23', 2, 'DOUBLES', '2026-09-20 15:35:03.642062+00'),
	('7b12c4b9-ebe5-4282-a9b7-6ec74689b491', 19, 'WEDNESDAY', '2027-02-24', 1, 'SINGLES', '2026-09-20 15:35:03.853161+00'),
	('6c8894de-abdd-43e8-96c1-199dc64dfd68', 20, 'MONDAY', '2027-03-01', 1, 'SINGLES', '2026-09-20 15:35:04.173081+00'),
	('50b38d5c-3d7f-4696-8441-aa37aec45b98', 20, 'MONDAY', '2027-03-01', 2, 'DOUBLES', '2026-09-20 15:35:04.435471+00'),
	('53b5e761-318b-44b2-8d5b-62bbf1451e4f', 20, 'TUESDAY', '2027-03-02', 1, 'DOUBLES', '2026-09-20 15:35:04.681529+00'),
	('2fb80c8a-4d5d-42b9-a3bb-d87229949d9a', 20, 'TUESDAY', '2027-03-02', 2, 'DOUBLES', '2026-09-20 15:35:04.914047+00'),
	('baee5cb5-0dcf-422b-91b1-f3e0cfc9829c', 20, 'WEDNESDAY', '2027-03-03', 1, 'SINGLES', '2026-09-20 15:35:05.212171+00'),
	('54b08d4a-ccd8-4bb2-9c49-00bffb8d3972', 21, 'MONDAY', '2027-03-08', 1, 'SINGLES', '2026-09-20 15:35:05.457579+00'),
	('d8e6a412-3898-4813-bde0-4f5070e29804', 21, 'MONDAY', '2027-03-08', 2, 'DOUBLES', '2026-09-20 15:35:05.724315+00'),
	('a774587d-cce3-4287-b03f-639122f777d2', 21, 'TUESDAY', '2027-03-09', 1, 'DOUBLES', '2026-09-20 15:35:05.946603+00'),
	('3f55799c-0ff1-403d-ab29-5a181d2f65ae', 22, 'MONDAY', '2027-03-15', 1, 'SINGLES', '2026-09-20 15:35:06.778566+00'),
	('3b8b1270-f557-4899-b5f1-f859af35f2f4', 22, 'TUESDAY', '2027-03-16', 2, 'DOUBLES', '2026-09-20 15:35:07.525841+00'),
	('51b9e1e1-d701-4997-85e3-254e44882b1e', 23, 'MONDAY', '2027-03-22', 2, 'DOUBLES', '2026-09-20 15:35:08.402497+00'),
	('ea8da9ac-b4fd-4555-aced-a0ccab0a4c98', 23, 'TUESDAY', '2027-03-23', 2, 'DOUBLES', '2026-09-20 15:35:08.888285+00'),
	('b20d3538-c1a6-405c-ba9d-25af80db2888', 24, 'MONDAY', '2027-03-29', 2, 'DOUBLES', '2026-09-20 15:35:09.638529+00'),
	('23de1442-e837-4aeb-b0e3-5d419bf4635b', 24, 'WEDNESDAY', '2027-03-31', 1, 'SINGLES', '2026-09-20 15:35:10.450941+00'),
	('292bc695-0247-4176-bbaa-6883c307afe5', 21, 'TUESDAY', '2027-03-09', 2, 'DOUBLES', '2026-09-20 15:35:06.256615+00'),
	('5cb190aa-5f5f-42c2-b573-53ba05b31a07', 22, 'MONDAY', '2027-03-15', 2, 'DOUBLES', '2026-09-20 15:35:06.996063+00'),
	('b73bbecb-4343-4fa0-8779-94b9079596ca', 22, 'WEDNESDAY', '2027-03-17', 1, 'SINGLES', '2026-09-20 15:35:07.843359+00'),
	('b94576c5-5ec0-49ba-81ba-dc0b2b669808', 23, 'TUESDAY', '2027-03-23', 1, 'DOUBLES', '2026-09-20 15:35:08.644339+00'),
	('5e8dda88-e2bf-48d9-acca-14c700db61f1', 23, 'WEDNESDAY', '2027-03-24', 1, 'SINGLES', '2026-09-20 15:35:09.123784+00'),
	('63cab63f-ff65-4972-898e-61717226b132', 24, 'TUESDAY', '2027-03-30', 1, 'DOUBLES', '2026-09-20 15:35:09.932007+00'),
	('d4e0790f-ef3e-48e9-8ca1-d2251032da2c', 21, 'WEDNESDAY', '2027-03-10', 1, 'SINGLES', '2026-09-20 15:35:06.469284+00'),
	('92d0e94b-cd2b-4182-bc2e-c5489b54e966', 22, 'TUESDAY', '2027-03-16', 1, 'DOUBLES', '2026-09-20 15:35:07.302376+00'),
	('e13d0994-3846-4549-98fc-dd8c8032015e', 23, 'MONDAY', '2027-03-22', 1, 'SINGLES', '2026-09-20 15:35:08.082356+00'),
	('066bac07-dc16-4755-97c3-67af53c2ecf8', 24, 'MONDAY', '2027-03-29', 1, 'SINGLES', '2026-09-20 15:35:09.402434+00'),
	('1d1628be-799f-4029-afdb-c50b20f6d7bf', 24, 'TUESDAY', '2027-03-30', 2, 'DOUBLES', '2026-09-20 15:35:10.141494+00');


--
-- Data for Name: players; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."players" ("id", "full_name", "email", "singles_share", "doubles_share", "created_at", "blackout_weeks", "approved", "is_admin", "blackout_days") VALUES
	('ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', 'Derek Miller', 'dmiller@gmail.com', 0.75, 0.50, '2026-09-12 03:55:05.274103+00', '{}', true, false, '{}'),
	('acc69047-4841-426c-9d4c-e03ec410dbab', 'Sam Shah', 'sshah@gmail.com', 0.00, 1.00, '2026-09-12 03:51:25.2971+00', '{}', true, false, '{}'),
	('d43c7c01-a789-41fe-ac86-394f96039e84', 'Sandeep Dhuri', 'sdhuri@gmail.com', 0.00, 0.50, '2026-09-12 03:51:06.763768+00', '{}', true, false, '{}'),
	('713e00dd-adfe-437f-bb08-0e0aa2f49d18', 'Nilesh Shukla', 'nshukla@gmail.com', 0.25, 0.75, '2026-09-12 03:49:59.314463+00', '{}', true, false, '{}'),
	('61fbdbf1-2aff-4952-8de4-f927769f7eb1', 'John Bower', 'jbower@gmail.com', 0.00, 0.25, '2026-09-12 03:49:20.487787+00', '{}', true, false, '{}'),
	('02c73c8f-0818-4320-a711-6541a85c1b3a', 'Joe Basco', 'jbasco@gmail.com', 0.00, 0.50, '2026-09-12 03:47:31.96196+00', '{}', true, false, '{}'),
	('5fef7276-0907-4004-801e-d3b1065140cb', 'Tim Grosso', 'tgrosso@gmail.com', 0.50, 0.50, '2026-09-12 03:47:13.616678+00', '{}', true, false, '{}'),
	('3ad2fedd-1afe-4759-b5e6-046e58bf24d9', 'Jolly Benitez', 'jb@gmail.com', 0.50, 0.50, '2026-09-12 03:45:44.659383+00', '{}', true, false, '{}'),
	('913c45fa-015d-4e3b-aaf8-cd5fe20080b6', 'Jon Chen', 'jdbagby@aol.com', 0.50, 0.50, '2026-09-12 03:47:55.845801+00', '{}', true, false, '{}'),
	('94dd49a0-ba37-472f-aa59-f97f981a6a88', 'Ferran Valldosera', 'fval@gmail.com', 0.50, 0.50, '2026-09-14 00:34:41.956475+00', '{}', true, false, '{}'),
	('caed991a-828a-4d4a-95f0-ef93e4ddd18c', 'Jonathan Bagby', 'jdbagby@gmail.com', 0.00, 0.00, '2026-09-11 19:10:41.198439+00', '{}', true, true, '{}'),
	('deefe2d4-bb2d-4e0a-af20-534b4d83064d', 'Sunny X', 'sx@gmail.com', 0.00, 1.00, '2026-09-12 03:49:03.385242+00', '{}', true, false, '{Tuesday}'),
	('eaff167c-c90a-44fd-ac95-7f3d335bbb8a', 'Rob Jelenik', 'rjelenik@gmail.com', 0.50, 0.00, '2026-09-12 04:01:04.270353+00', '{}', true, false, '{Tuesday,Wednesday}'),
	('4a55ceaf-a12b-4c81-bd46-55f707ee3a00', 'Mike Perron', 'jp@z.com', 0.38, 0.13, '2026-09-19 21:06:39.141558+00', '{13,14,15,16,17,18,19,20,21,22,23,24}', true, false, '{}'),
	('d300860c-1f08-4f8d-afa5-52357b8df69f', 'Steve Kong', 'skong@gmail.com', 0.25, 0.25, '2026-09-12 03:50:28.141013+00', '{}', true, false, '{Tuesday}'),
	('c104549b-2959-4db5-ae83-e528566f7f6a', 'Steve Sandberg', 'ssandberg@gmail.com', 0.25, 0.25, '2026-09-12 03:48:23.413364+00', '{}', true, false, '{Tuesday}'),
	('17981e13-10cc-41f2-a624-23a6a56edce2', 'Dan Bruce', 'dbruce45611@gmail.com', 0.00, 0.50, '2026-09-12 03:34:46.033661+00', '{}', true, false, '{Tuesday}'),
	('bffc63a7-64b2-4c3f-9172-44d0219aaeef', 'Tom Buker', 'tbuker@gmail.com', 0.00, 0.50, '2026-09-12 03:59:30.832198+00', '{}', true, false, '{Monday,Tuesday}'),
	('e7902abf-0412-438c-a065-be122ae01978', 'Akhilesh Kumar', 'akumar@gmail.com', 0.50, 0.50, '2026-09-12 03:46:31.990444+00', '{1}', true, false, '{}'),
	('90347980-3ea6-449c-8891-4f3d2fdc6043', 'Kyle Zola', 'tennisgod1409@aol.com', 0.00, 1.00, '2026-09-11 19:12:02.344468+00', '{}', true, true, '{}');


--
-- Data for Name: match_slots; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."match_slots" ("id", "match_id", "player_id", "original_player_id", "status", "slot_position", "updated_at") VALUES
	('846594ae-4112-488b-8899-9328007ddde0', 'ea8da9ac-b4fd-4555-aced-a0ccab0a4c98', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:09.000558+00'),
	('1f62f48e-08a7-44fe-a852-ec886cc6bcbe', 'ea8da9ac-b4fd-4555-aced-a0ccab0a4c98', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:09.000558+00'),
	('61bde14e-956d-416d-872c-e71182a1a8f6', 'ea8da9ac-b4fd-4555-aced-a0ccab0a4c98', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:09.000558+00'),
	('0360f934-7da0-460d-bce5-305ad11dc10c', 'ea8da9ac-b4fd-4555-aced-a0ccab0a4c98', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:09.000558+00'),
	('73f93c53-6cc7-4427-97ba-93abf5a2ea51', 'b20d3538-c1a6-405c-ba9d-25af80db2888', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:09.811457+00'),
	('dc75f02e-c7e0-41d3-99d2-8e1e08033387', 'b20d3538-c1a6-405c-ba9d-25af80db2888', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:09.811457+00'),
	('8f96cf7c-5112-41ec-8122-2c245df90eda', 'b20d3538-c1a6-405c-ba9d-25af80db2888', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:09.811457+00'),
	('e0af3b9a-1d9b-45b0-a180-57b0d7e9c8a9', 'b20d3538-c1a6-405c-ba9d-25af80db2888', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:09.811457+00'),
	('91df0256-15cc-45ac-bea6-c99a7d02c372', '23de1442-e837-4aeb-b0e3-5d419bf4635b', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:10.552704+00'),
	('30934579-a2eb-412e-a332-6ec5e0fdcd47', '23de1442-e837-4aeb-b0e3-5d419bf4635b', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:10.552704+00'),
	('0cb0cdbc-8957-41b4-bddb-5aad462fd6d4', '5e8dda88-e2bf-48d9-acca-14c700db61f1', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:09.288981+00'),
	('4733a9f2-0c24-46dc-b878-ed4130c251c0', '5e8dda88-e2bf-48d9-acca-14c700db61f1', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:09.288981+00'),
	('ce996dc1-5ea8-4122-94ed-abb71fe6932e', '63cab63f-ff65-4972-898e-61717226b132', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:10.035815+00'),
	('4dc22f54-aa71-4f37-9ddb-19fd5eaeaa10', '63cab63f-ff65-4972-898e-61717226b132', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:10.035815+00'),
	('2667c0ac-fad6-4e1a-ab9c-2c5178efb0c6', '63cab63f-ff65-4972-898e-61717226b132', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:10.035815+00'),
	('59dcaa35-a5be-4319-9c8e-4e8df08e32e1', '63cab63f-ff65-4972-898e-61717226b132', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:10.035815+00'),
	('eda75d75-bb62-4bc8-ada3-ae243606eedd', '066bac07-dc16-4755-97c3-67af53c2ecf8', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:09.519002+00'),
	('5360bd8a-67e1-4c13-91bd-1005184a6960', '066bac07-dc16-4755-97c3-67af53c2ecf8', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:09.519002+00'),
	('0d8a04e7-d27f-4ff5-8f20-df9e92e42a5d', '1d1628be-799f-4029-afdb-c50b20f6d7bf', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:10.332442+00'),
	('e017ccb8-7230-4713-a440-970b3663a3cb', '1d1628be-799f-4029-afdb-c50b20f6d7bf', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:10.332442+00'),
	('f26bcb41-efc1-4dec-bf59-f579411baf5e', '1d1628be-799f-4029-afdb-c50b20f6d7bf', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:10.332442+00'),
	('96f543d2-b730-41dc-93e1-33f63b8afbbd', '1d1628be-799f-4029-afdb-c50b20f6d7bf', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:10.332442+00'),
	('0e8d7736-d574-4311-a379-809b7d8c173f', 'b49d1a96-21a5-4699-bb0e-7a61567c5c25', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:39.248098+00'),
	('bc927f36-7f1b-424b-b86b-648f7f3fddce', 'b49d1a96-21a5-4699-bb0e-7a61567c5c25', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:39.248098+00'),
	('60859bd8-81be-495b-a9e7-386c387e8530', 'e726701e-c23b-4c9c-9505-183158ad4988', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:39.526631+00'),
	('aa61efef-d2ba-42f5-ae81-153b32a85f4f', 'e726701e-c23b-4c9c-9505-183158ad4988', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:39.526631+00'),
	('f5c968e4-0940-45dd-97b9-d6ae89a5151b', 'e726701e-c23b-4c9c-9505-183158ad4988', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:39.526631+00'),
	('a11a3fae-663c-412a-8c9e-35636611b12c', 'e726701e-c23b-4c9c-9505-183158ad4988', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:39.526631+00'),
	('f8a1c3cd-9e6d-49f6-ad85-a4a45506c92c', '740f492c-fa78-45b8-95c3-27d0841e9249', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:39.750619+00'),
	('8f04498a-f3ca-43e2-a1bb-6a9d32154217', '740f492c-fa78-45b8-95c3-27d0841e9249', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:39.750619+00'),
	('121e033e-5ca6-4e75-a9e8-1290d9b1e01e', '740f492c-fa78-45b8-95c3-27d0841e9249', '4a55ceaf-a12b-4c81-bd46-55f707ee3a00', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:39.750619+00'),
	('e3cbd082-72f0-4289-9132-10f84d314100', '740f492c-fa78-45b8-95c3-27d0841e9249', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:39.750619+00'),
	('6733e092-a930-4c39-8fec-9eaeb9fbd0ec', 'e30201e6-53c5-4425-b50f-7571cc750f3a', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:40.045223+00'),
	('8065e648-4a9e-4b6a-9ea3-8d195283e173', 'e30201e6-53c5-4425-b50f-7571cc750f3a', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:40.045223+00'),
	('4a51b33a-3d7c-4ed2-8b57-14f06c007dff', 'e30201e6-53c5-4425-b50f-7571cc750f3a', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:40.045223+00'),
	('c1bc4aa3-c8fa-4097-bb18-2160793f96aa', 'e30201e6-53c5-4425-b50f-7571cc750f3a', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:40.045223+00'),
	('dc5f1471-6455-4f76-b971-b4a690ee989b', '9d256ff9-90be-4e8b-bdd6-b94c0b70ada0', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:40.274355+00'),
	('d7d2fe1a-c540-4fdb-805e-f57e64bba385', '9d256ff9-90be-4e8b-bdd6-b94c0b70ada0', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:40.274355+00'),
	('f0670e10-5d6f-481d-b5ce-2c043ab04e23', 'da1ab58b-823a-4fc5-9860-fef044336921', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:40.565735+00'),
	('2696f1c9-3624-4d55-ae45-df89ca222acb', 'da1ab58b-823a-4fc5-9860-fef044336921', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:40.565735+00'),
	('3a30d192-eb85-4dbe-82eb-9916d06a1f67', 'e894960c-102b-4018-a492-08b058ec96d1', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:40.803231+00'),
	('7513cd81-1308-46c7-acca-4d48670d9bac', 'e894960c-102b-4018-a492-08b058ec96d1', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:40.803231+00'),
	('9b6d6727-a0fc-477f-ab6e-8594bf475365', 'e894960c-102b-4018-a492-08b058ec96d1', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:40.803231+00'),
	('196ae758-c24d-457e-80ab-05ddc4589c08', 'e894960c-102b-4018-a492-08b058ec96d1', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:40.803231+00'),
	('c783660c-f46c-4253-87cb-32a7d084f9b1', '3ea81b2a-014f-4295-9482-0c5e3f5b70d1', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:41.09879+00'),
	('b5e89c10-4d2c-4a91-9811-a87d6f61a002', '3ea81b2a-014f-4295-9482-0c5e3f5b70d1', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:41.09879+00'),
	('2291c511-fda5-498f-adb7-76546976b5db', '3ea81b2a-014f-4295-9482-0c5e3f5b70d1', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:41.09879+00'),
	('a570e049-e45c-4bb2-ac5b-8df8f47d3ab0', '3ea81b2a-014f-4295-9482-0c5e3f5b70d1', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:41.09879+00'),
	('fd30de8e-1b1a-42a6-b660-3c3e3bdfce16', '76fb63c3-e467-40f7-bc48-46da3e9a8102', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:41.330655+00'),
	('02305562-e94d-4682-bb63-5292e545cdae', '76fb63c3-e467-40f7-bc48-46da3e9a8102', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:41.330655+00'),
	('422e347c-d8d7-475d-afaa-629ccc3bfa6b', '76fb63c3-e467-40f7-bc48-46da3e9a8102', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:41.330655+00'),
	('54bbee13-03bc-48b7-8cb0-7ab9e78f6dcf', '76fb63c3-e467-40f7-bc48-46da3e9a8102', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:41.330655+00'),
	('2cc4252d-c090-4459-9384-b6050e5d52cd', 'e623e3ea-764e-4ab7-ab01-c7eaa0c81354', '4a55ceaf-a12b-4c81-bd46-55f707ee3a00', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:41.614558+00'),
	('90614587-d747-4b32-9015-45f5e0d7af1f', 'e623e3ea-764e-4ab7-ab01-c7eaa0c81354', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:41.614558+00'),
	('56da69c1-3194-4d59-9259-49d7a75614a5', 'f7696afc-9369-4748-8a1d-d4c812d61b15', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:41.849118+00'),
	('445c6abe-04c2-4da1-b45d-f7a33a2ece76', 'f7696afc-9369-4748-8a1d-d4c812d61b15', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:41.849118+00'),
	('a39a36d1-3177-4f86-bf56-dc41358a3b8e', 'a2ae4d72-08a9-44a3-8ff7-fabca847efc9', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:42.155588+00'),
	('603ccfde-193d-4209-b3bc-20244dc6828d', 'a2ae4d72-08a9-44a3-8ff7-fabca847efc9', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:42.155588+00'),
	('e933bd15-b345-468e-bd04-b8588721a048', 'a2ae4d72-08a9-44a3-8ff7-fabca847efc9', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:42.155588+00'),
	('ab37f0b5-857f-4f3c-a8fd-d6a5690791bb', 'a2ae4d72-08a9-44a3-8ff7-fabca847efc9', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:42.155588+00'),
	('2a18a3ba-0167-44e0-bb3c-d6e36a89311e', 'afb5f45a-c0fd-4a6d-abc6-8fc080583081', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:42.37806+00'),
	('e0da4ab2-65ac-46d4-9942-0cdd562714fe', 'afb5f45a-c0fd-4a6d-abc6-8fc080583081', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:42.37806+00'),
	('227dbb7e-cf42-4b9a-9d73-3b0f8f5fe313', 'afb5f45a-c0fd-4a6d-abc6-8fc080583081', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:42.37806+00'),
	('88f80534-55f0-4df1-b481-cadca267bca7', 'afb5f45a-c0fd-4a6d-abc6-8fc080583081', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:42.37806+00'),
	('d922c035-fb2a-4b82-8081-77296528a5d9', '9a66895d-e6f6-428e-8f8b-a4616201e6b8', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:42.670808+00'),
	('b636cf8e-71fd-47e4-b4c9-50cf81dddf61', '9a66895d-e6f6-428e-8f8b-a4616201e6b8', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:42.670808+00'),
	('b18e2465-4e04-4bc3-89c2-c3fa5fa6d57f', '9a66895d-e6f6-428e-8f8b-a4616201e6b8', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:42.670808+00'),
	('2ebfb9fc-9131-4a34-a0ba-fafa10ed3f79', '9a66895d-e6f6-428e-8f8b-a4616201e6b8', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:42.670808+00'),
	('231a65a1-ece2-4be3-8583-373c7c560cdd', '38907462-41e6-4e81-a647-fe02d9b104ad', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:42.883573+00'),
	('59fedee8-67ad-4b50-af6d-0a38ec22aef2', '38907462-41e6-4e81-a647-fe02d9b104ad', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:42.883573+00'),
	('75da40f5-05d7-47f4-bc5d-6a2727d2e1b2', 'cee91519-8e44-454c-8736-991a0c7b9432', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:43.201598+00'),
	('69aecb14-da39-437e-bf29-8fd789c7aadf', 'cee91519-8e44-454c-8736-991a0c7b9432', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:43.201598+00'),
	('41bca538-37a8-4dc1-b079-28899778407b', '899205ca-3e78-4d47-a19a-dd11e5a5b860', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:43.577013+00'),
	('93cb4c69-287c-491c-a98d-4471422f9dfc', '899205ca-3e78-4d47-a19a-dd11e5a5b860', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:43.577013+00'),
	('a553a3fb-55df-40ec-ab87-44b0f56064cc', '899205ca-3e78-4d47-a19a-dd11e5a5b860', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:43.577013+00'),
	('b46084d7-eb65-4b2e-a719-b5981859ae52', '899205ca-3e78-4d47-a19a-dd11e5a5b860', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:43.577013+00'),
	('8534400a-10e7-47fe-b953-777b25e16efd', '889d6938-57fe-4faa-beea-6a4e105afced', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:43.813033+00'),
	('d475dfef-75de-4a76-b63a-74b9b8c4a597', '889d6938-57fe-4faa-beea-6a4e105afced', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:43.813033+00'),
	('949b69b8-ed5d-4755-8bc1-5e0a4e3f1eb5', '889d6938-57fe-4faa-beea-6a4e105afced', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:43.813033+00'),
	('5ec1dcdf-0e69-4698-bf57-a7305b6691aa', '889d6938-57fe-4faa-beea-6a4e105afced', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:43.813033+00'),
	('93443fd6-827e-4ae2-81ea-5efe72e7ac38', '84dcffe7-4544-449e-a56f-9919e331837a', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:44.110306+00'),
	('b76e1c43-081a-4b85-b4b5-9c3ca664953c', '84dcffe7-4544-449e-a56f-9919e331837a', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:44.110306+00'),
	('3d01c62e-9ff6-44f1-b0d0-fb4848fd200f', '84dcffe7-4544-449e-a56f-9919e331837a', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:44.110306+00'),
	('bd7b7f65-0dc3-4879-8705-14a73e4fa503', '84dcffe7-4544-449e-a56f-9919e331837a', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:44.110306+00'),
	('24a2e285-cfd6-4326-8caf-b6eaaa0ec7ac', '2cb088fa-87f6-4382-be84-f96d906042d5', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:44.871025+00'),
	('02ebcb1f-7049-4b18-a241-4247cef363fb', '2cb088fa-87f6-4382-be84-f96d906042d5', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:44.871025+00'),
	('718d8f0f-9d4c-400c-8930-adb2ca1fae81', '2cb088fa-87f6-4382-be84-f96d906042d5', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:44.871025+00'),
	('420d401c-1cb5-4a14-8256-00db98d5ab85', '2cb088fa-87f6-4382-be84-f96d906042d5', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:44.871025+00'),
	('3d7fbb86-b3e1-4a9b-b928-11f756ceba52', '9fcf2b42-6535-4618-8b8f-9f298f7c3b0c', '4a55ceaf-a12b-4c81-bd46-55f707ee3a00', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:45.700622+00'),
	('95f724dd-549f-48fa-be5b-386e8139ea8b', '9fcf2b42-6535-4618-8b8f-9f298f7c3b0c', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:45.700622+00'),
	('29082f97-e9f5-439f-adf5-e14f331306b5', '109dc18f-c6aa-4dbb-a6e7-e5b6725453d1', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:46.448948+00'),
	('e8fe9aec-c732-4cf1-b347-c859127a68c4', '109dc18f-c6aa-4dbb-a6e7-e5b6725453d1', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:46.448948+00'),
	('ac8eae9c-8b6f-4e8d-9cd9-b861f9684302', '109dc18f-c6aa-4dbb-a6e7-e5b6725453d1', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:46.448948+00'),
	('3717cc64-b01f-446b-ac1a-de4073bdf9ed', '109dc18f-c6aa-4dbb-a6e7-e5b6725453d1', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:46.448948+00'),
	('37780eb8-5f94-4c6e-826c-56356dcd2aff', 'c85b980e-db4f-400a-96e6-c6982d0960cd', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:47.276411+00'),
	('bebd9667-e77e-4117-828f-6dee7818ca99', 'c85b980e-db4f-400a-96e6-c6982d0960cd', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:47.276411+00'),
	('be0c36c9-3748-44f4-9ef9-2fd43d9799cc', 'df3c69c9-adc6-41aa-910b-b21d207c39ae', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:48.018259+00'),
	('a9dd0b57-6471-472f-9da5-93248aef27b7', 'df3c69c9-adc6-41aa-910b-b21d207c39ae', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:48.018259+00'),
	('8d0dc856-c3da-4edf-966a-2c5cf54e8953', 'df3c69c9-adc6-41aa-910b-b21d207c39ae', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:48.018259+00'),
	('008afd90-cab8-46cc-9894-8f6340b7cd7d', 'df3c69c9-adc6-41aa-910b-b21d207c39ae', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:48.018259+00'),
	('7ff11661-f05a-428a-b8af-246a24395bc1', 'd33d5606-39b0-4779-b4aa-05ec6f930182', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:48.842568+00'),
	('7acda2c4-4393-4090-8d36-89dac2c6f781', 'd33d5606-39b0-4779-b4aa-05ec6f930182', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:48.842568+00'),
	('516e7dfd-eec7-4ef8-90a5-b550e3d4e3ea', 'd33d5606-39b0-4779-b4aa-05ec6f930182', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:48.842568+00'),
	('bd4f929f-6c70-48af-91d7-f809bbf3c0b7', 'd33d5606-39b0-4779-b4aa-05ec6f930182', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:48.842568+00'),
	('60d4961e-017b-44a6-a3e1-a3250ab5fae3', 'ea8ca30a-84c4-4e60-82a3-3b5123f9dcc2', '4a55ceaf-a12b-4c81-bd46-55f707ee3a00', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:49.588641+00'),
	('827d1fbf-213b-4ff3-b56f-b9c4ae977951', 'ea8ca30a-84c4-4e60-82a3-3b5123f9dcc2', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:49.588641+00'),
	('cfdf8bb6-97f4-4177-b945-c06eb9b181c7', '38d384c8-e5fa-403d-b621-5f9e64ada360', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:50.416591+00'),
	('07a803fe-23af-46ee-a6ec-9c8684158a63', '38d384c8-e5fa-403d-b621-5f9e64ada360', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:50.416591+00'),
	('b21418e2-f31d-4fe9-9ea8-ec77027bd0c0', '38d384c8-e5fa-403d-b621-5f9e64ada360', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:50.416591+00'),
	('cb0eabe9-a257-4957-8344-023e5949dd80', '38d384c8-e5fa-403d-b621-5f9e64ada360', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:50.416591+00'),
	('cc8f8016-feb7-433c-90f9-2322ebbb764a', '71be01bc-4275-42ec-abb8-b682f49392ad', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:51.158783+00'),
	('5b2aa99e-1cb5-4637-a8b0-8981eefb2d21', '71be01bc-4275-42ec-abb8-b682f49392ad', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:51.158783+00'),
	('ab534d95-90eb-4bc5-8008-2c7d22bb553e', '4ec4fa95-aca1-4d03-96eb-136d56b87409', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:51.985386+00'),
	('4b55c076-d5d4-4f79-95db-48d342aa8f2f', '4ec4fa95-aca1-4d03-96eb-136d56b87409', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:51.985386+00'),
	('aa3043ba-d29a-4099-a49d-61832ab87358', '4ec4fa95-aca1-4d03-96eb-136d56b87409', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:51.985386+00'),
	('8dbdf8c2-9584-4c3d-af8e-282e8f5a1825', '4ec4fa95-aca1-4d03-96eb-136d56b87409', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:51.985386+00'),
	('310a067e-9353-4d9c-a8f3-fd4ac61a5308', '81921172-cd6e-49c2-9d3f-ac1bfec46cfd', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:52.741811+00'),
	('21e33beb-de8c-4487-a168-9907c13bffb0', '81921172-cd6e-49c2-9d3f-ac1bfec46cfd', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:52.741811+00'),
	('29aa9294-eeb3-4568-9859-c9372d615b63', '81921172-cd6e-49c2-9d3f-ac1bfec46cfd', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:52.741811+00'),
	('9e524c52-4029-4bd0-b228-7ab6ecb15500', '81921172-cd6e-49c2-9d3f-ac1bfec46cfd', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:52.741811+00'),
	('6e0d8d88-289d-465b-b3eb-03123e089de3', '62c6713b-6688-47a4-b11f-b3e9d45628e1', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:53.561125+00'),
	('8281f8f5-495e-4c02-a27a-8b014968c61e', '62c6713b-6688-47a4-b11f-b3e9d45628e1', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:53.561125+00'),
	('2f70c581-6870-4124-a934-74d0ea36cae5', 'aa5dbeb6-09f6-49e8-8285-6521199f7797', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:54.322753+00'),
	('44d60440-b237-4922-9b3c-4f81d81f6f35', 'aa5dbeb6-09f6-49e8-8285-6521199f7797', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:54.322753+00'),
	('135c244b-5803-466b-accd-142776beecbc', 'aa5dbeb6-09f6-49e8-8285-6521199f7797', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:54.322753+00'),
	('bb81aa04-ab2d-488c-bd75-4671c18333a0', 'aa5dbeb6-09f6-49e8-8285-6521199f7797', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:54.322753+00'),
	('2e48d49f-1545-4ed2-886d-e4f405b04f81', 'f747a0ec-f689-447e-866f-4011b1cf5ceb', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:55.132574+00'),
	('a4ef7713-2892-4af7-a606-2e6684629bbd', 'f747a0ec-f689-447e-866f-4011b1cf5ceb', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:55.132574+00'),
	('b523fd70-c1a5-44a6-bf7f-3dcc0f1521a1', '0624c292-7d4e-4105-b12e-550010cd13d5', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:55.875516+00'),
	('3ec16ccd-6fdf-409e-9911-3e8be6a13114', '0624c292-7d4e-4105-b12e-550010cd13d5', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:55.875516+00'),
	('42fd637e-4ee3-4ea1-a34d-eea068ceece8', '0624c292-7d4e-4105-b12e-550010cd13d5', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:55.875516+00'),
	('79f075f3-9324-43a8-bd15-4f44138273d4', '0624c292-7d4e-4105-b12e-550010cd13d5', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:55.875516+00'),
	('cc724216-a3ad-489f-a170-206d45b79bfc', 'cfdc1463-b9ca-42cb-b0c9-053b4733fd12', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:56.702198+00'),
	('d55b9f1b-3b68-45b4-832d-1f851118a666', 'cfdc1463-b9ca-42cb-b0c9-053b4733fd12', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:56.702198+00'),
	('dd9fd905-a896-4865-a054-16489763f30f', 'cfdc1463-b9ca-42cb-b0c9-053b4733fd12', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:56.702198+00'),
	('07eb7a4b-c32d-4f67-930f-f8006ab3cbf9', 'cfdc1463-b9ca-42cb-b0c9-053b4733fd12', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:56.702198+00'),
	('e45934d1-7b11-45aa-aa4b-aa4734dd87d0', 'd67aacf0-1de3-4b91-b082-f90987cbf932', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:57.452883+00'),
	('a5552c47-c468-4bff-91a8-58180cf9982f', 'd67aacf0-1de3-4b91-b082-f90987cbf932', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:57.452883+00'),
	('d45f8b91-7804-4cdd-a608-91c4e921ceac', '5651791b-265a-4436-ac9b-a00b38b071e3', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:58.295594+00'),
	('49d8ffc8-6fb7-4578-b8b0-8ad088aef04f', '5651791b-265a-4436-ac9b-a00b38b071e3', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:58.295594+00'),
	('8106687b-fc14-42cf-93eb-3070ab398366', '5651791b-265a-4436-ac9b-a00b38b071e3', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:58.295594+00'),
	('5e258726-4865-45e9-a83d-635ed03b6649', '5651791b-265a-4436-ac9b-a00b38b071e3', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:58.295594+00'),
	('71a67795-cf59-4aa8-9bd4-948ba6c0f539', '6d1e089d-3f69-4e34-8a57-eb291754a1f8', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:59.019374+00'),
	('ea63ea57-b567-4b02-bbf8-c1e9c2d27663', '6d1e089d-3f69-4e34-8a57-eb291754a1f8', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:59.019374+00'),
	('37863033-2903-45cb-9088-f8fb21e6cf76', '557e741c-c792-41ce-8ded-f07a81fad60f', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:59.846644+00'),
	('3f04a20f-24f8-44b7-b968-6a3993ba0683', '557e741c-c792-41ce-8ded-f07a81fad60f', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:59.846644+00'),
	('2cf8bdfc-0b42-478f-b651-b644ef895199', '557e741c-c792-41ce-8ded-f07a81fad60f', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:59.846644+00'),
	('e846d5b9-7de1-4c3f-8009-b344d524b57b', '557e741c-c792-41ce-8ded-f07a81fad60f', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:59.846644+00'),
	('bc6c82e3-5744-4082-ac51-792915a69bf5', '93961fc3-ba24-4025-8cae-4579b2445997', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:00.604646+00'),
	('75b13efc-4d20-4607-9b9a-1ab3583563f4', '93961fc3-ba24-4025-8cae-4579b2445997', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:00.604646+00'),
	('1532e25f-eccf-4d7c-a946-289711d1f772', '93961fc3-ba24-4025-8cae-4579b2445997', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:00.604646+00'),
	('90ec62af-43d5-4121-b210-51c524922aaf', '93961fc3-ba24-4025-8cae-4579b2445997', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:00.604646+00'),
	('da67fa5b-26ba-4fd3-ac68-34781c0f1c7a', 'fb4b3885-6592-4642-bb83-4dd4ef3c9b0c', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:01.422473+00'),
	('50e46f6b-b62d-4d4b-b791-58e07cc8cf59', 'fb4b3885-6592-4642-bb83-4dd4ef3c9b0c', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:01.422473+00'),
	('b8581a8f-a235-4d72-a662-ec0427aee54a', '85a39639-7b93-4358-8263-ff84ce7ba261', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:02.186267+00'),
	('740d9dea-4619-4a82-88ff-58a17b53e6e5', '85a39639-7b93-4358-8263-ff84ce7ba261', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:02.186267+00'),
	('759f788d-9b05-465c-ba4d-baad7859d1d5', '85a39639-7b93-4358-8263-ff84ce7ba261', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:02.186267+00'),
	('371cab7b-fdc3-417d-9ef2-3a629a230c2c', '85a39639-7b93-4358-8263-ff84ce7ba261', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:02.186267+00'),
	('f6e34f18-076a-41ed-8d31-8892427aa142', '7a7c21a3-3df0-4110-8285-d25e1458e440', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:02.999665+00'),
	('318a0118-156f-4561-90a9-1b9ebefdb168', '7a7c21a3-3df0-4110-8285-d25e1458e440', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:02.999665+00'),
	('88985149-736b-4702-9b09-5e4b1d603614', 'c8e311f0-7986-4258-b10d-a92070101578', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:03.742+00'),
	('cb943194-e090-4f15-be42-6892d6810a8a', 'c8e311f0-7986-4258-b10d-a92070101578', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:03.742+00'),
	('87794ba5-0349-468a-ae5a-e8e00214c0a9', 'c8e311f0-7986-4258-b10d-a92070101578', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:03.742+00'),
	('5d48dfc7-687f-4e9c-8e92-15c0427f85e7', 'c8e311f0-7986-4258-b10d-a92070101578', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:03.742+00'),
	('953fad0d-3c0a-4876-a76a-91547ec8b14c', '50b38d5c-3d7f-4696-8441-aa37aec45b98', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:04.577685+00'),
	('476b2286-09c2-4aca-9f34-1d61b09eebcd', '50b38d5c-3d7f-4696-8441-aa37aec45b98', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:04.577685+00'),
	('12f7c51b-844d-4100-9fb7-42b259b8400e', '50b38d5c-3d7f-4696-8441-aa37aec45b98', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:04.577685+00'),
	('7d69b723-1db4-4ad2-8d77-f8ebf5d09543', '50b38d5c-3d7f-4696-8441-aa37aec45b98', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:04.577685+00'),
	('b1dc90d9-70bc-4a33-b3bf-d9e9bee0b33f', 'baee5cb5-0dcf-422b-91b1-f3e0cfc9829c', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:05.330869+00'),
	('99b1db8f-14c1-4085-a389-5e2ff61cd7e8', 'baee5cb5-0dcf-422b-91b1-f3e0cfc9829c', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:05.330869+00'),
	('3c8beee0-c213-4727-bc59-548749d74184', 'a774587d-cce3-4287-b03f-639122f777d2', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:06.137025+00'),
	('ef8a38a4-344d-42ee-b2cd-ebf1417cb541', '4d366266-62bc-4776-88ab-410ba5c3e5dc', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:44.36029+00'),
	('7a142360-8bd1-4885-83eb-14fd6bb762ae', '4d366266-62bc-4776-88ab-410ba5c3e5dc', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:44.36029+00'),
	('dda0ea7f-09be-4e23-bf00-f83a15bff6f8', 'bb0df7e6-c0ad-42c0-9f22-973e0ae02d66', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:45.17298+00'),
	('9485ac69-a76b-4167-8450-f7ff7424c1a5', 'bb0df7e6-c0ad-42c0-9f22-973e0ae02d66', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:45.17298+00'),
	('0a21aa7b-e50e-4dd0-b73b-68cdb999b652', 'bb0df7e6-c0ad-42c0-9f22-973e0ae02d66', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:45.17298+00'),
	('86d67adb-bea0-4875-81a7-d999954a5265', 'bb0df7e6-c0ad-42c0-9f22-973e0ae02d66', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:45.17298+00'),
	('2c77951f-ce93-47e0-a5be-f4763b534800', '689abbf0-c5cc-42d3-924b-7f404e44ffd5', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:45.90571+00'),
	('5b5ffa5c-1c1b-4a9e-96e2-9dcc6375ebcf', '689abbf0-c5cc-42d3-924b-7f404e44ffd5', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:45.90571+00'),
	('d2cc6c24-a00b-4a53-b7f9-28c2eed6a604', '8ce5a4f6-f56a-4b2a-b169-d823b163643a', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:46.742854+00'),
	('22e9fd8a-2598-4b73-8671-f416aee19868', '8ce5a4f6-f56a-4b2a-b169-d823b163643a', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:46.742854+00'),
	('f77abec1-56de-4603-9f46-090c9e1d9ec1', '8ce5a4f6-f56a-4b2a-b169-d823b163643a', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:46.742854+00'),
	('764f087f-c555-464b-a299-f6ef61ddcfdc', '8ce5a4f6-f56a-4b2a-b169-d823b163643a', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:46.742854+00'),
	('620730d0-501b-4289-acb7-bac0d51ecc61', '65fb6cdd-8ef7-47bc-a037-9d7a5869cd31', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:47.488619+00'),
	('677f4e3f-57ae-427c-8322-7d8bd7fb5776', '65fb6cdd-8ef7-47bc-a037-9d7a5869cd31', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:47.488619+00'),
	('e34196f6-64fc-4061-bebf-dd96f0ab53d7', '65fb6cdd-8ef7-47bc-a037-9d7a5869cd31', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:47.488619+00'),
	('50bd7c0b-2d97-4b9e-9a7a-9b792d4293ff', '65fb6cdd-8ef7-47bc-a037-9d7a5869cd31', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:47.488619+00'),
	('ff16907b-06bd-4306-b30a-2c1431a4cf6c', '05165895-3197-4700-941f-a2feaa2b9a8d', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:48.328675+00'),
	('2dc982e6-6f92-4aea-9de7-68500fb0715e', '05165895-3197-4700-941f-a2feaa2b9a8d', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:48.328675+00'),
	('3d9e15d7-3291-4364-9046-2c034b2d5e4f', 'f1746010-670f-4373-a91c-259886e6884b', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:49.072459+00'),
	('74f8ab07-29b7-4173-bbc1-0065365c7e98', 'f1746010-670f-4373-a91c-259886e6884b', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:49.072459+00'),
	('6b805d11-8965-450e-8770-e4332d2eb7d3', 'f1746010-670f-4373-a91c-259886e6884b', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:49.072459+00'),
	('2fbbff97-d7cd-40a2-9135-996c5e30a13a', 'f1746010-670f-4373-a91c-259886e6884b', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:49.072459+00'),
	('cdebad28-b592-4e0e-a518-ec08dcf4f27a', 'ca8e05a5-d207-4306-a0e5-fa541ed7da40', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:49.891181+00'),
	('1f5a3808-dae9-4f6d-b075-17d72ab7e91f', 'ca8e05a5-d207-4306-a0e5-fa541ed7da40', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:49.891181+00'),
	('a2abf09b-b68d-4c34-aa7f-53a0933282e3', '6ba725ab-e2c9-4071-9218-f11230963c3a', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:50.638171+00'),
	('d18ba86d-3200-4641-94bf-cf59d646dfdc', '6ba725ab-e2c9-4071-9218-f11230963c3a', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:50.638171+00'),
	('9cb5d411-4dcb-4458-905a-ca54f0945f66', '6ba725ab-e2c9-4071-9218-f11230963c3a', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:50.638171+00'),
	('dbac77fa-df4f-4c29-b424-f29b0bb4b04f', '6ba725ab-e2c9-4071-9218-f11230963c3a', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:50.638171+00'),
	('d9d8ded7-56e4-485e-8a60-0c58873be736', '530682c0-61b8-47da-a8fc-7266229177d8', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:51.46399+00'),
	('4fbd460a-4e63-42be-82e5-c28177dbe051', '530682c0-61b8-47da-a8fc-7266229177d8', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:51.46399+00'),
	('aa8755ba-4d44-43c8-9cc1-1d7bae5b07ac', '530682c0-61b8-47da-a8fc-7266229177d8', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:51.46399+00'),
	('2edc46ee-82a6-4faa-84aa-81d34b93e0b3', '530682c0-61b8-47da-a8fc-7266229177d8', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:51.46399+00'),
	('aba4994b-6439-4f2f-99d3-ec73d2bf7c90', '132a61ad-f88f-4165-9e90-2c263d4bb36f', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:52.222794+00'),
	('0e225f74-408a-4363-85d5-5155d48c360f', '132a61ad-f88f-4165-9e90-2c263d4bb36f', '4a55ceaf-a12b-4c81-bd46-55f707ee3a00', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:52.222794+00'),
	('d93fbc59-551a-47de-931c-698e50000a36', '0e08629c-996e-4806-839e-4ba39e54191d', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:53.030588+00'),
	('4abcda6f-01a6-4fbc-af4e-2f2d00b053df', '0e08629c-996e-4806-839e-4ba39e54191d', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:53.030588+00'),
	('be4ecf2c-d848-4be3-a4b9-eb4af330627a', '0e08629c-996e-4806-839e-4ba39e54191d', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:53.030588+00'),
	('5eb659ba-0a6f-4c91-bf67-3789a98494a8', '0e08629c-996e-4806-839e-4ba39e54191d', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:53.030588+00'),
	('fb47a99a-46ef-4727-af65-ea79e68ad18a', 'ec70a75d-40ae-440e-a60b-d2778feb5c54', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:53.797356+00'),
	('50127c8d-dfd4-464a-9770-1ca0a9a98e18', 'ec70a75d-40ae-440e-a60b-d2778feb5c54', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:53.797356+00'),
	('ef71b006-1dd4-4a10-a238-969459ea605e', 'cab45aff-2613-45a4-96ab-143f68698a79', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:54.605789+00'),
	('8eed6020-7bcb-4991-a711-81147b48f240', 'cab45aff-2613-45a4-96ab-143f68698a79', '4a55ceaf-a12b-4c81-bd46-55f707ee3a00', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:54.605789+00'),
	('54437300-b5f2-408a-903b-c1464f35cf99', 'cab45aff-2613-45a4-96ab-143f68698a79', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:54.605789+00'),
	('8f2ad0d1-096c-48e5-aeb4-41c86103fc20', 'cab45aff-2613-45a4-96ab-143f68698a79', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:54.605789+00'),
	('276ce7a7-9086-4b2f-a642-83d5a1fbae4e', '13180c10-fda4-4c65-bd86-5d056a15e781', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:55.361916+00'),
	('29f04ac3-7f70-4d8d-98cd-b2a6cf0fe5fe', '13180c10-fda4-4c65-bd86-5d056a15e781', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:55.361916+00'),
	('70bcae73-a8b5-4baa-bde6-d68bd4ab3e06', '13180c10-fda4-4c65-bd86-5d056a15e781', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:55.361916+00'),
	('242bab7a-ade2-4885-a929-f692ddb516db', '13180c10-fda4-4c65-bd86-5d056a15e781', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:55.361916+00'),
	('ade773c8-2a9e-4099-9f01-7f843f3367e3', '2209ef31-ea5a-4bda-a12a-efc62ef4e846', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:56.176652+00'),
	('435d8b21-498c-475b-a371-cbd38ea00cea', '2209ef31-ea5a-4bda-a12a-efc62ef4e846', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:56.176652+00'),
	('43726b4c-66dc-4ac9-86fd-8da6ad5f6880', 'b0ef3e8b-13a8-4f66-90ac-1926989126f3', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:56.933364+00'),
	('6ed837e0-6e28-40dd-b222-6828d07ec9e6', 'b0ef3e8b-13a8-4f66-90ac-1926989126f3', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:56.933364+00'),
	('5a922633-a8d3-47c5-bde9-79cbee1000f7', 'b0ef3e8b-13a8-4f66-90ac-1926989126f3', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:56.933364+00'),
	('bb3ad164-414f-4599-ba32-9b7861a1e4b2', 'b0ef3e8b-13a8-4f66-90ac-1926989126f3', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:56.933364+00'),
	('bff73a26-8545-49f4-b3fa-08db0dff450a', 'cab061b3-0b62-41ab-bcfd-838596d1a558', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:57.762359+00'),
	('23b0c6b1-9020-49b2-abfb-05af12e19ae1', 'cab061b3-0b62-41ab-bcfd-838596d1a558', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:57.762359+00'),
	('8ee70f8a-419b-4caa-8b49-bfbc9050a54d', '468dbe12-cd04-4754-93d4-7725205b5d3d', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:58.515196+00'),
	('89f1e5d8-ee1f-41e4-bc4c-4f5cd5d0dddd', '468dbe12-cd04-4754-93d4-7725205b5d3d', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:58.515196+00'),
	('52fb5383-7f7b-421c-9614-2009238e2f0e', '468dbe12-cd04-4754-93d4-7725205b5d3d', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:58.515196+00'),
	('5084c18a-591b-4c76-b7f4-3bb009b79c7f', '468dbe12-cd04-4754-93d4-7725205b5d3d', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:58.515196+00'),
	('9588b7c0-5495-4ea3-873b-b57a3a38b825', '6a28091e-cdf9-40db-aa13-4ec151423227', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:59.326593+00'),
	('cca08fde-5c64-4c7c-b93c-4e32b8d8b75f', '6a28091e-cdf9-40db-aa13-4ec151423227', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:59.326593+00'),
	('6d668098-5846-4d13-9da6-48152d020a9d', '6a28091e-cdf9-40db-aa13-4ec151423227', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:59.326593+00'),
	('8480337c-ab02-4dba-bdd3-1e9cd66c5851', '6a28091e-cdf9-40db-aa13-4ec151423227', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:59.326593+00'),
	('16f81db7-d0bc-40f5-b8d2-04217fcdd8c4', '546e8734-a23a-483b-8262-b7911fb72fcb', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:00.075968+00'),
	('7dbd7c1a-64eb-40ba-aac0-651b5752a2d2', '546e8734-a23a-483b-8262-b7911fb72fcb', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:00.075968+00'),
	('d2869d69-8dc9-40f5-8012-10374cb96955', '4e1f1db2-d661-49b6-897f-90f12493bdd0', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:00.899872+00'),
	('343c6568-3416-493f-b4ba-f1394cf0ed37', '4e1f1db2-d661-49b6-897f-90f12493bdd0', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:00.899872+00'),
	('cc586c7e-29b4-42a0-8b9e-2e72c948c307', '4e1f1db2-d661-49b6-897f-90f12493bdd0', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:00.899872+00'),
	('43b5fead-2fac-49dc-81d6-1bbd98e5991b', '4e1f1db2-d661-49b6-897f-90f12493bdd0', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:00.899872+00'),
	('f15213b9-c98b-45aa-a4b0-44fc0038c7e1', '4f97fb07-b16b-43a5-b0e2-b40f1e7ae53f', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:01.65398+00'),
	('00f90519-8262-4ce4-8876-76cf5c7b2bca', '4f97fb07-b16b-43a5-b0e2-b40f1e7ae53f', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:01.65398+00'),
	('9bdf2767-0841-4081-b118-b06f38b991e6', '024fc99a-7812-4f37-996f-22df107b06dc', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:02.469643+00'),
	('d5f61be0-10f7-40b3-b471-c5e4e4ea032a', '024fc99a-7812-4f37-996f-22df107b06dc', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:02.469643+00'),
	('769730d8-fbfa-4364-b7db-b4a5d50667a5', '024fc99a-7812-4f37-996f-22df107b06dc', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:02.469643+00'),
	('1de05ba2-32c2-48a9-9460-52d65fbcb018', '024fc99a-7812-4f37-996f-22df107b06dc', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:02.469643+00'),
	('79651ffa-535d-436e-be2e-1b0bd417ebbb', 'a9df7202-0c6c-4a12-b4b2-732e0e9a2929', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:03.220029+00'),
	('3f5361f5-06af-4516-bdb5-948106d0da8a', 'a9df7202-0c6c-4a12-b4b2-732e0e9a2929', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:03.220029+00'),
	('b1ca5b4b-3b29-4b1c-bd2d-34cd79fa0105', 'a9df7202-0c6c-4a12-b4b2-732e0e9a2929', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:03.220029+00'),
	('5683f32d-a9e2-4ae4-b1d0-c4540bbcfbf1', 'a9df7202-0c6c-4a12-b4b2-732e0e9a2929', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:03.220029+00'),
	('f419ca5b-c644-4e94-8edc-3dc27b349ebe', '7b12c4b9-ebe5-4282-a9b7-6ec74689b491', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:04.047412+00'),
	('3435bccc-f6d2-44b8-9b59-fbf76481b7ff', '7b12c4b9-ebe5-4282-a9b7-6ec74689b491', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:04.047412+00'),
	('3e453586-99f2-4eba-833b-7992b700dd17', '53b5e761-318b-44b2-8d5b-62bbf1451e4f', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:04.799345+00'),
	('6824cfc6-b27c-4987-9f0a-52dadba00ad2', '53b5e761-318b-44b2-8d5b-62bbf1451e4f', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:04.799345+00'),
	('34f25bc8-4b55-49f7-aeaa-fc8feb2c875d', '53b5e761-318b-44b2-8d5b-62bbf1451e4f', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:04.799345+00'),
	('03236d5f-38d3-4b4b-9322-352c3dc1d020', '53b5e761-318b-44b2-8d5b-62bbf1451e4f', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:04.799345+00'),
	('fe7ac5d0-cc54-4ec9-b030-8ed348913d01', '54b08d4a-ccd8-4bb2-9c49-00bffb8d3972', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:05.617398+00'),
	('6f0ad877-a8d9-4dee-a3c6-e464999ddc39', '54b08d4a-ccd8-4bb2-9c49-00bffb8d3972', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:05.617398+00'),
	('44cf237b-f2d4-4fa7-ba4a-cb5414c7d7d2', '77c8f68d-8299-487e-9ee7-db0e2ce004ec', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:44.646957+00'),
	('d4a97c9e-79d2-4226-9fb3-19306095f861', '77c8f68d-8299-487e-9ee7-db0e2ce004ec', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:44.646957+00'),
	('6150c5e2-d00b-4cb3-b850-229c595d66bf', '1d851557-a880-4080-be2e-e098d2250899', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:45.393023+00'),
	('b11baa16-54b3-4e64-aa7b-8ec4bdeb7bad', '1d851557-a880-4080-be2e-e098d2250899', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:45.393023+00'),
	('21dbee43-8c0c-466a-9714-80a0f68bb6e3', '1d851557-a880-4080-be2e-e098d2250899', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:45.393023+00'),
	('4308e952-48a0-4965-b0d5-8f0420dae709', '1d851557-a880-4080-be2e-e098d2250899', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:45.393023+00'),
	('5560e680-d89d-4d8c-8bd4-32b306d0c566', '75916de4-9e99-4ffa-939e-500c8736adcc', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:46.216333+00'),
	('493a1217-9227-4466-a1b3-d65a2d488774', '75916de4-9e99-4ffa-939e-500c8736adcc', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:46.216333+00'),
	('c405f607-ede1-4da7-886c-87d31b23e93e', '75916de4-9e99-4ffa-939e-500c8736adcc', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:46.216333+00'),
	('29155a6b-6a53-483a-aa89-ae14d058ff5d', '75916de4-9e99-4ffa-939e-500c8736adcc', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:46.216333+00'),
	('be335219-c22d-4591-b465-a037e3c8af8e', 'b75e8e88-c1d3-4f38-8972-6963d753ef56', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:46.968776+00'),
	('2b42cd2f-c96b-4a97-8852-0e4540726186', 'b75e8e88-c1d3-4f38-8972-6963d753ef56', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:46.968776+00'),
	('ff8bb583-6992-4152-a105-3000b9b443cf', 'efaa9992-6fd8-4241-b321-170132b8382c', '4a55ceaf-a12b-4c81-bd46-55f707ee3a00', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:47.800421+00'),
	('81cae2c9-492c-4a2f-8dfd-8d58de32a632', 'efaa9992-6fd8-4241-b321-170132b8382c', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:47.800421+00'),
	('369eac5b-01d5-4ea5-8d7c-61e6f15968f1', 'efaa9992-6fd8-4241-b321-170132b8382c', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:47.800421+00'),
	('5e8aaba0-ee19-4d97-bff4-dd1aa9ff2738', 'efaa9992-6fd8-4241-b321-170132b8382c', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:47.800421+00'),
	('7ec2ac0c-f983-405e-811a-f67ef72f663f', 'f15fea5c-c548-4acb-9ce0-834b7558066c', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:48.549778+00'),
	('425c229d-abce-4c56-8c9e-dce1a86013bb', 'f15fea5c-c548-4acb-9ce0-834b7558066c', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:48.549778+00'),
	('a270c48b-ba65-49ce-9892-ea1f58129601', 'b2232217-338d-4cf0-97a8-9ed2c0e41492', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:49.364298+00'),
	('3023fbd9-8ed8-45fe-aead-e2e4873f9f06', 'b2232217-338d-4cf0-97a8-9ed2c0e41492', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:49.364298+00'),
	('f6cc84ac-7def-4701-b610-c96bea8b8c21', 'b2232217-338d-4cf0-97a8-9ed2c0e41492', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:49.364298+00'),
	('eb036959-9f41-4e6d-b1d6-dd536f1dc766', 'b2232217-338d-4cf0-97a8-9ed2c0e41492', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:49.364298+00'),
	('7338ecea-d8a9-4761-a86e-1d2f2d5ade50', 'd0014b5e-de9e-4e6e-9dc1-d20b2e17613f', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:50.111273+00'),
	('6484d391-ce8a-477d-95a0-99f317b7ea82', 'd0014b5e-de9e-4e6e-9dc1-d20b2e17613f', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:50.111273+00'),
	('17554d6d-2aa9-4799-947b-6579c82e114a', 'd0014b5e-de9e-4e6e-9dc1-d20b2e17613f', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:50.111273+00'),
	('325a6f50-1596-4619-880e-4f6d48f2149a', 'd0014b5e-de9e-4e6e-9dc1-d20b2e17613f', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:50.111273+00'),
	('6f71e696-2d16-4ff4-905d-5687a67f07c4', '96350eb1-50a2-4c68-816a-81e2e9a5b7e1', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:50.933291+00'),
	('546f82c4-1990-4a3a-8000-b2a57fe4bf94', '96350eb1-50a2-4c68-816a-81e2e9a5b7e1', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:50.933291+00'),
	('79ee229d-7384-486d-a457-66681827a688', 'd8632333-a12a-4fab-ac6b-1b1ae8b2eb30', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:51.68167+00'),
	('fc66655b-1926-4f0f-9149-82f0fa4addcb', 'd8632333-a12a-4fab-ac6b-1b1ae8b2eb30', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:51.68167+00'),
	('a81f31cb-0520-4477-beda-7d115cdd61e5', 'd8632333-a12a-4fab-ac6b-1b1ae8b2eb30', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:51.68167+00'),
	('8a36ab59-f13a-4f27-865c-f623675c5de1', 'd8632333-a12a-4fab-ac6b-1b1ae8b2eb30', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:51.68167+00'),
	('0aeef4d6-0357-4127-b687-3962284cd38e', 'f447c2eb-eacd-4d11-b895-26dca791b30d', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:52.510079+00'),
	('8cc88998-b15a-47cc-9f19-d01da4bd2c3b', 'f447c2eb-eacd-4d11-b895-26dca791b30d', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:52.510079+00'),
	('318b6b6e-b380-439e-90e6-62c65ddfbff9', '4b4b9151-a7aa-44fd-b9a6-058a775bc344', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:53.253427+00'),
	('d7717ef1-d7e1-49a7-a226-21ef2278a93e', '4b4b9151-a7aa-44fd-b9a6-058a775bc344', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:53.253427+00'),
	('0a9a552a-e722-4098-93de-a6e776d9c461', '4b4b9151-a7aa-44fd-b9a6-058a775bc344', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:53.253427+00'),
	('b5ffaf28-97f0-455e-8804-65597ea5de4e', '4b4b9151-a7aa-44fd-b9a6-058a775bc344', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:53.253427+00'),
	('a20d97af-1de5-44af-9931-7f42fa46ec3b', '3bd38447-8ecc-4b7b-9b3b-46d2130c967a', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:54.083185+00'),
	('c5248689-b18e-444a-ae55-1f4a0794eb06', '3bd38447-8ecc-4b7b-9b3b-46d2130c967a', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:54.083185+00'),
	('d40b7f68-01f6-4f59-ad9b-36ba0b62a71c', '3bd38447-8ecc-4b7b-9b3b-46d2130c967a', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:54.083185+00'),
	('031f3c95-69ab-4385-acfc-2f67c9172faa', '3bd38447-8ecc-4b7b-9b3b-46d2130c967a', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:54.083185+00'),
	('2b6e8651-0ba6-4bbd-91ac-be040f237d94', 'a52f4b4c-fe15-4832-830d-9614a3ac4214', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:54.830475+00'),
	('ae1d55ac-ba60-4b60-a23e-f30bc749275e', 'a52f4b4c-fe15-4832-830d-9614a3ac4214', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:54.830475+00'),
	('2d394d16-b6f1-4c72-8862-9793fbb7b9c4', '40d371c6-cc54-4eda-bc60-338aa36f8735', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:55.667407+00'),
	('972acd59-d143-47e2-9548-f0344a5f7c46', '40d371c6-cc54-4eda-bc60-338aa36f8735', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:55.667407+00'),
	('ba0e6f0a-3e76-4404-bc7e-1d479694fa23', '40d371c6-cc54-4eda-bc60-338aa36f8735', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:55.667407+00'),
	('7af2756c-9873-4a4a-b934-800765c92dfa', '40d371c6-cc54-4eda-bc60-338aa36f8735', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:55.667407+00'),
	('c5e3ac38-0247-4a93-8216-92559feb94a8', '8a83b2b8-7881-4e4e-af54-8d0f9f1a7f7e', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:56.402032+00'),
	('74bcba18-f47c-4584-a7d2-a5b6c85e4ad2', '8a83b2b8-7881-4e4e-af54-8d0f9f1a7f7e', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:56.402032+00'),
	('40f99a5b-0877-4059-853d-d79cf208b9be', '03f1600b-ede0-4932-98a8-44e85e23eeeb', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:57.238103+00'),
	('2674642b-552b-4884-9967-5c69406f8b92', '03f1600b-ede0-4932-98a8-44e85e23eeeb', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:57.238103+00'),
	('dad13cd1-ea02-43f0-a628-f58ca91e8882', '03f1600b-ede0-4932-98a8-44e85e23eeeb', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:57.238103+00'),
	('45fa054b-517c-41b9-8a0a-aae2f9c4a43f', '03f1600b-ede0-4932-98a8-44e85e23eeeb', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:57.238103+00'),
	('c2bf49f8-ba70-44ee-a907-7b37d2272ab5', '8ee2487b-3d0b-471c-ad5b-9fb2ffc07d07', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:57.975412+00'),
	('cc8c6f8f-3fc9-485b-86c4-8d2eca2d60cf', '8ee2487b-3d0b-471c-ad5b-9fb2ffc07d07', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:57.975412+00'),
	('3f44b361-3a88-4a8e-8720-adacbd838e47', '8ee2487b-3d0b-471c-ad5b-9fb2ffc07d07', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:57.975412+00'),
	('6227af74-5840-45de-bcc8-1c2ebadeb2ce', '8ee2487b-3d0b-471c-ad5b-9fb2ffc07d07', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:57.975412+00'),
	('8df48066-cd56-4284-acd6-abf31f3ad218', 'f62dbad9-bc5a-476f-a412-20428a2399fa', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:58.809511+00'),
	('b862babe-b459-49ba-b896-7b0123733d03', 'f62dbad9-bc5a-476f-a412-20428a2399fa', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:58.809511+00'),
	('a2446075-07a9-4407-a363-28d39084a41c', '98b71466-45b5-4449-9580-f075a974f2da', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:34:59.54579+00'),
	('fcc2a4a4-e6c1-4a08-b562-817beeccbddf', '98b71466-45b5-4449-9580-f075a974f2da', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 2, '2026-09-20 15:34:59.54579+00'),
	('5967465c-d087-407f-9055-7bbaf5ae1913', '98b71466-45b5-4449-9580-f075a974f2da', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 3, '2026-09-20 15:34:59.54579+00'),
	('bbce5489-a24a-48e6-946f-0f700f47f845', '98b71466-45b5-4449-9580-f075a974f2da', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:34:59.54579+00'),
	('69fe6e5d-5ec4-4c10-aa44-12da2573baf2', '3987d72f-4879-4e3f-8d0c-139036f74ea8', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:00.371437+00'),
	('d1c9b16e-dc94-450d-ba6c-cc5b66a3fb03', '3987d72f-4879-4e3f-8d0c-139036f74ea8', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:00.371437+00'),
	('36027e55-9ed5-4a75-adbe-71135e5dcfd6', '123d6358-dba4-491a-bff8-0368571d9262', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:01.133099+00'),
	('ada2a422-d52e-4691-aef8-8907abdfe22a', '123d6358-dba4-491a-bff8-0368571d9262', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:01.133099+00'),
	('10d434c3-3497-4af9-aded-619f5d452514', '123d6358-dba4-491a-bff8-0368571d9262', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:01.133099+00'),
	('3f7b245d-69f7-4cb1-9b7f-e838ab6fef3c', '123d6358-dba4-491a-bff8-0368571d9262', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:01.133099+00'),
	('5ae663d0-18f7-4a57-b626-0ee23d4604f0', '3a54084f-30f9-4d92-8cad-ff24bd9cb6b1', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:01.953277+00'),
	('af1ac832-d315-4732-a57c-41d7d1b9627e', '3a54084f-30f9-4d92-8cad-ff24bd9cb6b1', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:01.953277+00'),
	('87fd4ebb-9086-4382-8c0b-15cb7ee44508', '3a54084f-30f9-4d92-8cad-ff24bd9cb6b1', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:01.953277+00'),
	('d740969e-798b-4477-841d-3bbdf5ea06ec', '3a54084f-30f9-4d92-8cad-ff24bd9cb6b1', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:01.953277+00'),
	('7b414fbf-f7aa-46be-988a-0c908c1c20f7', 'f3ff48f6-09e3-4dad-a10c-cd481aa77f66', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:02.706784+00'),
	('53d0cdb4-963a-4db5-a3bf-6aba009c9c05', 'f3ff48f6-09e3-4dad-a10c-cd481aa77f66', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:02.706784+00'),
	('c82faf3d-6348-4f72-bdcd-38f4c04092f2', 'ee05cb8c-4fec-4231-9213-48c6ee2d700e', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:03.51376+00'),
	('5ae3c2a5-d08f-4521-a150-c6f9317b3c70', 'ee05cb8c-4fec-4231-9213-48c6ee2d700e', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:03.51376+00'),
	('487b9774-c9d6-416b-b481-01798d739acb', 'ee05cb8c-4fec-4231-9213-48c6ee2d700e', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:03.51376+00'),
	('e4924be1-eb45-4889-8d24-5ca7f75197eb', 'ee05cb8c-4fec-4231-9213-48c6ee2d700e', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:03.51376+00'),
	('3112b079-7418-4e58-ba41-56728e0ea461', '6c8894de-abdd-43e8-96c1-199dc64dfd68', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:04.318998+00'),
	('ff9d95fc-aeb7-4026-976e-fcdf03064b1b', '6c8894de-abdd-43e8-96c1-199dc64dfd68', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:04.318998+00'),
	('2f6c6104-4fed-494c-a097-28ed922a8aaa', '2fb80c8a-4d5d-42b9-a3bb-d87229949d9a', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:05.111938+00'),
	('75c29c8c-1961-4739-a7c9-8213ae81b906', '2fb80c8a-4d5d-42b9-a3bb-d87229949d9a', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:05.111938+00'),
	('d5e6e1df-ce74-47ff-adb4-83ec96527e06', '2fb80c8a-4d5d-42b9-a3bb-d87229949d9a', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:05.111938+00'),
	('aced0dd4-25cd-4920-a805-d1375b62a7a1', '2fb80c8a-4d5d-42b9-a3bb-d87229949d9a', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:05.111938+00'),
	('f132f620-fcc3-4673-bf61-66fed98f3081', 'd8e6a412-3898-4813-bde0-4f5070e29804', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:05.844085+00'),
	('9fb35e43-0d35-4e3f-887a-c631bc3a20e6', 'd8e6a412-3898-4813-bde0-4f5070e29804', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:05.844085+00'),
	('83138610-12fe-4e43-9f88-c79661cdbc4d', 'd8e6a412-3898-4813-bde0-4f5070e29804', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:05.844085+00'),
	('35a5259c-f97a-4353-b6c1-a508d5e5d813', 'd8e6a412-3898-4813-bde0-4f5070e29804', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:05.844085+00'),
	('f02a4d76-3251-46b0-9d57-1495de8c6596', 'd4e0790f-ef3e-48e9-8ca1-d2251032da2c', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:06.676738+00'),
	('2ca2b86d-d4ce-4460-9e4e-2451197b72ab', 'd4e0790f-ef3e-48e9-8ca1-d2251032da2c', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:06.676738+00'),
	('0efe7a71-029f-45b8-905e-a4419ed2fa4e', '92d0e94b-cd2b-4182-bc2e-c5489b54e966', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:07.418304+00'),
	('c992931b-8507-4940-bb19-3a48e1ce6307', '92d0e94b-cd2b-4182-bc2e-c5489b54e966', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:07.418304+00'),
	('c52f5947-d755-4823-8398-064c3b56f153', '92d0e94b-cd2b-4182-bc2e-c5489b54e966', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:07.418304+00'),
	('f554a5d6-3f48-47c6-9190-3799d0b11939', '92d0e94b-cd2b-4182-bc2e-c5489b54e966', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:07.418304+00'),
	('290f8052-6ca5-4185-8ea7-f68798af87d7', 'e13d0994-3846-4549-98fc-dd8c8032015e', 'eaff167c-c90a-44fd-ac95-7f3d335bbb8a', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:08.237565+00'),
	('e5c3528b-509f-46fd-8019-02aa8e025921', 'e13d0994-3846-4549-98fc-dd8c8032015e', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:08.237565+00'),
	('88a1ece7-a4b0-43a8-96fa-572e43c3f18e', 'a774587d-cce3-4287-b03f-639122f777d2', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:06.137025+00'),
	('e0379761-5f43-47f6-93aa-4cedd708e8c4', 'a774587d-cce3-4287-b03f-639122f777d2', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:06.137025+00'),
	('90686279-fe42-4622-8cfd-dc367b72976f', 'a774587d-cce3-4287-b03f-639122f777d2', '61fbdbf1-2aff-4952-8de4-f927769f7eb1', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:06.137025+00'),
	('e346d24e-2cc4-4788-8444-90973babcb1f', '3f55799c-0ff1-403d-ab29-5a181d2f65ae', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:06.892057+00'),
	('8655a843-6cbd-4eb5-8734-c90b2d054c71', '3f55799c-0ff1-403d-ab29-5a181d2f65ae', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:06.892057+00'),
	('badb1935-247f-44ef-9cfb-5c5c7d08a5ff', '3b8b1270-f557-4899-b5f1-f859af35f2f4', '5fef7276-0907-4004-801e-d3b1065140cb', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:07.727612+00'),
	('c838107a-903b-43ea-96df-6ab40a03bf44', '3b8b1270-f557-4899-b5f1-f859af35f2f4', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:07.727612+00'),
	('a89006bf-761e-4ed3-bcf4-37734d936900', '3b8b1270-f557-4899-b5f1-f859af35f2f4', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:07.727612+00'),
	('aae48ee0-564c-49f3-89ec-79b6ed618ec4', '3b8b1270-f557-4899-b5f1-f859af35f2f4', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:07.727612+00'),
	('f50c9d8f-c67c-4a9c-9e5d-4c94fe07f1ca', '51b9e1e1-d701-4997-85e3-254e44882b1e', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:08.52407+00'),
	('8c0a4d8c-f72f-4a09-beee-93261741e136', '51b9e1e1-d701-4997-85e3-254e44882b1e', 'c104549b-2959-4db5-ae83-e528566f7f6a', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:08.52407+00'),
	('33aad74c-15bc-40bc-96eb-fe094b49bfbe', '51b9e1e1-d701-4997-85e3-254e44882b1e', '90347980-3ea6-449c-8891-4f3d2fdc6043', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:08.52407+00'),
	('7c200746-fbb3-4980-9844-540bfe2d08d7', '51b9e1e1-d701-4997-85e3-254e44882b1e', 'acc69047-4841-426c-9d4c-e03ec410dbab', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:08.52407+00'),
	('5866d6de-003e-4e66-83d7-a2b5d23c4684', '292bc695-0247-4176-bbaa-6883c307afe5', '02c73c8f-0818-4320-a711-6541a85c1b3a', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:06.365656+00'),
	('291af2ec-7bc3-4930-ac6c-2852086c5ec2', '292bc695-0247-4176-bbaa-6883c307afe5', 'e7902abf-0412-438c-a065-be122ae01978', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:06.365656+00'),
	('7f260988-75cd-417c-bba8-e2ae4077d454', '292bc695-0247-4176-bbaa-6883c307afe5', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:06.365656+00'),
	('8dd4c456-a73a-4cff-a488-464442dd8863', '292bc695-0247-4176-bbaa-6883c307afe5', '913c45fa-015d-4e3b-aaf8-cd5fe20080b6', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:06.365656+00'),
	('3cc398fb-f5b2-45b4-b84d-4102ed1ff18c', '5cb190aa-5f5f-42c2-b573-53ba05b31a07', 'deefe2d4-bb2d-4e0a-af20-534b4d83064d', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:07.200391+00'),
	('bed2d6b0-1d47-4b80-9ab2-63fa39de555f', '5cb190aa-5f5f-42c2-b573-53ba05b31a07', 'd43c7c01-a789-41fe-ac86-394f96039e84', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:07.200391+00'),
	('d01e8116-33bb-40e9-9997-1beba1798832', '5cb190aa-5f5f-42c2-b573-53ba05b31a07', 'd300860c-1f08-4f8d-afa5-52357b8df69f', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:07.200391+00'),
	('a13d7823-8e77-4181-9d50-98bff0434a99', '5cb190aa-5f5f-42c2-b573-53ba05b31a07', '17981e13-10cc-41f2-a624-23a6a56edce2', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:07.200391+00'),
	('86bd0142-330a-4beb-84f2-8c3b90787e88', 'b73bbecb-4343-4fa0-8779-94b9079596ca', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:07.95945+00'),
	('e07015d2-9564-460e-9049-6b2d61d29fe5', 'b73bbecb-4343-4fa0-8779-94b9079596ca', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:07.95945+00'),
	('6992ced4-1356-4132-a979-884999d5ad30', 'b94576c5-5ec0-49ba-81ba-dc0b2b669808', '713e00dd-adfe-437f-bb08-0e0aa2f49d18', NULL, 'CONFIRMED', 1, '2026-09-20 15:35:08.767052+00'),
	('3940ef4a-60ef-4010-b7dc-f9fa6769f405', 'b94576c5-5ec0-49ba-81ba-dc0b2b669808', 'ad9d51ed-1043-4ea9-b674-7cf6e7d774a5', NULL, 'CONFIRMED', 2, '2026-09-20 15:35:08.767052+00'),
	('357bd980-18f5-4105-adc3-cce56646be51', 'b94576c5-5ec0-49ba-81ba-dc0b2b669808', '94dd49a0-ba37-472f-aa59-f97f981a6a88', NULL, 'CONFIRMED', 3, '2026-09-20 15:35:08.767052+00'),
	('16b4d23d-c049-4a8b-97fe-c151e5e17f08', 'b94576c5-5ec0-49ba-81ba-dc0b2b669808', '3ad2fedd-1afe-4759-b5e6-046e58bf24d9', NULL, 'CONFIRMED', 4, '2026-09-20 15:35:08.767052+00');


--
-- Data for Name: swap_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('"auth"."refresh_tokens_id_seq"', 55, true);


--
-- PostgreSQL database dump complete
--

-- \unrestrict 57zVnUTqyj2I0SN8pN6KOdKy2Lekj0W9bcLPWKuW668bBnI8jnInsEQOUbgfS8t

RESET ALL;
