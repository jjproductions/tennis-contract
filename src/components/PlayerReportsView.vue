<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '../supabase';
import {
  FileSpreadsheet,
  FileText,
  RefreshCw,
  Search,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  CheckCircle2,
  Star,
  Users,
  Calendar,
  ChevronDown,
  ChevronUp,
  ArrowUpDown,
  ShieldCheck,
  Info,
  Check,
  ArrowRightLeft
} from 'lucide-vue-next';
import { formatDayOfWeek } from '../utils/scheduleGenerator';
import {
  exportPlayerMetricsToCSV,
  exportPlayerMetricsToPDF,
  type PlayerReportMetric,
} from '../utils/exportUtils';

interface PlayerRecord {
  id: string;
  full_name: string;
  email: string;
  singles_share: number;
  doubles_share: number;
  blackout_weeks: number[];
  blackout_days?: string[];
  approved?: boolean;
  is_admin?: boolean;
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
  player_email?: string;
}

interface BilateralKarmaDetail {
  partnerId: string;
  partnerName: string;
  iSubbedForThem: number;
  theySubbedForMe: number;
  balance: number; // positive: they owe me; negative: I owe them
}

const props = defineProps<{
  initialPlayers?: PlayerRecord[];
  initialSlots?: MatchSlotView[];
}>();

const loading = ref<boolean>(true);
const players = ref<PlayerRecord[]>([]);
const allSlots = ref<MatchSlotView[]>([]);
const subRankings = ref<any[]>([]);
const pendingSubRequests = ref<any[]>([]);

const searchQuery = ref<string>('');
const selectedFilter = ref<'all' | 'behind' | 'owed' | 'high_turnover' | 'singles' | 'doubles' | 'waitlist'>('all');
const sortKey = ref<string>('full_name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const expandedPlayerId = ref<string | null>(null);

const exportLoading = ref<boolean>(false);
const exportNotification = ref<string | null>(null);

// Current date and dynamic week
const todayStr = computed<string>(() => {
  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
});

const totalWeeks = computed<number>(() => {
  if (!allSlots.value.length) return 24;
  return Math.max(...allSlots.value.map((s) => s.week_number || 0), 24);
});

const currentWeekNumber = computed<number>(() => {
  if (!allSlots.value || allSlots.value.length === 0) return 1;

  const weekMap = new Map<number, { min: string; max: string }>();
  for (const slot of allSlots.value) {
    if (!slot.match_date) continue;
    const existing = weekMap.get(slot.week_number);
    if (!existing) {
      weekMap.set(slot.week_number, { min: slot.match_date, max: slot.match_date });
    } else {
      if (slot.match_date < existing.min) existing.min = slot.match_date;
      if (slot.match_date > existing.max) existing.max = slot.match_date;
    }
  }

  const sortedWeeks = Array.from(weekMap.keys()).sort((a, b) => a - b);
  if (sortedWeeks.length === 0) return 1;

  const firstWeek = sortedWeeks[0];
  if (todayStr.value < weekMap.get(firstWeek)!.min) {
    return firstWeek;
  }

  for (let i = 0; i < sortedWeeks.length; i++) {
    const w = sortedWeeks[i];
    const currentRange = weekMap.get(w)!;
    const nextWeek = sortedWeeks[i + 1];

    if (nextWeek) {
      const nextRange = weekMap.get(nextWeek)!;
      if (todayStr.value >= currentRange.min && todayStr.value < nextRange.min) {
        return w;
      }
    } else {
      if (todayStr.value >= currentRange.min) {
        return w;
      }
    }
  }
  return 1;
});

const loadData = async () => {
  loading.value = true;
  try {
    // 1. Fetch Players
    const { data: pData } = await supabase
      .from('players')
      .select('id, full_name, email, singles_share, doubles_share, blackout_weeks, blackout_days, approved, is_admin')
      .order('full_name', { ascending: true });
    if (pData) players.value = pData;

    // 2. Fetch Match Slots
    const { data: sData } = await supabase
      .from('match_slots')
      .select(`
        id,
        status,
        player_id,
        original_player_id,
        players!match_slots_player_id_fkey ( full_name, email ),
        matches ( id, week_number, day_of_week, match_date, type, court_number )
      `);

    if (sData) {
      allSlots.value = sData
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
          player_email: item.players?.email,
        }));
    }

    // 3. Fetch sub_requests
    const { data: rData } = await supabase
      .from('sub_requests')
      .select('*')
      .eq('status', 'PENDING');
    if (rData) pendingSubRequests.value = rData;

    // 4. Fetch sub_request_rankings for is_owed_match
    const { data: rkData } = await supabase
      .from('sub_request_rankings')
      .select('*');
    if (rkData) subRankings.value = rkData;
  } catch (err) {
    console.error('Error loading report data:', err);
  } finally {
    loading.value = false;
  }
};

onMounted(async () => {
  await loadData();
});

// Map of matches to all slots in that match (to determine co-players, opponents, partners)
const matchSlotsMap = computed(() => {
  const map = new Map<string, MatchSlotView[]>();
  for (const s of allSlots.value) {
    if (!map.has(s.match_id)) {
      map.set(s.match_id, []);
    }
    map.get(s.match_id)!.push(s);
  }
  return map;
});

