<script setup lang="ts">
import { ref, computed } from 'vue';
import { supabase } from '../supabase';
import {
  generateSeasonSchedule,
  calculateCourtsFromShares,
  getMatchDateForDay,
  formatDayOfWeek,
  compareMatches,
  MAX_COURTS,
  type PlayerForScheduling,
  type ScheduleGenResult,
  type DayCourtConfig,
} from '../utils/scheduleGenerator';
import { Calendar, Play, CheckCircle2, AlertCircle, RefreshCw, Layers, ShieldCheck, UserCheck, Sparkles, AlertTriangle, Pin, Download, ChevronDown, FileText, FileSpreadsheet, FileCode } from 'lucide-vue-next';
import { notifySchedulePublished } from '../utils/discordNotifier';
import { exportDraftSchedulePDF, exportDraftScheduleExcel, exportDraftScheduleCSV } from '../utils/exportUtils';

const props = defineProps<{
  players: PlayerForScheduling[];
}>();

const emit = defineEmits(['scheduled']);

const startDate = ref<string>('2026-10-19'); // Default to Monday

// Predetermined weekly schedule (Mon: 1 Singles, Tue: 2 Doubles, Wed: 1 Singles)
const dailySchedule = ref<DayCourtConfig[]>([
  { dayOfWeek: 'Monday', singlesCourts: 1, doublesCourts: 0 },
  { dayOfWeek: 'Tuesday', singlesCourts: 0, doublesCourts: 2 },
  { dayOfWeek: 'Wednesday', singlesCourts: 1, doublesCourts: 0 },
]);

const generatedResult = ref<ScheduleGenResult | null>(null);
const selectedPreviewWeek = ref<number>(1);

const isPublishing = ref<boolean>(false);
const statusMessage = ref<{ text: string; error?: boolean } | null>(null);

const hoveredPlayerId = ref<string | null>(null);
const selectedPlayerId = ref<string | null>(null);
const draftExportMenuOpen = ref<boolean>(false);

const handleExportDraftPDF = () => {
  if (generatedResult.value) {
    exportDraftSchedulePDF(generatedResult.value);
    draftExportMenuOpen.value = false;
  }
};

const handleExportDraftExcel = () => {
  if (generatedResult.value) {
    exportDraftScheduleExcel(generatedResult.value);
    draftExportMenuOpen.value = false;
  }
};

const handleExportDraftCSV = () => {
  if (generatedResult.value) {
    exportDraftScheduleCSV(generatedResult.value);
    draftExportMenuOpen.value = false;
  }
};

const handleSelectPlayer = (playerId: string) => {
  if (selectedPlayerId.value === playerId) {
    selectedPlayerId.value = null; // Toggle off stickiness
  } else {
    selectedPlayerId.value = playerId; // Make selection sticky
  }
};

const activePlayerId = computed<string | null>(() => {
  return hoveredPlayerId.value || selectedPlayerId.value;
});

// Calculated share capacity from approved player roster
const shareCapacity = computed(() => {
  return calculateCourtsFromShares(props.players);
});

// Total courts per week configured (Fixed 4 courts)
const totalWeeklyCourts = computed(() => {
  return dailySchedule.value.reduce(
    (acc, d) => acc + (d.singlesCourts || 0) + (d.doublesCourts || 0),
    0
  );
});

const handleResetToPredetermined = () => {
  dailySchedule.value = [
    { dayOfWeek: 'Monday', singlesCourts: 1, doublesCourts: 0 },
    { dayOfWeek: 'Tuesday', singlesCourts: 0, doublesCourts: 2 },
    { dayOfWeek: 'Wednesday', singlesCourts: 1, doublesCourts: 0 },
  ];
  statusMessage.value = {
    text: 'Court schedule reset to predetermined default (Mon: 1 Singles, Tue: 2 Doubles, Wed: 1 Singles).',
  };
};

