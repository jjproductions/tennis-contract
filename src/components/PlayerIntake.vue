<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '../supabase';
import { CheckCircle2, AlertTriangle, UserPlus, Users } from 'lucide-vue-next';

interface PlayerRecord {
  id?: string;
  full_name: string;
  email: string;
  singles_share: number;
  doubles_share: number;
  blackout_weeks: number[];
}

const emit = defineEmits(['registered']);

const registeredPlayers = ref<PlayerRecord[]>([]);
const fullName = ref('');
const email = ref('');
const singlesShare = ref<number>(0.5);
const doublesShare = ref<number>(0.5);
const selectedBlackouts = ref<number[]>([]);
const isSubmitting = ref(false);
const statusMessage = ref<{ text: string; error?: boolean } | null>(null);

const shareOptions = [
  { label: '0% (0 matches)', value: 0 },
  { label: '1/4 Share - 25% (6 matches)', value: 0.25 },
  { label: '1/2 Share - 50% (12 matches)', value: 0.5 },
  { label: '3/4 Share - 75% (18 matches)', value: 0.75 },
  { label: 'Full Share - 100% (24 matches)', value: 1.0 },
];

const loadRoster = async () => {
  const { data } = await supabase
    .from('players')
    .select('id, full_name, email, singles_share, doubles_share, blackout_weeks')
    .order('created_at', { ascending: true });
  if (data) registeredPlayers.value = data;
};

onMounted(loadRoster);

// Quota totals
const totalSingles = computed(() =>
  registeredPlayers.value.reduce((acc, p) => acc + Number(p.singles_share), 0)
);
const totalDoubles = computed(() =>
  registeredPlayers.value.reduce((acc, p) => acc + Number(p.doubles_share), 0)
);

const toggleBlackout = (week: number) => {
  if (selectedBlackouts.value.includes(week)) {
    selectedBlackouts.value = selectedBlackouts.value.filter((w) => w !== week);
  } else {
    selectedBlackouts.value.push(week);
  }
};

const handleRegister = async () => {
  if (!fullName.value.trim()) {
    statusMessage.value = { text: 'Please enter your full name.', error: true };
    return;
  }

  if (!email.value.trim()) {
    statusMessage.value = { text: 'Please enter a valid email address (required for portal login).', error: true };
    return;
  }

  isSubmitting.value = true;
  statusMessage.value = null;

  // Check if current user is logged in
  const { data: { session } } = await supabase.auth.getSession();
  const isSelfUpdate = session?.user?.email?.toLowerCase() === email.value.trim().toLowerCase();

  const payload: any = {
    full_name: fullName.value.trim(),
    email: email.value.trim(),
    singles_share: singlesShare.value,
    doubles_share: doublesShare.value,
    blackout_weeks: selectedBlackouts.value.sort((a, b) => a - b),
  };

  // New registrations default to pending approval
  if (!isSelfUpdate) {
    payload.approved = false;
  }

  // Upsert on full_name so players can update preferences
  const { error } = await supabase.from('players').upsert(payload, { onConflict: 'full_name' });

  isSubmitting.value = false;

  if (error) {
    statusMessage.value = { text: error.message, error: true };
  } else {
    if (isSelfUpdate) {
      statusMessage.value = { text: `Preferences updated successfully for ${fullName.value}!` };
    } else {
      statusMessage.value = { text: `Registration submitted for ${fullName.value}! Your submission is currently pending Admin approval.` };
    }
    fullName.value = '';
    email.value = '';
    selectedBlackouts.value = [];
    await loadRoster();
    emit('registered');
  }
};
</script>

