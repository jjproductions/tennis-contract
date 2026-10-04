# Indoor Winter Tennis Contract & Schedule Manager 🎾

A self-service portal built for indoor winter tennis contract leagues. Designed to streamline player intake, share commitment tracking, automated 24-week schedule generation, substitute management, and secure Discord notifications via Cloudflare Workers.

---

## ✨ Features

### 📝 Player Intake & Capacity Tracker
- **Share Commitment Management**: Players register for Singles and Doubles shares (ranging from 1/8 share [3 matches] to 1.0 full share [24 matches]).
- **Capacity Tracker**: Real-time visual progress bars tracking league quotas (6.0 Singles shares / 144 court spots, 8.0 Doubles shares / 192 court spots).
- **Blackout Preferences**:
  - Select preferred blackout days of the week (e.g., *Mondays*, *Tuesdays*).
  - Select full blackout weeks (e.g., *W1 to W24*).
  - Smart range compression formats consecutive week selections cleanly (e.g., `W13–17`).
- **Submitted Preferences Roster**: Compact table layout with badge pills for blackout days/weeks and self-service edit permissions.

### 📅 Automated 24-Week Schedule Generator
- **Algorithmic Schedule Generation**: Generates a balanced 24-week season schedule based on exact player share commitments.
- **Blackout Constraint Engine**: Respects individual player blackout days and blackout weeks when assigning court slots.
- **Fair Rotation**: Balances singles/doubles match distributions and partner/opponent rotation across courts.

### 🔄 Match Schedule & Sub Request Management
- **Interactive Season Schedule**: View weekly match assignments, court times, and player pairings in either Card view or Compact Table view.
- **Dual Sub Request Flows** (Configured via Admin League Settings):
  - 🤖 **Maintenance Free (Auto-Draft - Default)**: Players request open sub slots through the schedule. 24 hours prior to each match, an automated drafting engine evaluates all candidate requests and assigns the slot to the highest-ranked eligible player (fewest season substitutions, strictly honoring max 1 match/day and max 2 matches/week limits). Eliminates first-come-first-serve racing.
  - 🛡️ **Admin Assists (Manual Approval)**: Players submit sub requests. All requests are aggregated and ranked algorithmically in the Admin Pending Requests panel. The administrator reviews candidate rankings and clicks **Approve Sub** to select the winning player.
- **Algorithmic Sub Ranking Engine (`sub_request_rankings`)**:
  - Automatically ranks candidates by fewest previous substitutions (`times_subbed`).
  - Flags rule conflicts (`rule_penalty = -1` for same-day conflict, `rule_penalty = -2` for exceeding 2 matches/week).
  - Highlights top candidate with `[⭐ Recommended: Fewest Subs]`.
- **Blackout Override Confirmation**: If a player requests a sub slot on a date matching their previously configured blackout day or week, an interactive dialog confirms their availability before submitting.
- **Self-Service Request & Cancellation**: Players can request open slots with one click and cancel/withdraw their request anytime before approval.
- **PDF & CSV Export**: Export the full season schedule to PDF, Excel, or CSV with code-split lazy loading for instant page loads.

### 🛡️ Admin Control Panel
- **Pending Approvals Hub**:
  - **Sub Slot Requests**: Grouped by match fixture with candidate sub rankings, rule violation warnings, and one-click approvals.
  - **Player Registrations**: Review and approve new intake applicants before granting access.
- **League Settings**:
  - Switch between **Maintenance Free (Auto-Draft)** and **Admin Assists (Manual Approval)** modes.
  - **Manual Auto-Draft Engine Trigger**: Manually execute a draft run for testing or immediate assignment with instant status feedback.
- **Roster Management**: Manage player roles (Admin vs Player), edit share allocations, or adjust blackout preferences.
- **Schedule Publication**: Trigger new schedule generation, preview court distribution, and publish updates to the league.