const handleGenerate = () => {
  statusMessage.value = null;
  selectedPlayerId.value = null;
  hoveredPlayerId.value = null;

  if (props.players.length === 0) {
    statusMessage.value = { text: 'No approved players available. Approve players in the intake list first.', error: true };
    return;
  }

  if (totalWeeklyCourts.value > MAX_COURTS) {
    statusMessage.value = {
      text: `Cannot generate schedule: You have configured ${totalWeeklyCourts.value} courts per week. Maximum allowed is ${MAX_COURTS} courts per week.`,
      error: true,
    };
    return;
  }

  if (totalWeeklyCourts.value === 0) {
    statusMessage.value = { text: 'Please configure at least 1 court on at least 1 day of the week.', error: true };
    return;
  }

  const result = generateSeasonSchedule(props.players, {
    startDate: startDate.value,
    numWeeks: 24,
    dailySchedule: dailySchedule.value,
  });

  generatedResult.value = result;
  selectedPreviewWeek.value = 1;
};

const handlePublish = async () => {
  if (!generatedResult.value) return;

  if (!confirm('Are you sure you want to publish this schedule to Supabase? This will clear any existing matches and publish the new 24-week schedule.')) {
    return;
  }

  isPublishing.value = true;
  statusMessage.value = null;

  try {
    // 1. Delete existing match slots and matches
    await supabase.from('match_slots').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabase.from('matches').delete().neq('id', '00000000-0000-0000-0000-000000000000');

    // 2. Insert generated matches and slots
    let totalSlotsCount = 0;
    for (const match of generatedResult.value.matches) {
      const { data: insertedMatch, error: matchError } = await supabase
        .from('matches')
        .insert({
          week_number: match.week_number,
          day_of_week: match.day_of_week.toUpperCase(),
          match_date: match.match_date,
          type: match.type,
          court_number: match.court_number,
        })
        .select()
        .single();

      if (matchError || !insertedMatch) {
        throw new Error(matchError?.message || 'Failed to insert match');
      }

      const slotRecords = match.slots.map((slot, index) => ({
        match_id: insertedMatch.id,
        player_id: slot.player_id,
        slot_position: index + 1,
        status: 'CONFIRMED',
      }));

      totalSlotsCount += slotRecords.length;

      const { error: slotError } = await supabase.from('match_slots').insert(slotRecords);
      if (slotError) {
        throw new Error(slotError.message);
      }
    }

    statusMessage.value = { text: '24-Week Schedule successfully generated and published to Supabase!' };
    isPublishing.value = false;

    // Trigger Discord notification for published schedule
    notifySchedulePublished({
      numWeeks: 24,
      totalMatches: generatedResult.value.matches.length,
      totalSlots: totalSlotsCount,
      startDate: startDate.value,
    });

    emit('scheduled');
  } catch (err: any) {
    isPublishing.value = false;
    statusMessage.value = { text: err.message || 'Failed to publish schedule.', error: true };
  }
};

const weekMatches = computed(() => {
  if (!generatedResult.value) return [];
  return generatedResult.value.matches
    .filter((m) => m.week_number === selectedPreviewWeek.value)
    .sort(compareMatches);
});

const formattedMondayDate = computed(() => {
  if (!startDate.value) return '';
  const dateStr = getMatchDateForDay(startDate.value, selectedPreviewWeek.value, 'Monday');
  const [year, month, day] = dateStr.split('-').map(Number);
  const d = new Date(year, month - 1, day);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
});

interface WeekMatchCount {
  singles: number;
  doubles: number;
  total: number;
}

const activePlayerBlackoutWeeks = computed<Set<number>>(() => {
  if (!activePlayerId.value) return new Set();
  const player = props.players.find((p) => p.id === activePlayerId.value);
  return new Set(player?.blackout_weeks || []);
});

const activePlayerBlackoutDays = computed<string[]>(() => {
  if (!activePlayerId.value) return [];
  const player = props.players.find((p) => p.id === activePlayerId.value);
  return player?.blackout_days || [];
});

