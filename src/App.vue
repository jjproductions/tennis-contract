<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { supabase } from './supabase';
import { AlertCircle, CheckCircle2, LogOut, ShieldCheck, LogIn, X, KeyRound } from 'lucide-vue-next';
import PlayerIntake from './components/PlayerIntake.vue';
import AuthModal from './components/AuthModal.vue';
import AdminApprovalPanel from './components/AdminApprovalPanel.vue';
import MatchScheduleView from './components/MatchScheduleView.vue';
import { notifySubRequested, notifySubClaimed } from './utils/discordNotifier';
import { compareMatches } from './utils/scheduleGenerator';

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
  original_player_id: string | null;
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
const activePlayer = ref<any>(null);
const session = ref<any>(null);
const authModalOpen = ref<boolean>(false);
const authModalMode = ref<'normal' | 'recovery' | 'reset'>('normal');
const allSlots = ref<MatchSlotView[]>([]);
const loading = ref<boolean>(true);
const notification = ref<NotificationState | null>(null);
const currentView = ref<'intake' | 'schedule' | 'admin'>('schedule');
const profileMenuOpen = ref<boolean>(false);
const profileDropdownRef = ref<HTMLElement | null>(null);

const handleClickOutside = (event: MouseEvent) => {
  if (profileDropdownRef.value && !profileDropdownRef.value.contains(event.target as Node)) {
    profileMenuOpen.value = false;
  }
};

// Resolve authenticated user identity against players table
const resolvePlayerIdentity = async () => {
  const { data: { session: currentSession } } = await supabase.auth.getSession();
  session.value = currentSession;

  if (currentSession?.user?.email) {
    userEmail.value = currentSession.user.email;
    const { data } = await supabase
      .from('players')
      .select('id, full_name, email, is_admin, blackout_weeks, blackout_days')
      .ilike('email', currentSession.user.email)
      .maybeSingle();

    if (data) {
      activePlayerId.value = data.id;
      activePlayerName.value = data.full_name;
      isAdmin.value = data.is_admin === true;
      activePlayer.value = data;
    } else {
      activePlayerId.value = '';
      activePlayerName.value = '';
      isAdmin.value = false;
      activePlayer.value = null;
    }
  } else {
    userEmail.value = '';
    activePlayerId.value = '';
    activePlayerName.value = '';
    isAdmin.value = false;
    activePlayer.value = null;
  }

  if (!isAdmin.value && currentView.value === 'admin') {
    currentView.value = 'schedule';
  }
};

const handleSignOut = async () => {
  profileMenuOpen.value = false;
  await supabase.auth.signOut();
  session.value = null;
  activePlayerId.value = '';
  activePlayerName.value = '';
  isAdmin.value = false;
  if (currentView.value === 'admin') {
    currentView.value = 'schedule';
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
    .select('id, full_name, email, singles_share, doubles_share, blackout_weeks, blackout_days, approved')
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
      original_player_id,
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
        original_player_id: item.original_player_id,
        player_name: item.players?.full_name ?? 'Vacant',
      }));

    flattened.sort(compareMatches);
    allSlots.value = flattened;
  }
  loading.value = false;
};

onMounted(async () => {
  document.addEventListener('click', handleClickOutside);
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
    } else if (newSession && authModalOpen.value && authModalMode.value !== 'recovery' && authModalMode.value !== 'reset') {
      handleAuthenticated({ type: 'signed_in' });
    }
  });
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
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

  const isOverride = targetSlot && targetSlot.player_id !== activePlayerId.value;

  notification.value = {
    text: isOverride 
      ? (status === 'OPEN_SUB' ? `Slot listed on sub board on behalf of ${targetSlot.player_name}.` : `Slot reclaimed on behalf of ${targetSlot.player_name}.`)
      : (status === 'OPEN_SUB' ? 'Slot listed on the sub board.' : 'Slot reclaimed.'),
  };
  await loadData();
};

