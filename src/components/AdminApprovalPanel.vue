<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '../supabase';
import {
  ShieldAlert,
  Check,
  X,
  AlertCircle,
  Users,
  CheckCircle2,
  Calendar,
  Radio,
  Send,
  Save,
  Bell,
  RefreshCw,
  ToggleLeft,
  ToggleRight,
  Settings2,
  Star,
  Clock,
  Sliders,
  AlertTriangle,
} from 'lucide-vue-next';
import ScheduleGeneratorModal from './ScheduleGeneratorModal.vue';
import {
  testDiscordWebhook,
  sendCustomBroadcast,
  notifyPlayerApproved,
  notifySubClaimed,
  getNotificationConfig,
  fetchGlobalDiscordSettings,
  saveGlobalDiscordSettings,
  type DiscordNotificationConfig,
} from '../utils/discordNotifier';
import {
  fetchLeagueConfig,
  saveLeagueConfig,
  type LeagueConfiguration,
} from '../utils/leagueSettings';
import { formatDayOfWeek } from '../utils/scheduleGenerator';

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

export interface SubRequestRanking {
  request_id: string;
  slot_id: string;
  requesting_player_id: string;
  full_name: string;
  email: string;
  times_subbed: number;
  rule_penalty: number;
  match_id: string;
  match_date: string;
  week_number: number;
  day_of_week: string;
  type: string;
  court_number: number;
  original_player_name?: string;
  requested_at: string;
}

export interface GroupedSubRequestSlot {
  slot_id: string;
  match_id: string;
  week_number: number;
  day_of_week: string;
  match_date: string;
  type: string;
  court_number: number;
  original_player_name: string;
  requests: SubRequestRanking[];
  recommendedRequestId?: string;
}

const props = defineProps<{
  pendingPlayers: PlayerRecord[];
}>();

const emit = defineEmits(['updated']);

const allPlayers = ref<PlayerRecord[]>([]);
const processingId = ref<string | null>(null);
const actionError = ref<string | null>(null);
const activeTab = ref<'pending' | 'roster' | 'generator' | 'discord' | 'settings'>('pending');

// Sub Requests State
const subRequests = ref<SubRequestRanking[]>([]);
const isProcessingSubRequest = ref<string | null>(null);

// League Configuration State
const leagueConfig = ref<LeagueConfiguration>({ sub_request_flow: 'maintenance_free' });
const isSavingLeagueConfig = ref<boolean>(false);
const leagueConfigStatus = ref<{ text: string; error?: boolean } | null>(null);

const isRunningAutoDraft = ref<boolean>(false);
const autoDraftStatus = ref<{ text: string; error?: boolean } | null>(null);

// Discord configuration and broadcast state
const webhookUrlInput = ref<string>('');
const webhookStatus = ref<{ text: string; error?: boolean } | null>(null);
const isTestingWebhook = ref<boolean>(false);

const eventConfig = ref<DiscordNotificationConfig>(getNotificationConfig());
const configSaveStatus = ref<string | null>(null);

const broadcastTitle = ref<string>('');
const broadcastMessage = ref<string>('');
const broadcastType = ref<'announcement' | 'urgent' | 'warning' | 'info'>('announcement');
const isBroadcasting = ref<boolean>(false);
const broadcastStatus = ref<{ text: string; error?: boolean } | null>(null);

const fetchRoster = async () => {
  const { data } = await supabase
    .from('players')
    .select('*')
    .order('full_name', { ascending: true });
  if (data) allPlayers.value = data;
};

const fetchSubRequests = async () => {
  const { data, error } = await supabase
    .from('sub_request_rankings')
    .select('*')
    .order('requested_at', { ascending: true });
  if (!error && data) {
    subRequests.value = data as SubRequestRanking[];
  }
};

const fetchConfig = async () => {
  const cfg = await fetchLeagueConfig();
  leagueConfig.value = cfg;
};

onMounted(async () => {
  fetchRoster();
  fetchSubRequests();
  fetchConfig();
  const globalSettings = await fetchGlobalDiscordSettings();
  webhookUrlInput.value = globalSettings.webhook_url;
  eventConfig.value = globalSettings.events;
});

const groupedSubRequests = computed<GroupedSubRequestSlot[]>(() => {
  const map = new Map<string, GroupedSubRequestSlot>();
  for (const item of subRequests.value) {
    if (!map.has(item.slot_id)) {
      map.set(item.slot_id, {
        slot_id: item.slot_id,
        match_id: item.match_id,
        week_number: item.week_number,
        day_of_week: item.day_of_week,
        match_date: item.match_date,
        type: item.type,
        court_number: item.court_number,
        original_player_name: item.original_player_name || 'Open Sub',
        requests: [],
      });
    }
    map.get(item.slot_id)!.requests.push(item);
  }

  const list = Array.from(map.values());
  for (const group of list) {
    group.requests.sort((a, b) => {
      // 1. Eligible (rule_penalty === 0) before penalties (< 0)
      if (a.rule_penalty === 0 && b.rule_penalty !== 0) return -1;
      if (a.rule_penalty !== 0 && b.rule_penalty === 0) return 1;
      // 2. Fewest subs first
      if (a.times_subbed !== b.times_subbed) return a.times_subbed - b.times_subbed;
      // 3. Earliest requested
      return new Date(a.requested_at).getTime() - new Date(b.requested_at).getTime();
    });

    const eligible = group.requests.filter((r) => r.rule_penalty === 0);
    if (eligible.length > 0) {
      group.recommendedRequestId = eligible[0].request_id;
    }
  }

  return list;
});

