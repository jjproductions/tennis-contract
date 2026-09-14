<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '../supabase';
import { ShieldCheck, ShieldAlert, Check, X, AlertCircle, Users, CheckCircle2, Calendar, Radio, Send, Save, Bell, RefreshCw, ToggleLeft, ToggleRight, Settings2 } from 'lucide-vue-next';
import ScheduleGeneratorModal from './ScheduleGeneratorModal.vue';
import {
  testDiscordWebhook,
  sendCustomBroadcast,
  notifyPlayerApproved,
  getNotificationConfig,
  fetchGlobalDiscordSettings,
  saveGlobalDiscordSettings,
  type DiscordNotificationConfig,
} from '../utils/discordNotifier';

interface PlayerRecord {
  id: string;
  full_name: string;
  email: string;
  singles_share: number;
  doubles_share: number;
  blackout_weeks: number[];
  approved?: boolean;
  is_admin?: boolean;
}

const props = defineProps<{
  pendingPlayers: PlayerRecord[];
}>();

const emit = defineEmits(['updated']);

const allPlayers = ref<PlayerRecord[]>([]);
const processingId = ref<string | null>(null);
const actionError = ref<string | null>(null);
const activeTab = ref<'pending' | 'roster' | 'generator' | 'discord'>('pending');

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

onMounted(async () => {
  fetchRoster();
  const globalSettings = await fetchGlobalDiscordSettings();
  webhookUrlInput.value = globalSettings.webhook_url;
  eventConfig.value = globalSettings.events;
});

const approvedPlayers = computed(() => {
  return allPlayers.value.filter((p) => p.approved !== false);
});

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
</script>

<template>
  <div class="bg-white border border-slate-200 rounded-xl p-5 mb-6 shadow-sm">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 pb-3 border-b border-slate-200">
      <h3 class="text-sm font-bold text-slate-800 flex items-center gap-2">
        <ShieldCheck class="w-5 h-5 text-indigo-600" />
        Admin Control Panel
      </h3>

      <!-- Sub-tabs -->
      <div class="flex gap-2">
        <button
          @click="activeTab = 'pending'"
          :class="activeTab === 'pending' ? 'bg-amber-100 text-amber-900 border-amber-300 font-bold' : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border-slate-200'"
          class="text-xs px-3 py-1 rounded-lg border transition flex items-center gap-1.5"
        >
          <ShieldAlert class="w-3.5 h-3.5 text-amber-600" />
          Pending Requests ({{ pendingPlayers.length }})
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
      </div>
    </div>

    <!-- Error Banner -->
    <div v-if="actionError" class="mt-3 p-2.5 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700 flex items-center gap-2">
      <AlertCircle class="w-4 h-4 flex-shrink-0" />
      <span>{{ actionError }}</span>
    </div>

    <!-- TAB 1: PENDING APPROVALS -->
    <div v-if="activeTab === 'pending'" class="pt-4">
      <div v-if="pendingPlayers.length === 0" class="p-4 bg-emerald-50 border border-emerald-200 rounded-lg text-xs text-emerald-700 flex items-center gap-2">
        <CheckCircle2 class="w-4 h-4 text-emerald-600 flex-shrink-0" />
        <span>All player registrations approved! There are 0 pending requests right now.</span>
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
              Singles: <span class="font-medium text-slate-700">{{ (p.singles_share * 100).toFixed(0) }}%</span> • 
              Doubles: <span class="font-medium text-slate-700">{{ (p.doubles_share * 100).toFixed(0) }}%</span> • 
              Blackouts: <span class="text-slate-600">{{ p.blackout_weeks?.length ? p.blackout_weeks.map(w => `W${w}`).join(', ') : 'None' }}</span>
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
  </div>
</template>
