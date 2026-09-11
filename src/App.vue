<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from './supabase';
import { Calendar, UserCheck, RefreshCw, AlertCircle, CheckCircle, LogOut, User, ShieldCheck, LogIn } from 'lucide-vue-next';
import PlayerIntake from './components/PlayerIntake.vue';
import AuthModal from './components/AuthModal.vue';
import AdminApprovalPanel from './components/AdminApprovalPanel.vue';

interface Player {
  id: string;
  full_name: string;
}

interface MatchSlotView {
  slot_id: string;
  match_id: string;
  week_number: number;
  day_of_week: string;
  match_date: string;
  type: 'SINGLES' | 'DOUBLES';
  court_number: number;
  status: 'CONFIRMED' | 'OPEN_SUB';
  player_id: string | null;
  player_name: string;
}

const players = ref<Player[]>([]);
const pendingPlayers = ref<any[]>([]);
const activePlayerId = ref<string>('');
const activePlayerName = ref<string>('');
const userEmail = ref<string>('');
const isAdmin = ref<boolean>(false);
const session = ref<any>(null);
const authModalOpen = ref<boolean>(false);
const allSlots = ref<MatchSlotView[]>([]);
const loading = ref<boolean>(true);
const notification = ref<{ text: string; error?: boolean } | null>(null);
const currentView = ref<'intake' | 'schedule'>('intake');

// Resolve authenticated user identity against players table
const resolvePlayerIdentity = async () => {
  const { data: { session: currentSession } } = await supabase.auth.getSession();
  session.value = currentSession;

  if (currentSession?.user?.email) {
    userEmail.value = currentSession.user.email;
    const { data } = await supabase
      .from('players')
      .select('id, full_name, is_admin')
      .ilike('email', currentSession.user.email)
      .maybeSingle();

    if (data) {
      activePlayerId.value = data.id;
      activePlayerName.value = data.full_name;
      isAdmin.value = data.is_admin === true;
    } else {
      activePlayerId.value = '';
      activePlayerName.value = '';
      isAdmin.value = false;
    }
  } else {
    userEmail.value = '';
    activePlayerId.value = '';
    activePlayerName.value = '';
    isAdmin.value = false;
  }
};

const handleSignOut = async () => {
  await supabase.auth.signOut();
  session.value = null;
  activePlayerId.value = '';
  activePlayerName.value = '';
  notification.value = { text: 'Signed out successfully.' };
};

// Fetch data from Supabase
const loadData = async () => {
  loading.value = true;

  // 1. Fetch Approved Players
  const { data: pData } = await supabase
    .from('players')
    .select('id, full_name')
    .order('full_name');
  if (pData) players.value = pData;

  // 2. Fetch Pending Player Intake Registrations for Admin Approval
  const { data: pendingData, error: pendingErr } = await supabase
    .from('players')
    .select('id, full_name, email, singles_share, doubles_share, blackout_weeks, approved')
    .eq('approved', false)
    .order('created_at', { ascending: false });
  
  if (!pendingErr && pendingData) {
    pendingPlayers.value = pendingData;
  } else {
    pendingPlayers.value = [];
  }

  // 3. Fetch Match Slots with parent Match & Player details
  const { data: sData } = await supabase
    .from('match_slots')
    .select(`
      id,
      status,
      player_id,
      players ( full_name ),
      matches ( id, week_number, day_of_week, match_date, type, court_number )
    `);

  if (sData) {
    const flattened: MatchSlotView[] = sData.map((item: any) => ({
      slot_id: item.id,
      match_id: item.matches.id,
      week_number: item.matches.week_number,
      day_of_week: item.matches.day_of_week,
      match_date: item.matches.match_date,
      type: item.matches.type,
      court_number: item.matches.court_number,
      status: item.status,
      player_id: item.player_id,
      player_name: item.players?.full_name ?? 'Vacant',
    }));

    flattened.sort((a, b) => a.week_number - b.week_number);
    allSlots.value = flattened;
  }
  loading.value = false;
};

onMounted(async () => {
  await loadData();
  await resolvePlayerIdentity();

  supabase.auth.onAuthStateChange(async (_event, newSession) => {
    session.value = newSession;
    await resolvePlayerIdentity();
    if (newSession) {
      authModalOpen.value = false;
    }
  });
});

// Computed views
const myMatches = computed(() =>
  allSlots.value.filter((s) => s.player_id === activePlayerId.value)
);

const openSubMatches = computed(() =>
  allSlots.value.filter((s) => s.status === 'OPEN_SUB')
);

// Actions
const setSubStatus = async (slotId: string, status: 'OPEN_SUB' | 'CONFIRMED') => {
  if (!session.value || !activePlayerId.value) {
    authModalOpen.value = true;
    notification.value = { text: 'Please sign in to manage your sub status.', error: true };
    return;
  }

  const { error } = await supabase
    .from('match_slots')
    .update({ status })
    .eq('id', slotId);

  if (error) {
    notification.value = { text: error.message, error: true };
    return;
  }

  notification.value = {
    text: status === 'OPEN_SUB' ? 'Slot listed on the sub board.' : 'Slot reclaimed.',
  };
  await loadData();
};