// Calculate full metrics per player
const calculatedMetrics = computed<PlayerReportMetric[]>(() => {
  const totalW = totalWeeks.value;
  const currW = currentWeekNumber.value;
  const today = todayStr.value;

  // Build name lookup map
  const playerNameMap = new Map<string, string>();
  for (const p of players.value) {
    playerNameMap.set(p.id, p.full_name);
  }

  return players.value.map((player) => {
    const pId = player.id;

    // Confirmed slots where player is currently scheduled/playing
    const confirmedSlots = allSlots.value.filter(
      (s) => s.player_id === pId && s.status === 'CONFIRMED'
    );

    // Slots originally belonging to this player from the baseline schedule
    const originalSlots = allSlots.value.filter(
      (s) =>
        s.original_player_id === pId ||
        (s.original_player_id === null && s.player_id === pId)
    );

    // Singles & Doubles breakdown
    const scheduled_singles = confirmedSlots.filter((s) => s.type === 'SINGLES').length;
    const scheduled_doubles = confirmedSlots.filter((s) => s.type === 'DOUBLES').length;
    const scheduled_total = confirmedSlots.length;

    // Target contract calculations
    const singles_share = Number(player.singles_share) || 0;
    const doubles_share = Number(player.doubles_share) || 0;
    const total_share = singles_share + doubles_share;

    const target_singles = Math.round(singles_share * totalW);
    const target_doubles = Math.round(doubles_share * totalW);
    const target_total = target_singles + target_doubles;

    // Played to date (matches scheduled on or before today, or in week <= currentWeek)
    const played_singles_to_date = confirmedSlots.filter(
      (s) => s.type === 'SINGLES' && (s.match_date <= today || s.week_number <= currW)
    ).length;

    const played_doubles_to_date = confirmedSlots.filter(
      (s) => s.type === 'DOUBLES' && (s.match_date <= today || s.week_number <= currW)
    ).length;

    const played_total_to_date = played_singles_to_date + played_doubles_to_date;

    // Expected to date
    const expected_to_date =
      target_total > 0 ? (target_total * currW) / totalW : 0;
    const pace_delta = target_total > 0 ? played_total_to_date - expected_to_date : 0;

    // Sub Turnover Calculations
    // Subbed Out: slots originally belonging to this player that were given away or are OPEN_SUB
    const times_subbed_out = originalSlots.filter(
      (s) =>
        s.status === 'OPEN_SUB' ||
        (s.status === 'CONFIRMED' && s.player_id !== pId)
    ).length;

    // Subbed In: slots where this player filled in for another player
    const times_subbed_in = allSlots.value.filter(
      (s) =>
        s.player_id === pId &&
        s.original_player_id !== null &&
        s.original_player_id !== pId &&
        s.status === 'CONFIRMED'
    ).length;

    const net_sub_impact = times_subbed_in - times_subbed_out;
    const projected_total = scheduled_total;
    const projected_variance = projected_total - target_total;

    // Option 3: Primary focus on PROJ. TOTAL against target contract
    // 'behind' indicates an actual projected deficit (e.g. unfilled sub-outs or under-allocation)
    let pace_status: 'ahead' | 'on_track' | 'behind' | 'sub_pool' = 'on_track';
    if (target_total === 0) {
      pace_status = 'sub_pool';
    } else if (projected_variance < 0) {
      pace_status = 'behind';
    } else if (projected_variance > 0) {
      pace_status = 'ahead';
    } else {
      pace_status = 'on_track';
    }

    // Pending requests & Owed requests
    const playerPendingReqs = pendingSubRequests.value.filter(
      (r) => r.requesting_player_id === pId
    );
    const pending_sub_requests_count = playerPendingReqs.length;

    // Find pending requests where is_owed_match = true
    const pending_owed_requests_count = subRankings.value.filter(
      (rk) => rk.requesting_player_id === pId && rk.is_owed_match === true
    ).length;

    // Bilateral Karma Balance:
    // (Times player subbed for others) - (Times others subbed for player)
    let favorsOwedToMe = 0;
    let favorsIOweOthers = 0;

    for (const other of players.value) {
      if (other.id === pId) continue;
      const iSubbedForOther = allSlots.value.filter(
        (s) =>
          s.player_id === pId &&
          s.original_player_id === other.id &&
          s.status === 'CONFIRMED'
      ).length;

      const otherSubbedForMe = allSlots.value.filter(
        (s) =>
          s.player_id === other.id &&
          s.original_player_id === pId &&
          s.status === 'CONFIRMED'
      ).length;

      if (iSubbedForOther > otherSubbedForMe) {
        favorsOwedToMe += iSubbedForOther - otherSubbedForMe;
      } else if (otherSubbedForMe > iSubbedForOther) {
        favorsIOweOthers += otherSubbedForMe - iSubbedForOther;
      }
    }
    const net_karma_balance = favorsOwedToMe - favorsIOweOthers;

    // Blackouts & Streaks
    const blackout_weeks = player.blackout_weeks || [];
    const blackout_weeks_count = blackout_weeks.length;

    // Max idle streak across season weeks
    const activeWeeks = new Set(confirmedSlots.map((s) => s.week_number));
    let max_inactivity_streak = 0;
    let currentIdle = 0;
    for (let w = 1; w <= totalW; w++) {
      if (!activeWeeks.has(w)) {
        currentIdle++;
        if (currentIdle > max_inactivity_streak) {
          max_inactivity_streak = currentIdle;
        }
      } else {
        currentIdle = 0;
      }
    }

    // Last & Next Match
    const pastSlots = confirmedSlots
      .filter((s) => s.match_date <= today)
      .sort((a, b) => a.match_date.localeCompare(b.match_date));
    const lastSlot = pastSlots.length ? pastSlots[pastSlots.length - 1] : null;

    const futureSlots = confirmedSlots
      .filter((s) => s.match_date > today)
      .sort((a, b) => a.match_date.localeCompare(b.match_date));
    const nextSlot = futureSlots.length ? futureSlots[0] : null;

    // Opponent & Partner Variety
    const opponentsSet = new Set<string>();
    const partnersSet = new Set<string>();

    for (const slot of confirmedSlots) {
      const matchSlots = matchSlotsMap.value.get(slot.match_id) || [];
      for (const otherSlot of matchSlots) {
        if (otherSlot.player_id && otherSlot.player_id !== pId) {
          opponentsSet.add(otherSlot.player_id);
          if (slot.type === 'DOUBLES') {
            partnersSet.add(otherSlot.player_id);
          }
        }
      }
    }

    return {
      id: player.id,
      full_name: player.full_name,
      email: player.email || '',
      is_admin: player.is_admin === true,
      approved: player.approved !== false,
      singles_share,
      doubles_share,
      total_share,
      target_singles,
      target_doubles,
      target_total,
      scheduled_singles,
      scheduled_doubles,
      scheduled_total,
      played_singles_to_date,
      played_doubles_to_date,
      played_total_to_date,
      expected_to_date,
      pace_delta,
      pace_status,
      times_subbed_out,
      times_subbed_in,
      net_sub_impact,
      projected_total,
      projected_variance,
      pending_sub_requests_count,
      pending_owed_requests_count,
      net_karma_balance,
      blackout_weeks_count,
      max_inactivity_streak,
      last_match_date: lastSlot?.match_date ?? null,
      last_match_week: lastSlot?.week_number ?? null,
      next_match_date: nextSlot?.match_date ?? null,
      next_match_week: nextSlot?.week_number ?? null,
      unique_opponents_count: opponentsSet.size,
      unique_partners_count: partnersSet.size,
    };
  });
});