const approvedPlayers = computed(() => {
  return allPlayers.value.filter((p) => p.approved !== false);
});

const getBlackoutWeekRanges = (weeks?: number[]): string[] => {
  if (!weeks || weeks.length === 0) return [];
  const sorted = [...weeks].sort((a, b) => a - b);
  const ranges: string[] = [];
  let start = sorted[0];
  let end = start;
  for (let i = 1; i < sorted.length; i++) {
    if (sorted[i] === end + 1) {
      end = sorted[i];
    } else {
      ranges.push(start === end ? `W${start}` : `W${start}–${end}`);
      start = sorted[i];
      end = start;
    }
  }
  ranges.push(start === end ? `W${start}` : `W${start}–${end}`);
  return ranges;
};

const handleToggleEvent = async (key: keyof DiscordNotificationConfig) => {
  eventConfig.value[key] = !eventConfig.value[key];
  const res = await saveGlobalDiscordSettings(webhookUrlInput.value, eventConfig.value);
  configSaveStatus.value = res.message;
  setTimeout(() => {
    configSaveStatus.value = null;
  }, 3500);
};

const handleSaveWebhookUrl = async () => {
  const res = await saveGlobalDiscordSettings(webhookUrlInput.value, eventConfig.value);
  webhookStatus.value = { text: res.message, error: false };
  setTimeout(() => {
    webhookStatus.value = null;
  }, 3500);
};

const handleTestWebhook = async () => {
  isTestingWebhook.value = true;
  webhookStatus.value = null;
  const res = await testDiscordWebhook(webhookUrlInput.value);
  isTestingWebhook.value = false;
  webhookStatus.value = { text: res.message, error: !res.success };
};

const handleSendBroadcast = async () => {
  if (!broadcastTitle.value.trim() || !broadcastMessage.value.trim()) {
    broadcastStatus.value = { text: 'Please fill in both the title and message for the announcement.', error: true };
    return;
  }

  isBroadcasting.value = true;
  broadcastStatus.value = null;

  const res = await sendCustomBroadcast(
    broadcastTitle.value,
    broadcastMessage.value,
    broadcastType.value,
    'League Administrator'
  );

  isBroadcasting.value = false;
  if (res.success) {
    broadcastStatus.value = { text: 'Announcement broadcasted successfully to your Discord channel! 📣' };
    broadcastTitle.value = '';
    broadcastMessage.value = '';
  } else {
    broadcastStatus.value = { text: res.message, error: true };
  }
};

const handleApprove = async (player: PlayerRecord) => {
  processingId.value = player.id;
  actionError.value = null;

  const { error } = await supabase
    .from('players')
    .update({ approved: true })
    .eq('id', player.id);

  processingId.value = null;

  if (error) {
    actionError.value = error.message;
  } else {
    await fetchRoster();
    emit('updated');

    // Trigger automated Discord notification for approval
    notifyPlayerApproved({
      full_name: player.full_name,
      email: player.email,
    });
  }
};

const handleRevoke = async (player: PlayerRecord) => {
  processingId.value = player.id;
  actionError.value = null;

  const { error } = await supabase
    .from('players')
    .update({ approved: false })
    .eq('id', player.id);

  processingId.value = null;

  if (error) {
    actionError.value = error.message;
  } else {
    await fetchRoster();
    emit('updated');
  }
};

const handleReject = async (player: PlayerRecord) => {
  if (!confirm(`Are you sure you want to delete ${player.full_name} from the roster?`)) {
    return;
  }

  processingId.value = player.id;
  actionError.value = null;

  const { error } = await supabase
    .from('players')
    .delete()
    .eq('id', player.id);

  processingId.value = null;

  if (error) {
    actionError.value = error.message;
  } else {
    await fetchRoster();
    emit('updated');
  }
};

const handleApproveSubRequest = async (request: SubRequestRanking, group: GroupedSubRequestSlot) => {
  isProcessingSubRequest.value = request.request_id;
  actionError.value = null;

  const { data, error } = await supabase.rpc('approve_sub_request', {
    request_id: request.request_id,
  });

  isProcessingSubRequest.value = null;

  if (error || !data?.success) {
    actionError.value = error?.message || data?.message || 'Failed to approve sub request.';
    return;
  }

  // Notify public Discord about the sub being claimed
  notifySubClaimed(
    {
      week_number: group.week_number,
      day_of_week: formatDayOfWeek(group.day_of_week),
      match_date: group.match_date,
      type: group.type,
      court_number: group.court_number,
      original_player: group.original_player_name,
    },
    request.full_name
  );

  await fetchSubRequests();
  emit('updated');
};

const handleDeclineSubRequest = async (request: SubRequestRanking) => {
  isProcessingSubRequest.value = request.request_id;
  actionError.value = null;

  const { error } = await supabase
    .from('sub_requests')
    .update({ status: 'REJECTED' })
    .eq('id', request.request_id);

  isProcessingSubRequest.value = null;

  if (error) {
    actionError.value = error.message;
  } else {
    await fetchSubRequests();
  }
};

