<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { supabase } from '../supabase';
import { ShieldCheck, ShieldAlert, Check, X, AlertCircle, Users, CheckCircle2 } from 'lucide-vue-next';

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
const activeTab = ref<'pending' | 'roster'>('pending');

const fetchRoster = async () => {
  const { data } = await supabase
    .from('players')
    .select('*')
    .order('full_name', { ascending: true });
  if (data) allPlayers.value = data;
};

onMounted(fetchRoster);

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
          Manage League Roster
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
  </div>
</template>