// League-wide summary statistics
const summaryStats = computed(() => {
  const all = calculatedMetrics.value;
  const totalPlayers = all.length;
  const onTrackCount = all.filter((m) => m.pace_status === 'on_track').length;
  const behindCount = all.filter((m) => m.pace_status === 'behind').length;
  const aheadCount = all.filter((m) => m.pace_status === 'ahead').length;
  const subPoolCount = all.filter((m) => m.pace_status === 'sub_pool').length;

  const totalSubTurnover = all.reduce((acc, m) => acc + m.times_subbed_out, 0);
  const pendingKarmaFavors = all.reduce((acc, m) => acc + m.pending_owed_requests_count, 0);

  const contractedPlayers = all.filter((m) => m.target_total > 0);
  const deliveryPacePct =
    contractedPlayers.length > 0
      ? Math.round(((onTrackCount + aheadCount) / contractedPlayers.length) * 100)
      : 100;

  return {
    totalPlayers,
    onTrackCount,
    behindCount,
    aheadCount,
    subPoolCount,
    totalSubTurnover,
    pendingKarmaFavors,
    deliveryPacePct,
    currentWeek: currentWeekNumber.value,
  };
});

// Filter & Sort
const filteredMetrics = computed(() => {
  let list = calculatedMetrics.value;

  // Search filter
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase().trim();
    list = list.filter(
      (m) =>
        m.full_name.toLowerCase().includes(q) ||
        m.email.toLowerCase().includes(q)
    );
  }

  // Preset Filters
  if (selectedFilter.value === 'behind') {
    list = list.filter((m) => m.pace_status === 'behind');
  } else if (selectedFilter.value === 'owed') {
    list = list.filter((m) => m.pending_owed_requests_count > 0 || m.net_karma_balance > 0);
  } else if (selectedFilter.value === 'high_turnover') {
    list = list.filter((m) => {
      if (m.scheduled_total === 0) return false;
      return m.times_subbed_out / m.scheduled_total >= 0.25;
    });
  } else if (selectedFilter.value === 'singles') {
    list = list.filter((m) => m.singles_share > 0);
  } else if (selectedFilter.value === 'doubles') {
    list = list.filter((m) => m.doubles_share > 0);
  } else if (selectedFilter.value === 'waitlist') {
    list = list.filter((m) => m.target_total === 0 || !m.approved);
  }

  // Sorting
  const order = sortOrder.value === 'asc' ? 1 : -1;
  return [...list].sort((a: any, b: any) => {
    let valA = a[sortKey.value];
    let valB = b[sortKey.value];

    if (typeof valA === 'string') {
      return valA.localeCompare(valB) * order;
    }
    if (valA == null) return 1 * order;
    if (valB == null) return -1 * order;
    return (valA - valB) * order;
  });
});

const handleSort = (key: string) => {
  if (sortKey.value === key) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortKey.value = key;
    sortOrder.value = 'asc';
  }
};

const toggleExpand = (playerId: string) => {
  expandedPlayerId.value = expandedPlayerId.value === playerId ? null : playerId;
};

// Expand detail helpers
const playerNameMap = computed(() => {
  const map = new Map<string, string>();
  for (const p of players.value) {
    map.set(p.id, p.full_name);
  }
  return map;
});

const getPlayerMatches = (playerId: string) => {
  return allSlots.value
    .filter((s) => s.player_id === playerId && s.status === 'CONFIRMED')
    .sort((a, b) => a.week_number - b.week_number || a.match_date.localeCompare(b.match_date));
};

const getPlayerSubOuts = (playerId: string) => {
  return allSlots.value
    .filter((s) => {
      const isOriginallyMine =
        s.original_player_id === playerId ||
        (s.original_player_id === null && s.player_id === playerId);
      const isSubbedOut =
        s.status === 'OPEN_SUB' ||
        (s.status === 'CONFIRMED' && s.player_id !== playerId);
      return isOriginallyMine && isSubbedOut;
    })
    .map((s) => {
      const isClaimed = s.status === 'CONFIRMED' && s.player_id && s.player_id !== playerId;
      const subPlayerName = isClaimed
        ? playerNameMap.value.get(s.player_id!) || s.player_name || 'Sub Assigned'
        : null;
      return {
        slot_id: s.slot_id,
        week_number: s.week_number,
        match_date: s.match_date,
        day_of_week: s.day_of_week,
        type: s.type,
        court_number: s.court_number,
        status: s.status,
        subPlayerName,
      };
    })
    .sort((a, b) => a.week_number - b.week_number || a.match_date.localeCompare(b.match_date));
};

const getPlayerSubIns = (playerId: string) => {
  return allSlots.value
    .filter(
      (s) =>
        s.player_id === playerId &&
        s.original_player_id !== null &&
        s.original_player_id !== playerId &&
        s.status === 'CONFIRMED'
    )
    .map((s) => {
      const origPlayerName =
        playerNameMap.value.get(s.original_player_id!) || 'Original Owner';
      return {
        slot_id: s.slot_id,
        week_number: s.week_number,
        match_date: s.match_date,
        day_of_week: s.day_of_week,
        type: s.type,
        court_number: s.court_number,
        origPlayerName,
      };
    })
    .sort((a, b) => a.week_number - b.week_number || a.match_date.localeCompare(b.match_date));
};

const getPlayerKarmaDetails = (playerId: string): BilateralKarmaDetail[] => {
  const result: BilateralKarmaDetail[] = [];
  for (const other of players.value) {
    if (other.id === playerId) continue;
    const iSubbed = allSlots.value.filter(
      (s) =>
        s.player_id === playerId &&
        s.original_player_id === other.id &&
        s.status === 'CONFIRMED'
    ).length;

    const theySubbed = allSlots.value.filter(
      (s) =>
        s.player_id === other.id &&
        s.original_player_id === playerId &&
        s.status === 'CONFIRMED'
    ).length;

    if (iSubbed > 0 || theySubbed > 0) {
      result.push({
        partnerId: other.id,
        partnerName: other.full_name,
        iSubbedForThem: iSubbed,
        theySubbedForMe: theySubbed,
        balance: iSubbed - theySubbed,
      });
    }
  }
  return result.sort((a, b) => Math.abs(b.balance) - Math.abs(a.balance));
};

// Export Handlers
const handleExportCSV = () => {
  exportNotification.value = 'Generating CSV export...';
  try {
    exportPlayerMetricsToCSV(filteredMetrics.value);
    exportNotification.value = 'CSV exported successfully!';
    setTimeout(() => {
      exportNotification.value = null;
    }, 3000);
  } catch (err: any) {
    exportNotification.value = `CSV export failed: ${err.message}`;
  }
};

