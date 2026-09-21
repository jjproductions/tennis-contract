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

### 🔄 Match Schedule & Sub/Swap Management
- **Interactive Season Schedule**: View weekly match assignments, court times, and player pairings.
- **Sub & Swap Request System**:
  - Flag matches when unable to play to open up substitute requests for other league members.
  - Claim open sub slots with instant roster status updates.
- **PDF & CSV Export**: Export the full season schedule to PDF, Excel, or CSV with code-split lazy loading for instant page loads.

### 🛡️ Admin Control Panel
- **Pending Approvals**: Review and approve new player registrations before granting access.
- **Roster Management**: Manage player roles (Admin vs Player), edit share allocations, or adjust blackout preferences.
- **Schedule Publication**: Trigger new schedule generation, preview court distribution, and publish updates to the league.

### 📣 Secure Discord Webhook Integration (via Cloudflare Workers & KV)
- **Zero Client-Side Secret Exposure**: Webhook URLs are hidden in Cloudflare KV; client bundles never leak Discord tokens.
- **Multi-Channel Targeted Routing**:
  - 📝 **Admin Channel**: New player intake registrations (alerts managers to review applicants).
  - 📢 **Public Channel**: Player approvals, season schedule releases, open sub alerts, sub claims, and custom broadcasts.
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

Run the migrations in `supabase/migrations/` on your Supabase Postgres database. The primary tables include:
- `players`: Stores player profiles, email, `singles_share`, `doubles_share`, `blackout_days`, `blackout_weeks`, and `approved` status.
- `matches`: Stores the weekly schedule metadata (week number, day, date, court number, match type).
- `match_slots`: Stores individual player assignments per match, original player assignments, and `OPEN_SUB` status.
- `league_settings`: Stores league configuration settings and notification toggles.

---

## 📄 License

Private / Personal Project.