### 📣 Secure Discord Webhook Integration (via Cloudflare Workers & KV)
- **Zero Client-Side Secret Exposure**: Webhook URLs are hidden in Cloudflare KV; client bundles never leak Discord tokens.
- **Multi-Channel Targeted Routing**:
  - 📝 **Admin Channel**: New player intake registrations and sub-request submissions (alerts managers to review candidate requests).
  - 📢 **Public Channel**: Player approvals, season schedule releases, open sub alerts, sub claims/assignments, and custom broadcasts.
- **Built-in Security & Anti-Spam Guardrails**:
  - **Same-Origin Enforcement**: Rejects cross-origin requests from outside sites (`sec-fetch-site` verification).
  - **IP Rate Limiting**: Max 8 requests per 60 seconds per IP to prevent spamming.
  - **Field Validation & Length Limits**: Max 100 characters for title, message, description, and footer text; strict alphanumeric sport/league constraints and embed validation.

---

## 🛠️ Tech Stack

- **Frontend Framework**: [Vue 3](https://vuejs.org/) (Composition API with `<script setup>`)
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Build Tool**: [Vite](https://vitejs.dev/)
- **Styling**: [Tailwind CSS v4](https://tailwindcss.com/)
- **Database & Auth**: [Supabase](https://supabase.com/) (PostgreSQL, Row Level Security, Auth)
- **Deployment & Edge Proxy**: [Cloudflare Workers](https://workers.cloudflare.com/) (Workers with Static Assets & Cloudflare KV)
- **Icons**: [Lucide Vue Next](https://lucide.dev/)
- **PDF Export**: [jsPDF](https://github.com/parallax/jsPDF) & [jsPDF-AutoTable](https://github.com/simonbengtsson/jsPDF-AutoTable) (dynamically imported)

---

## 🚀 Getting Started

### Prerequisites
- Node.js (v18+ recommended)
- npm or pnpm
- A [Supabase](https://supabase.com/) project
- A [Cloudflare](https://cloudflare.com/) account (with Wrangler CLI)

### Environment Setup
Create a `.env` file in the root directory:

```env
VITE_SUPABASE_URL=https://your-supabase-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-supabase-publishable-key
VITE_MAX_COURTS=5
```

### Cloudflare KV Webhook Setup
Store Discord webhook URLs securely in your Cloudflare KV namespace bound to `DISCORD_WEBHOOKS`:

```bash
# Format: <sport>:<leagueId>:<target>
# Target can be "public" or "admin"

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

3. Start local development:
   ```bash
   npm run dev
   ```

4. Build for production:
   ```bash
   npm run build
   ```

5. Deploy with Wrangler:
   ```bash
   # Deploy to Production:
   npx wrangler deploy

   # Deploy to Staging:
   npx wrangler deploy --env staging
   ```

---

## 🗄️ Database Setup

Run the migrations in `supabase/migrations/` on your Supabase Postgres database. The primary tables, views, and functions include:
- `players`: Stores player profiles, email, `singles_share`, `doubles_share`, `blackout_days`, `blackout_weeks`, and `approved` status.
- `matches`: Stores the weekly schedule metadata (week number, day, date, court number, match type).
- `match_slots`: Stores individual player assignments per match, `original_player_id` assignments, and `OPEN_SUB` status.
- `sub_requests`: Stores player requests for open sub slots (`slot_id`, `requesting_player_id`, `status` [PENDING, APPROVED, REJECTED, CANCELLED]).
- `sub_request_rankings`: SQL view evaluating pending sub requests, calculating seasonal substitution count (`times_subbed`), and checking rule penalties (`rule_penalty`).
- `league_settings`: Stores global app configuration (`league_configuration`, `discord_settings`, `schedule_settings`).
- `approve_sub_request(request_id)`: Atomic RPC to assign the winning candidate to a slot and reject competing requests.
- `process_auto_draft()`: Stored procedure executed on a recurring schedule (or via Admin panel) to auto-assign slots <24 hours away to the highest-ranked eligible player when in Maintenance Free mode.

---

## 📄 License

Private / Personal Project.
