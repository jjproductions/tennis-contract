<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '../supabase';
import { CheckCircle2, AlertTriangle, UserPlus, Users, Pencil, X } from 'lucide-vue-next';
import { notifyNewPlayerIntake } from '../utils/discordNotifier';

interface PlayerRecord {
  id?: string;
  full_name: string;
  email: string;
  singles_share: number;
  doubles_share: number;
  blackout_weeks: number[];
  blackout_days?: string[];
}

const props = defineProps<{
  session?: any;
  isAdmin?: boolean;
}>();

const emit = defineEmits(['registered']);

const registeredPlayers = ref<PlayerRecord[]>([]);
const fullName = ref('');
const email = ref('');
const singlesShare = ref<number>(0.5);
const doublesShare = ref<number>(0.5);
const selectedBlackouts = ref<number[]>([]);
const selectedBlackoutDays = ref<string[]>([]);
const editingPlayerId = ref<string | null>(null);
const isSubmitting = ref(false);
const statusMessage = ref<{ text: string; error?: boolean } | null>(null);

const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const currentUserEmail = computed<string>(() =>
  (props.session?.user?.email || '').toLowerCase()
);

const canEditPlayer = (p: PlayerRecord): boolean => {
  if (props.isAdmin) return true;
  if (currentUserEmail.value && p.email?.toLowerCase() === currentUserEmail.value) return true;
  return false;
};

const formatSharePercentage = (share: number): string => {
  const pct = Number(share || 0) * 100;
  return (pct % 1 === 0 ? pct.toFixed(0) : pct.toFixed(1)) + '%';
};

const formatShareMatches = (share: number): number => {
  return Math.round(Number(share || 0) * 24);
};

const shareOptions = [
  { label: '0% (0 matches)', value: 0 },
  { label: '1/8 Share - 12.5% (3 matches)', value: 0.125 },
  { label: '1/4 Share - 25% (6 matches)', value: 0.25 },
  { label: '3/8 Share - 37.5% (9 matches)', value: 0.375 },
  { label: '1/2 Share - 50% (12 matches)', value: 0.5 },
  { label: '5/8 Share - 62.5% (15 matches)', value: 0.625 },
  { label: '3/4 Share - 75% (18 matches)', value: 0.75 },
  { label: '7/8 Share - 87.5% (21 matches)', value: 0.875 },
  { label: 'Full Share - 100% (24 matches)', value: 1.0 },
];

const loadRoster = async () => {
  const { data } = await supabase
    .from('players')
    .select('id, full_name, email, singles_share, doubles_share, blackout_weeks, blackout_days')
    .order('created_at', { ascending: true });
  if (data) {
    registeredPlayers.value = data;

    // If signed in, check if user matches a registered player to auto-prefill
    if (currentUserEmail.value && !editingPlayerId.value) {
      const userPlayer = data.find((p) => p.email.toLowerCase() === currentUserEmail.value);
      if (userPlayer) {
        editPlayer(userPlayer);
      }
    }
  }
};

const editPlayer = (p: PlayerRecord) => {
  if (!canEditPlayer(p)) {
    statusMessage.value = {
      text: `Permission denied: You can only edit your own preferences unless you are a League Admin.`,
      error: true,
    };
    return;
  }

  editingPlayerId.value = p.id || null;
  fullName.value = p.full_name;
  email.value = p.email;
  singlesShare.value = p.singles_share;
  doublesShare.value = p.doubles_share;
  selectedBlackouts.value = [...(p.blackout_weeks || [])];
  selectedBlackoutDays.value = [...(p.blackout_days || [])];
  statusMessage.value = { text: `Loaded saved preferences for ${p.full_name}. Update below and click Save.` };

  const formCard = document.getElementById('intake-form-card');
  if (formCard) formCard.scrollIntoView({ behavior: 'smooth' });
};