const claimSlot = async (slotId: string, playerId?: string) => {
  if (!session.value || !activePlayerId.value) {
    authModalOpen.value = true;
    notification.value = { text: 'Please sign in to claim sub slots.', error: true };
    return;
  }

  const finalPlayerId = playerId || activePlayerId.value;
  const targetSlot = allSlots.value.find((s) => s.slot_id === slotId);

  // Call the atomic PostgreSQL RPC function
  const { data, error } = await supabase.rpc('claim_sub_slot', {
    target_slot_id: slotId,
    claiming_player_id: finalPlayerId,
  });

  if (error) {
    notification.value = { text: error.message, error: true };
    return;
  }

  notification.value = { text: data.message, error: !data.success };
  if (data.success) {
    if (targetSlot) {
      let claimingPlayerName = activePlayerName.value || 'A League Player';
      if (playerId && playerId !== activePlayerId.value) {
        const p = players.value.find((pl) => pl.id === playerId);
        if (p) claimingPlayerName = p.full_name;
      }
      notifySubClaimed(
        {
          week_number: targetSlot.week_number,
          day_of_week: targetSlot.day_of_week,
          match_date: targetSlot.match_date,
          type: targetSlot.type,
          court_number: targetSlot.court_number,
          original_player: targetSlot.player_name,
        },
        claimingPlayerName
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
      :initial-email="userEmail"
      @update:mode="authModalMode = $event"
      @authenticated="handleAuthenticated"
      @close="authModalOpen = false; authModalMode = 'normal';"
    />

    <!-- Global Header & Identity Status -->
    <div class="bg-white p-6 rounded-xl border border-slate-200 shadow-sm mb-6 flex items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-slate-800">Indoor Winter Tennis Portal</h1>
        <!-- <p class="text-sm text-slate-500">Vue 3 + Supabase Self-Service Sub & Swap Manager</p> -->
      </div>

      <!-- Profile Menu Trigger & Dropdown -->
      <div v-if="session && activePlayerId" ref="profileDropdownRef" class="relative">
        <button
          type="button"
          @click="profileMenuOpen = !profileMenuOpen"
          class="w-10 h-10 rounded-full bg-blue-600 hover:bg-blue-700 text-white flex items-center justify-center font-bold text-base shadow-sm transition hover:ring-4 hover:ring-blue-500/20 active:scale-95 focus:outline-none"
          :class="{ 'ring-4 ring-blue-500/30': profileMenuOpen }"
          :title="`Account menu (${activePlayerName})`"
          :aria-expanded="profileMenuOpen"
          aria-haspopup="true"
        >
          {{ activePlayerName ? activePlayerName.charAt(0).toUpperCase() : 'U' }}
        </button>

        <!-- Dropdown Menu: 3 Sections -->
        <div
          v-if="profileMenuOpen"
          class="absolute right-0 mt-2 w-72 bg-white rounded-2xl shadow-xl border border-slate-200/90 z-50 divide-y divide-slate-100 overflow-hidden"
        >
          <!-- Section 1: User Info Section -->
          <div class="p-4 bg-gradient-to-br from-slate-50 to-blue-50/40">
            <div class="flex items-start gap-3">
              <div class="w-10 h-10 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold text-sm shadow flex-shrink-0">
                {{ activePlayerName ? activePlayerName.charAt(0).toUpperCase() : 'U' }}
              </div>
              <div class="min-w-0 flex-1">
                <div class="font-bold text-sm text-slate-900 truncate flex items-center gap-1.5">
                  <span class="truncate">{{ activePlayerName }}</span>
                  <ShieldCheck class="w-4 h-4 text-emerald-600 flex-shrink-0" title="Verified Member" />
                </div>
                <div class="text-xs text-slate-500 truncate mt-0.5">{{ userEmail }}</div>
                <div class="mt-2">
                  <span
                    v-if="isAdmin"
                    class="text-[10px] font-extrabold uppercase px-2 py-0.5 bg-amber-100 text-amber-800 rounded-md border border-amber-300 inline-flex items-center gap-1"
                  >
                    League Admin
                  </span>
                  <span
                    v-else
                    class="text-[10px] font-semibold px-2 py-0.5 bg-blue-100 text-blue-800 rounded-md border border-blue-200 inline-flex items-center"
                  >
                    Verified Player
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Section 2: Change Password Section -->
          <div class="p-1.5">
            <button
              type="button"
              @click="profileMenuOpen = false; authModalMode = 'recovery'; authModalOpen = true;"
              class="w-full flex items-center gap-3 px-3 py-2.5 text-xs font-semibold text-slate-700 hover:text-blue-700 hover:bg-blue-50/80 rounded-xl transition text-left group"
            >
              <div class="p-1.5 rounded-lg bg-slate-100 text-slate-500 group-hover:bg-blue-100 group-hover:text-blue-600 transition">
                <KeyRound class="w-4 h-4" />
              </div>
              <div>
                <div class="font-semibold text-slate-800 group-hover:text-blue-700">Change Password</div>
                <div class="text-[10px] text-slate-400 font-normal">Update your login credentials</div>
              </div>
            </button>
          </div>

          <!-- Section 3: Sign Out Section -->
          <div class="p-1.5 bg-slate-50/40">
            <button
              type="button"
              @click="profileMenuOpen = false; handleSignOut();"
              class="w-full flex items-center gap-3 px-3 py-2.5 text-xs font-semibold text-rose-600 hover:bg-rose-50 rounded-xl transition text-left group"
            >
              <div class="p-1.5 rounded-lg bg-rose-50 text-rose-500 group-hover:bg-rose-100 group-hover:text-rose-700 transition">
                <LogOut class="w-4 h-4" />
              </div>
              <div>
                <div class="font-semibold text-rose-700">Sign Out</div>
                <div class="text-[10px] text-slate-400 font-normal">End your session on this device</div>
              </div>
            </button>
          </div>
        </div>
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
        @click="currentView = 'schedule'; notification = null;"
        :class="currentView === 'schedule' ? 'bg-blue-600 text-white' : 'bg-white text-slate-700 hover:bg-slate-100'"
        class="text-xs font-semibold px-4 py-2 rounded-lg border border-slate-200 transition"
      >
        Match Schedule & Sub Board
      </button>
      <button
        @click="currentView = 'intake'; notification = null;"
        :class="currentView === 'intake' ? 'bg-blue-600 text-white' : 'bg-white text-slate-700 hover:bg-slate-100'"
        class="text-xs font-semibold px-4 py-2 rounded-lg border border-slate-200 transition"
      >
        Player Intake & Quotas
      </button>
      <button
        v-if="session && isAdmin"
        @click="currentView = 'admin'; notification = null;"
        :class="currentView === 'admin' ? 'bg-blue-600 text-white' : 'bg-white text-slate-700 hover:bg-slate-100'"
        class="text-xs font-semibold px-4 py-2 rounded-lg border border-slate-200 transition flex items-center gap-2"
      >
        <span>Admin Portal</span>
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

    <!-- View 1: Schedule & Sub Board -->
    <MatchScheduleView
      v-if="currentView === 'schedule'"
      :all-slots="allSlots"
      :active-player-id="activePlayerId"
      :active-player-name="activePlayerName"
      :active-player="activePlayer"
      :session="session"
      :players="players"
      @set-sub-status="setSubStatus"
      @claim-slot="claimSlot"
      @updated="loadData"
      @open-auth-modal="authModalOpen = true; authModalMode = 'normal';"
    />

    <!-- View 2: Intake -->
    <PlayerIntake
      v-else-if="currentView === 'intake'"
      :session="session"
      :is-admin="isAdmin"
      @registered="loadData"
    />

    <!-- View 3: Admin Portal -->
    <AdminApprovalPanel
      v-else-if="currentView === 'admin' && session && isAdmin"
      :pendingPlayers="pendingPlayers"
      @updated="loadData"
    />
  </main>
</template>