const handleExportPDF = async () => {
  exportLoading.value = true;
  exportNotification.value = 'Generating PDF audit report...';
  try {
    await exportPlayerMetricsToPDF(filteredMetrics.value, summaryStats.value);
    exportNotification.value = 'PDF exported successfully!';
    setTimeout(() => {
      exportNotification.value = null;
    }, 3000);
  } catch (err: any) {
    exportNotification.value = `PDF export failed: ${err.message}`;
  } finally {
    exportLoading.value = false;
  }
};
</script>

<template>
  <div class="space-y-6">
    <!-- Top Header Card -->
    <div class="bg-gradient-to-r from-slate-900 via-blue-950 to-slate-900 rounded-2xl p-6 text-white shadow-xl border border-slate-800">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div class="flex items-center gap-2 mb-1">
            <span class="px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-blue-500/20 text-blue-300 border border-blue-400/30">
              Admin Executive Suite
            </span>
            <span class="text-xs text-slate-400">
              Active League Week: <strong class="text-white">Week {{ currentWeekNumber }} of {{ totalWeeks }}</strong>
            </span>
          </div>
          <h2 class="text-2xl font-black tracking-tight text-white flex items-center gap-2">
            <span>Player Quota & Season Analytics</span>
          </h2>
          <p class="text-xs sm:text-sm text-slate-300 mt-1 max-w-2xl">
            Live player-by-player audit comparing singles vs. doubles splits, contracted quota delivery pace, sub turnover, and bilateral karma favor ledgers.
          </p>
        </div>

        <!-- Export Actions Toolbar -->
        <div class="flex flex-wrap items-center gap-2">
          <button
            type="button"
            @click="loadData"
            :disabled="loading"
            class="px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold rounded-xl border border-slate-700 transition flex items-center gap-1.5 shadow-sm disabled:opacity-50"
            title="Refresh database records"
          >
            <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': loading }" />
            <span>Refresh</span>
          </button>

          <button
            type="button"
            @click="handleExportCSV"
            :disabled="loading || filteredMetrics.length === 0"
            class="px-3.5 py-2 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold rounded-xl shadow-md transition flex items-center gap-1.5 disabled:opacity-50"
          >
            <FileSpreadsheet class="w-4 h-4" />
            <span>Export CSV</span>
          </button>

          <button
            type="button"
            @click="handleExportPDF"
            :disabled="loading || exportLoading || filteredMetrics.length === 0"
            class="px-3.5 py-2 bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold rounded-xl shadow-md transition flex items-center gap-1.5 disabled:opacity-50"
          >
            <FileText class="w-4 h-4" />
            <span>Export PDF</span>
          </button>
        </div>
      </div>

      <!-- Export Notification Banner -->
      <div
        v-if="exportNotification"
        class="mt-4 px-3 py-2 bg-blue-500/20 border border-blue-400/30 rounded-lg text-xs text-blue-200 flex items-center gap-2"
      >
        <Info class="w-4 h-4 text-blue-300 flex-shrink-0" />
        <span>{{ exportNotification }}</span>
      </div>
    </div>

    <!-- KPI Summary Row -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <!-- KPI 1: Delivery Pace -->
      <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <div class="flex items-center justify-between text-slate-500 text-xs font-semibold">
          <span>Quota Delivery Health</span>
          <CheckCircle2 class="w-4 h-4 text-emerald-500" />
        </div>
        <div class="mt-2 flex items-baseline gap-2">
          <span class="text-2xl font-black text-slate-900">{{ summaryStats.deliveryPacePct }}%</span>
          <span class="text-xs font-medium text-emerald-600">On Track / Ahead</span>
        </div>
        <div class="text-[11px] text-slate-400 mt-1">
          {{ summaryStats.onTrackCount }} on track, {{ summaryStats.aheadCount }} ahead of quota
        </div>
      </div>

      <!-- KPI 2: Deficit Alerts -->
      <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm" :class="{ 'border-rose-300 bg-rose-50/20': summaryStats.behindCount > 0 }">
        <div class="flex items-center justify-between text-slate-500 text-xs font-semibold">
          <span>Quota Deficit Alert</span>
          <AlertTriangle class="w-4 h-4" :class="summaryStats.behindCount > 0 ? 'text-rose-600' : 'text-slate-400'" />
        </div>
        <div class="mt-2 flex items-baseline gap-2">
          <span class="text-2xl font-black" :class="summaryStats.behindCount > 0 ? 'text-rose-700' : 'text-slate-900'">
            {{ summaryStats.behindCount }}
          </span>
          <span class="text-xs font-medium text-slate-500">In Deficit</span>
        </div>
        <div class="text-[11px] text-slate-400 mt-1">
          Projected to finish below contracted share
        </div>
      </div>

      <!-- KPI 3: Sub Turnover -->
      <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <div class="flex items-center justify-between text-slate-500 text-xs font-semibold">
          <span>Total Substitutions</span>
          <RefreshCw class="w-4 h-4 text-amber-500" />
        </div>
        <div class="mt-2 flex items-baseline gap-2">
          <span class="text-2xl font-black text-slate-900">{{ summaryStats.totalSubTurnover }}</span>
          <span class="text-xs font-medium text-amber-600">Matches Swapped</span>
        </div>
        <div class="text-[11px] text-slate-400 mt-1">
          Sub exchange activity across season
        </div>
      </div>

      <!-- KPI 4: Pending Karma Favors -->
      <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <div class="flex items-center justify-between text-slate-500 text-xs font-semibold">
          <span>Pending Karma Favors</span>
          <Star class="w-4 h-4 text-amber-500" />
        </div>
        <div class="mt-2 flex items-baseline gap-2">
          <span class="text-2xl font-black text-amber-600">{{ summaryStats.pendingKarmaFavors }}</span>
          <span class="text-xs font-medium text-slate-500">Requests Owed</span>
        </div>
        <div class="text-[11px] text-slate-400 mt-1">
          Sub requests where applicant returned favor
        </div>
      </div>
    </div>

    <!-- Filter & Search Controls Bar -->
    <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm space-y-3">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <!-- Search Input -->
        <div class="relative flex-1 max-w-md">
          <Search class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search by player name or email..."
            class="w-full pl-9 pr-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
          />
        </div>

        <div class="text-xs font-semibold text-slate-500">
          Showing <span class="font-bold text-slate-800">{{ filteredMetrics.length }}</span> of {{ calculatedMetrics.length }} players
        </div>
      </div>

      <!-- Quick Filter Pills -->
      <div class="flex flex-wrap items-center gap-1.5 pt-1">
        <button
          type="button"
          @click="selectedFilter = 'all'"
          :class="selectedFilter === 'all' ? 'bg-slate-900 text-white shadow-sm' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'"
          class="px-3 py-1.5 rounded-lg text-xs font-semibold transition"
        >
          All Players ({{ calculatedMetrics.length }})
        </button>

        <button
          type="button"
          @click="selectedFilter = 'behind'"
          :class="selectedFilter === 'behind' ? 'bg-rose-600 text-white shadow-sm' : 'bg-rose-50 text-rose-700 hover:bg-rose-100 border border-rose-200'"
          class="px-3 py-1.5 rounded-lg text-xs font-semibold transition flex items-center gap-1"
        >
          <AlertTriangle class="w-3 h-3" />
          <span>In Deficit ({{ summaryStats.behindCount }})</span>
        </button>

        <button
          type="button"
          @click="selectedFilter = 'owed'"
          :class="selectedFilter === 'owed' ? 'bg-amber-600 text-white shadow-sm' : 'bg-amber-50 text-amber-800 hover:bg-amber-100 border border-amber-200'"
          class="px-3 py-1.5 rounded-lg text-xs font-semibold transition flex items-center gap-1"
        >
          <Star class="w-3 h-3 text-amber-500 fill-amber-500" />
          <span>Has Owed Favors</span>
        </button>

        <button
          type="button"
          @click="selectedFilter = 'high_turnover'"
          :class="selectedFilter === 'high_turnover' ? 'bg-indigo-600 text-white shadow-sm' : 'bg-indigo-50 text-indigo-700 hover:bg-indigo-100 border border-indigo-200'"
          class="px-3 py-1.5 rounded-lg text-xs font-semibold transition"
        >
          High Turnover (&gt;25% Subbed Out)
        </button>

        <button
          type="button"
          @click="selectedFilter = 'singles'"
          :class="selectedFilter === 'singles' ? 'bg-blue-600 text-white shadow-sm' : 'bg-blue-50 text-blue-700 hover:bg-blue-100 border border-blue-200'"
          class="px-3 py-1.5 rounded-lg text-xs font-semibold transition"
        >
          Singles Players
        </button>

        <button
          type="button"
          @click="selectedFilter = 'doubles'"
          :class="selectedFilter === 'doubles' ? 'bg-emerald-600 text-white shadow-sm' : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200'"
          class="px-3 py-1.5 rounded-lg text-xs font-semibold transition"
        >
          Doubles Players
        </button>

        <button
          type="button"
          @click="selectedFilter = 'waitlist'"
          :class="selectedFilter === 'waitlist' ? 'bg-slate-700 text-white shadow-sm' : 'bg-slate-100 text-slate-700 hover:bg-slate-200 border border-slate-200'"
          class="px-3 py-1.5 rounded-lg text-xs font-semibold transition"
        >
          Sub Pool / Waitlist ({{ summaryStats.subPoolCount }})
        </button>
      </div>
    </div>

    <!-- Main Player Metrics Table -->
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-200 text-[11px] font-black uppercase tracking-wider text-slate-500">
              <th scope="col" class="py-3 px-4 cursor-pointer hover:bg-slate-100 transition" @click="handleSort('full_name')">
                <div class="flex items-center gap-1.5">
                  <span>Player</span>
                  <ArrowUpDown class="w-3 h-3 text-slate-400" />
                </div>
              </th>
              <th scope="col" class="py-3 px-3 cursor-pointer hover:bg-slate-100 transition text-center" @click="handleSort('total_share')">
                <div class="flex items-center justify-center gap-1.5">
                  <span>Contract</span>
                  <ArrowUpDown class="w-3 h-3 text-slate-400" />
                </div>
              </th>
              <th scope="col" class="py-3 px-3 cursor-pointer hover:bg-slate-100 transition" @click="handleSort('scheduled_singles')">
                <div class="flex items-center gap-1.5">
                  <span>Singles (Act/Tgt)</span>
                  <ArrowUpDown class="w-3 h-3 text-slate-400" />
                </div>
              </th>
              <th scope="col" class="py-3 px-3 cursor-pointer hover:bg-slate-100 transition" @click="handleSort('scheduled_doubles')">
                <div class="flex items-center gap-1.5">
                  <span>Doubles (Act/Tgt)</span>
                  <ArrowUpDown class="w-3 h-3 text-slate-400" />
                </div>
              </th>
              <th scope="col" class="py-3 px-3 cursor-pointer hover:bg-slate-100 transition text-center" @click="handleSort('projected_variance')">
                <div class="flex items-center justify-center gap-1.5">
                  <span>Season Quota Pace</span>
                  <ArrowUpDown class="w-3 h-3 text-slate-400" />
                </div>
              </th>
              <th scope="col" class="py-3 px-3 cursor-pointer hover:bg-slate-100 transition text-center" @click="handleSort('projected_total')">
                <div class="flex items-center justify-center gap-1.5">
                  <span>Proj. Total</span>
                  <ArrowUpDown class="w-3 h-3 text-slate-400" />
                </div>
              </th>
              <th scope="col" class="py-3 px-3 cursor-pointer hover:bg-slate-100 transition text-center" @click="handleSort('times_subbed_out')">
                <div class="flex items-center justify-center gap-1.5">
                  <span>Subs (Out/In)</span>
                  <ArrowUpDown class="w-3 h-3 text-slate-400" />
                </div>
              </th>
              <th scope="col" class="py-3 px-3 cursor-pointer hover:bg-slate-100 transition text-center" @click="handleSort('net_karma_balance')">
                <div class="flex items-center justify-center gap-1.5">
                  <span>Karma Ledger</span>
                  <ArrowUpDown class="w-3 h-3 text-slate-400" />
                </div>
              </th>
              <th scope="col" class="py-3 px-3 text-center">
                <span>Idle Streak</span>
              </th>
              <th scope="col" class="py-3 px-3 text-right">
                <span class="sr-only">Actions</span>
              </th>
            </tr>
          </thead>

          <tbody class="divide-y divide-slate-100 text-xs">
            <template v-for="player in filteredMetrics" :key="player.id">
              <!-- Summary Row -->
              <tr
                class="hover:bg-blue-50/40 transition cursor-pointer"
                :class="{ 'bg-blue-50/70': expandedPlayerId === player.id }"
                @click="toggleExpand(player.id)"
              >
                <!-- Player Name & Email -->
                <td class="py-3 px-4">
                  <div class="flex items-center gap-2.5">
                    <div class="w-8 h-8 rounded-full bg-slate-800 text-white font-bold flex items-center justify-center text-xs flex-shrink-0">
                      {{ player.full_name.charAt(0).toUpperCase() }}
                    </div>
                    <div class="min-w-0">
                      <div class="font-bold text-slate-900 flex items-center gap-1.5 truncate">
                        <span class="truncate">{{ player.full_name }}</span>
                        <ShieldCheck v-if="player.is_admin" class="w-3.5 h-3.5 text-amber-600 flex-shrink-0" title="Administrator" />
                        <span v-if="!player.approved" class="px-1.5 py-0.2 text-[9px] font-bold bg-amber-100 text-amber-800 rounded">Waitlist</span>
                      </div>
                      <div class="text-[11px] text-slate-400 truncate">{{ player.email }}</div>
                    </div>
                  </div>
                </td>

                <!-- Contract Share -->
                <td class="py-3 px-3 text-center">
                  <span class="font-bold text-slate-700 bg-slate-100 px-2 py-0.5 rounded-md text-[11px]">
                    {{ player.singles_share }}S / {{ player.doubles_share }}D
                  </span>
                  <div class="text-[10px] text-slate-400 mt-0.5">
                    {{ player.target_total }} matches
                  </div>
                </td>

                <!-- Singles Scheduled / Target -->
                <td class="py-3 px-3">
                  <div class="flex items-center justify-between text-xs font-semibold mb-1">
                    <span class="text-blue-800">{{ player.scheduled_singles }}</span>
                    <span class="text-slate-400 text-[10px]">/ {{ player.target_singles }}</span>
                  </div>
                  <div class="w-20 bg-slate-100 rounded-full h-1.5 overflow-hidden">
                    <div
                      class="bg-blue-600 h-1.5 rounded-full"
                      :style="{ width: `${player.target_singles > 0 ? Math.min(100, Math.round((player.scheduled_singles / player.target_singles) * 100)) : 0}%` }"
                    ></div>
                  </div>
                </td>

                <!-- Doubles Scheduled / Target -->
                <td class="py-3 px-3">
                  <div class="flex items-center justify-between text-xs font-semibold mb-1">
                    <span class="text-emerald-800">{{ player.scheduled_doubles }}</span>
                    <span class="text-slate-400 text-[10px]">/ {{ player.target_doubles }}</span>
                  </div>
                  <div class="w-20 bg-slate-100 rounded-full h-1.5 overflow-hidden">
                    <div
                      class="bg-emerald-600 h-1.5 rounded-full"
                      :style="{ width: `${player.target_doubles > 0 ? Math.min(100, Math.round((player.scheduled_doubles / player.target_doubles) * 100)) : 0}%` }"
                    ></div>
                  </div>
                </td>

                <!-- Season Quota Status Badge -->
                <td class="py-3 px-3 text-center">
                  <div v-if="player.pace_status === 'behind'" class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-rose-100 text-rose-800 border border-rose-200">
                    <TrendingDown class="w-3 h-3 text-rose-600" />
                    <span>{{ player.projected_variance }} Deficit</span>
                  </div>
                  <div v-else-if="player.pace_status === 'ahead'" class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-purple-100 text-purple-800 border border-purple-200">
                    <TrendingUp class="w-3 h-3 text-purple-600" />
                    <span>+{{ player.projected_variance }} Surplus</span>
                  </div>
                  <div v-else-if="player.pace_status === 'sub_pool'" class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-slate-100 text-slate-700">
                    <span>Sub Pool</span>
                  </div>
                  <div v-else class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800 border border-emerald-200">
                    <Check class="w-3 h-3 text-emerald-600" />
                    <span>On Track</span>
                  </div>
                  <div class="text-[10px] text-slate-400 mt-0.5">
                    {{ player.played_total_to_date }} played • {{ Math.max(0, player.scheduled_total - player.played_total_to_date) }} upcoming
                  </div>
                </td>

                <!-- Projected Total & Variance -->
                <td class="py-3 px-3 text-center">
                  <span class="font-bold text-slate-900 text-xs">{{ player.projected_total }}</span>
                  <span
                    v-if="player.target_total > 0"
                    class="text-[10px] ml-1 font-semibold"
                    :class="player.projected_variance >= 0 ? 'text-emerald-600' : 'text-rose-600'"
                  >
                    ({{ player.projected_variance > 0 ? '+' : '' }}{{ player.projected_variance }})
                  </span>
                </td>

                <!-- Subs Out / In -->
                <td class="py-3 px-3 text-center">
                  <div class="flex items-center justify-center gap-1.5 font-semibold">
                    <span class="text-amber-700 bg-amber-50 px-1.5 py-0.5 rounded border border-amber-200" title="Subbed Out (Given away)">
                      {{ player.times_subbed_out }} out
                    </span>
                    <span class="text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-200" title="Subbed In (Played for others)">
                      {{ player.times_subbed_in }} in
                    </span>
                  </div>
                  <div class="text-[10px] text-slate-400 mt-0.5">
                    Net: <strong :class="player.net_sub_impact >= 0 ? 'text-emerald-600' : 'text-rose-600'">{{ player.net_sub_impact > 0 ? '+' : '' }}{{ player.net_sub_impact }}</strong>
                  </div>
                </td>

                <!-- Karma Ledger & Owed Sub Requests -->
                <td class="py-3 px-3 text-center">
                  <div v-if="player.pending_owed_requests_count > 0" class="mb-1">
                    <span class="px-2 py-0.5 rounded-full text-[10px] font-black bg-amber-400 text-slate-950 inline-flex items-center gap-1 shadow-sm animate-pulse">
                      <Star class="w-3 h-3 fill-slate-950" />
                      <span>{{ player.pending_owed_requests_count }} Owed Pending</span>
                    </span>
                  </div>
                  <div>
                    <span
                      class="text-[11px] font-bold px-2 py-0.5 rounded-md"
                      :class="player.net_karma_balance > 0 ? 'bg-amber-100 text-amber-900 border border-amber-300' : player.net_karma_balance < 0 ? 'bg-slate-100 text-slate-600' : 'text-slate-400'"
                    >
                      {{ player.net_karma_balance > 0 ? `+${player.net_karma_balance} Favors Owed` : player.net_karma_balance < 0 ? `${player.net_karma_balance} Favors Due` : 'Even (0)' }}
                    </span>
                  </div>
                </td>

                <!-- Idle Streak -->
                <td class="py-3 px-3 text-center text-slate-600">
                  <span :class="{ 'font-bold text-amber-700': player.max_inactivity_streak >= 3 }">
                    {{ player.max_inactivity_streak }} wks
                  </span>
                  <div v-if="player.last_match_date" class="text-[10px] text-slate-400">
                    Last: Wk {{ player.last_match_week }}
                  </div>
                </td>

                <!-- Toggle Chevron -->
                <td class="py-3 px-3 text-right">
                  <button
                    type="button"
                    class="p-1 rounded-lg hover:bg-slate-200 text-slate-400 hover:text-slate-700 transition"
                  >
                    <ChevronUp v-if="expandedPlayerId === player.id" class="w-4 h-4 text-blue-600" />
                    <ChevronDown v-else class="w-4 h-4" />
                  </button>
                </td>
              </tr>

              <!-- Expanded Detail Drawer Row -->
              <tr v-if="expandedPlayerId === player.id" class="bg-slate-50/80 border-b border-slate-200">
                <td colspan="10" class="p-4 sm:p-6">
                  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <!-- Column 1: Match Calendar & Timeline -->
                    <div class="space-y-3 bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                      <div class="flex items-center justify-between border-b border-slate-100 pb-2">
                        <h4 class="font-bold text-xs uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
                          <Calendar class="w-3.5 h-3.5 text-blue-600" />
                          <span>Active Scheduled Matches</span>
                        </h4>
                        <span class="text-[10px] font-bold text-slate-500">
                          {{ getPlayerMatches(player.id).length }} Matches
                        </span>
                      </div>

                      <div class="max-h-60 overflow-y-auto space-y-1.5 pr-1 divide-y divide-slate-50 text-xs">
                        <div
                          v-for="m in getPlayerMatches(player.id)"
                          :key="m.slot_id"
                          class="pt-1.5 flex items-center justify-between text-xs"
                        >
                          <div class="flex items-center gap-2">
                            <span class="font-bold text-slate-700">Wk {{ m.week_number }}</span>
                            <span class="text-slate-400 text-[11px]">{{ formatDayOfWeek(m.day_of_week) }} • {{ m.match_date }}</span>
                          </div>
                          <div class="flex items-center gap-1.5">
                            <span
                              class="text-[9px] font-bold px-1.5 py-0.2 rounded"
                              :class="m.type === 'SINGLES' ? 'bg-blue-100 text-blue-800' : 'bg-emerald-100 text-emerald-800'"
                            >
                              {{ m.type }}
                            </span>
                            <span class="text-[10px] text-slate-500 font-semibold">Ct #{{ m.court_number }}</span>
                            <span
                              v-if="m.match_date <= todayStr"
                              class="text-[9px] font-bold text-emerald-700 bg-emerald-50 px-1 py-0.2 rounded"
                            >
                              Completed
                            </span>
                            <span
                              v-else
                              class="text-[9px] font-bold text-slate-500 bg-slate-100 px-1 py-0.2 rounded"
                            >
                              Upcoming
                            </span>
                          </div>
                        </div>

                        <div v-if="getPlayerMatches(player.id).length === 0" class="py-4 text-center text-xs text-slate-400 italic">
                          No active confirmed matches assigned.
                        </div>
                      </div>
                    </div>

                    <!-- Column 2: Sub Exchanges & Bilateral Karma -->
                    <div class="space-y-4">
                      <!-- Card A: Sub Turnover & Exchanges Log -->
                      <div class="space-y-3 bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                        <div class="flex items-center justify-between border-b border-slate-100 pb-2">
                          <h4 class="font-bold text-xs uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
                            <ArrowRightLeft class="w-3.5 h-3.5 text-amber-600" />
                            <span>Sub Exchange Log</span>
                          </h4>
                          <div class="flex items-center gap-1 text-[10px] font-bold">
                            <span class="text-amber-700 bg-amber-50 px-1.5 py-0.2 rounded border border-amber-200">
                              {{ getPlayerSubOuts(player.id).length }} Out
                            </span>
                            <span class="text-emerald-700 bg-emerald-50 px-1.5 py-0.2 rounded border border-emerald-200">
                              {{ getPlayerSubIns(player.id).length }} In
                            </span>
                          </div>
                        </div>

                        <div class="max-h-52 overflow-y-auto space-y-2 pr-1 divide-y divide-slate-50 text-xs">
                          <!-- Subbed Out items -->
                          <div
                            v-for="sOut in getPlayerSubOuts(player.id)"
                            :key="sOut.slot_id"
                            class="pt-1.5 flex items-start justify-between gap-2"
                          >
                            <div class="min-w-0">
                              <div class="font-semibold text-slate-800 flex items-center gap-1.5 flex-wrap">
                                <span class="text-amber-700 font-bold">Wk {{ sOut.week_number }}</span>
                                <span class="text-slate-500 text-[11px]">{{ formatDayOfWeek(sOut.day_of_week) }} • {{ sOut.match_date }}</span>
                                <span class="text-[9px] px-1 py-0.2 font-bold bg-slate-100 rounded text-slate-600">
                                  {{ sOut.type }} (Ct #{{ sOut.court_number }})
                                </span>
                              </div>
                              <div class="text-[11px] text-slate-500 mt-0.5">
                                <template v-if="sOut.status === 'OPEN_SUB'">
                                  <span class="text-amber-600 font-bold">⏳ Unclaimed</span> — listed on Sub Board
                                </template>
                                <template v-else>
                                  Claimed by: <strong class="text-slate-800">{{ sOut.subPlayerName }}</strong>
                                </template>
                              </div>
                            </div>
                            <span
                              class="text-[9px] font-bold px-1.5 py-0.5 rounded flex-shrink-0"
                              :class="sOut.status === 'OPEN_SUB' ? 'bg-amber-100 text-amber-900 border border-amber-300' : 'bg-orange-50 text-orange-800 border border-orange-200'"
                            >
                              {{ sOut.status === 'OPEN_SUB' ? 'Open Sub' : 'Subbed Out' }}
                            </span>
                          </div>

                          <!-- Subbed In items -->
                          <div
                            v-for="sIn in getPlayerSubIns(player.id)"
                            :key="sIn.slot_id"
                            class="pt-1.5 flex items-start justify-between gap-2"
                          >
                            <div class="min-w-0">
                              <div class="font-semibold text-slate-800 flex items-center gap-1.5 flex-wrap">
                                <span class="text-emerald-700 font-bold">Wk {{ sIn.week_number }}</span>
                                <span class="text-slate-500 text-[11px]">{{ formatDayOfWeek(sIn.day_of_week) }} • {{ sIn.match_date }}</span>
                                <span class="text-[9px] px-1 py-0.2 font-bold bg-slate-100 rounded text-slate-600">
                                  {{ sIn.type }} (Ct #{{ sIn.court_number }})
                                </span>
                              </div>
                              <div class="text-[11px] text-slate-500 mt-0.5">
                                Filled in for: <strong class="text-slate-800">{{ sIn.origPlayerName }}</strong>
                              </div>
                            </div>
                            <span class="text-[9px] font-bold px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-800 border border-emerald-200 flex-shrink-0">
                              Subbed In
                            </span>
                          </div>

                          <!-- Empty state -->
                          <div
                            v-if="getPlayerSubOuts(player.id).length === 0 && getPlayerSubIns(player.id).length === 0"
                            class="py-3 text-center text-slate-400 italic text-[11px]"
                          >
                            No sub activity. Playing originally drafted schedule.
                          </div>
                        </div>
                      </div>

                      <!-- Card B: Bilateral Karma Favors -->
                      <div class="space-y-3 bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                        <div class="flex items-center justify-between border-b border-slate-100 pb-2">
                          <h4 class="font-bold text-xs uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
                            <Star class="w-3.5 h-3.5 text-amber-500" />
                            <span>Bilateral Sub Karma Ledger</span>
                          </h4>
                          <span class="text-[10px] font-semibold text-slate-500">
                            Net: {{ player.net_karma_balance > 0 ? `+${player.net_karma_balance}` : player.net_karma_balance }}
                          </span>
                        </div>

                        <div class="max-h-36 overflow-y-auto space-y-1.5 pr-1 divide-y divide-slate-50 text-xs">
                          <div
                            v-for="k in getPlayerKarmaDetails(player.id)"
                            :key="k.partnerId"
                            class="pt-1.5 flex items-center justify-between"
                          >
                            <div>
                              <div class="font-semibold text-slate-800">{{ k.partnerName }}</div>
                              <div class="text-[10px] text-slate-400">
                                Subbed for them: {{ k.iSubbedForThem }}x • They subbed for me: {{ k.theySubbedForMe }}x
                              </div>
                            </div>
                            <div>
                              <span
                                v-if="k.balance > 0"
                                class="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-100 text-amber-900 border border-amber-300"
                              >
                                Owes me {{ k.balance }} match{{ k.balance > 1 ? 'es' : '' }}
                              </span>
                              <span
                                v-else-if="k.balance < 0"
                                class="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-700"
                              >
                                I owe {{ Math.abs(k.balance) }} match{{ Math.abs(k.balance) > 1 ? 'es' : '' }}
                              </span>
                              <span
                                v-else
                                class="px-1.5 py-0.2 rounded text-[10px] text-slate-400 font-medium"
                              >
                                Even
                              </span>
                            </div>
                          </div>

                          <div v-if="getPlayerKarmaDetails(player.id).length === 0" class="py-2 text-center text-xs text-slate-400 italic">
                            No bilateral sub history yet.
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Column 3: Blackouts & Community Equity -->
                    <div class="space-y-3 bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                      <div class="border-b border-slate-100 pb-2">
                        <h4 class="font-bold text-xs uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
                          <Users class="w-3.5 h-3.5 text-indigo-600" />
                          <span>Opponent Variety & Blackout Constraints</span>
                        </h4>
                      </div>

                      <div class="space-y-3 text-xs">
                        <!-- Opponents Encountered -->
                        <div class="flex items-center justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-100">
                          <div>
                            <div class="font-bold text-slate-800">Unique Opponents Faced</div>
                            <div class="text-[10px] text-slate-400">Diverse match pairings</div>
                          </div>
                          <span class="text-base font-black text-indigo-600">
                            {{ player.unique_opponents_count }} players
                          </span>
                        </div>

                        <!-- Blackout Weeks -->
                        <div class="p-2.5 rounded-lg bg-slate-50 border border-slate-100 space-y-1">
                          <div class="flex items-center justify-between">
                            <span class="font-bold text-slate-800">Blackout Weeks ({{ player.blackout_weeks_count }})</span>
                            <span class="text-[10px] text-slate-500 font-semibold">
                              {{ Math.round((player.blackout_weeks_count / totalWeeks) * 100) }}% Season Off
                            </span>
                          </div>
                          <div v-if="player.blackout_weeks_count > 0" class="flex flex-wrap gap-1 mt-1">
                            <span
                              v-for="wk in (players.find(p => p.id === player.id)?.blackout_weeks || [])"
                              :key="wk"
                              class="px-1.5 py-0.2 bg-slate-200 text-slate-700 rounded text-[10px] font-semibold"
                            >
                              W{{ wk }}
                            </span>
                          </div>
                          <div v-else class="text-[11px] text-slate-400 italic">
                            No blackout weeks registered. Full 24-week availability.
                          </div>
                        </div>

                        <!-- Blackout Days of Week -->
                        <div class="p-2.5 rounded-lg bg-slate-50 border border-slate-100 space-y-1">
                          <span class="font-bold text-slate-800">Blackout Days</span>
                          <div v-if="(players.find(p => p.id === player.id)?.blackout_days || []).length > 0" class="flex flex-wrap gap-1 mt-1">
                            <span
                              v-for="day in (players.find(p => p.id === player.id)?.blackout_days || [])"
                              :key="day"
                              class="px-1.5 py-0.2 bg-rose-100 text-rose-800 rounded text-[10px] font-semibold"
                            >
                              {{ formatDayOfWeek(day) }}s
                            </span>
                          </div>
                          <div v-else class="text-[11px] text-slate-400 italic">
                            Available all league days of week.
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </td>
              </tr>
            </template>

            <!-- Empty State -->
            <tr v-if="filteredMetrics.length === 0">
              <td colspan="10" class="py-12 text-center text-slate-400 text-xs">
                No players match your search and filter criteria.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
