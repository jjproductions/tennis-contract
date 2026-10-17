# Indoor Winter Tennis Contract & Schedule Manager 🎾

A comprehensive, self-service web portal built for indoor winter tennis contract leagues. Designed to streamline player intake and commitment tracking, automated multi-court schedule generation with a modular Rules & Priorities engine, bilateral Karma-based substitute rankings, auto-drafting, and secure Discord notifications proxied via Cloudflare Workers and KV.

---

## ✨ Features

### 📝 Player Intake & Capacity Tracker
- **Granular Share Commitments**: Players select Singles and Doubles shares ranging from 0% (0 matches) to 200% / Double Share (48 matches) in 1/8 share (12.5% / 3 matches) increments (supported by `numeric(4,3)` database precision).
- **Visual Capacity Quotas**: Real-time progress bars monitor league capacity quotas:
  - **Singles**: Target 6.0 shares (144 court spots over 24 weeks).
  - **Doubles**: Target 8.0 shares (192 court spots over 24 weeks).
- **Dual Blackout Preferences**:
  - **Day-of-Week Blackouts**: Players toggle specific days they cannot play (e.g., *Mondays*, *Wednesdays*).
  - **Weekly Blackouts**: Interactive multi-week picker (Weeks 1–24) with smart consecutive range compression (e.g., `W13–17`).
- **Interactive Roster Table**:
  - Automatically sorted alphabetically by player last name, with 0-share members grouped at the bottom.
  - Formatted badge pills for blackout days and weeks.
  - Self-service editing allows players to update their own preferences, while league administrators maintain override permissions for all players.

### 🔐 Authentication & Roster Whitelist Gate
- **Official Roster Whitelist**: Sign-in is strictly verified against the approved `players` database table.
  - If a player's intake submission is pending admin approval, a friendly pending notification is displayed.
  - Unregistered emails are guided directly to the intake form.
- **Dual Authentication Methods**:
  - **6-Digit Passcode (Magic Code / OTP)**: Passwordless one-time code sent directly to player email for friction-free sign-in on mobile and desktop.
  - **Email & Password**: Traditional credential login with registration, password creation, and secure recovery flows (`type=recovery` hash handler).
- **Role-Based Access Control (RBAC)**: Automatically identifies administrators (`is_admin: true`) upon login, revealing the Admin Portal tab and administrative schedule controls.

