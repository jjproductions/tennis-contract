<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { supabase } from './supabase';
import { AlertCircle, CheckCircle2, LogOut, User, ShieldCheck, LogIn, X } from 'lucide-vue-next';
import PlayerIntake from './components/PlayerIntake.vue';
import AuthModal from './components/AuthModal.vue';
import AdminApprovalPanel from './components/AdminApprovalPanel.vue';
import MatchScheduleView from './components/MatchScheduleView.vue';
import { notifySubRequested, notifySubClaimed } from './utils/discordNotifier';

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

interface NotificationState {
  text: string;
  title?: string;
  steps?: string[];
  error?: boolean;
}

const players = ref<Player[]>([]);
const pendingPlayers = ref<any[]>([]);
const activePlayerId = ref<string>('');
const activePlayerName = ref<string>('');
const userEmail = ref<string>('');
const isAdmin = ref<boolean>(false);
const session = ref<any>(null);
const authModalOpen = ref<boolean>(false);
const authModalMode = ref<'normal' | 'recovery'>('normal');
const allSlots = ref<MatchSlotView[]>([]);
const loading = ref<boolean>(true);
const notification = ref<NotificationState | null>(null);
const currentView = ref<'intake' | 'schedule' | 'admin'>('intake');

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

  if (!isAdmin.value && currentView.value === 'admin') {
    currentView.value = 'intake';
  }
};

const handleSignOut = async () => {
  await supabase.auth.signOut();
  session.value = null;
  activePlayerId.value = '';
  activePlayerName.value = '';
  isAdmin.value = false;
  if (currentView.value === 'admin') {
    currentView.value = 'intake';
  }
  notification.value = { text: 'Signed out successfully.' };
};