const claimSlot = async (slotId: string) => {
  if (!session.value || !activePlayerId.value) {
    authModalOpen.value = true;
    notification.value = { text: 'Please sign in to claim sub slots.', error: true };
    return;
  }

  // Call the atomic PostgreSQL RPC function
  const { data, error } = await supabase.rpc('claim_sub_slot', {
    target_slot_id: slotId,
    claiming_player_id: activePlayerId.value,
  });

  if (error) {
    notification.value = { text: error.message, error: true };
    return;
  }

  notification.value = { text: data.message, error: !data.success };
  if (data.success) {
    await loadData();
  }
};
</script>

<template>
  <main class="max-w-4xl mx-auto p-4 sm:p-6 bg-slate-50 min-h-screen text-slate-900 font-sans">
    <!-- Auth Modal -->
    <AuthModal
      v-if="authModalOpen"
      @authenticated="resolvePlayerIdentity(); authModalOpen = false;"
    />

    <!-- Global Header & Identity Status -->
    <div class="bg-white p-6 rounded-xl border border-slate-200 shadow-sm mb-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-slate-800">Indoor Winter Tennis Portal</h1>
        <p class="text-sm text-slate-500">Vue 3 + Supabase Self-Service Sub & Swap Manager</p>
      </div>

      <!-- Auth Status Badge -->
      <div v-if="session && activePlayerId" class="flex items-center gap-3 bg-slate-50 p-3 rounded-xl border border-slate-200">
        <div class="w-9 h-9 bg-blue-100 text-blue-700 rounded-full flex items-center justify-center font-bold text-sm">
          <User class="w-5 h-5" />
        </div>
        <div>
          <div class="text-xs font-bold text-slate-800 flex items-center gap-1.5">
            {{ activePlayerName }}
            <ShieldCheck class="w-3.5 h-3.5 text-emerald-600" />
            <span v-if="isAdmin" class="text-[10px] font-extrabold uppercase px-1.5 py-0.5 bg-amber-100 text-amber-800 rounded border border-amber-300">
              Admin
            </span>
          </div>
          <div class="text-[11px] text-slate-400">{{ userEmail }}</div>
        </div>
        <button
          @click="handleSignOut"
          class="ml-2 text-xs font-medium text-slate-500 hover:text-rose-600 p-1.5 rounded-lg hover:bg-rose-50 transition flex items-center gap-1"
          title="Sign Out"
        >
          <LogOut class="w-4 h-4" />
          <span class="hidden sm:inline">Sign Out</span>
        </button>
      </div>

      <div v-else class="flex items-center gap-3">
        <button
          @click="authModalOpen = true"
          class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-xs rounded-lg shadow-sm transition flex items-center gap-2"
        >
          <LogIn class="w-4 h-4" />
          Player Sign In
        </button>
      </div>
    </div>

    <!-- Admin Approval Panel for Pending Player Intake Submissions (Visible ONLY to Logged-In Admins) -->
    <AdminApprovalPanel
      v-if="session && isAdmin"
      :pendingPlayers="pendingPlayers"
      @updated="loadData"
    />

    <!-- View Switcher -->
    <div class="flex gap-2 mb-6 border-b border-slate-200 pb-3">
      <button
        @click="currentView = 'intake'"
        :class="currentView === 'intake' ? 'bg-blue-600 text-white' : 'bg-white text-slate-700 hover:bg-slate-100'"
        class="text-xs font-semibold px-4 py-2 rounded-lg border border-slate-200 transition"
      >
        1. Player Intake & Quotas
      </button>
      <button
        @click="currentView = 'schedule'"
        :class="currentView === 'schedule' ? 'bg-blue-600 text-white' : 'bg-white text-slate-700 hover:bg-slate-100'"
        class="text-xs font-semibold px-4 py-2 rounded-lg border border-slate-200 transition"
      >
        2. Match Schedule & Sub Board
      </button>
    </div>

    <!-- View 1: Intake -->
    <PlayerIntake v-if="currentView === 'intake'" @registered="loadData" />

    <!-- View 2: Existing Schedule & Sub Board -->
    <div v-else>

      <!-- Notification Banner -->
      <div
        v-if="notification"
        class="p-4 mb-6 rounded-lg flex items-center gap-2 text-sm transition-all"
        :class="notification.error ? 'bg-red-50 text-red-700 border border-red-200' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'"
      >
        <AlertCircle v-if="notification.error" class="w-5 h-5 flex-shrink-0" />
        <CheckCircle v-else class="w-5 h-5 flex-shrink-0" />
        <span>{{ notification.text }}</span>
      </div>

      <!-- Open Sub Opportunities -->
      <section class="mb-8">
        <h2 class="text-lg font-bold flex items-center gap-2 text-amber-900 mb-3">
          <RefreshCw class="w-5 h-5 text-amber-600" />
          Open Sub Opportunities ({{ openSubMatches.length }})
        </h2>

        <div
          v-if="openSubMatches.length === 0"
          class="p-4 bg-white border border-dashed border-slate-300 rounded-lg text-sm text-slate-500 text-center"
        >
          No open sub slots available right now.
        </div>

        <div v-else class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div
            v-for="slot in openSubMatches"
            :key="slot.slot_id"
            class="bg-amber-50/70 border border-amber-200 p-4 rounded-lg flex flex-col justify-between"
          >
            <div>
              <div class="flex justify-between items-start mb-1">
                <span class="font-semibold text-slate-800">
                  Week {{ slot.week_number }} ({{ slot.day_of_week }})
                </span>
                <span class="text-xs px-2 py-0.5 rounded font-medium bg-amber-200 text-amber-800">
                  {{ slot.type }}
                </span>
              </div>
              <p class="text-xs text-slate-600 mb-2">
                {{ slot.match_date }} • Court #{{ slot.court_number }}
              </p>
              <p class="text-xs text-slate-500">
                Offered by: <span class="font-medium text-slate-700">{{ slot.player_name }}</span>
              </p>
            </div>

            <div class="mt-4">
              <button
                v-if="slot.player_id === activePlayerId"
                @click="setSubStatus(slot.slot_id, 'CONFIRMED')"
                class="w-full text-xs font-semibold py-2 px-3 bg-slate-200 hover:bg-slate-300 rounded text-slate-700 transition"
              >
                Cancel Listing (Reclaim)
              </button>
              <button
                v-else
                @click="claimSlot(slot.slot_id)"
                class="w-full text-xs font-semibold py-2 px-3 bg-blue-600 hover:bg-blue-700 text-white rounded transition shadow-sm"
              >
                Claim This Spot
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- Active Player Schedule -->
      <section v-if="activePlayerId" class="mb-8">
        <h2 class="text-lg font-bold flex items-center gap-2 mb-3 text-slate-800">
          <UserCheck class="w-5 h-5 text-blue-600" />
          Your Scheduled Matches ({{ myMatches.length }})
        </h2>

        <div class="bg-white border border-slate-200 rounded-lg divide-y divide-slate-100 overflow-hidden shadow-sm">
          <div v-if="myMatches.length === 0" class="p-4 text-sm text-slate-500 text-center">
            No matches found for this player.
          </div>
          <div
            v-for="slot in myMatches"
            :key="slot.slot_id"
            class="p-4 flex items-center justify-between hover:bg-slate-50"
          >
            <div>
              <div class="flex items-center gap-2">
                <span class="font-bold text-sm text-slate-800">Week {{ slot.week_number }}</span>
                <span class="text-xs text-slate-500">({{ slot.day_of_week }}, {{ slot.match_date }})</span>
                <span
                  class="text-[10px] px-1.5 py-0.5 rounded font-bold"
                  :class="slot.type === 'SINGLES' ? 'bg-indigo-100 text-indigo-800' : 'bg-emerald-100 text-emerald-800'"
                >
                  {{ slot.type }}
                </span>
              </div>
              <p class="text-xs text-slate-500 mt-0.5">Court #{{ slot.court_number }}</p>
            </div>

            <div>
              <span
                v-if="slot.status === 'OPEN_SUB'"
                class="text-xs text-amber-700 font-semibold bg-amber-100 px-2 py-1 rounded"
              >
                Sub Requested
              </span>
              <button
                v-else
                @click="setSubStatus(slot.slot_id, 'OPEN_SUB')"
                class="text-xs font-medium border border-rose-200 text-rose-600 hover:bg-rose-50 px-3 py-1.5 rounded transition"
              >
                Can't Make It
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- Master Grid (Read-Only) -->
      <section>
        <h2 class="text-lg font-bold flex items-center gap-2 mb-3 text-slate-800">
          <Calendar class="w-5 h-5 text-slate-600" />
          Full League Master Grid
        </h2>
        <div class="bg-white border border-slate-200 rounded-lg p-4 overflow-x-auto shadow-sm">
          <table class="w-full text-left text-xs border-collapse">
            <thead>
              <tr class="border-b border-slate-200 text-slate-500">
                <th class="p-2">Wk</th>
                <th class="p-2">Day</th>
                <th class="p-2">Type</th>
                <th class="p-2">Court</th>
                <th class="p-2">Player</th>
                <th class="p-2">Status</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr v-for="s in allSlots.slice(0, 30)" :key="s.slot_id" class="hover:bg-slate-50">
                <td class="p-2 font-medium">{{ s.week_number }}</td>
                <td class="p-2">{{ s.day_of_week }}</td>
                <td class="p-2">{{ s.type }}</td>
                <td class="p-2">Ct {{ s.court_number }}</td>
                <td class="p-2 font-medium">{{ s.player_name }}</td>
                <td class="p-2">
                  <span
                    class="px-1.5 py-0.5 rounded text-[10px] font-bold"
                    :class="s.status === 'CONFIRMED' ? 'bg-slate-100 text-slate-600' : 'bg-amber-100 text-amber-700'"
                  >
                    {{ s.status }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  </main>
</template>