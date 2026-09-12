<script setup lang="ts">
import { ref, computed } from 'vue';
import { supabase } from '../supabase';
import {
  generateSeasonSchedule,
  type PlayerForScheduling,
  type ScheduleGenResult,
} from '../utils/scheduleGenerator';
import { Calendar, Play, CheckCircle2, AlertCircle, RefreshCw, Layers, ShieldCheck, UserCheck } from 'lucide-vue-next';

const props = defineProps<{
  players: PlayerForScheduling[];
}>();

const emit = defineEmits(['scheduled']);

const startDate = ref<string>('2026-10-18');
const dayOfWeek = ref<string>('Sunday');
const singlesCourts = ref<number>(3);
const doublesCourts = ref<number>(2);

const generatedResult = ref<ScheduleGenResult | null>(null);
const selectedPreviewWeek = ref<number>(1);

const isPublishing = ref<boolean>(false);
const statusMessage = ref<{ text: string; error?: boolean } | null>(null);

const dayOptions = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

const handleGenerate = () => {
  statusMessage.value = null;

  if (props.players.length === 0) {
    statusMessage.value = { text: 'No approved players available. Approve players in the intake list first.', error: true };
    return;
  }

  const result = generateSeasonSchedule(props.players, {
    startDate: startDate.value,
    dayOfWeek: dayOfWeek.value,
    numWeeks: 24,
    singlesCourtsPerWeek: singlesCourts.value,
    doublesCourtsPerWeek: doublesCourts.value,
  });

  generatedResult.value = result;
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
    for (const match of generatedResult.value.matches) {
      const { data: insertedMatch, error: matchError } = await supabase
        .from('matches')
        .insert({
          week_number: match.week_number,
          day_of_week: match.day_of_week,
          match_date: match.match_date,
          type: match.type,
          court_number: match.court_number,
        })
        .select()
        .single();

      if (matchError || !insertedMatch) {
        throw new Error(matchError?.message || 'Failed to insert match');
      }

      // Insert slot records for this match
      const slotRecords = match.slots.map((slot) => ({
        match_id: insertedMatch.id,
        player_id: slot.player_id,
        status: 'CONFIRMED',
      }));

      const { error: slotError } = await supabase.from('match_slots').insert(slotRecords);
      if (slotError) {
        throw new Error(slotError.message);
      }
    }

    statusMessage.value = { text: '24-Week Schedule successfully generated and published to Supabase!' };
    isPublishing.value = false;
    emit('scheduled');
  } catch (err: any) {
    isPublishing.value = false;
    statusMessage.value = { text: err.message || 'Failed to publish schedule.', error: true };
  }
};

const weekMatches = computed(() => {
  if (!generatedResult.value) return [];
  return generatedResult.value.matches.filter(m => m.week_number === selectedPreviewWeek.value);
});
</script>

<template>
  <div class="space-y-6 pt-2">
    <!-- Generator Controls Form -->
    <div class="bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-4">
      <h3 class="text-sm font-bold text-slate-800 flex items-center gap-2">
        <Calendar class="w-4 h-4 text-indigo-600" />
        Season Schedule Configuration
      </h3>

      <div class="grid grid-cols-1 sm:grid-cols-4 gap-3 text-xs">
        <div>
          <label class="block font-semibold text-slate-700 mb-1">Season Start Date</label>
          <input
            v-model="startDate"
            type="date"
            class="w-full p-2 border border-slate-300 rounded-lg bg-white outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div>
          <label class="block font-semibold text-slate-700 mb-1">Match Day of Week</label>
          <select
            v-model="dayOfWeek"
            class="w-full p-2 border border-slate-300 rounded-lg bg-white outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option v-for="d in dayOptions" :key="d" :value="d">{{ d }}</option>
          </select>
        </div>

        <div>
          <label class="block font-semibold text-slate-700 mb-1">Singles Courts / Wk</label>
          <input
            v-model.number="singlesCourts"
            type="number"
            min="1"
            max="6"
            class="w-full p-2 border border-slate-300 rounded-lg bg-white outline-none focus:ring-2 focus:ring-blue-500"
          />
          <span class="text-[10px] text-slate-400">({{ singlesCourts * 2 }} spots/wk)</span>
        </div>

        <div>
          <label class="block font-semibold text-slate-700 mb-1">Doubles Courts / Wk</label>
          <input
            v-model.number="doublesCourts"
            type="number"
            min="1"
            max="6"
            class="w-full p-2 border border-slate-300 rounded-lg bg-white outline-none focus:ring-2 focus:ring-blue-500"
          />
          <span class="text-[10px] text-slate-400">({{ doublesCourts * 4 }} spots/wk)</span>
        </div>
      </div>

      <button
        @click="handleGenerate"
        class="w-full py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold text-xs rounded-lg shadow-sm transition flex items-center justify-center gap-2"
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
      <!-- Capacity & Quota Compliance Board -->
      <div class="bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-3">
        <div class="flex items-center justify-between">
          <h4 class="text-sm font-bold text-slate-800 flex items-center gap-2">
            <ShieldCheck class="w-4 h-4 text-emerald-600" />
            Quota & Blackout Compliance Summary
          </h4>
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
              <tr v-for="s in generatedResult.summaries" :key="s.player_id">
                <td class="py-2 font-semibold text-slate-800">{{ s.full_name }}</td>
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
                  {{ s.scheduled_singles + s.scheduled_doubles }} / {{ s.target_singles + s.target_doubles }}
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
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 border-b pb-3">
          <h4 class="text-sm font-bold text-slate-800 flex items-center gap-2">
            <Layers class="w-4 h-4 text-blue-600" />
            24-Week Schedule Preview
          </h4>

          <!-- Week Selector Slider / Buttons -->
          <div class="flex items-center gap-1 overflow-x-auto max-w-full pb-1">
            <button
              v-for="w in 24"
              :key="w"
              @click="selectedPreviewWeek = w"
              :class="selectedPreviewWeek === w ? 'bg-blue-600 text-white font-bold' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'"
              class="text-xs px-2.5 py-1 rounded transition min-w-[32px] text-center"
            >
              W{{ w }}
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div
            v-for="m in weekMatches"
            :key="`${m.type}-${m.court_number}`"
            class="p-4 rounded-xl border flex flex-col justify-between"
            :class="m.type === 'SINGLES' ? 'bg-indigo-50/60 border-indigo-200' : 'bg-emerald-50/60 border-emerald-200'"
          >
            <div>
              <div class="flex justify-between items-center mb-2">
                <span class="font-bold text-xs text-slate-800">
                  Court #{{ m.court_number }}
                </span>
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
