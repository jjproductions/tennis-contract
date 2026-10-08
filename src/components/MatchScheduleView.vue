<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { supabase } from '../supabase';
import {
  Calendar,
  UserCheck,
  RefreshCw,
  Search,
  Grid,
  List,
  AlertTriangle,
  ArrowRight,
  X,
  Download,
  FileText,
  FileSpreadsheet,
  FileCode,
  ChevronDown,
  CheckCircle2,
  AlertCircle,
  ShieldCheck,
} from 'lucide-vue-next';
import { formatDayOfWeek, compareMatches } from '../utils/scheduleGenerator';
import { exportToCSV, exportToExcel, exportToPDF } from '../utils/exportUtils';
import { fetchLeagueConfig, type LeagueConfiguration } from '../utils/leagueSettings';
import { notifySubRequestedByPlayer } from '../utils/discordNotifier';

export interface MatchSlotView {
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

export interface GroupedMatch {
  match_id: string;
  week_number: number;
  day_of_week: string;
  match_date: string;
  type: 'SINGLES' | 'DOUBLES';
  court_number: number;
  slots: MatchSlotView[];
}

const props = defineProps<{
  allSlots: MatchSlotView[];
  activePlayerId: string | null;
  activePlayerName: string | null;
  activePlayer?: {
    id: string;
    full_name: string;
    email?: string;
    is_admin?: boolean;
    blackout_weeks?: number[];
    blackout_days?: string[];
  } | null;
  session: any;
  players?: { id: string; full_name: string }[];
}>();

const emit = defineEmits<{
  (e: 'setSubStatus', slotId: string, status: 'OPEN_SUB' | 'CONFIRMED'): void;
  (e: 'claimSlot', slotId: string, playerId?: string): void;
  (e: 'openAuthModal'): void;
  (e: 'updated'): void;
}>();

const adminEditMode = ref(false);
const selectedAssignee = ref<Record<string, string>>({});

const getRankedPlayersForSlot = (targetSlot: MatchSlotView) => {
  if (!props.players) return [];
  return props.players.map(p => {
    const playingToday = props.allSlots.some(s => s.player_id === p.id && s.match_date === targetSlot.match_date && s.status === 'CONFIRMED');
    const weeklyMatches = props.allSlots.filter(s => s.player_id === p.id && s.week_number === targetSlot.week_number && s.status === 'CONFIRMED').length;
    let penalty = 0;
    let reason = 'Eligible';
    if (playingToday) { penalty = -1; reason = 'Ineligible: Playing Today'; }
    else if (weeklyMatches >= 2) { penalty = -2; reason = 'Ineligible: Max 2 Matches/Wk'; }

    const timesSubbed = props.allSlots.filter(s => s.player_id === p.id && s.original_player_id !== null && s.status === 'CONFIRMED').length;

    const owedByTargetToCandidate = props.allSlots.filter(s => 
      s.player_id === p.id && 
      s.original_player_id === targetSlot.player_id && 
      s.type === targetSlot.type && 
      s.status === 'CONFIRMED'
    ).length;
    
    const owedByCandidateToTarget = props.allSlots.filter(s => 
      s.player_id === targetSlot.player_id && 
      s.original_player_id === p.id && 
      s.type === targetSlot.type && 
      s.status === 'CONFIRMED'
    ).length;

    const isOwedMatch = owedByCandidateToTarget > owedByTargetToCandidate;

    if (penalty === 0) {
      if (isOwedMatch) {
        reason += ' - Karma: Owed Match';
      } else if (timesSubbed > 0) {
        reason += ` - Subbed ${timesSubbed}x`;
      }
    }

    return { ...p, penalty, reason, timesSubbed, isOwedMatch };
  }).sort((a, b) => {
    if (a.penalty !== b.penalty) return b.penalty - a.penalty;
    if (a.isOwedMatch && !b.isOwedMatch) return -1;
    if (!a.isOwedMatch && b.isOwedMatch) return 1;
    return a.timesSubbed - b.timesSubbed;
  });
};

// Sub Request & League Config State
const leagueConfig = ref<LeagueConfiguration>({ sub_request_flow: 'maintenance_free' });
const mySubRequests = ref<Record<string, string>>({}); // slot_id -> request_id
const isSubmittingSubRequest = ref<string | null>(null);
const subRequestToast = ref<{ text: string; error?: boolean } | null>(null);

// Blackout Confirmation Modal State
const blackoutModalOpen = ref<boolean>(false);
const pendingTargetSlot = ref<MatchSlotView | null>(null);
const blackoutReason = ref<string>('');
const localPlayerProfile = ref<{
  id: string;
  full_name: string;
  email?: string;
  blackout_weeks?: number[];
  blackout_days?: string[];
} | null>(null);

const fetchConfig = async () => {
  leagueConfig.value = await fetchLeagueConfig();
};

const syncPlayerProfile = async () => {
  if (props.activePlayer) {
    localPlayerProfile.value = props.activePlayer;
    return;
  }
  if (!props.activePlayerId) {
    localPlayerProfile.value = null;
    return;
  }
  const { data } = await supabase
    .from('players')
    .select('id, full_name, email, blackout_weeks, blackout_days')
    .eq('id', props.activePlayerId)
    .maybeSingle();
  if (data) {
    localPlayerProfile.value = data;
  }
};

const fetchMySubRequests = async () => {
  if (!props.activePlayerId) {
    mySubRequests.value = {};
    return;
  }
  const { data, error } = await supabase
    .from('sub_requests')
    .select('id, slot_id, status')
    .eq('requesting_player_id', props.activePlayerId)
    .eq('status', 'PENDING');

  if (!error && data) {
    const map: Record<string, string> = {};
    for (const r of data) {
      map[r.slot_id] = r.id;
    }
    mySubRequests.value = map;
  }
};

onMounted(async () => {
  await fetchConfig();
  await syncPlayerProfile();
  await fetchMySubRequests();
});

watch(
  () => props.activePlayerId,
  async () => {
    await syncPlayerProfile();
    await fetchMySubRequests();
  }
);

watch(
  () => props.activePlayer,
  (newVal) => {
    if (newVal) localPlayerProfile.value = newVal;
  }
);

const handleStartRequest = async (slot: MatchSlotView) => {
  if (!props.session || !props.activePlayerId) {
    emit('openAuthModal');
    return;
  }

  await syncPlayerProfile();
  const profile = localPlayerProfile.value || props.activePlayer;

  const playerWeeks = profile?.blackout_weeks || [];
  const playerDays = (profile?.blackout_days || []).map((d: string) => d.toUpperCase());

  const isWeekBlackout = playerWeeks.includes(slot.week_number);
  const isDayBlackout = playerDays.includes(slot.day_of_week.toUpperCase());

  if (isWeekBlackout || isDayBlackout) {
    let reason = '';
    if (isWeekBlackout && isDayBlackout) {
      reason = `Week ${slot.week_number} and ${formatDayOfWeek(slot.day_of_week)}s`;
    } else if (isWeekBlackout) {
      reason = `Week ${slot.week_number}`;
    } else {
      reason = `${formatDayOfWeek(slot.day_of_week)}s`;
    }
    blackoutReason.value = reason;
    pendingTargetSlot.value = slot;
    blackoutModalOpen.value = true;
    return;
  }

  await submitSubRequest(slot);
};

const submitSubRequest = async (slot: MatchSlotView) => {
  if (!props.activePlayerId) return;
  isSubmittingSubRequest.value = slot.slot_id;

  const { data, error } = await supabase
    .from('sub_requests')
    .insert({
      slot_id: slot.slot_id,
      requesting_player_id: props.activePlayerId,
      status: 'PENDING',
    })
    .select('id')
    .single();

  isSubmittingSubRequest.value = null;

  if (error) {
    subRequestToast.value = { text: error.message, error: true };
    return;
  }

  mySubRequests.value[slot.slot_id] = data.id;
  subRequestToast.value = {
    text: `Sub request submitted for Week ${slot.week_number} (${formatDayOfWeek(slot.day_of_week)})! You will be assigned if approved or drafted.`,
    error: false,
  };

  // Notify admin Discord
  notifySubRequestedByPlayer(
    {
      full_name: props.activePlayerName || 'A League Player',
      email: localPlayerProfile.value?.email || props.activePlayer?.email,
    },
    {
      week_number: slot.week_number,
      day_of_week: formatDayOfWeek(slot.day_of_week),
      match_date: slot.match_date,
      type: slot.type,
      court_number: slot.court_number,
      original_player_name: slot.player_name,
    }
  );

  emit('updated');
  setTimeout(() => {
    subRequestToast.value = null;
  }, 4500);
};

const handleConfirmBlackoutOverride = async () => {
  blackoutModalOpen.value = false;
  if (pendingTargetSlot.value) {
    const slot = pendingTargetSlot.value;
    pendingTargetSlot.value = null;
    await submitSubRequest(slot);
  }
};

const handleCancelRequest = async (slotId: string) => {
  if (!props.activePlayerId) return;
  isSubmittingSubRequest.value = slotId;

  const { error } = await supabase
    .from('sub_requests')
    .delete()
    .eq('slot_id', slotId)
    .eq('requesting_player_id', props.activePlayerId);

  isSubmittingSubRequest.value = null;

  if (error) {
    subRequestToast.value = { text: error.message, error: true };
  } else {
    delete mySubRequests.value[slotId];
    subRequestToast.value = { text: 'Sub request withdrawn.', error: false };
    emit('updated');
  }

  setTimeout(() => {
    subRequestToast.value = null;
  }, 3500);
};

// Filtering & Export state
const selectedFilter = ref<'all' | 'mine' | 'sub_open'>('all');
const selectedWeek = ref<number | 'all'>('all');
const searchQuery = ref<string>('');
const viewMode = ref<'cards' | 'table'>('cards');
const exportMenuOpen = ref<boolean>(false);

const handleExportPDF = () => {
  const slotsToExport = filteredGroupedMatches.value.flatMap((m) => m.slots);
  exportToPDF(slotsToExport, 'Winter Tennis League - Match Schedule');
  exportMenuOpen.value = false;
};

const handleExportExcel = () => {
  const slotsToExport = filteredGroupedMatches.value.flatMap((m) => m.slots);
  exportToExcel(slotsToExport);
  exportMenuOpen.value = false;
};

const handleExportCSV = () => {
  const slotsToExport = filteredGroupedMatches.value.flatMap((m) => m.slots);
  exportToCSV(slotsToExport);
  exportMenuOpen.value = false;
};

// Group raw slots by match_id
const groupedMatches = computed<GroupedMatch[]>(() => {
  const map = new Map<string, GroupedMatch>();
  props.allSlots.forEach((slot) => {
    if (!map.has(slot.match_id)) {
      map.set(slot.match_id, {
        match_id: slot.match_id,
        week_number: slot.week_number,
        day_of_week: slot.day_of_week,
        match_date: slot.match_date,
        type: slot.type,
        court_number: slot.court_number,
        slots: [],
      });
    }
    map.get(slot.match_id)!.slots.push(slot);
  });

  return Array.from(map.values()).sort(compareMatches);
});

// Available weeks for selector
const availableWeeks = computed<number[]>(() => {
  const weeks = new Set<number>();
  props.allSlots.forEach((s) => weeks.add(s.week_number));
  return Array.from(weeks).sort((a, b) => a - b);
});

// Open sub count
const openSubSlotsCount = computed(() => {
  return props.allSlots.filter((s) => s.status === 'OPEN_SUB').length;
});

// My scheduled matches count
const mySlotsCount = computed(() => {
  if (!props.activePlayerId) return 0;
  return props.allSlots.filter((s) => s.player_id === props.activePlayerId).length;
});

// Filtered Grouped Matches
const filteredGroupedMatches = computed<GroupedMatch[]>(() => {
  return groupedMatches.value.filter((match) => {
    // 1. Filter by Week
    if (selectedWeek.value !== 'all' && match.week_number !== selectedWeek.value) {
      return false;
    }

    // 2. Filter by Category Tab
    if (selectedFilter.value === 'mine') {
      if (!props.activePlayerId) return false;
      const hasMe = match.slots.some((s) => s.player_id === props.activePlayerId);
      if (!hasMe) return false;
    } else if (selectedFilter.value === 'sub_open') {
      const hasOpenSub = match.slots.some((s) => s.status === 'OPEN_SUB');
      if (!hasOpenSub) return false;
    }

    // 3. Filter by Search Query
    if (searchQuery.value.trim() !== '') {
      const q = searchQuery.value.toLowerCase().trim();
      const matchDayStr = formatDayOfWeek(match.day_of_week).toLowerCase();
      const matchDateStr = match.match_date.toLowerCase();
      const matchTypeStr = match.type.toLowerCase();
      const matchCourtStr = `court ${match.court_number}`;

      const matchesPlayer = match.slots.some((s) => s.player_name.toLowerCase().includes(q));
      const matchesMeta =
        matchDayStr.includes(q) ||
        matchDateStr.includes(q) ||
        matchTypeStr.includes(q) ||
        matchCourtStr.includes(q) ||
        `week ${match.week_number}`.includes(q);

      if (!matchesPlayer && !matchesMeta) return false;
    }

    return true;
  });
});
</script>

<template>
  <div class="space-y-6">
    <!-- Sub Request Toast Alert Banner -->
    <div
      v-if="subRequestToast"
      class="p-3.5 rounded-xl text-xs flex items-center justify-between gap-2 shadow-xs transition"
      :class="subRequestToast.error ? 'bg-red-50 text-red-700 border border-red-200' : 'bg-emerald-50 text-emerald-800 border border-emerald-200'"
    >
      <div class="flex items-center gap-2">
        <AlertCircle v-if="subRequestToast.error" class="w-4 h-4 flex-shrink-0" />
        <CheckCircle2 v-else class="w-4 h-4 flex-shrink-0 text-emerald-600" />
        <span class="font-medium">{{ subRequestToast.text }}</span>
      </div>
      <button @click="subRequestToast = null" class="text-slate-400 hover:text-slate-600 p-0.5">
        <X class="w-3.5 h-3.5" />
      </button>
    </div>