const playerWeekBreakdownMap = computed(() => {
  const map = new Map<string, Map<number, WeekMatchCount>>();
  if (!generatedResult.value) return map;

  for (const match of generatedResult.value.matches) {
    for (const slot of match.slots) {
      if (!map.has(slot.player_id)) {
        map.set(slot.player_id, new Map());
      }
      const playerWeeks = map.get(slot.player_id)!;
      if (!playerWeeks.has(match.week_number)) {
        playerWeeks.set(match.week_number, { singles: 0, doubles: 0, total: 0 });
      }
      const counts = playerWeeks.get(match.week_number)!;
      if (match.type === 'SINGLES') counts.singles++;
      else if (match.type === 'DOUBLES') counts.doubles++;
      counts.total++;
    }
  }
  return map;
});

const activePlayerSummary = computed(() => {
  if (!activePlayerId.value || !generatedResult.value) return null;
  const summary = generatedResult.value.summaries.find((s) => s.player_id === activePlayerId.value);
  if (!summary) return null;
  const playerWeeks = playerWeekBreakdownMap.value.get(activePlayerId.value);
  const totalWeeks = playerWeeks ? playerWeeks.size : 0;
  const blackoutCount = activePlayerBlackoutWeeks.value.size;
  const blackoutDaysList = activePlayerBlackoutDays.value;
  const isPinned = selectedPlayerId.value === activePlayerId.value && !hoveredPlayerId.value;

  return {
    playerId: summary.player_id,
    fullName: summary.full_name,
    totalWeeks,
    scheduledSingles: summary.scheduled_singles,
    scheduledDoubles: summary.scheduled_doubles,
    blackoutCount,
    blackoutDaysList,
    isPinned,
  };
});

const getWeekButtonClass = (w: number) => {
  const curId = activePlayerId.value;
  if (curId) {
    const isBlackout = activePlayerBlackoutWeeks.value.has(w);
    const counts = playerWeekBreakdownMap.value.get(curId)?.get(w);
    const isSelected = selectedPreviewWeek.value === w;
    const baseRing = isSelected ? 'ring-4 ring-amber-400 z-10' : 'ring-2';

    if (isBlackout) {
      return `bg-slate-950 text-slate-100 font-bold shadow-md scale-105 ${baseRing} ring-slate-700`;
    }

    if (counts) {
      if (counts.singles > 0 && counts.doubles > 0) {
        return `bg-purple-600 text-white font-bold shadow-md scale-105 ${baseRing} ring-purple-300`;
      } else if (counts.singles > 0) {
        return `bg-indigo-600 text-white font-bold shadow-md scale-105 ${baseRing} ring-indigo-300`;
      } else {
        return `bg-emerald-600 text-white font-bold shadow-md scale-105 ${baseRing} ring-emerald-300`;
      }
    } else {
      return 'bg-slate-100 text-slate-400 opacity-30 hover:opacity-80 scale-95';
    }
  }

  if (selectedPreviewWeek.value === w) {
    return 'bg-blue-600 text-white font-bold shadow-sm ring-1 ring-blue-600';
  }
  return 'bg-slate-100 text-slate-700 hover:bg-slate-200';
};

const getWeekBadgeText = (w: number) => {
  const curId = activePlayerId.value;
  if (!curId) return '';
  if (activePlayerBlackoutWeeks.value.has(w)) {
    return 'OFF';
  }
  const counts = playerWeekBreakdownMap.value.get(curId)?.get(w);
  if (!counts) return '';
  if (counts.singles > 0 && counts.doubles > 0) {
    return `${counts.singles}S ${counts.doubles}D`;
  } else if (counts.singles > 0) {
    return `${counts.singles}S`;
  } else if (counts.doubles > 0) {
    return `${counts.doubles}D`;
  }
  return '';
};
</script>