const handleSetFlow = async (flow: 'maintenance_free' | 'admin_assists') => {
  leagueConfig.value.sub_request_flow = flow;
  isSavingLeagueConfig.value = true;
  leagueConfigStatus.value = null;

  const res = await saveLeagueConfig({ sub_request_flow: flow });
  isSavingLeagueConfig.value = false;
  leagueConfigStatus.value = { text: res.message, error: !res.success };
  setTimeout(() => {
    leagueConfigStatus.value = null;
  }, 4000);
};

const handleTriggerAutoDraft = async () => {
  isRunningAutoDraft.value = true;
  autoDraftStatus.value = null;

  const { data, error } = await supabase.rpc('process_auto_draft');
  isRunningAutoDraft.value = false;

  if (error) {
    autoDraftStatus.value = { text: error.message, error: true };
  } else {
    autoDraftStatus.value = {
      text: data?.message || `Auto-draft processed. Assigned ${data?.assigned ?? 0} slot(s).`,
      error: !data?.success,
    };
    await fetchSubRequests();
    emit('updated');
  }
  setTimeout(() => {
    autoDraftStatus.value = null;
  }, 5000);
};
</script>

<template>
  <div class="bg-white border border-slate-200 rounded-xl p-5 mb-6 shadow-sm">
    <!-- Sub-tabs Header Bar -->
    <div class="flex flex-wrap items-center gap-2 pb-3 border-b border-slate-200">
      <button
          @click="activeTab = 'pending'"
          :class="activeTab === 'pending' ? 'bg-amber-100 text-amber-900 border-amber-300 font-bold' : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border-slate-200'"
          class="text-xs px-3 py-1 rounded-lg border transition flex items-center gap-1.5"
        >
          <ShieldAlert class="w-3.5 h-3.5 text-amber-600" />
          Pending Requests ({{ pendingPlayers.length + subRequests.length }})
        </button>
        <button
          @click="activeTab = 'roster'; fetchRoster();"
          :class="activeTab === 'roster' ? 'bg-indigo-100 text-indigo-900 border-indigo-300 font-bold' : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border-slate-200'"
          class="text-xs px-3 py-1 rounded-lg border transition flex items-center gap-1.5"
        >
          <Users class="w-3.5 h-3.5 text-indigo-600" />
          Manage Roster
        </button>
        <button
          @click="activeTab = 'generator'; fetchRoster();"
          :class="activeTab === 'generator' ? 'bg-indigo-600 text-white font-bold' : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border-slate-200'"
          class="text-xs px-3 py-1 rounded-lg border transition flex items-center gap-1.5"
        >
          <Calendar class="w-3.5 h-3.5" />
          Schedule Generator
        </button>
        <button
          @click="activeTab = 'discord'"
          :class="activeTab === 'discord' ? 'bg-purple-600 text-white font-bold' : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border-slate-200'"
          class="text-xs px-3 py-1 rounded-lg border transition flex items-center gap-1.5"
        >
          <Radio class="w-3.5 h-3.5" />
          Discord Broadcast
        </button>
        <button
          @click="activeTab = 'settings'; fetchConfig();"
          :class="activeTab === 'settings' ? 'bg-indigo-600 text-white font-bold' : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border-slate-200'"
          class="text-xs px-3 py-1 rounded-lg border transition flex items-center gap-1.5"
        >
          <Settings2 class="w-3.5 h-3.5" />
          League Settings
        </button>
      </div>

    <!-- Error Banner -->
    <div v-if="actionError" class="mt-3 p-2.5 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700 flex items-center gap-2">
      <AlertCircle class="w-4 h-4 flex-shrink-0" />
      <span>{{ actionError }}</span>
    </div>

    <!-- TAB 1: PENDING APPROVALS -->
    <div v-if="activeTab === 'pending'" class="pt-4 space-y-6">
      <!-- Section A: Pending Sub Requests -->
      <div class="space-y-3">
        <div class="flex items-center justify-between pb-1 border-b border-slate-100">
          <div class="flex items-center gap-2">
            <h4 class="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center gap-1.5">
              <Clock class="w-4 h-4 text-amber-600" />
              Sub Slot Requests ({{ subRequests.length }})
            </h4>
            <span
              class="text-[10px] font-semibold px-2 py-0.5 rounded-full border"
              :class="leagueConfig.sub_request_flow === 'maintenance_free' ? 'bg-blue-50 text-blue-700 border-blue-200' : 'bg-purple-50 text-purple-700 border-purple-200'"
            >
              Mode: {{ leagueConfig.sub_request_flow === 'maintenance_free' ? 'Maintenance Free (Auto-Draft)' : 'Admin Assists (Manual)' }}
            </span>
          </div>
          <button
            @click="fetchSubRequests"
            class="text-[11px] text-slate-500 hover:text-slate-800 flex items-center gap-1 transition"
          >
            <RefreshCw class="w-3 h-3" />
            Refresh
          </button>
        </div>

        <div v-if="groupedSubRequests.length === 0" class="p-4 bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-500 flex items-center gap-2">
          <CheckCircle2 class="w-4 h-4 text-emerald-600 flex-shrink-0" />
          <span>No pending sub requests. Open sub slots can be requested by players on the schedule page.</span>
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="group in groupedSubRequests"
            :key="group.slot_id"
            class="bg-white border border-amber-200 rounded-xl overflow-hidden shadow-xs"
          >
            <!-- Match Slot Header -->
            <div class="bg-amber-50/80 px-4 py-2.5 border-b border-amber-200 flex flex-col sm:flex-row sm:items-center justify-between gap-1 text-xs">
              <div class="flex items-center gap-2">
                <span class="font-extrabold text-amber-900">Week {{ group.week_number }}</span>
                <span class="text-amber-700 font-semibold">• {{ formatDayOfWeek(group.day_of_week) }}, {{ group.match_date }}</span>
                <span class="bg-amber-200 text-amber-900 text-[10px] font-bold px-2 py-0.5 rounded-full">
                  {{ group.type }} (Court {{ group.court_number }})
                </span>
              </div>
              <div class="text-[11px] text-amber-800 font-medium">
                Original Player: <span class="font-bold">{{ group.original_player_name }}</span>
              </div>
            </div>

            <!-- Candidate Requests for this Slot -->
            <div class="p-3 divide-y divide-slate-100">
              <div
                v-for="r in group.requests"
                :key="r.request_id"
                class="py-2.5 first:pt-1 last:pb-1 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2"
              >
                <div>
                  <div class="flex flex-wrap items-center gap-2">
                    <span class="font-bold text-xs text-slate-800">{{ r.full_name }}</span>
                    <span class="text-[11px] text-slate-400">({{ r.email }})</span>
                    
                    <!-- Times Subbed Badge -->
                    <span class="text-[10px] bg-slate-100 text-slate-600 border border-slate-200 px-1.5 py-0.5 rounded font-medium">
                      Subbed {{ r.times_subbed }}x this season
                    </span>

                    <!-- Recommendation Badge -->
                    <span
                      v-if="r.request_id === group.recommendedRequestId"
                      class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800 border border-emerald-300 flex items-center gap-1 shadow-2xs"
                    >
                      <Star class="w-3 h-3 fill-emerald-600 text-emerald-600" />
                      Recommended
                    </span>

                    <!-- Rule Ineligibility Warnings -->
                    <span
                      v-if="r.rule_penalty === -1"
                      class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-rose-100 text-rose-800 border border-rose-300 flex items-center gap-1"
                    >
                      <AlertTriangle class="w-3 h-3 text-rose-600" />
                      Ineligible: Playing Today
                    </span>
                    <span
                      v-else-if="r.rule_penalty === -2"
                      class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-rose-100 text-rose-800 border border-rose-300 flex items-center gap-1"
                    >
                      <AlertTriangle class="w-3 h-3 text-rose-600" />
                      Ineligible: Max 2 Matches/Wk
                    </span>
                  </div>
                  <div class="text-[10px] text-slate-400 mt-0.5">
                    Requested on {{ new Date(r.requested_at).toLocaleDateString() }} at {{ new Date(r.requested_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) }}
                  </div>
                </div>

                <!-- Approval Actions -->
                <div class="flex items-center gap-2 w-full sm:w-auto">
                  <button
                    @click="handleApproveSubRequest(r, group)"
                    :disabled="isProcessingSubRequest === r.request_id"
                    class="flex-1 sm:flex-none px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-xs rounded-lg transition flex items-center justify-center gap-1 shadow-2xs disabled:opacity-50"
                  >
                    <Check class="w-3.5 h-3.5" />
                    Approve Sub
                  </button>
                  <button
                    @click="handleDeclineSubRequest(r)"
                    :disabled="isProcessingSubRequest === r.request_id"
                    class="flex-1 sm:flex-none px-2.5 py-1.5 bg-slate-100 hover:bg-rose-50 text-slate-600 hover:text-rose-700 font-medium text-xs rounded-lg transition flex items-center justify-center gap-1 disabled:opacity-50"
                  >
                    <X class="w-3.5 h-3.5" />
                    Decline
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Section B: Player Intake Registrations -->
      <div class="space-y-3 pt-3 border-t border-slate-200">
        <h4 class="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center gap-1.5">
          <Users class="w-4 h-4 text-indigo-600" />
          Player Registration Approvals ({{ pendingPlayers.length }})
        </h4>

        <div v-if="pendingPlayers.length === 0" class="p-4 bg-emerald-50 border border-emerald-200 rounded-lg text-xs text-emerald-700 flex items-center gap-2">
          <CheckCircle2 class="w-4 h-4 text-emerald-600 flex-shrink-0" />
          <span>All player registrations approved! There are 0 pending registration requests.</span>
        </div>

        <div v-else class="space-y-2">
          <p class="text-xs text-slate-500 mb-2">
            The following players submitted intake preferences and are waiting for admin approval before they can log in:
          </p>

          <div
            v-for="p in pendingPlayers"
            :key="p.id"
            class="bg-amber-50/70 border border-amber-200 p-3 rounded-lg flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3"
          >
            <div>
              <div class="flex items-center gap-2">
                <span class="font-bold text-sm text-slate-800">{{ p.full_name }}</span>
                <span class="text-xs text-slate-500">({{ p.email }})</span>
              </div>
              <p class="text-xs text-slate-500 mt-0.5">
                Singles: <span class="font-medium text-slate-700">{{ (p.singles_share * 100 % 1 === 0 ? (p.singles_share * 100).toFixed(0) : (p.singles_share * 100).toFixed(1)) }}%</span> • 
                Doubles: <span class="font-medium text-slate-700">{{ (p.doubles_share * 100 % 1 === 0 ? (p.doubles_share * 100).toFixed(0) : (p.doubles_share * 100).toFixed(1)) }}%</span> • 
                Blackout Days: <span class="text-slate-600 font-medium">{{ p.blackout_days?.length ? p.blackout_days.join(', ') : 'None' }}</span> • 
                Blackout Weeks: <span class="text-slate-600 font-medium">{{ getBlackoutWeekRanges(p.blackout_weeks).length ? getBlackoutWeekRanges(p.blackout_weeks).join(', ') : 'None' }}</span>
              </p>
            </div>

            <div class="flex items-center gap-2 w-full sm:w-auto">
              <button
                @click="handleApprove(p)"
                :disabled="processingId === p.id"
                class="flex-1 sm:flex-none px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-xs rounded-lg transition flex items-center justify-center gap-1 shadow-2xs disabled:opacity-50"
              >
                <Check class="w-3.5 h-3.5" />
                Approve
              </button>
              <button
                @click="handleReject(p)"
                :disabled="processingId === p.id"
                class="flex-1 sm:flex-none px-3 py-1.5 bg-slate-200 hover:bg-rose-100 text-slate-700 hover:text-rose-700 font-semibold text-xs rounded-lg transition flex items-center justify-center gap-1 disabled:opacity-50"
              >
                <X class="w-3.5 h-3.5" />
                Decline
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB 2: MANAGE FULL ROSTER -->
    <div v-else-if="activeTab === 'roster'" class="pt-4">
      <div class="overflow-x-auto">
        <table class="w-full text-xs text-left">
          <thead>
            <tr class="border-b text-slate-400">
              <th class="pb-2">Player Name</th>
              <th class="pb-2">Email</th>
              <th class="pb-2">Status</th>
              <th class="pb-2 text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="p in allPlayers" :key="p.id" class="hover:bg-slate-50">
              <td class="py-2.5 font-semibold text-slate-800 flex items-center gap-1.5">
                {{ p.full_name }}
                <span v-if="p.is_admin" class="text-[9px] bg-amber-100 text-amber-800 px-1.5 py-0.5 rounded font-extrabold uppercase">
                  Admin
                </span>
              </td>
              <td class="py-2.5 text-slate-500">{{ p.email || 'No email' }}</td>
              <td class="py-2.5">
                <span
                  class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                  :class="p.approved !== false ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'"
                >
                  {{ p.approved !== false ? 'Approved' : 'Pending' }}
                </span>
              </td>
              <td class="py-2.5 text-right space-x-2">
                <button
                  v-if="p.approved === false"
                  @click="handleApprove(p)"
                  :disabled="processingId === p.id"
                  class="px-2.5 py-1 bg-emerald-600 text-white rounded text-[11px] font-medium hover:bg-emerald-700 transition"
                >
                  Approve
                </button>
                <button
                  v-else
                  @click="handleRevoke(p)"
                  :disabled="processingId === p.id"
                  class="px-2.5 py-1 bg-slate-100 text-slate-600 rounded text-[11px] font-medium hover:bg-amber-100 hover:text-amber-800 transition"
                >
                  Revoke Access
                </button>
                <button
                  @click="handleReject(p)"
                  :disabled="processingId === p.id"
                  class="px-2.5 py-1 bg-rose-50 text-rose-600 rounded text-[11px] font-medium hover:bg-rose-100 transition"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 3: SCHEDULE GENERATOR -->
    <div v-else-if="activeTab === 'generator'">
      <ScheduleGeneratorModal
        :players="approvedPlayers"
        @scheduled="emit('updated')"
      />
    </div>

    <!-- TAB 4: DISCORD BROADCAST & WEBHOOK CONFIG -->
    <div v-else-if="activeTab === 'discord'" class="pt-4 space-y-6">
      <!-- Webhook Configuration Box -->
      <div class="bg-purple-50/60 border border-purple-200 rounded-xl p-4">
        <h4 class="text-xs font-bold text-purple-900 flex items-center gap-2 mb-2">
          <Bell class="w-4 h-4 text-purple-600" />
          Discord Webhook Configuration
        </h4>
        <p class="text-xs text-purple-700 mb-3">
          Enter your Discord Channel Webhook URL below to send automatic alerts for schedule updates, open sub requests, new player intake, and custom broadcast announcements.
        </p>

        <div class="flex flex-col sm:flex-row gap-2">
          <input
            v-model="webhookUrlInput"
            type="url"
            placeholder="https://discord.com/api/webhooks/..."
            class="flex-1 px-3 py-2 text-xs border border-purple-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:outline-none bg-white text-slate-800"
          />
          <button
            @click="handleSaveWebhookUrl"
            class="px-3.5 py-2 bg-purple-600 hover:bg-purple-700 text-white font-semibold text-xs rounded-lg transition flex items-center justify-center gap-1.5 shadow-2xs"
          >
            <Save class="w-3.5 h-3.5" />
            Save Webhook
          </button>
          <button
            @click="handleTestWebhook"
            :disabled="isTestingWebhook"
            class="px-3.5 py-2 bg-white hover:bg-purple-100 text-purple-700 border border-purple-300 font-semibold text-xs rounded-lg transition flex items-center justify-center gap-1.5 disabled:opacity-50"
          >
            <RefreshCw v-if="isTestingWebhook" class="w-3.5 h-3.5 animate-spin" />
            <Send v-else class="w-3.5 h-3.5" />
            Test Connection
          </button>
        </div>

        <div
          v-if="webhookStatus"
          class="mt-3 p-2.5 rounded-lg text-xs flex items-center gap-2"
          :class="webhookStatus.error ? 'bg-red-100 text-red-800 border border-red-200' : 'bg-emerald-100 text-emerald-800 border border-emerald-200'"
        >
          <AlertCircle v-if="webhookStatus.error" class="w-4 h-4 flex-shrink-0" />
          <CheckCircle2 v-else class="w-4 h-4 flex-shrink-0" />
          <span>{{ webhookStatus.text }}</span>
        </div>
      </div>

      <!-- Event Notification Preferences & Toggles Box -->
      <div class="bg-white border border-slate-200 rounded-xl p-4 shadow-xs space-y-3">
        <div class="flex items-center justify-between border-b border-slate-100 pb-2.5">
          <div>
            <h4 class="text-xs font-bold text-slate-800 flex items-center gap-2">
              <Settings2 class="w-4 h-4 text-purple-600" />
              Automated Event Notification Triggers
            </h4>
            <p class="text-[11px] text-slate-500 mt-0.5">
              Select which events automatically post notifications to your Discord channel.
            </p>
          </div>
          <div v-if="configSaveStatus" class="text-[11px] font-semibold text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-md flex items-center gap-1">
            <CheckCircle2 class="w-3.5 h-3.5 text-emerald-500" />
            <span>{{ configSaveStatus }}</span>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-1">
          <!-- 1. Open Sub Requested -->
          <div
            @click="handleToggleEvent('sub_requested')"
            class="p-3 rounded-lg border cursor-pointer transition flex items-center justify-between select-none"
            :class="eventConfig.sub_requested ? 'bg-amber-50/70 border-amber-300' : 'bg-slate-50 border-slate-200 opacity-60'"
          >
            <div>
              <div class="flex items-center gap-1.5 font-bold text-xs" :class="eventConfig.sub_requested ? 'text-amber-900' : 'text-slate-600'">
                <span>🚨 Open Sub Requested</span>
              </div>
              <p class="text-[11px] text-slate-500 mt-0.5">Alerts channel when a player puts a slot up for a sub.</p>
            </div>
            <ToggleRight v-if="eventConfig.sub_requested" class="w-6 h-6 text-amber-600 flex-shrink-0 ml-2" />
            <ToggleLeft v-else class="w-6 h-6 text-slate-400 flex-shrink-0 ml-2" />
          </div>

          <!-- 2. Sub Claimed -->
          <div
            @click="handleToggleEvent('sub_claimed')"
            class="p-3 rounded-lg border cursor-pointer transition flex items-center justify-between select-none"
            :class="eventConfig.sub_claimed ? 'bg-emerald-50/70 border-emerald-300' : 'bg-slate-50 border-slate-200 opacity-60'"
          >
            <div>
              <div class="flex items-center gap-1.5 font-bold text-xs" :class="eventConfig.sub_claimed ? 'text-emerald-900' : 'text-slate-600'">
                <span>🤝 Sub Claimed</span>
              </div>
              <p class="text-[11px] text-slate-500 mt-0.5">Confirms when a substitute takes over an open slot.</p>
            </div>
            <ToggleRight v-if="eventConfig.sub_claimed" class="w-6 h-6 text-emerald-600 flex-shrink-0 ml-2" />
            <ToggleLeft v-else class="w-6 h-6 text-slate-400 flex-shrink-0 ml-2" />
          </div>

          <!-- 3. Season Schedule Published -->
          <div
            @click="handleToggleEvent('schedule_published')"
            class="p-3 rounded-lg border cursor-pointer transition flex items-center justify-between select-none"
            :class="eventConfig.schedule_published ? 'bg-purple-50/70 border-purple-300' : 'bg-slate-50 border-slate-200 opacity-60'"
          >
            <div>
              <div class="flex items-center gap-1.5 font-bold text-xs" :class="eventConfig.schedule_published ? 'text-purple-900' : 'text-slate-600'">
                <span>📅 Season Schedule Published</span>
              </div>
              <p class="text-[11px] text-slate-500 mt-0.5">Posts breakdown when a new 24-week schedule is generated.</p>
            </div>
            <ToggleRight v-if="eventConfig.schedule_published" class="w-6 h-6 text-purple-600 flex-shrink-0 ml-2" />
            <ToggleLeft v-else class="w-6 h-6 text-slate-400 flex-shrink-0 ml-2" />
          </div>

          <!-- 4. New Player Intake -->
          <div
            @click="handleToggleEvent('new_player_intake')"
            class="p-3 rounded-lg border cursor-pointer transition flex items-center justify-between select-none"
            :class="eventConfig.new_player_intake ? 'bg-blue-50/70 border-blue-300' : 'bg-slate-50 border-slate-200 opacity-60'"
          >
            <div>
              <div class="flex items-center gap-1.5 font-bold text-xs" :class="eventConfig.new_player_intake ? 'text-blue-900' : 'text-slate-600'">
                <span>📝 New Player Registration</span>
              </div>
              <p class="text-[11px] text-slate-500 mt-0.5">Alerts when a new player submits registration preferences.</p>
            </div>
            <ToggleRight v-if="eventConfig.new_player_intake" class="w-6 h-6 text-blue-600 flex-shrink-0 ml-2" />
            <ToggleLeft v-else class="w-6 h-6 text-slate-400 flex-shrink-0 ml-2" />
          </div>

          <!-- 5. Player Approved -->
          <div
            @click="handleToggleEvent('player_approved')"
            class="p-3 rounded-lg border cursor-pointer transition flex items-center justify-between select-none sm:col-span-2"
            :class="eventConfig.player_approved ? 'bg-indigo-50/70 border-indigo-300' : 'bg-slate-50 border-slate-200 opacity-60'"
          >
            <div>
              <div class="flex items-center gap-1.5 font-bold text-xs" :class="eventConfig.player_approved ? 'text-indigo-900' : 'text-slate-600'">
                <span>🎉 Player Roster Approval</span>
              </div>
              <p class="text-[11px] text-slate-500 mt-0.5">Welcomes new players to the league when approved by an admin.</p>
            </div>
            <ToggleRight v-if="eventConfig.player_approved" class="w-6 h-6 text-indigo-600 flex-shrink-0 ml-2" />
            <ToggleLeft v-else class="w-6 h-6 text-slate-400 flex-shrink-0 ml-2" />
          </div>
        </div>
      </div>

      <!-- Broadcast Announcement Composer -->
      <div class="bg-slate-50 border border-slate-200 rounded-xl p-4">
        <h4 class="text-xs font-bold text-slate-800 flex items-center gap-2 mb-3">
          <Radio class="w-4 h-4 text-purple-600" />
          Send Custom Discord Broadcast
        </h4>

        <div class="space-y-3">
          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Alert Type / Severity</label>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <button
                type="button"
                @click="broadcastType = 'announcement'"
                :class="broadcastType === 'announcement' ? 'bg-purple-600 text-white font-bold ring-2 ring-purple-400' : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-100'"
                class="px-3 py-1.5 rounded-lg text-xs transition text-center"
              >
                📣 Announcement
              </button>
              <button
                type="button"
                @click="broadcastType = 'urgent'"
                :class="broadcastType === 'urgent' ? 'bg-red-600 text-white font-bold ring-2 ring-red-400' : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-100'"
                class="px-3 py-1.5 rounded-lg text-xs transition text-center"
              >
                🚨 Urgent Alert
              </button>
              <button
                type="button"
                @click="broadcastType = 'warning'"
                :class="broadcastType === 'warning' ? 'bg-amber-600 text-white font-bold ring-2 ring-amber-400' : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-100'"
                class="px-3 py-1.5 rounded-lg text-xs transition text-center"
              >
                ⚠️ Match Notice
              </button>
              <button
                type="button"
                @click="broadcastType = 'info'"
                :class="broadcastType === 'info' ? 'bg-blue-600 text-white font-bold ring-2 ring-blue-400' : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-100'"
                class="px-3 py-1.5 rounded-lg text-xs transition text-center"
              >
                ℹ️ General Info
              </button>
            </div>
          </div>

          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Headline / Title</label>
            <input
              v-model="broadcastTitle"
              type="text"
              placeholder="e.g. Week 4 Match Rescheduled due to Weather 🌧️"
              class="w-full px-3 py-2 text-xs border border-slate-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:outline-none bg-white text-slate-800"
            />
          </div>

          <div>
            <label class="block text-xs font-medium text-slate-700 mb-1">Message Content</label>
            <textarea
              v-model="broadcastMessage"
              rows="4"
              placeholder="Type your message here. Markdown formatting is supported (e.g. **bold**, *italics*, bullet points)..."
              class="w-full px-3 py-2 text-xs border border-slate-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:outline-none bg-white text-slate-800"
            ></textarea>
          </div>

          <div v-if="broadcastStatus" class="p-2.5 rounded-lg text-xs flex items-center gap-2" :class="broadcastStatus.error ? 'bg-red-50 text-red-700 border border-red-200' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'">
            <AlertCircle v-if="broadcastStatus.error" class="w-4 h-4 flex-shrink-0" />
            <CheckCircle2 v-else class="w-4 h-4 flex-shrink-0" />
            <span>{{ broadcastStatus.text }}</span>
          </div>

          <div class="flex justify-end pt-2">
            <button
              @click="handleSendBroadcast"
              :disabled="isBroadcasting"
              class="px-4 py-2 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white font-bold text-xs rounded-lg transition flex items-center gap-2 shadow-md disabled:opacity-50"
            >
              <RefreshCw v-if="isBroadcasting" class="w-4 h-4 animate-spin" />
              <Send v-else class="w-4 h-4" />
              Broadcast to Discord Channel
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB 5: LEAGUE SETTINGS -->
    <div v-else-if="activeTab === 'settings'" class="pt-4 space-y-6">
      <div class="border-b border-slate-200 pb-3">
        <h4 class="text-sm font-bold text-slate-800 flex items-center gap-2">
          <Settings2 class="w-4 h-4 text-indigo-600" />
          Sub Request & Draft Flow
        </h4>
        <p class="text-xs text-slate-500 mt-0.5">
          Configure how open substitute requests are processed and assigned across the league.
        </p>
      </div>

      <!-- Mode Selector Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Option 1: Maintenance Free (Auto-Draft) -->
        <div
          @click="handleSetFlow('maintenance_free')"
          class="cursor-pointer rounded-xl border p-4 transition relative flex flex-col justify-between"
          :class="leagueConfig.sub_request_flow === 'maintenance_free' ? 'border-blue-500 bg-blue-50/40 ring-2 ring-blue-400/50' : 'border-slate-200 bg-white hover:bg-slate-50'"
        >
          <div>
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center gap-2">
                <span class="text-lg">🤖</span>
                <span class="font-bold text-sm text-slate-800">Maintenance Free (Auto-Draft)</span>
              </div>
              <span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 border border-emerald-300">
                Default
              </span>
            </div>
            <p class="text-xs text-slate-600 leading-relaxed mb-3">
              Players submit sub requests through the weekly schedule. <strong>24 hours prior to each match</strong>, an automated drafting engine evaluates all candidate requests and assigns the slot to the highest-ranked eligible player (prioritizing players with the fewest season substitutions and strictly honoring single-day and weekly match limits).
            </p>
          </div>
          <div class="flex items-center gap-2 pt-2 border-t border-slate-100 text-[11px] font-medium" :class="leagueConfig.sub_request_flow === 'maintenance_free' ? 'text-blue-700' : 'text-slate-400'">
            <div class="w-3.5 h-3.5 rounded-full border flex items-center justify-center" :class="leagueConfig.sub_request_flow === 'maintenance_free' ? 'border-blue-600 bg-blue-600 text-white' : 'border-slate-300'">
              <Check v-if="leagueConfig.sub_request_flow === 'maintenance_free'" class="w-2.5 h-2.5" />
            </div>
            <span>{{ leagueConfig.sub_request_flow === 'maintenance_free' ? 'Active Mode' : 'Click to Select' }}</span>
          </div>
        </div>

        <!-- Option 2: Admin Assists (Manual Review) -->
        <div
          @click="handleSetFlow('admin_assists')"
          class="cursor-pointer rounded-xl border p-4 transition relative flex flex-col justify-between"
          :class="leagueConfig.sub_request_flow === 'admin_assists' ? 'border-purple-500 bg-purple-50/40 ring-2 ring-purple-400/50' : 'border-slate-200 bg-white hover:bg-slate-50'"
        >
          <div>
            <div class="flex items-center justify-between mb-2">
              <div class="flex items-center gap-2">
                <span class="text-lg">🛡️</span>
                <span class="font-bold text-sm text-slate-800">Admin Assists (Manual Approval)</span>
              </div>
              <span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-purple-100 text-purple-800 border border-purple-300">
                Admin Review
              </span>
            </div>
            <p class="text-xs text-slate-600 leading-relaxed mb-3">
              Players request open sub slots through the schedule. All candidate requests are routed to the <strong>Admin Pending Requests</strong> tab and ranked algorithmically. The administrator compares players and manually clicks <strong>Approve Sub</strong> to select the winning player.
            </p>
          </div>
          <div class="flex items-center gap-2 pt-2 border-t border-slate-100 text-[11px] font-medium" :class="leagueConfig.sub_request_flow === 'admin_assists' ? 'text-purple-700' : 'text-slate-400'">
            <div class="w-3.5 h-3.5 rounded-full border flex items-center justify-center" :class="leagueConfig.sub_request_flow === 'admin_assists' ? 'border-purple-600 bg-purple-600 text-white' : 'border-slate-300'">
              <Check v-if="leagueConfig.sub_request_flow === 'admin_assists'" class="w-2.5 h-2.5" />
            </div>
            <span>{{ leagueConfig.sub_request_flow === 'admin_assists' ? 'Active Mode' : 'Click to Select' }}</span>
          </div>
        </div>
      </div>

      <!-- League Config Save Status Toast -->
      <div v-if="leagueConfigStatus" class="p-3 rounded-lg text-xs flex items-center gap-2" :class="leagueConfigStatus.error ? 'bg-red-50 text-red-700 border border-red-200' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'">
        <AlertCircle v-if="leagueConfigStatus.error" class="w-4 h-4 flex-shrink-0" />
        <CheckCircle2 v-else class="w-4 h-4 flex-shrink-0" />
        <span>{{ leagueConfigStatus.text }}</span>
      </div>

      <!-- Auto-Draft Engine Diagnostics & Manual Run -->
      <div class="bg-slate-50 border border-slate-200 rounded-xl p-4">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h5 class="text-xs font-bold text-slate-800 flex items-center gap-1.5">
              <RefreshCw class="w-3.5 h-3.5 text-indigo-600" />
              Auto-Draft Engine Trigger
            </h5>
            <p class="text-[11px] text-slate-500 mt-0.5">
              In production, Supabase pg_cron runs hourly to draft players for matches within 24 hours. You can also manually trigger a draft run right now.
            </p>
          </div>
          <button
            @click="handleTriggerAutoDraft"
            :disabled="isRunningAutoDraft"
            class="px-3.5 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-lg transition flex items-center justify-center gap-1.5 shadow-xs disabled:opacity-50"
          >
            <RefreshCw v-if="isRunningAutoDraft" class="w-3.5 h-3.5 animate-spin" />
            <Sliders v-else class="w-3.5 h-3.5" />
            Process Auto-Draft Now
          </button>
        </div>

        <div v-if="autoDraftStatus" class="mt-3 p-2.5 rounded-lg text-xs flex items-center gap-2" :class="autoDraftStatus.error ? 'bg-red-50 text-red-700 border border-red-200' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'">
          <AlertCircle v-if="autoDraftStatus.error" class="w-4 h-4 flex-shrink-0" />
          <CheckCircle2 v-else class="w-4 h-4 flex-shrink-0" />
          <span>{{ autoDraftStatus.text }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