    <!-- Top Summary Banner & Quick Filters -->
    <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-4">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 class="text-xl font-bold text-slate-800 flex items-center gap-2">
            <Calendar class="w-6 h-6 text-blue-600" />
            Winter League Match Schedule
          </h2>
          <p class="text-xs text-slate-500 mt-0.5">
            View full weekly fixtures, check your assigned playing times, or request/claim sub spots.
          </p>
        </div>

        <!-- Right Quick Action Icon Buttons with Hover Titles -->
        <div class="flex items-center gap-2 flex-wrap text-xs font-semibold">
          <button
            v-if="props.activePlayer?.is_admin"
            @click="adminEditMode = !adminEditMode"
            :title="adminEditMode ? 'Exit Admin Edit Mode' : 'Enter Admin Edit Mode'"
            class="p-2 rounded-xl border transition flex items-center justify-center gap-1.5"
            :class="adminEditMode ? 'bg-indigo-600 text-white border-indigo-600 shadow-sm' : 'bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border-indigo-200'"
          >
            <ShieldCheck class="w-4 h-4" />
          </button>

          <button
            @click="selectedFilter = selectedFilter === 'mine' ? 'all' : 'mine'"
            title="My Matches"
            aria-label="My Matches"
            class="p-2 rounded-xl border transition flex items-center gap-1.5"
            :class="
              selectedFilter === 'mine'
                ? 'bg-blue-600 text-white border-blue-600 shadow-sm'
                : 'bg-slate-50 hover:bg-slate-100 text-slate-700 border-slate-200'
            "
          >
            <UserCheck class="w-4 h-4" />
            <span
              class="px-1.5 py-0.2 text-[10px] rounded-full font-bold"
              :class="selectedFilter === 'mine' ? 'bg-white/20 text-white' : 'bg-slate-200 text-slate-700'"
            >
              {{ mySlotsCount }}
            </span>
          </button>