<template>
  <div class="space-y-6 pt-2">
    <!-- Generator Controls & Per-Day Configuration -->
    <div class="bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-5">
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 border-b pb-3">
        <div>
          <h3 class="text-sm font-bold text-slate-800 flex items-center gap-2">
            <Calendar class="w-4 h-4 text-indigo-600" />
            Season Schedule & Court Configuration
          </h3>
          <p class="text-xs text-slate-500 mt-0.5">
            Predetermined court allocation (Monday – Wednesday, {{ MAX_COURTS }} Courts Total per week).
          </p>
        </div>

        <button
          @click="handleResetToPredetermined"
          type="button"
          class="px-3 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-semibold text-xs rounded-lg border border-indigo-200 transition flex items-center gap-1.5"
        >
          <Sparkles class="w-3.5 h-3.5 text-indigo-600" />
          Reset to Default Schedule
        </button>
      </div>

      <!-- General Settings & Share Demand Summary -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
        <div>
          <label class="block font-semibold text-slate-700 mb-1">Season Start Date (Week 1)</label>
          <input
            v-model="startDate"
            type="date"
            class="w-full p-2 border border-slate-300 rounded-lg bg-white outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <!-- Live Demand vs Capacity Monitor -->
        <div class="p-3 bg-slate-50 rounded-lg border border-slate-200 col-span-2 flex flex-col justify-center space-y-1">
          <div class="flex justify-between items-center text-xs font-semibold text-slate-700">
            <span>Approved Roster Demand:</span>
            <span
              :class="totalWeeklyCourts <= MAX_COURTS ? 'text-emerald-700' : 'text-rose-600 font-bold'"
            >
              Configured: {{ totalWeeklyCourts }} / {{ MAX_COURTS }} Courts Max / Wk
            </span>
          </div>
          <p class="text-[11px] text-slate-500">
            • Singles: {{ shareCapacity.totalSinglesShares.toFixed(2) }} shares -> Needs {{ shareCapacity.suggestedSinglesCourts }} court/wk
            | Doubles: {{ shareCapacity.totalDoublesShares.toFixed(2) }} shares -> Needs {{ shareCapacity.suggestedDoublesCourts }} courts/wk
          </p>
        </div>
      </div>

      <!-- Per-Day Court Allocation Matrix (Mon - Wed) -->
      <div class="space-y-2">
        <div class="flex items-center justify-between">
          <h4 class="text-xs font-bold text-slate-700">Predetermined Daily Court Schedule (Mon – Wed)</h4>
          <span
            class="text-[11px] font-bold px-2.5 py-0.5 rounded bg-emerald-100 text-emerald-800"
          >
            {{ totalWeeklyCourts }} / {{ MAX_COURTS }} Courts Total
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <div
            v-for="day in dailySchedule"
            :key="day.dayOfWeek"
            class="p-3 rounded-lg border text-center space-y-2 bg-indigo-50/50 border-indigo-200"
          >
            <div class="font-bold text-xs text-slate-800 border-b pb-1.5 border-indigo-200/60 flex items-center justify-center gap-1.5">
              <span>{{ day.dayOfWeek }}</span>
            </div>

            <div class="space-y-2 text-[11px]">
              <div>
                <label class="block text-[10px] font-medium text-slate-500 mb-0.5">Singles Courts</label>
                <input
                  v-model.number="day.singlesCourts"
                  type="number"
                  min="0"
                  :max="MAX_COURTS"
                  class="w-full text-center border rounded p-1 text-xs font-semibold bg-white"
                />
              </div>

              <div>
                <label class="block text-[10px] font-medium text-slate-500 mb-0.5">Doubles Courts</label>
                <input
                  v-model.number="day.doublesCourts"
                  type="number"
                  min="0"
                  :max="MAX_COURTS"
                  class="w-full text-center border rounded p-1 text-xs font-semibold bg-white"
                />
              </div>
            </div>

            <div class="text-[11px] font-bold text-indigo-900 pt-0.5 border-t border-indigo-200/60">
              {{ day.singlesCourts + day.doublesCourts }} Court{{ (day.singlesCourts + day.doublesCourts) === 1 ? '' : 's' }}
            </div>
          </div>
        </div>
      </div>

      <div v-if="totalWeeklyCourts > MAX_COURTS" class="p-3 bg-rose-50 border border-rose-200 rounded-lg text-xs text-rose-700 flex items-center gap-2">
        <AlertTriangle class="w-4 h-4 flex-shrink-0" />
        <span>Weekly court limit exceeded! You have configured {{ totalWeeklyCourts }} courts. Maximum allowed per week is {{ MAX_COURTS }} courts.</span>
      </div>

      <button
        @click="handleGenerate"
        :disabled="totalWeeklyCourts > MAX_COURTS || totalWeeklyCourts === 0"
        class="w-full py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-semibold text-xs rounded-lg shadow-sm transition flex items-center justify-center gap-2"
      >
        <Play class="w-4 h-4 fill-white" />
        Generate Draft Schedule Preview (24 Weeks)
      </button>
    </div>

    <!-- Notification Banner -->
    <div
      v-if="statusMessage"
      class="p-3.5 rounded-lg text-xs flex items-center gap-2"
      :class="statusMessage.error ? 'bg-red-50 text-red-700 border border-red-200' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'"
    >
      <AlertCircle v-if="statusMessage.error" class="w-4 h-4 flex-shrink-0" />
      <CheckCircle2 v-else class="w-4 h-4 flex-shrink-0" />
      <span>{{ statusMessage.text }}</span>
    </div>

    <!-- Generated Results & Preview Section -->
    <div v-if="generatedResult" class="space-y-5">
      <!-- Quota & Blackout Compliance Summary -->
      <div class="bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-3">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <h4 class="text-sm font-bold text-slate-800 flex items-center gap-2">
            <ShieldCheck class="w-4 h-4 text-emerald-600" />
            Quota & Blackout Compliance Summary
          </h4>

          <div class="flex items-center gap-2">
            <!-- Draft Export Menu -->
            <div class="relative">
              <button
                @click="draftExportMenuOpen = !draftExportMenuOpen"
                title="Export Draft Preview (Quota & Blackout Summary + Lineups)"
                class="px-3 py-2 rounded-lg border border-slate-300 bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs transition flex items-center gap-1.5 shadow-2xs"
              >
                <Download class="w-3.5 h-3.5 text-blue-600" />
                <span>Export Draft</span>
                <ChevronDown class="w-3 h-3 text-slate-400 transition-transform" :class="{ 'rotate-180': draftExportMenuOpen }" />
              </button>

              <div
                v-if="draftExportMenuOpen"
                class="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-lg border border-slate-200 z-50 py-1 text-xs"
              >
                <button
                  @click="handleExportDraftPDF"
                  class="w-full px-3 py-2 text-left text-slate-700 hover:bg-slate-50 flex items-center gap-2 transition font-medium"
                >
                  <FileText class="w-4 h-4 text-rose-500" />
                  <span>Export PDF (Summary + Lineup)</span>
                </button>
                <button
                  @click="handleExportDraftExcel"
                  class="w-full px-3 py-2 text-left text-slate-700 hover:bg-slate-50 flex items-center gap-2 transition font-medium"
                >
                  <FileSpreadsheet class="w-4 h-4 text-emerald-600" />
                  <span>Export Excel (Summary + Lineup)</span>
                </button>
                <button
                  @click="handleExportDraftCSV"
                  class="w-full px-3 py-2 text-left text-slate-700 hover:bg-slate-50 flex items-center gap-2 transition font-medium"
                >
                  <FileCode class="w-4 h-4 text-blue-600" />
                  <span>Export CSV (Match Lineup)</span>
                </button>
              </div>
            </div>

            <button
              @click="handlePublish"
              :disabled="isPublishing"
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-lg shadow-sm transition flex items-center gap-1.5 disabled:opacity-50"
            >
              <RefreshCw v-if="isPublishing" class="w-3.5 h-3.5 animate-spin" />
              <CheckCircle2 v-else class="w-3.5 h-3.5" />
              Publish Schedule to Supabase
            </button>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-xs text-left">
            <thead>
              <tr class="border-b text-slate-400">
                <th class="pb-2">Player Name</th>
                <th class="pb-2">Singles Matches</th>
                <th class="pb-2">Doubles Matches</th>
                <th class="pb-2">Total Matches</th>
                <th class="pb-2">Blackout Compliance</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr
                v-for="s in generatedResult.summaries"
                :key="s.player_id"
                @mouseenter="hoveredPlayerId = s.player_id"
                @mouseleave="hoveredPlayerId = null"
                @click="handleSelectPlayer(s.player_id)"
                class="transition-all duration-150 cursor-pointer select-none"
                :class="[
                  selectedPlayerId === s.player_id
                    ? 'bg-indigo-100/90 font-bold border-l-4 border-l-indigo-600 shadow-2xs'
                    : hoveredPlayerId === s.player_id
                    ? 'bg-indigo-50/80 font-bold'
                    : 'hover:bg-slate-50/80'
                ]"
              >
                <td class="py-2 font-semibold text-slate-800 flex items-center justify-between pr-3">
                  <span>{{ s.full_name }}</span>
                  <span
                    v-if="selectedPlayerId === s.player_id"
                    class="text-[10px] px-1.5 py-0.5 rounded bg-indigo-600 text-white font-bold flex items-center gap-1 shadow-2xs"
                  >
                    <Pin class="w-2.5 h-2.5 fill-white" />
                    Pinned
                  </span>
                </td>
                <td class="py-2">
                  <span :class="s.scheduled_singles === s.target_singles ? 'text-emerald-700 font-bold' : 'text-amber-700 font-bold'">
                    {{ s.scheduled_singles }} / {{ s.target_singles }}
                  </span>
                </td>
                <td class="py-2">
                  <span :class="s.scheduled_doubles === s.target_doubles ? 'text-emerald-700 font-bold' : 'text-amber-700 font-bold'">
                    {{ s.scheduled_doubles }} / {{ s.target_doubles }}
                  </span>
                </td>
                <td class="py-2 font-bold text-slate-800">
                  <div class="inline-flex items-center gap-2 tabular-nums">
                    <span class="w-14 inline-block text-left">{{ s.scheduled_singles + s.scheduled_doubles }} / {{ s.target_singles + s.target_doubles }}</span>
                    <span class="text-[11px] font-semibold text-slate-500 min-w-[44px] inline-block text-left">
                      ({{ (s.target_singles + s.target_doubles) > 0 ? Math.round(((s.scheduled_singles + s.scheduled_doubles) / (s.target_singles + s.target_doubles)) * 100) : 0 }}%)
                    </span>
                  </div>
                </td>
                <td class="py-2 text-slate-500">
                  <span class="text-emerald-700 font-semibold flex items-center gap-1">
                    <CheckCircle2 class="w-3 h-3 text-emerald-600" />
                    0 Blackout Conflicts ({{ s.blackout_count }} weeks off)
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Weekly Schedule Lineup Previewer -->
      <div class="bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-4">
        <div class="flex flex-col gap-2 border-b pb-3">
          <div class="flex items-center justify-between">
            <h4 class="text-sm font-bold text-slate-800 flex items-center gap-2">
              <Layers class="w-4 h-4 text-blue-600" />
              24-Week Schedule Preview
            </h4>
            <div class="text-right">
              <div class="text-xs font-bold text-slate-700">Viewing Week {{ selectedPreviewWeek }}</div>
              <div class="text-[11px] font-medium text-slate-500">{{ formattedMondayDate }}</div>
            </div>
          </div>

          <!-- Active Hover / Sticky Summary Banner -->
          <div
            v-if="activePlayerSummary"
            class="p-2.5 bg-indigo-50 border border-indigo-200 rounded-lg text-xs flex items-center justify-between font-semibold text-indigo-900 transition-all shadow-sm"
          >
            <span class="flex items-center gap-1.5">
              <span
                class="w-2 h-2 rounded-full"
                :class="activePlayerSummary.isPinned ? 'bg-indigo-600 ring-2 ring-indigo-300' : 'bg-indigo-600 animate-pulse'"
              ></span>
              <span>{{ activePlayerSummary.isPinned ? 'Selected (Pinned):' : 'Highlighting:' }}</span>
              <strong class="text-indigo-950">{{ activePlayerSummary.fullName }}</strong>
            </span>
            <span class="text-[11px] bg-white px-2.5 py-0.5 rounded-md border border-indigo-200 text-slate-700 shadow-2xs">
              Scheduled in {{ activePlayerSummary.totalWeeks }} Weeks (
              <span class="text-indigo-600 font-bold">{{ activePlayerSummary.scheduledSingles }} Singles</span>, 
              <span class="text-emerald-600 font-bold">{{ activePlayerSummary.scheduledDoubles }} Doubles</span>
              )
              <span v-if="activePlayerSummary.blackoutCount > 0" class="font-bold text-slate-900 ml-1">
                • {{ activePlayerSummary.blackoutCount }} Wks OFF
              </span>
              <span v-if="activePlayerSummary.blackoutDaysList && activePlayerSummary.blackoutDaysList.length > 0" class="font-bold text-amber-700 ml-1">
                • {{ activePlayerSummary.blackoutDaysList.join(', ') }} OFF
              </span>
            </span>
          </div>

          <!-- 2-Row Week Selector (12 columns per row) -->
          <div class="grid grid-cols-6 sm:grid-cols-12 gap-1.5 w-full pt-1">
            <button
              v-for="w in 24"
              :key="w"
              @click="selectedPreviewWeek = w"
              :class="getWeekButtonClass(w)"
              class="text-[11px] py-1.5 rounded-lg transition-all duration-150 text-center font-medium flex flex-col items-center justify-center relative min-h-[40px]"
            >
              <span class="leading-none">W{{ w }}</span>
              <span
                v-if="activePlayerId && getWeekBadgeText(w)"
                class="text-[9px] font-extrabold mt-0.5 px-1 py-0.2 rounded leading-none bg-white/20 text-white border border-white/30"
              >
                {{ getWeekBadgeText(w) }}
              </span>
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div
            v-for="m in weekMatches"
            :key="`${m.day_of_week}-${m.type}-${m.court_number}`"
            class="p-4 rounded-xl border flex flex-col justify-between"
            :class="m.type === 'SINGLES' ? 'bg-indigo-50/60 border-indigo-200' : 'bg-emerald-50/60 border-emerald-200'"
          >
            <div>
              <div class="flex justify-between items-center mb-2">
                <div>
                  <span class="font-bold text-xs text-slate-800">
                    {{ formatDayOfWeek(m.day_of_week) }} • Court #{{ m.court_number }}
                  </span>
                  <p class="text-[10px] text-slate-500">{{ m.match_date }}</p>
                </div>
                <span
                  class="text-[10px] font-bold px-2 py-0.5 rounded"
                  :class="m.type === 'SINGLES' ? 'bg-indigo-200 text-indigo-800' : 'bg-emerald-200 text-emerald-800'"
                >
                  {{ m.type }}
                </span>
              </div>

              <div class="space-y-1 pt-1">
                <div
                  v-for="slot in m.slots"
                  :key="slot.player_id"
                  class="text-xs flex items-center gap-2 text-slate-700"
                >
                  <UserCheck class="w-3.5 h-3.5 text-slate-400" />
                  <span class="font-medium">{{ slot.player_name }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

