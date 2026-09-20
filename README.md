# Indoor Winter Tennis Contract & Schedule Manager 🎾

A self-service portal built for indoor winter tennis contract leagues. Designed to streamline player intake, share commitment tracking, automated 24-week schedule generation, substitute management, and Discord notifications.

---

## ✨ Features

### 📝 Player Intake & Capacity Tracker
- **Share Commitment Management**: Players register for Singles and Doubles shares (ranging from 1/8 share [3 matches] to 1.0 full share [24 matches]).
- **Capacity Tracker**: Real-time visual progress bars tracking league quotas (6.0 Singles shares / 144 court spots, 8.0 Doubles shares / 192 court spots).
- **Blackout Preferences**:
  - Select preferred blackout days of the week (e.g., *Mondays*, *Tuesdays*).
  - Select full blackout weeks (e.g., *W1 to W24*).
  - Smart range compression formats consecutive week selections cleanly (e.g., `W13–17`).
- **Submitted Preferences Roster**: Compact, 2-row table layout with badge pills for blackout days/weeks and self-service edit permissions.

### 📅 Automated 24-Week Schedule Generator
- **Algorithmic Schedule Generation**: Generates a balanced 24-week season schedule based on exact player share commitments.
- **Blackout Constraint Engine**: Respects individual player blackout days and blackout weeks when assigning court slots.
- **Fair Rotation**: Balances singles/doubles match distributions and partner/opponent rotation across courts.

### 🔄 Match Schedule & Sub/Swap Management
- **Interactive Season Schedule**: View weekly match assignments, court times, and player pairings.
- **Sub & Swap Request System**:
  - Flag matches when unable to play to open up substitute requests for other league members.
  - Claim open sub slots with instant roster status updates.
- **PDF & CSV Export**: Export the full season schedule to PDF or downloadable CSV files for printing or offline sharing.

### 🛡️ Admin Control Panel
- **Pending Approvals**: Review and approve new player registrations before granting access.
- **Roster Management**: Manage player roles (Admin vs Player), edit share allocations, or adjust blackout preferences.
- **Schedule Publication**: Trigger new schedule generation, preview court distribution, and publish updates to the league.

### 📣 Discord Webhook Integration
- **Automated Event Triggers**: Automatically post alerts to a configured Discord channel for:
  - 🚨 Open substitute requests
  - 🤝 Sub slot claims
  - 📅 Season schedule publications
  - 📝 New player registrations
  - 🎉 Player roster approvals
- **Custom Admin Broadcasts**: Send targeted announcements, urgent alerts, and weather notices directly to Discord.

---

## 🛠️ Tech Stack

- **Frontend Framework**: [Vue 3](https://vuejs.org/) (Composition API with `<script setup>`)
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Build Tool**: [Vite](https://vitejs.dev/)
- **Styling**: [Tailwind CSS v4](https://tailwindcss.com/)
- **Database & Auth**: [Supabase](https://supabase.com/) (PostgreSQL, Row Level Security, Auth)
- **Icons**: [Lucide Vue Next](https://lucide.dev/)
- **PDF Export**: [jsPDF](https://github.com/parallax/jsPDF) & [jsPDF-AutoTable](https://github.com/simonbengtsson/jsPDF-AutoTable)

---

## 🚀 Getting Started

### Prerequisites
- Node.js (v18+ recommended)
- npm or pnpm
- A [Supabase](https://supabase.com/) project

### Environment Setup
Create a `.env` file in the root directory:

```env
VITE_SUPABASE_URL=https://your-supabase-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jjproductions/tennis-contract.git
   cd winter-tennis
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the local development server:
   ```bash
   npm run dev
   ```

4. Build for production:
   ```bash
   npm run build
   ```

---

## 🗄️ Database Setup

Run the migrations in `supabase/migrations/` on your Supabase Postgres database. The primary tables include:
- `players`: Stores player profiles, email, `singles_share`, `doubles_share`, `blackout_days`, `blackout_weeks`, and `approved` status.
- `league_settings`: Stores global configurations such as Discord Webhook URLs and event notification toggles.
- `schedules`: Stores generated 24-week season match assignments and sub request states.

---

## 📄 License

Private / Personal Project.