          <button
            @click="selectedFilter = selectedFilter === 'sub_open' ? 'all' : 'sub_open'"
            title="Open Sub Opportunities"
            aria-label="Open Sub Opportunities"
            class="p-2 rounded-xl border transition flex items-center gap-1.5"
            :class="
              selectedFilter === 'sub_open'
                ? 'bg-amber-600 text-white border-amber-600 shadow-sm'
                : 'bg-amber-50 hover:bg-amber-100 text-amber-800 border-amber-200'
            "
          >
            <RefreshCw class="w-4 h-4" />
            <span
              class="px-1.5 py-0.2 text-[10px] rounded-full font-bold"
              :class="selectedFilter === 'sub_open' ? 'bg-white/20 text-white' : 'bg-amber-200 text-amber-900'"
            >
              {{ openSubSlotsCount }}
            </span>
          </button>

          <!-- Export Dropdown Icon Button -->
          <div class="relative">
            <button
              @click="exportMenuOpen = !exportMenuOpen"
              title="Export Schedule (PDF, Excel, CSV)"
              aria-label="Export Schedule"
              class="p-2 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 transition flex items-center gap-1 shadow-xs"
            >
              <Download class="w-4 h-4 text-blue-600" />
              <ChevronDown class="w-3 h-3 text-slate-400 transition-transform" :class="{ 'rotate-180': exportMenuOpen }" />
            </button>