### 📅 Rules & Priorities Schedule Generator
- **Multi-Day & Custom Court Configuration**:
  - Configure season start date and flexible multi-day weekly court layouts (e.g., Monday Court #4, Tuesday Courts #5 & #6, Wednesday Court #2).
  - Automated court number synchronization and conflict validation prevents duplicate court assignments on the same day.
  - Exclude specific holiday or blackout dates from the season calendar.
- **Modular Rules & Priorities Engine Architecture**:
  - **Hard Constraints (Rules)**:
    - *Share Requirement*: Only players with non-zero commitments are drafted.
    - *Blackout Enforcement*: Strictly honors player blackout weeks and blackout days of the week.
    - *Daily Limit*: Enforces a hard cap of maximum 1 match per player per day.
    - *Weekly Limit*: Enforces a hard cap of maximum 2 matches per player per week.
    - *Singles Soft Limit*: Imposes an aggressive penalty score against assigning a player to a second singles match in the same week, preventing empty courts while prioritizing fresh players.
    - *Unique Matchup Rule*: Prevents pairing the same two players as singles opponents in the same week.
  - **Modular Heuristic Scorers**:
    - *Pace-Tier Urgency Scorer*: Compares expected matches played at week *W* against actual scheduled matches, grouping players into 10,000-point pace tiers to guarantee players finish on pace.
    - *Rest Scorer*: Rewards players who sat out previous weeks (`+100 pts` per week of rest).
    - *Opponent Fatigue Scorer*: Penalizes repetitive matchups (`-50 pts` per past encounter) to maximize opponent variety across the league.
    - *Random Tiebreaker*: Applies a sub-point decimal tiebreaker to eliminate deterministic or alphabetical drafting bias.
- **Dynamic Season-Long Capacity Balancing**: Dynamically balances weekly Singles vs. Doubles court allocations to match total registered share demand.
- **Post-Processing Quota Swap Pass**: An iterative optimization pass that analyzes the generated schedule to identify under-allocated players and swaps them into slots occupied by over-allocated players without violating any constraints.
- **One-Click Publishing & Live Sync**: Preview court distribution and quota compliance summaries before committing the schedule directly to Supabase with real-time Discord league broadcasts.

### 🔄 Match Schedule & Sub Management
- **Interactive Match Views**:
  - Toggle between **Card View** (grouped by week with clear court badges) and **Compact Table View** for rapid scanning.
  - Filter matches by week number with quick navigation.
- **Sub Listing & Slot Reclaiming**:
  - Players can list their scheduled slot on the league sub board with one click (**Sub Out**).
  - Slot owners can reclaim their listed slot anytime before a sub is confirmed (**Reclaim Slot**).
- **Admin In-Schedule Overrides**:
  - Admins can toggle Edit Mode directly on the match schedule to list or reclaim slots on behalf of any player.
  - **Admin Direct Assignment Dropdown**: Admins can immediately assign an open sub slot to any roster player. The dropdown dynamically scores and displays player eligibility, rule conflict warnings, Karma status, and season substitution counts.

### ⚖️ Algorithmic Sub Ranking & Karma Engine
- **Sub Karma (`is_owed_match`)**:
  - Tracks bilateral sub history between the requesting player and the slot owner for matches of the same type (`SINGLES` or `DOUBLES`).
  - If the slot owner previously subbed for the requesting candidate more times than the candidate has subbed for the slot owner, the candidate is flagged with `is_owed_match = true`.
  - Displayed prominently in admin and player views as `[⭐ Owed Match: Returning Favor]`.
- **Candidate Ranking Hierarchy (`sub_request_rankings`)**:
  1. **Rule Eligibility**: Players with zero rule violations (`rule_penalty = 0`) are prioritized over conflicting candidates (penalty `-1` for same-day match, `-2` for exceeding 2 matches/week).
  2. **Sub Karma**: Players owed a match by the slot owner are prioritized first.
  3. **Season Substitution Equity**: Players with the fewest total seasonal substitutions (`times_subbed ASC`) receive top ranking.
  4. **Submission Timestamp**: Earliest request timestamp (`requested_at ASC`) serves as the final tiebreaker.
- **Automatic Conflict Rejection Trigger (`tr_auto_reject_sub_requests`)**:
  - A PostgreSQL database trigger automatically marks all competing pending sub requests as `REJECTED` whenever a slot's status changes from `OPEN_SUB` to `CONFIRMED` (via admin approval, auto-draft execution, direct assignment, or slot reclaim).
- **Blackout Override Confirmation**: If a player requests an open sub slot falling on one of their personal blackout days or weeks, the app prompts for explicit confirmation before submitting.

### 🤖 Dual Sub Request Workflows
League administrators can toggle between two operational modes in **League Settings**:
1. **Maintenance Free (Auto-Draft - Default)**:
   - Players submit sub requests via the schedule.
   - 24 hours prior to each match, the automated drafting engine (`process_auto_draft()`) assigns open slots to the highest-ranked eligible candidate (honoring Karma, fewest substitutions, and schedule limits).
   - Eliminates first-come-first-serve racing and minimizes admin workload.
2. **Admin Assists (Manual Approval)**:
   - Players submit sub requests.
   - All candidate requests are aggregated in the Admin Approval Hub with candidate rankings and conflict alerts.
   - The administrator reviews candidates and clicks **Approve Sub** to select the winning player.

### 📊 Export & Reporting Suite
- **Multi-Format Schedule Export**: Export draft and published schedules to **PDF**, **Excel (`.xls`)**, and **CSV**.
- **Quota Compliance Audit Table**: Exported documents and draft previews include an audit table comparing each player's target matches, scheduled matches, and blackout counts.
- **Code-Split Dynamic Imports**: `jspdf` and `jspdf-autotable` are loaded on demand to maintain lightweight bundle sizes and instant initial page loads.

### 🛡️ Admin Control Panel
- **Pending Approvals Hub**:
  - **Sub Slot Requests**: Fixture-grouped overview of all open sub slots and applicant pools, with Karma indicators, rule conflict warnings, and one-click approvals.
  - **Player Registrations**: Review and approve new intake applicants before granting login access.
  - **Manual Auto-Draft Trigger**: Execute an on-demand auto-draft run with instant status reporting.
- **Roster Management**: Manage player roles (Admin vs. Player), modify share allocations, and adjust blackout preferences.
- **Schedule Generator Modal**: Complete schedule generation suite with customizable court parameters, date exclusions, and direct database publication.
- **Discord Notification Center**: Dispatch custom announcements and test webhook integrations across public and admin channels.
- **League Settings**: Toggle between Auto-Draft and Admin Assists operational flows.

### 📣 Secure Discord Integration (via Cloudflare Workers & KV)
- **Zero Client-Side Secret Exposure**: Discord webhook URLs are securely stored in Cloudflare KV; client bundles never contain Discord credentials.
- **Targeted Multi-Channel Routing**:
  - 📝 **Admin Channel**: Alerts for new intake registrations and sub-request submissions.
  - 📢 **Public Channel**: Player approvals, season schedule publications, open sub alerts, and sub claim confirmations.
- **Direct Portal Deep Linking**: Discord embeds feature dynamic URLs linking players directly back into the schedule view to claim slots with a single click.
- **Edge Security Guardrails**:
  - **Same-Origin Enforcement**: Rejects cross-origin requests (`sec-fetch-site` validation).
  - **IP Rate Limiting**: In-memory rate limiting (max 8 requests per 60 seconds per IP).
  - **Payload Validation**: Strict length validation on titles, messages, embed fields, and sport identifiers.

---

## 🛠️ Tech Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend Framework** | [Vue 3](https://vuejs.org/) | Composition API with `<script setup>` |
| **Language** | [TypeScript](https://www.typescriptlang.org/) | Strict type checking (`~6.0.2`) |
| **Build Tool** | [Vite](https://vitejs.dev/) | High-performance bundling (`^8.3.0`) |
| **Styling** | [Tailwind CSS v4](https://tailwindcss.com/) | Using `@tailwindcss/vite` |
| **Database & Auth** | [Supabase](https://supabase.com/) | PostgreSQL, Row Level Security, Auth OTP & Passwords |
| **Edge Proxy & Hosting** | [Cloudflare Workers](https://workers.cloudflare.com/) | Workers with Static Assets & Cloudflare KV |
| **Icons** | [Lucide Vue Next](https://lucide.dev/) | Clean, modern iconography |
| **Exports** | [jsPDF](https://github.com/parallax/jsPDF) & [AutoTable](https://github.com/simonbengtsson/jsPDF-AutoTable) | Client-side lazy-loaded document generation |

---

## 🚀 Getting Started

### Prerequisites
- Node.js (v18+ recommended)
- npm or pnpm
- A [Supabase](https://supabase.com/) project with migrations applied
- A [Cloudflare](https://cloudflare.com/) account with Wrangler CLI

### Environment Setup
Create a `.env` file in the project root:

```env
VITE_SUPABASE_URL=https://your-supabase-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-supabase-publishable-key
VITE_MAX_COURTS=5
```

### Cloudflare KV Webhook Setup
Store Discord webhook URLs securely in your Cloudflare KV namespace bound to `DISCORD_WEBHOOKS`:

```bash
# Key format: <sport>:<leagueId>:<target>
# Target: "public" or "admin"

# Production Webhooks:
npx wrangler kv key put --binding=DISCORD_WEBHOOKS "tennis:winter-contract-kyle:public" "https://discord.com/api/webhooks/..."
npx wrangler kv key put --binding=DISCORD_WEBHOOKS "tennis:winter-contract-kyle:admin" "https://discord.com/api/webhooks/..."

# Staging Webhooks (if using staging environment):
npx wrangler kv key put --binding=DISCORD_WEBHOOKS --env staging "tennis:winter-contract-kyle:public" "https://discord.com/api/webhooks/..."
npx wrangler kv key put --binding=DISCORD_WEBHOOKS --env staging "tennis:winter-contract-kyle:admin" "https://discord.com/api/webhooks/..."
```

### Installation & Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/jjproductions/tennis-contract.git
   cd winter-tennis
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run local development server:
   ```bash
   npm run dev
   ```

4. Build and typecheck for production:
   ```bash
   npm run build
   ```

5. Deploy via Wrangler:
   ```bash
   # Deploy to Production:
   npx wrangler deploy

   # Deploy to Staging:
   npx wrangler deploy --env staging
   ```

---

## 🗄️ Database Architecture & Migrations

Database migrations reside in `supabase/migrations/` and define the relational schema, security policies, and stored procedures:

### Core Tables
- `players`: Player roster, contact information, `singles_share`, `doubles_share`, `blackout_days`, `blackout_weeks`, `is_admin`, and `approved` status.
- `matches`: Season fixtures (`week_number`, `day_of_week`, `match_date`, `court_number`, `type`).
- `match_slots`: Individual court slot assignments per match (`status` ['CONFIRMED', 'OPEN_SUB'], `player_id`, `original_player_id`).
- `sub_requests`: Volunteer player requests for open sub slots (`slot_id`, `requesting_player_id`, `status` ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED']).
- `league_settings`: Key-value configuration store for league configuration (`sub_request_flow`), Discord webhook events, and schedule generator settings.
- `swap_logs`: Historical audit log of player substitutions and court reassignments.

### Key Views, Stored Procedures & Triggers
- `sub_request_rankings`: Evaluates pending sub requests with bilateral Karma calculation (`is_owed_match`), seasonal substitution counts (`times_subbed`), and eligibility penalty checks (`rule_penalty`).
- `claim_sub_slot(target_slot_id, claiming_player_id)`: Atomic RPC to assign an open sub slot to a claiming player and mark status as `CONFIRMED`.
- `approve_sub_request(request_id)`: Atomic RPC to assign the winning sub candidate to a slot and reject competing requests.
- `process_auto_draft()`: Evaluates open sub slots within 24 hours of match date and automatically assigns the highest-ranking eligible candidate.
- `auto_reject_sub_requests_fn()` & `tr_auto_reject_sub_requests`: Trigger on `match_slots` that automatically marks all pending sub requests as `REJECTED` whenever a slot changes from `OPEN_SUB` to `CONFIRMED`.
- `direct_swap_slots(slot_id_a, slot_id_b)`: Direct atomic swap of two assigned player slots.

---

## 📄 License

Private / Personal Project.