const handleAuthenticated = async (details?: { type?: string; name?: string; email?: string }) => {
  await resolvePlayerIdentity();
  authModalOpen.value = false;
  authModalMode.value = 'normal';
  currentView.value = 'schedule';

  const displayName = activePlayerName.value || details?.name || userEmail.value || 'Player';

  if (details?.type === 'password_created') {
    notification.value = {
      title: '🔑 Password Set & Logged In Successfully!',
      text: `Welcome ${displayName}! Your password has been set and your session is active.`,
      steps: [
        'View your scheduled matches below in the Match Schedule tab.',
        'If you cannot play a match, click "Sub Out" on your match slot to list it on the sub board.',
        'Browse open sub positions from other players and click "Claim Sub Slot" to play extra matches.'
      ],
      error: false
    };
  } else {
    notification.value = {
      title: '🎾 Signed In Successfully!',
      text: `Welcome back, ${displayName}! You are signed in to the Winter Tennis Portal.`,
      steps: [
        'Check your upcoming scheduled matches in the list below.',
        'Use "Sub Out" if you cannot attend a scheduled match.',
        'Browse open sub positions to fill in for other players.'
      ],
      error: false
    };
  }
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
      players!match_slots_player_id_fkey ( full_name ),
      matches ( id, week_number, day_of_week, match_date, type, court_number )
    `);

  if (sData) {
    const flattened: MatchSlotView[] = sData
      .filter((item: any) => item.matches != null)
      .map((item: any) => ({
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

  if (window.location.hash.includes('type=recovery')) {
    authModalMode.value = 'recovery';
    authModalOpen.value = true;
  }

  supabase.auth.onAuthStateChange(async (event, newSession) => {
    session.value = newSession;
    await resolvePlayerIdentity();

    if (event === 'PASSWORD_RECOVERY') {
      authModalMode.value = 'recovery';
      authModalOpen.value = true;
    } else if (newSession && authModalOpen.value && authModalMode.value !== 'recovery') {
      handleAuthenticated({ type: 'signed_in' });
    }
  });
});


// Actions
const setSubStatus = async (slotId: string, status: 'OPEN_SUB' | 'CONFIRMED') => {
  if (!session.value || !activePlayerId.value) {
    authModalOpen.value = true;
    notification.value = { text: 'Please sign in to manage your sub status.', error: true };
    return;
  }

  const targetSlot = allSlots.value.find((s) => s.slot_id === slotId);

  const { error } = await supabase
    .from('match_slots')
    .update({ status })
    .eq('id', slotId);

  if (error) {
    notification.value = { text: error.message, error: true };
    return;
  }

  if (status === 'OPEN_SUB' && targetSlot) {
    notifySubRequested({
      week_number: targetSlot.week_number,
      day_of_week: targetSlot.day_of_week,
      match_date: targetSlot.match_date,
      type: targetSlot.type,
      court_number: targetSlot.court_number,
      player_name: targetSlot.player_name,
    });
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

  const targetSlot = allSlots.value.find((s) => s.slot_id === slotId);

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
    if (targetSlot) {
      notifySubClaimed(
        {
          week_number: targetSlot.week_number,
          day_of_week: targetSlot.day_of_week,
          match_date: targetSlot.match_date,
          type: targetSlot.type,
          court_number: targetSlot.court_number,
          original_player: targetSlot.player_name,
        },
        activePlayerName.value || 'A League Player'
      );
    }
    await loadData();
  }
};
</script>

<template>
  <main class="max-w-4xl mx-auto p-4 sm:p-6 bg-slate-50 min-h-screen text-slate-900 font-sans">
    <!-- Auth Modal -->
    <AuthModal
      v-if="authModalOpen"
      :mode="authModalMode"
      @authenticated="handleAuthenticated"
      @close="authModalOpen = false; authModalMode = 'normal';"
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
          @click="authModalOpen = true; authModalMode = 'normal';"
          class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-xs rounded-lg shadow-sm transition flex items-center gap-2"
        >
          <LogIn class="w-4 h-4" />
          Player Sign In
        </button>
      </div>
    </div>

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
      <button
        v-if="session && isAdmin"
        @click="currentView = 'admin'"
        :class="currentView === 'admin' ? 'bg-blue-600 text-white' : 'bg-white text-slate-700 hover:bg-slate-100'"
        class="text-xs font-semibold px-4 py-2 rounded-lg border border-slate-200 transition flex items-center gap-2"
      >
        <span>3. Admin Control Panel</span>
        <span
          v-if="pendingPlayers.length > 0"
          class="px-1.5 py-0.5 text-[10px] font-bold rounded-full"
          :class="currentView === 'admin' ? 'bg-amber-400 text-slate-900' : 'bg-amber-500 text-white'"
        >
          {{ pendingPlayers.length }}
        </span>
      </button>
    </div>

    <!-- Global Instructions / Notification Banner -->
    <div
      v-if="notification"
      class="p-4 mb-6 rounded-xl border transition-all relative shadow-sm"
      :class="notification.error ? 'bg-red-50 text-red-800 border-red-200' : 'bg-emerald-50 text-emerald-900 border-emerald-200'"
    >
      <button
        @click="notification = null"
        class="absolute top-3 right-3 p-1 rounded-lg hover:bg-black/10 text-slate-500 hover:text-slate-700 transition"
        title="Dismiss message"
      >
        <X class="w-4 h-4" />
      </button>

      <div class="flex items-start gap-3 pr-6">
        <div class="p-2 rounded-lg mt-0.5 flex-shrink-0" :class="notification.error ? 'bg-red-100 text-red-700' : 'bg-emerald-100 text-emerald-700'">
          <AlertCircle v-if="notification.error" class="w-5 h-5" />
          <CheckCircle2 v-else class="w-5 h-5" />
        </div>
        <div class="space-y-1 text-sm">
          <h4 v-if="notification.title" class="font-bold text-base tracking-tight">
            {{ notification.title }}
          </h4>
          <p class="text-xs sm:text-sm font-medium leading-relaxed">
            {{ notification.text }}
          </p>
          <div v-if="notification.steps && notification.steps.length > 0" class="mt-3 pt-2 border-t border-emerald-200/60 space-y-1.5 text-xs">
            <p class="font-bold uppercase tracking-wider text-[10px] text-emerald-800">What to do next:</p>
            <ul class="space-y-1">
              <li v-for="(step, idx) in notification.steps" :key="idx" class="flex items-start gap-2 text-emerald-900">
                <span class="font-bold text-emerald-700 select-none">•</span>
                <span>{{ step }}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <!-- View 1: Intake -->
    <PlayerIntake v-if="currentView === 'intake'" @registered="loadData" />

    <!-- View 2: Schedule & Sub Board -->
    <MatchScheduleView
      v-else-if="currentView === 'schedule'"
      :all-slots="allSlots"
      :active-player-id="activePlayerId"
      :active-player-name="activePlayerName"
      :session="session"
      @set-sub-status="setSubStatus"
      @claim-slot="claimSlot"
      @open-auth-modal="authModalOpen = true; authModalMode = 'normal';"
    />

    <!-- View 3: Admin Control Panel -->
    <AdminApprovalPanel
      v-else-if="currentView === 'admin' && session && isAdmin"
      :pendingPlayers="pendingPlayers"
      @updated="loadData"
    />
  </main>
</template>