            <!-- Dropdown Menu -->
            <div
              v-if="exportMenuOpen"
              class="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-slate-200 z-50 py-1 font-sans text-xs"
            >
              <button
                @click="handleExportPDF"
                class="w-full px-3 py-2 text-left text-slate-700 hover:bg-slate-50 flex items-center gap-2.5 transition font-medium"
              >
                <FileText class="w-4 h-4 text-rose-500" />
                <span>Export as PDF (.pdf)</span>
              </button>
              <button
                @click="handleExportExcel"
                class="w-full px-3 py-2 text-left text-slate-700 hover:bg-slate-50 flex items-center gap-2.5 transition font-medium"
              >
                <FileSpreadsheet class="w-4 h-4 text-emerald-600" />
                <span>Export as Excel (.xls)</span>
              </button>
              <button
                @click="handleExportCSV"
                class="w-full px-3 py-2 text-left text-slate-700 hover:bg-slate-50 flex items-center gap-2.5 transition font-medium"
              >
                <FileCode class="w-4 h-4 text-blue-600" />
                <span>Export as CSV (.csv)</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Controls & Filter Toolbar -->
      <div class="pt-4 border-t border-slate-100 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
        <!-- Filter Tabs & Search -->
        <div class="flex flex-wrap items-center gap-2">
          <!-- Filter Tabs -->
          <div class="inline-flex bg-slate-100 p-1 rounded-xl text-xs font-semibold">
            <button
              @click="selectedFilter = 'all'"
              class="px-3 py-1 rounded-lg transition"
              :class="selectedFilter === 'all' ? 'bg-white text-slate-800 shadow-xs' : 'text-slate-600 hover:text-slate-900'"
            >
              All Matches
            </button>
            <button
              @click="selectedFilter = 'mine'"
              class="px-3 py-1 rounded-lg transition"
              :class="selectedFilter === 'mine' ? 'bg-white text-slate-800 shadow-xs' : 'text-slate-600 hover:text-slate-900'"
            >
              My Schedule
            </button>
            <button
              @click="selectedFilter = 'sub_open'"
              class="px-3 py-1 rounded-lg transition"
              :class="selectedFilter === 'sub_open' ? 'bg-white text-slate-800 shadow-xs' : 'text-slate-600 hover:text-slate-900'"
            >
              Sub Needed
            </button>
          </div>