const cancelEdit = () => {
  editingPlayerId.value = null;
  fullName.value = '';
  email.value = '';
  singlesShare.value = 0.5;
  doublesShare.value = 0.5;
  selectedBlackouts.value = [];
  selectedBlackoutDays.value = [];
  statusMessage.value = null;
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

const toggleBlackoutDay = (day: string) => {
  if (selectedBlackoutDays.value.includes(day)) {
    selectedBlackoutDays.value = selectedBlackoutDays.value.filter((d) => d !== day);
  } else {
    selectedBlackoutDays.value.push(day);
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

  const targetName = fullName.value.trim().toLowerCase();
  const targetEmail = email.value.trim().toLowerCase();

  // Check if trying to edit an existing registered player
  const existingByName = registeredPlayers.value.find(
    (p) => p.full_name.toLowerCase() === targetName || p.email.toLowerCase() === targetEmail
  );

  if (existingByName) {
    const isAllowed = canEditPlayer(existingByName);
    if (!isAllowed) {
      isSubmitting.value = false;
      statusMessage.value = {
        text: `Permission denied: ${existingByName.full_name} is already registered. You cannot modify preferences for other players. Please sign in as ${existingByName.email} or contact an Admin.`,
        error: true,
      };
      return;
    }
  }

  const isSelfUpdate = currentUserEmail.value === targetEmail;

  const payload: any = {
    full_name: fullName.value.trim(),
    email: email.value.trim(),
    singles_share: singlesShare.value,
    doubles_share: doublesShare.value,
    blackout_weeks: selectedBlackouts.value.sort((a, b) => a - b),
    blackout_days: selectedBlackoutDays.value,
  };

  // New registrations default to pending approval
  if (!isSelfUpdate && !props.isAdmin) {
    payload.approved = false;
  }

  // Upsert on full_name so players can update preferences
  const { error } = await supabase.from('players').upsert(payload, { onConflict: 'full_name' });

  isSubmitting.value = false;

  if (error) {
    statusMessage.value = { text: error.message, error: true };
  } else {
    // Notify Discord channel
    notifyNewPlayerIntake({
      full_name: payload.full_name,
      email: payload.email,
      singles_share: payload.singles_share,
      doubles_share: payload.doubles_share,
      blackout_weeks: payload.blackout_weeks,
      blackout_days: payload.blackout_days,
    });

    if (isSelfUpdate || props.isAdmin) {
      statusMessage.value = { text: `Preferences saved successfully for ${fullName.value}!` };
    } else {
      statusMessage.value = { text: `Registration submitted for ${fullName.value}! Your submission is currently pending Admin approval.` };
    }
    fullName.value = '';
    email.value = '';
    selectedBlackouts.value = [];
    selectedBlackoutDays.value = [];
    editingPlayerId.value = null;
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
    <div id="intake-form-card" class="bg-white p-6 rounded-xl border border-slate-200 shadow-sm transition-all" :class="editingPlayerId ? 'ring-2 ring-blue-500 bg-blue-50/20' : ''">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-base font-bold text-slate-800 flex items-center gap-2">
          <Pencil v-if="editingPlayerId" class="w-5 h-5 text-amber-600" />
          <UserPlus v-else class="w-5 h-5 text-blue-600" />
          {{ editingPlayerId ? `Editing Preferences: ${fullName}` : 'Player Intake & Share Preferences' }}
        </h2>

        <button
          v-if="editingPlayerId"
          @click="cancelEdit"
          class="text-xs font-semibold px-2.5 py-1 bg-slate-200 hover:bg-slate-300 text-slate-700 rounded-lg transition flex items-center gap-1"
        >
          <X class="w-3.5 h-3.5" />
          Cancel Editing
        </button>
      </div>

      <div class="space-y-4">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label class="block text-xs font-semibold text-slate-700 mb-1">Full Name *</label>
            <input
              v-model="fullName"
              type="text"
              placeholder="e.g. Dave Miller"
              class="w-full border rounded-lg p-2 text-sm border-slate-300 focus:ring-2 focus:ring-blue-500 outline-none bg-white"
            />
          </div>
          <div>
            <label class="block text-xs font-semibold text-slate-700 mb-1">Email (Required for Login) *</label>
            <input
              v-model="email"
              type="email"
              placeholder="dave@example.com"
              class="w-full border rounded-lg p-2 text-sm border-slate-300 focus:ring-2 focus:ring-blue-500 outline-none bg-white"
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

        <!-- Blackout Days Selector (Day of Week) -->
        <div>
          <label class="block text-xs font-semibold text-slate-700 mb-1">
            Blackout Days (Select specific days of the week you CANNOT play)
          </label>
          <div class="flex flex-wrap gap-1.5 pt-1">
            <button
              v-for="day in daysOfWeek"
              :key="day"
              type="button"
              @click="toggleBlackoutDay(day)"
              :class="selectedBlackoutDays.includes(day) ? 'bg-amber-500 text-white border-amber-600' : 'bg-slate-100 text-slate-700 hover:bg-slate-200 border-slate-200'"
              class="text-xs font-medium px-3 py-1.5 rounded-lg border transition text-center"
            >
              {{ day }}s
            </button>
          </div>
          <p class="text-[11px] text-slate-400 mt-1.5">
            You will not be scheduled for matches on highlighted blackout days.
          </p>
        </div>

        <!-- Blackout Weeks Selector -->
        <div>
          <label class="block text-xs font-semibold text-slate-700 mb-1">
            Blackout Weeks (Select any full weeks you know you will be away)
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

        <div class="flex gap-2">
          <button
            @click="handleRegister"
            :disabled="isSubmitting"
            class="flex-1 py-2.5 px-4 text-white font-semibold text-sm rounded-lg shadow-sm transition disabled:opacity-50"
            :class="editingPlayerId ? 'bg-amber-600 hover:bg-amber-700' : 'bg-blue-600 hover:bg-blue-700'"
          >
            {{ isSubmitting ? 'Saving...' : editingPlayerId ? 'Save Updated Preferences' : 'Submit Preferences' }}
          </button>
          <button
            v-if="editingPlayerId"
            @click="cancelEdit"
            type="button"
            class="px-4 py-2.5 bg-slate-200 hover:bg-slate-300 text-slate-700 font-semibold text-sm rounded-lg transition"
          >
            Cancel
          </button>
        </div>

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
            <th class="pb-2">Blackout Days</th>
            <th class="pb-2">Blackout Weeks</th>
            <th class="pb-2 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="p in registeredPlayers" :key="p.id" :class="editingPlayerId === p.id ? 'bg-amber-50/60 font-medium' : ''">
            <td class="py-2 font-semibold text-slate-800 flex items-center gap-1.5">
              <span>{{ p.full_name }}</span>
              <span v-if="editingPlayerId === p.id" class="text-[9px] bg-amber-200 text-amber-800 px-1.5 py-0.5 rounded font-bold">
                Editing
              </span>
            </td>
            <td class="py-2">{{ formatSharePercentage(p.singles_share) }} ({{ formatShareMatches(p.singles_share) }})</td>
            <td class="py-2">{{ formatSharePercentage(p.doubles_share) }} ({{ formatShareMatches(p.doubles_share) }})</td>
            <td class="py-2 font-medium">{{ formatShareMatches(p.singles_share) + formatShareMatches(p.doubles_share) }}</td>
            <td class="py-2 text-slate-500">
              {{ p.blackout_days?.length ? p.blackout_days.join(', ') : 'None' }}
            </td>
            <td class="py-2 text-slate-500">
              {{ p.blackout_weeks?.length ? p.blackout_weeks.map(w => `W${w}`).join(', ') : 'None' }}
            </td>
            <td class="py-2 text-right">
              <button
                v-if="canEditPlayer(p)"
                @click="editPlayer(p)"
                class="px-2.5 py-1 text-xs font-semibold rounded-lg border transition flex items-center gap-1 ml-auto"
                :class="editingPlayerId === p.id ? 'bg-amber-600 text-white border-amber-600' : 'bg-slate-100 hover:bg-blue-50 text-slate-700 hover:text-blue-700 border-slate-200'"
              >
                <Pencil class="w-3 h-3" />
                {{ editingPlayerId === p.id ? 'Editing...' : 'Edit' }}
              </button>
              <span v-else class="text-[11px] text-slate-300 italic select-none">
                —
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>