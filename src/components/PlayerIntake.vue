<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { supabase } from '../supabase';
import { CheckCircle2, AlertTriangle, UserPlus, Users, Pencil, X, Lock } from 'lucide-vue-next';
import { notifyNewPlayerIntake } from '../utils/discordNotifier';

interface PlayerRecord {
  id?: string;
  full_name: string;
  email: string;
  singles_share: number;
  doubles_share: number;
  blackout_weeks: number[];
  blackout_days?: string[];
  approved?: boolean;
}

const props = defineProps<{
  session?: any;
  isAdmin?: boolean;
  hasPublishedSchedule?: boolean;
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

const activeRosterPlayer = computed<PlayerRecord | undefined>(() => {
  if (!currentUserEmail.value) return undefined;
  return registeredPlayers.value.find(
    (p) => p.email?.toLowerCase() === currentUserEmail.value && p.approved !== false
  );
});

const isSelfLocked = computed<boolean>(() => {
  if (props.isAdmin) return false;
  return Boolean(props.hasPublishedSchedule && activeRosterPlayer.value);
});

const canEditPlayer = (p: PlayerRecord): boolean => {
  if (props.isAdmin) return true;
  // If schedule is active and player is an approved member, commitments are fixed for non-admins
  if (props.hasPublishedSchedule && p.approved !== false) return false;
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

const getFirstName = (fullName: string): string => {
  if (!fullName) return '';
  const parts = fullName.trim().split(/\s+/);
  return parts[0] || '';
};

const getLastName = (fullName: string): string => {
  if (!fullName) return '';
  const parts = fullName.trim().split(/\s+/);
  return parts.length > 1 ? parts.slice(1).join(' ') : '';
};

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
  { label: '1 1/8 Share - 112.5% (27 matches)', value: 1.125 },
  { label: '1 1/4 Share - 125% (30 matches)', value: 1.25 },
  { label: '1 1/2 Share - 150% (36 matches)', value: 1.5 },
  { label: '1 3/4 Share - 175% (42 matches)', value: 1.75 },
  { label: 'Double Share - 200% (48 matches)', value: 2.0 },
];

// Helper to normalize and snap any numeric/string/floating point share to an exact number
const snapToShare = (val: any): number => {
  if (val === null || val === undefined || val === '') return 0;
  const num = Number(val);
  if (isNaN(num)) return 0;
  const match = shareOptions.find((opt) => Math.abs(opt.value - num) < 0.005);
  return match ? match.value : num;
};

// Generates option list ensuring any non-standard or legacy share value has a matching option in the select
const getAvailableShareOptions = (currentVal: number) => {
  const normalized = Number(currentVal ?? 0);
  const exists = shareOptions.some((opt) => Math.abs(opt.value - normalized) < 0.005);
  if (exists) {
    return shareOptions;
  }
  const customOption = {
    label: `Custom: ${formatSharePercentage(normalized)} (${formatShareMatches(normalized)} matches)`,
    value: normalized,
  };
  return [...shareOptions, customOption].sort((a, b) => a.value - b.value);
};

const singlesShareOptions = computed(() => getAvailableShareOptions(singlesShare.value));
const doublesShareOptions = computed(() => getAvailableShareOptions(doublesShare.value));

const loadRoster = async () => {
  const { data } = await supabase
    .from('players')
    .select('id, full_name, email, singles_share, doubles_share, blackout_weeks, blackout_days, approved')
    .order('created_at', { ascending: true });
  if (data) {
    registeredPlayers.value = data;

    // If signed in, check if user matches a registered player to auto-prefill (only if allowed to edit)
    if (currentUserEmail.value && !editingPlayerId.value) {
      const userPlayer = data.find((p) => p.email.toLowerCase() === currentUserEmail.value);
      if (userPlayer && canEditPlayer(userPlayer)) {
        editPlayer(userPlayer);
      }
    }
  }
};

const editPlayer = (p: PlayerRecord) => {
  if (!canEditPlayer(p)) {
    const errorText = (props.hasPublishedSchedule && p.approved !== false && !props.isAdmin)
      ? `Season schedule is active. Existing player commitments for ${p.full_name} are fixed. Please contact a League Admin to adjust.`
      : `Permission denied: You can only edit your own preferences unless you are a League Admin.`;
    statusMessage.value = {
      text: errorText,
      error: true,
    };
    return;
  }

  editingPlayerId.value = p.id || null;
  fullName.value = p.full_name;
  email.value = p.email;
  singlesShare.value = snapToShare(p.singles_share);
  doublesShare.value = snapToShare(p.doubles_share);
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

// Sort registered players: 0 total shares last, then alphabetical by last name
const sortedRegisteredPlayers = computed(() => {
  return [...registeredPlayers.value].sort((a, b) => {
    const totalSharesA = Number(a.singles_share || 0) + Number(a.doubles_share || 0);
    const totalSharesB = Number(b.singles_share || 0) + Number(b.doubles_share || 0);

    // 0 total matches goes at the very end
    if (totalSharesA === 0 && totalSharesB !== 0) return 1;
    if (totalSharesB === 0 && totalSharesA !== 0) return -1;

    // Alphabetical by last name (fallback to first name if no last name)
    const lastNameA = getLastName(a.full_name).toLowerCase() || a.full_name.toLowerCase();
    const lastNameB = getLastName(b.full_name).toLowerCase() || b.full_name.toLowerCase();

    if (lastNameA < lastNameB) return -1;
    if (lastNameA > lastNameB) return 1;
    return 0;
  });
});

// Active players with share > 0%
const activeRegisteredPlayers = computed(() =>
  registeredPlayers.value.filter(
    (p) => Number(p.singles_share || 0) > 0 || Number(p.doubles_share || 0) > 0
  )
);

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
      const deniedMessage = (props.hasPublishedSchedule && existingByName.approved !== false && !props.isAdmin)
        ? `Season schedule is active. Existing player commitments for ${existingByName.full_name} are fixed. Please contact a League Administrator to request changes.`
        : `Permission denied: ${existingByName.full_name} is already registered. You cannot modify preferences for other players. Please sign in as ${existingByName.email} or contact an Admin.`;
      statusMessage.value = {
        text: deniedMessage,
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

  // If editing an existing player, update by primary key ID; otherwise insert/upsert new registration
  let updateError: any = null;
  if (editingPlayerId.value) {
    const { error: err } = await supabase
      .from('players')
      .update(payload)
      .eq('id', editingPlayerId.value);
    updateError = err;
  } else {
    const { error: err } = await supabase
      .from('players')
      .upsert(payload, { onConflict: 'full_name' });
    updateError = err;
  }

  isSubmitting.value = false;

  if (updateError) {
    statusMessage.value = { text: updateError.message, error: true };
  } else {
    // Notify Discord admin channel
    const isUpdateAction = isSelfUpdate || props.isAdmin || !!editingPlayerId.value;
    notifyNewPlayerIntake(
      {
        full_name: payload.full_name,
        email: payload.email,
        singles_share: payload.singles_share,
        doubles_share: payload.doubles_share,
        blackout_weeks: payload.blackout_weeks,
        blackout_days: payload.blackout_days,
      },
      isUpdateAction
    );

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
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-3">
        <h2 class="text-base font-bold text-slate-800 flex items-center gap-2">
          <Users class="w-5 h-5 text-indigo-600" />
          League Capacity & Demand Tracker
        </h2>
        <span class="text-xs font-medium text-slate-500">
          {{ activeRegisteredPlayers.length }} Players Registered
        </span>
      </div>

      <!-- Capacity Alert Notice -->
      <div v-if="(totalSingles + totalDoubles) > 14.0" class="mb-3 p-2.5 bg-rose-50 border border-rose-200 rounded-lg text-xs text-rose-800 flex items-center gap-2 font-medium">
        <AlertTriangle class="w-4 h-4 text-rose-600 flex-shrink-0" />
        <span>Demand is over court capacity by {{ ((totalSingles + totalDoubles) - 14.0).toFixed(2) }} shares. Adjust player shares in the roster table below to balance.</span>
      </div>
      <div v-else-if="(totalSingles + totalDoubles) === 14.0" class="mb-3 p-2.5 bg-emerald-50 border border-emerald-200 rounded-lg text-xs text-emerald-800 flex items-center gap-2 font-medium">
        <CheckCircle2 class="w-4 h-4 text-emerald-600 flex-shrink-0" />
        <span>League court capacity is perfectly balanced at 14.00 total shares!</span>
      </div>
      <div v-else class="mb-3 p-2.5 bg-amber-50 border border-amber-200 rounded-lg text-xs text-amber-800 flex items-center gap-2 font-medium">
        <AlertTriangle class="w-4 h-4 text-amber-600 flex-shrink-0" />
        <span>{{ (14.0 - (totalSingles + totalDoubles)).toFixed(2) }} shares remaining to reach full 14.00 court capacity.</span>
      </div>

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

    <!-- Active Player Confirmed Roster Commitments Card (When Season is Live) -->
    <div v-if="isSelfLocked && activeRosterPlayer" class="bg-white p-5 rounded-xl border border-blue-200 bg-gradient-to-br from-white to-blue-50/30 shadow-sm space-y-3">
      <div class="flex items-start justify-between gap-3">
        <div class="flex items-start gap-3">
          <div class="p-2.5 bg-blue-100 text-blue-700 rounded-xl flex-shrink-0 mt-0.5">
            <Lock class="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <div class="flex items-center gap-2 flex-wrap">
              <h3 class="text-sm font-bold text-slate-900">Your Season Commitments are Fixed</h3>
              <span class="text-[10px] font-bold px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded-md border border-emerald-200">
                Active Member
              </span>
            </div>
            <p class="text-xs text-slate-600 mt-1 leading-relaxed">
              The season schedule is live. Your share commitments and blackout dates are fixed to guarantee league operational balance. To offer your spot for a match, please use the Sub Board. To adjust contracted shares, contact a League Administrator.
            </p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 sm:grid-cols-4 gap-2.5 pt-2 border-t border-blue-100/80 text-xs">
        <div class="p-2.5 bg-white/80 rounded-lg border border-slate-200/70">
          <span class="text-[10px] text-slate-400 font-semibold block uppercase">Singles Share</span>
          <span class="font-bold text-slate-900 text-sm">{{ formatSharePercentage(activeRosterPlayer.singles_share) }}</span>
          <span class="text-[10px] text-slate-500 ml-1">({{ formatShareMatches(activeRosterPlayer.singles_share) }} matches)</span>
        </div>
        <div class="p-2.5 bg-white/80 rounded-lg border border-slate-200/70">
          <span class="text-[10px] text-slate-400 font-semibold block uppercase">Doubles Share</span>
          <span class="font-bold text-slate-900 text-sm">{{ formatSharePercentage(activeRosterPlayer.doubles_share) }}</span>
          <span class="text-[10px] text-slate-500 ml-1">({{ formatShareMatches(activeRosterPlayer.doubles_share) }} matches)</span>
        </div>
        <div class="p-2.5 bg-white/80 rounded-lg border border-slate-200/70">
          <span class="text-[10px] text-slate-400 font-semibold block uppercase">Blackout Days</span>
          <span class="font-semibold text-slate-800">{{ activeRosterPlayer.blackout_days?.length ? activeRosterPlayer.blackout_days.join(', ') : 'None' }}</span>
        </div>
        <div class="p-2.5 bg-white/80 rounded-lg border border-slate-200/70">
          <span class="text-[10px] text-slate-400 font-semibold block uppercase">Blackout Weeks</span>
          <span class="font-semibold text-slate-800">{{ activeRosterPlayer.blackout_weeks?.length ? getBlackoutWeekRanges(activeRosterPlayer.blackout_weeks).join(', ') : 'None' }}</span>
        </div>
      </div>
    </div>

    <!-- Intake Form -->
    <div id="intake-form-card" class="bg-white p-6 rounded-xl border border-slate-200 shadow-sm transition-all" :class="editingPlayerId ? 'ring-2 ring-blue-500 bg-blue-50/20' : ''">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-base font-bold text-slate-800 flex items-center gap-2">
          <Pencil v-if="editingPlayerId && props.isAdmin" class="w-5 h-5 text-amber-600" />
          <UserPlus v-else class="w-5 h-5 text-blue-600" />
          <span v-if="editingPlayerId && props.isAdmin">Admin Override: Editing Preferences for {{ fullName }}</span>
          <span v-else-if="props.hasPublishedSchedule">New Player Intake & Substitute Pool Registration</span>
          <span v-else>Player Intake & Share Preferences</span>
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

      <div v-if="props.hasPublishedSchedule && !editingPlayerId" class="mb-4 p-2.5 bg-blue-50 border border-blue-200 rounded-lg text-xs text-blue-800 flex items-center gap-2 font-medium">
        <Users class="w-4 h-4 text-blue-600 flex-shrink-0" />
        <span>The season schedule is active. New submissions will be placed in the Substitute Pool & Waitlist for Admin approval.</span>
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
              <option v-for="opt in singlesShareOptions" :key="opt.value" :value="opt.value">
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
              <option v-for="opt in doublesShareOptions" :key="opt.value" :value="opt.value">
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
            {{ isSubmitting ? 'Saving...' : editingPlayerId ? 'Save Updated Preferences' : props.hasPublishedSchedule ? 'Submit Application for Admin Review' : 'Submit Preferences' }}
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
      <table class="w-full text-xs text-left border-collapse">
        <thead>
          <tr class="border-b border-slate-200 text-slate-400 font-semibold">
            <th class="pb-2 px-2">Player</th>
            <th class="pb-2 px-2 whitespace-nowrap">Singles</th>
            <th class="pb-2 px-2 whitespace-nowrap">Doubles</th>
            <th class="pb-2 px-2 whitespace-nowrap text-center">Total Matches</th>
            <th class="pb-2 px-2 whitespace-nowrap">Blackout Days</th>
            <th class="pb-2 px-2 whitespace-nowrap">Blackout Weeks</th>
            <th class="pb-2 px-2 text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="p in sortedRegisteredPlayers" :key="p.id" :class="editingPlayerId === p.id ? 'bg-amber-50/60 font-medium' : ''">
            <td class="py-2.5 px-2 font-semibold text-slate-800 align-top">
              <div class="leading-tight">
                <div class="text-slate-900 font-bold">{{ getFirstName(p.full_name) }}</div>
                <div v-if="getLastName(p.full_name)" class="text-slate-600 font-medium">{{ getLastName(p.full_name) }}</div>
              </div>
              <span v-if="editingPlayerId === p.id" class="text-[9px] bg-amber-200 text-amber-800 px-1.5 py-0.5 rounded font-bold inline-block mt-1">
                Editing
              </span>
            </td>
            <td class="py-2.5 px-2 align-top whitespace-nowrap">
              <div class="font-semibold text-slate-800">{{ formatSharePercentage(p.singles_share) }}</div>
              <div class="text-[10px] text-slate-400">({{ formatShareMatches(p.singles_share) }})</div>
            </td>
            <td class="py-2.5 px-2 align-top whitespace-nowrap">
              <div class="font-semibold text-slate-800">{{ formatSharePercentage(p.doubles_share) }}</div>
              <div class="text-[10px] text-slate-400">({{ formatShareMatches(p.doubles_share) }})</div>
            </td>
            <td class="py-2.5 px-2 align-top text-center whitespace-nowrap font-bold text-slate-700">
              {{ formatShareMatches(p.singles_share) + formatShareMatches(p.doubles_share) }}
            </td>
            <td class="py-2.5 px-2 align-top">
              <div v-if="p.blackout_days?.length" class="flex flex-wrap gap-1">
                <span
                  v-for="d in p.blackout_days"
                  :key="d"
                  class="bg-amber-100 text-amber-800 text-[10px] font-semibold px-1.5 py-0.5 rounded"
                >
                  {{ d }}
                </span>
              </div>
              <span v-else class="text-slate-300 select-none">—</span>
            </td>
            <td class="py-2.5 px-2 align-top">
              <div v-if="p.blackout_weeks?.length" class="flex flex-wrap gap-1">
                <span
                  v-for="range in getBlackoutWeekRanges(p.blackout_weeks)"
                  :key="range"
                  class="bg-rose-100 text-rose-700 text-[10px] font-semibold px-1.5 py-0.5 rounded"
                >
                  {{ range }}
                </span>
              </div>
              <span v-else class="text-slate-300 select-none">—</span>
            </td>
            <td class="py-2.5 px-2 text-right align-top">
              <button
                v-if="canEditPlayer(p)"
                @click="editPlayer(p)"
                class="px-2.5 py-1 text-xs font-semibold rounded-lg border transition flex items-center gap-1 ml-auto"
                :class="editingPlayerId === p.id ? 'bg-amber-600 text-white border-amber-600' : 'bg-slate-100 hover:bg-blue-50 text-slate-700 hover:text-blue-700 border-slate-200'"
              >
                <Pencil class="w-3 h-3" />
                {{ editingPlayerId === p.id ? 'Editing...' : 'Edit' }}
              </button>
              <span
                v-else-if="props.hasPublishedSchedule && p.approved !== false"
                class="inline-flex items-center gap-1 text-[10px] text-slate-400 font-semibold px-2 py-0.5 bg-slate-100 rounded border border-slate-200/80"
                title="Commitments are locked while season schedule is active"
              >
                <Lock class="w-2.5 h-2.5 text-slate-400" />
                Fixed
              </span>
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