          <!-- Week Dropdown -->
          <div class="relative">
            <select
              v-model="selectedWeek"
              class="text-xs font-semibold bg-slate-100 border border-transparent rounded-xl px-3 py-1.5 pr-7 text-slate-700 hover:bg-slate-200/70 cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Weeks (1-{{ availableWeeks.length || 24 }})</option>
              <option v-for="w in availableWeeks" :key="w" :value="w">
                Week {{ w }}
              </option>
            </select>
          </div>
        </div>

        <!-- Search Bar & View Mode Toggle -->
        <div class="flex items-center gap-2">
          <div class="relative flex-1 sm:w-56">
            <Search class="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search player name or day..."
              class="w-full text-xs pl-8 pr-8 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
            />
            <button
              v-if="searchQuery"
              @click="searchQuery = ''"
              class="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 p-0.5 rounded-full hover:bg-slate-200/70 transition flex items-center justify-center"
              title="Clear search text"
              aria-label="Clear search"
            >
              <X class="w-3.5 h-3.5" />
            </button>
          </div>

          <!-- Layout Switcher -->
          <div class="inline-flex bg-slate-100 p-1 rounded-xl text-xs">
            <button
              @click="viewMode = 'cards'"
              class="p-1 rounded-lg transition"
              :class="viewMode === 'cards' ? 'bg-white text-blue-600 shadow-xs' : 'text-slate-500 hover:text-slate-800'"
              title="Match Cards View"
            >
              <Grid class="w-4 h-4" />
            </button>
            <button
              @click="viewMode = 'table'"
              class="p-1 rounded-lg transition"
              :class="viewMode === 'table' ? 'bg-white text-blue-600 shadow-xs' : 'text-slate-500 hover:text-slate-800'"
              title="Compact Table View"
            >
              <List class="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Open Sub Opportunities Alert Bar (If Any Exist & 'all' view selected) -->
    <div
      v-if="openSubSlotsCount > 0 && selectedFilter === 'all'"
      class="bg-amber-50 border border-amber-200 rounded-2xl p-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-xs"
    >
      <div class="flex items-center gap-3">
        <div class="w-9 h-9 bg-amber-100 text-amber-800 rounded-xl flex items-center justify-center font-bold flex-shrink-0">
          <RefreshCw class="w-5 h-5 animate-pulse" />
        </div>
        <div>
          <h3 class="text-xs font-bold text-amber-900">
            {{ openSubSlotsCount }} Sub {{ openSubSlotsCount === 1 ? 'Opportunity' : 'Opportunities' }} Available
          </h3>
          <p class="text-[11px] text-amber-700">
            Players have requested subs for upcoming matches. Click below to review and claim open spots.
          </p>
        </div>
      </div>
      <button
        @click="selectedFilter = 'sub_open'"
        class="text-xs font-bold px-3 py-1.5 bg-amber-600 hover:bg-amber-700 text-white rounded-xl transition shadow-xs flex items-center gap-1.5 flex-shrink-0"
      >
        <span>View Sub Board</span>
        <ArrowRight class="w-3.5 h-3.5" />
      </button>
    </div>

    <!-- Empty State -->
    <div
      v-if="filteredGroupedMatches.length === 0"
      class="bg-white border border-dashed border-slate-300 p-8 rounded-2xl text-center space-y-3"
    >
      <Calendar class="w-10 h-10 mx-auto text-slate-300" />
      <div>
        <h3 class="text-sm font-bold text-slate-700">No matches found</h3>
        <p class="text-xs text-slate-500 max-w-sm mx-auto mt-1">
          No scheduled matches match your selected filters (Week {{ selectedWeek }}, {{ selectedFilter }} view).
        </p>
      </div>
      <button
        @click="selectedFilter = 'all'; selectedWeek = 'all'; searchQuery = '';"
        class="text-xs font-semibold text-blue-600 hover:underline"
      >
        Reset Filters
      </button>
    </div>