<template>
  <div class="space-y-6">
    <!-- Quota & Capacity Status Board -->
    <div class="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
      <h2 class="text-base font-bold text-slate-800 flex items-center gap-2 mb-3">
        <Users class="w-5 h-5 text-indigo-600" />
        League Capacity Tracker ({{ registeredPlayers.length }}/14 Registered)
      </h2>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-- Singles Quota -->
        <div class="p-3 bg-slate-50 border rounded-lg">
          <div class="flex justify-between items-center mb-1 text-sm font-medium">
            <span>Singles Shares:</span>
            <span :class="totalSingles === 6.0 ? 'text-emerald-700 font-bold' : totalSingles > 6.0 ? 'text-rose-600 font-bold' : 'text-amber-600 font-bold'">
              {{ totalSingles.toFixed(2) }} / 6.00
            </span>
          </div>
          <div class="w-full bg-slate-200 rounded-full h-2">
            <div
              class="h-2 rounded-full transition-all"
              :class="totalSingles === 6.0 ? 'bg-emerald-500' : totalSingles > 6.0 ? 'bg-rose-500' : 'bg-amber-500'"
              :style="{ width: `${Math.min((totalSingles / 6.0) * 100, 100)}%` }"
            ></div>
          </div>
          <p class="text-[11px] text-slate-500 mt-1">Target: Exactly 6.0 shares (144 court spots)</p>
        </div>

        <!-- Doubles Quota -->
        <div class="p-3 bg-slate-50 border rounded-lg">
          <div class="flex justify-between items-center mb-1 text-sm font-medium">
            <span>Doubles Shares:</span>
            <span :class="totalDoubles === 8.0 ? 'text-emerald-700 font-bold' : totalDoubles > 8.0 ? 'text-rose-600 font-bold' : 'text-amber-600 font-bold'">
              {{ totalDoubles.toFixed(2) }} / 8.00
            </span>
          </div>
          <div class="w-full bg-slate-200 rounded-full h-2">
            <div
              class="h-2 rounded-full transition-all"
              :class="totalDoubles === 8.0 ? 'bg-emerald-500' : totalDoubles > 8.0 ? 'bg-rose-500' : 'bg-amber-500'"
              :style="{ width: `${Math.min((totalDoubles / 8.0) * 100, 100)}%` }"
            ></div>
          </div>
          <p class="text-[11px] text-slate-500 mt-1">Target: Exactly 8.0 shares (192 court spots)</p>
        </div>
      </div>
    </div>

    <!-- Intake Form -->
    <div class="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
      <h2 class="text-base font-bold text-slate-800 flex items-center gap-2 mb-4">
        <UserPlus class="w-5 h-5 text-blue-600" />
        Player Intake & Share Preferences
      </h2>

      <div class="space-y-4">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-semibold text-slate-700 mb-1">Full Name *</label>
            <input
              v-model="fullName"
              type="text"
              placeholder="e.g. Dave Miller"
              class="w-full border rounded-lg p-2 text-sm border-slate-300 focus:ring-2 focus:ring-blue-500 outline-none"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-700 mb-1">Email (Required for Login) *</label>
            <input
              v-model="email"
              type="email"
              placeholder="dave@example.com"
              class="w-full border rounded-lg p-2 text-sm border-slate-300 focus:ring-2 focus:ring-blue-500 outline-none"
            />
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-semibold text-slate-700 mb-1">Singles Commitment</label>
            <select
              v-model="singlesShare"
              class="w-full border rounded-lg p-2 text-sm border-slate-300 bg-white focus:ring-2 focus:ring-blue-500 outline-none"
            >
              <option v-for="opt in shareOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-700 mb-1">Doubles Commitment</label>
            <select
              v-model="doublesShare"
              class="w-full border rounded-lg p-2 text-sm border-slate-300 bg-white focus:ring-2 focus:ring-blue-500 outline-none"
            >
              <option v-for="opt in shareOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>
          </div>
        </div>

        <!-- Blackout Weeks Selector -->
        <div>
          <label class="block text-xs font-semibold text-slate-700 mb-1">
            Blackout Weeks (Select any weeks you know you will be away)
          </label>
          <div class="grid grid-cols-6 sm:grid-cols-12 gap-1.5 pt-1">
            <button
              v-for="w in 24"
              :key="w"
              type="button"
              @click="toggleBlackout(w)"
              :class="selectedBlackouts.includes(w) ? 'bg-rose-500 text-white border-rose-600' : 'bg-slate-100 text-slate-700 hover:bg-slate-200 border-slate-200'"
              class="text-xs font-medium py-1.5 rounded border transition text-center"
            >
              W{{ w }}
            </button>
          </div>
          <p class="text-[11px] text-slate-400 mt-1.5">
            Matches will not be scheduled for you on highlighted blackout weeks.
          </p>
        </div>

        <button
          @click="handleRegister"
          :disabled="isSubmitting"
          class="w-full py-2.5 px-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold text-sm rounded-lg shadow-sm transition disabled:opacity-50"
        >
          {{ isSubmitting ? 'Saving...' : 'Submit / Update Preferences' }}
        </button>

        <div
          v-if="statusMessage"
          class="p-3 rounded-lg text-xs flex items-center gap-2"
          :class="statusMessage.error ? 'bg-red-50 text-red-700 border border-red-200' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'"
        >
          <AlertTriangle v-if="statusMessage.error" class="w-4 h-4 flex-shrink-0" />
          <CheckCircle2 v-else class="w-4 h-4 flex-shrink-0" />
          <span>{{ statusMessage.text }}</span>
        </div>
      </div>
    </div>

    <!-- Registered Roster Table -->
    <div class="bg-white p-5 rounded-xl border border-slate-200 shadow-sm overflow-x-auto">
      <h3 class="text-sm font-bold text-slate-700 mb-3">Submitted Preferences Roster</h3>
      <table class="w-full text-xs text-left">
        <thead>
          <tr class="border-b text-slate-400">
            <th class="pb-2">Player</th>
            <th class="pb-2">Singles</th>
            <th class="pb-2">Doubles</th>
            <th class="pb-2">Total Matches</th>
            <th class="pb-2">Blackout Weeks</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="p in registeredPlayers" :key="p.id">
            <td class="py-2 font-semibold text-slate-800">{{ p.full_name }}</td>
            <td class="py-2">{{ (p.singles_share * 100).toFixed(0) }}% ({{ p.singles_share * 24 }})</td>
            <td class="py-2">{{ (p.doubles_share * 100).toFixed(0) }}% ({{ p.doubles_share * 24 }})</td>
            <td class="py-2 font-medium">{{ p.singles_share * 24 + p.doubles_share * 24 }}</td>
            <td class="py-2 text-slate-500">
              {{ p.blackout_weeks?.length ? p.blackout_weeks.map(w => `W${w}`).join(', ') : 'None' }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>