    <!-- VIEW MODE 1: MATCH CARDS GRID (Grouped Fixtures) -->
    <div v-else-if="viewMode === 'cards'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="match in filteredGroupedMatches"
        :key="match.match_id"
        class="bg-white rounded-2xl border transition-all shadow-sm overflow-hidden flex flex-col justify-between"
        :class="[
          match.slots.some((s) => s.player_id === activePlayerId)
            ? 'border-blue-300 ring-2 ring-blue-500/10'
            : 'border-slate-200 hover:border-slate-300',
        ]"
      >
        <!-- Match Header -->
        <div class="p-4 bg-slate-50/80 border-b border-slate-100 flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <span class="text-xs font-extrabold px-2.5 py-1 bg-slate-800 text-white rounded-lg">
              Wk {{ match.week_number }}
            </span>
            <div>
              <div class="text-xs font-bold text-slate-800">
                {{ formatDayOfWeek(match.day_of_week) }}, {{ match.match_date }}
              </div>
              <div class="text-[10px] text-slate-500 font-medium">Court #{{ match.court_number }}</div>
            </div>
          </div>

          <!-- Type Badge -->
          <span
            class="text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider"
            :class="
              match.type === 'SINGLES'
                ? 'bg-indigo-100 text-indigo-800 border border-indigo-200'
                : 'bg-emerald-100 text-emerald-800 border border-emerald-200'
            "
          >
            {{ match.type }}
          </span>
        </div>

        <!-- Match Roster / Court Slots -->
        <div class="p-4 space-y-2.5 flex-1">
          <div class="text-[10px] font-bold uppercase tracking-wider text-slate-400">
            Court Roster ({{ match.slots.length }} Players)
          </div>

          <div
            v-for="(slot, idx) in match.slots"
            :key="slot.slot_id"
            class="p-2.5 rounded-xl border flex items-center justify-between transition-all"
            :class="[
              slot.player_id === activePlayerId
                ? 'bg-blue-50/70 border-blue-200'
                : slot.status === 'OPEN_SUB'
                ? 'bg-amber-50/80 border-amber-200'
                : 'bg-slate-50/50 border-slate-100',
            ]"
          >
            <div class="flex items-center gap-2.5">
              <div
                class="w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold"
                :class="
                  slot.player_id === activePlayerId
                    ? 'bg-blue-600 text-white'
                    : slot.status === 'OPEN_SUB'
                    ? 'bg-amber-500 text-white'
                    : 'bg-slate-200 text-slate-600'
                "
              >
                {{ idx + 1 }}
              </div>

              <div>
                <div class="text-xs font-semibold text-slate-800 flex items-center gap-1.5">
                  <span>{{ slot.player_name }}</span>
                  <span
                    v-if="slot.player_id === activePlayerId"
                    class="text-[9px] font-extrabold uppercase px-1.5 py-0.2 bg-blue-600 text-white rounded-full"
                  >
                    You
                  </span>
                </div>
                <div class="text-[10px] flex items-center gap-1 mt-0.5">
                  <span
                    v-if="slot.status === 'OPEN_SUB'"
                    class="text-amber-700 font-semibold flex items-center gap-1"
                  >
                    <AlertTriangle class="w-3 h-3 text-amber-500" />
                    Sub Needed
                  </span>
                  <span v-else class="text-slate-400">Confirmed</span>
                </div>
              </div>
            </div>

            <!-- Action Button per Slot -->
            <div>
              <!-- If this slot belongs to logged in player OR Admin Edit Mode -->
              <template v-if="slot.player_id === activePlayerId || (props.activePlayer?.is_admin && adminEditMode)">
                <button
                  v-if="slot.status === 'CONFIRMED'"
                  @click="emit('setSubStatus', slot.slot_id, 'OPEN_SUB')"
                  class="text-[11px] font-semibold px-2.5 py-1 bg-white border border-rose-200 text-rose-600 hover:bg-rose-50 rounded-lg transition"
                >
                  Request Sub
                </button>
                <button
                  v-else
                  @click="emit('setSubStatus', slot.slot_id, 'CONFIRMED')"
                  class="text-[11px] font-semibold px-2.5 py-1 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded-lg transition"
                >
                  Reclaim Spot
                </button>
              </template>

              <!-- If this slot is OPEN_SUB and belongs to another player -->
              <template v-if="slot.status === 'OPEN_SUB' && slot.player_id !== activePlayerId">
                <div class="flex flex-col items-end gap-1">
                  <!-- Admin Assign UI -->
                  <div v-if="props.activePlayer?.is_admin && adminEditMode" class="flex flex-col items-end gap-1 mt-1">
                    <select v-model="selectedAssignee[slot.slot_id]" class="text-[10px] p-1 rounded border max-w-[140px] truncate bg-white">
                      <option disabled value="">Select Player...</option>
                      <option 
                        v-for="p in getRankedPlayersForSlot(slot)" 
                        :key="p.id" 
                        :value="p.id"
                        :disabled="p.penalty < 0"
                      >
                        {{ p.full_name }} ({{ p.reason }})
                      </option>
                    </select>
                    <button 
                      @click="emit('claimSlot', slot.slot_id, selectedAssignee[slot.slot_id])"
                      :disabled="!selectedAssignee[slot.slot_id]"
                      class="text-[10px] font-bold px-3 py-1 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition disabled:opacity-50"
                    >
                      Assign
                    </button>
                  </div>
                  <template v-else>
                    <button
                      v-if="mySubRequests[slot.slot_id]"
                    @click="handleCancelRequest(slot.slot_id)"
                    :disabled="isSubmittingSubRequest === slot.slot_id"
                    class="text-[11px] font-bold px-3 py-1 bg-slate-200 hover:bg-rose-100 text-slate-700 hover:text-rose-700 rounded-lg transition disabled:opacity-50"
                  >
                    <RefreshCw v-if="isSubmittingSubRequest === slot.slot_id" class="w-3 h-3 animate-spin inline-block mr-1" />
                    Cancel Request
                  </button>
                  <button
                    v-else
                    @click="handleStartRequest(slot)"
                    :disabled="isSubmittingSubRequest === slot.slot_id"
                    class="text-[11px] font-bold px-3 py-1 bg-amber-500 hover:bg-amber-600 text-white rounded-lg transition shadow-xs disabled:opacity-50"
                  >
                    <RefreshCw v-if="isSubmittingSubRequest === slot.slot_id" class="w-3 h-3 animate-spin inline-block mr-1" />
                    Request Slot
                  </button>
                  <span
                    v-if="leagueConfig.sub_request_flow === 'maintenance_free'"
                    class="text-[10px] text-amber-700 font-medium text-right"
                  >
                    Slot will be auto-assigned 24 hours before the match.
                  </span>
                  </template>
                </div>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- VIEW MODE 2: COMPACT TABLE VIEW (Grouped by Match Fixture) -->
    <div v-else class="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs border-collapse">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-200 text-slate-500 font-semibold">
              <th class="p-3">Wk</th>
              <th class="p-3">Day & Date</th>
              <th class="p-3">Type</th>
              <th class="p-3">Court</th>
              <th class="p-3">Match Lineup / Roster</th>
              <th class="p-3 text-right">Sub Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr
              v-for="match in filteredGroupedMatches"
              :key="match.match_id"
              class="hover:bg-slate-50/80 transition"
              :class="{ 'bg-blue-50/30': match.slots.some((s) => s.player_id === activePlayerId) }"
            >
              <td class="p-3 font-extrabold text-slate-800">Wk {{ match.week_number }}</td>
              <td class="p-3">
                <div class="font-bold text-slate-800">{{ formatDayOfWeek(match.day_of_week) }}</div>
                <div class="text-[10px] text-slate-400">{{ match.match_date }}</div>
              </td>
              <td class="p-3">
                <span
                  class="text-[10px] font-bold px-2 py-0.5 rounded-full"
                  :class="
                    match.type === 'SINGLES'
                      ? 'bg-indigo-100 text-indigo-800'
                      : 'bg-emerald-100 text-emerald-800'
                  "
                >
                  {{ match.type }}
                </span>
              </td>
              <td class="p-3 font-semibold text-slate-700">Ct {{ match.court_number }}</td>

              <!-- Players list in match -->
              <td class="p-3">
                <div class="flex flex-wrap items-center gap-1.5">
                  <div
                    v-for="slot in match.slots"
                    :key="slot.slot_id"
                    class="px-2 py-1 rounded-lg border text-[11px] font-medium flex items-center gap-1"
                    :class="[
                      slot.player_id === activePlayerId
                        ? 'bg-blue-100 border-blue-300 text-blue-900 font-bold'
                        : slot.status === 'OPEN_SUB'
                        ? 'bg-amber-100 border-amber-300 text-amber-900 font-bold'
                        : 'bg-slate-100 border-slate-200 text-slate-700',
                    ]"
                  >
                    <span>{{ slot.player_name }}</span>
                    <span
                      v-if="slot.player_id === activePlayerId"
                      class="text-[8px] uppercase bg-blue-600 text-white px-1 rounded"
                    >
                      You
                    </span>
                    <span
                      v-if="slot.status === 'OPEN_SUB'"
                      class="text-[8px] uppercase bg-amber-600 text-white px-1 rounded"
                    >
                      Sub
                    </span>
                  </div>
                </div>
              </td>

              <!-- Sub Actions -->
              <td class="p-3 text-right">
                <div class="flex items-center justify-end gap-1.5">
                  <template v-for="slot in match.slots" :key="slot.slot_id">
                    <button
                      v-if="(slot.player_id === activePlayerId || (props.activePlayer?.is_admin && adminEditMode)) && slot.status === 'CONFIRMED'"
                      @click="emit('setSubStatus', slot.slot_id, 'OPEN_SUB')"
                      class="text-[10px] font-bold px-2 py-1 bg-white border border-rose-200 text-rose-600 hover:bg-rose-50 rounded transition"
                    >
                      Request Sub
                    </button>
                    <button
                      v-else-if="(slot.player_id === activePlayerId || (props.activePlayer?.is_admin && adminEditMode)) && slot.status === 'OPEN_SUB'"
                      @click="emit('setSubStatus', slot.slot_id, 'CONFIRMED')"
                      class="text-[10px] font-bold px-2 py-1 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded transition"
                    >
                      Reclaim
                    </button>
                    <template v-if="slot.status === 'OPEN_SUB' && slot.player_id !== activePlayerId">
                      <div class="flex flex-col items-end gap-0.5">
                        <!-- Admin Assign UI -->
                        <div v-if="props.activePlayer?.is_admin && adminEditMode" class="flex flex-col gap-1 my-1 items-end">
                          <select v-model="selectedAssignee[slot.slot_id]" class="text-[10px] p-0.5 rounded border max-w-[120px] truncate bg-white">
                            <option disabled value="">Select Player...</option>
                            <option 
                              v-for="p in getRankedPlayersForSlot(slot)" 
                              :key="p.id" 
                              :value="p.id"
                              :disabled="p.penalty < 0"
                            >
                              {{ p.full_name }} ({{ p.reason }})
                            </option>
                          </select>
                          <button 
                            @click="emit('claimSlot', slot.slot_id, selectedAssignee[slot.slot_id])"
                            :disabled="!selectedAssignee[slot.slot_id]"
                            class="text-[9px] font-bold px-2 py-1 bg-indigo-600 hover:bg-indigo-700 text-white rounded transition disabled:opacity-50"
                          >
                            Assign
                          </button>
                        </div>
                        <template v-else>
                          <button
                            v-if="mySubRequests[slot.slot_id]"
                          @click="handleCancelRequest(slot.slot_id)"
                          :disabled="isSubmittingSubRequest === slot.slot_id"
                          class="text-[10px] font-bold px-2 py-1 bg-slate-200 hover:bg-rose-100 text-slate-700 hover:text-rose-700 rounded transition disabled:opacity-50"
                        >
                          Cancel Request
                        </button>
                        <button
                          v-else
                          @click="handleStartRequest(slot)"
                          :disabled="isSubmittingSubRequest === slot.slot_id"
                          class="text-[10px] font-bold px-2.5 py-1 bg-amber-500 hover:bg-amber-600 text-white rounded transition shadow-xs disabled:opacity-50"
                        >
                          Request Slot
                        </button>
                          <span
                            v-if="leagueConfig.sub_request_flow === 'maintenance_free'"
                            class="text-[9px] text-amber-700 text-right"
                          >
                            Auto-assigned 24h prior
                          </span>
                        </template>
                      </div>
                    </template>
                  </template>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Blackout Override Confirmation Modal -->
    <div
      v-if="blackoutModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs"
    >
      <div class="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
        <div class="flex items-center gap-3 mb-4 text-amber-600">
          <div class="p-3 bg-amber-100 rounded-full">
            <AlertTriangle class="w-6 h-6 text-amber-600" />
          </div>
          <div>
            <h3 class="font-bold text-base text-slate-900">Blackout Period Notice</h3>
            <p class="text-xs text-slate-500">Confirm your availability for this slot</p>
          </div>
        </div>

        <div class="bg-amber-50/80 border border-amber-200 rounded-xl p-3.5 mb-4 text-xs text-amber-900 space-y-1.5">
          <p class="font-semibold">
            You previously marked <strong>{{ blackoutReason }}</strong> as an unavailable blackout period in your registration intake.
          </p>
          <p class="text-slate-600">
            Match: <span class="font-bold text-slate-800">Week {{ pendingTargetSlot?.week_number }} • {{ pendingTargetSlot ? formatDayOfWeek(pendingTargetSlot.day_of_week) : '' }}, {{ pendingTargetSlot?.match_date }} (Court {{ pendingTargetSlot?.court_number }})</span>
          </p>
          <p class="text-amber-800 pt-1">
            Are you sure your schedule has opened up and you are available to play during this time?
          </p>
        </div>

        <div class="flex justify-end gap-2.5">
          <button
            type="button"
            @click="blackoutModalOpen = false; pendingTargetSlot = null;"
            class="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-lg transition"
          >
            Cancel
          </button>
          <button
            type="button"
            @click="handleConfirmBlackoutOverride"
            class="px-4 py-2 text-xs font-bold bg-amber-500 hover:bg-amber-600 text-white rounded-lg transition shadow-xs"
          >
            Yes, Request Slot
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
