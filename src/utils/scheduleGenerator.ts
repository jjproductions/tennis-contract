export interface PlayerForScheduling {
  id: string;
  full_name: string;
  email?: string;
  singles_share: number;
  doubles_share: number;
  blackout_weeks: number[];
  blackout_days?: string[];
}

export interface DayCourtConfig {
  dayOfWeek: 'Sunday' | 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | string;
  singlesCourts: number;
  doublesCourts: number;
}

const DAY_ORDER: Record<string, number> = {
  sunday: 0,
  monday: 1,
  tuesday: 2,
  wednesday: 3,
  thursday: 4,
  friday: 5,
  saturday: 6,
};

export function getDayOrderIndex(day: string): number {
  if (!day) return 99;
  const lower = day.toLowerCase().trim();
  return DAY_ORDER[lower] ?? 99;
}

export interface MatchLike {
  week_number: number;
  day_of_week?: string;
  match_date?: string;
  type?: 'SINGLES' | 'DOUBLES' | string;
  court_number?: number;
}

export function compareMatches<T extends MatchLike>(a: T, b: T): number {
  // 1. Week number ascending
  if (a.week_number !== b.week_number) {
    return a.week_number - b.week_number;
  }

  // 2. Days together (ordered chronologically by match_date if present, else day_of_week index)
  if (a.match_date && b.match_date && a.match_date !== b.match_date) {
    const dateComp = a.match_date.localeCompare(b.match_date);
    if (dateComp !== 0) return dateComp;
  } else {
    const dayIdxA = getDayOrderIndex(a.day_of_week || '');
    const dayIdxB = getDayOrderIndex(b.day_of_week || '');
    if (dayIdxA !== dayIdxB) {
      return dayIdxA - dayIdxB;
    }
  }

  // 3. Match type: SINGLES first, then DOUBLES
  const typeA = (a.type || '').toUpperCase();
  const typeB = (b.type || '').toUpperCase();
  if (typeA !== typeB) {
    if (typeA === 'SINGLES') return -1;
    if (typeB === 'SINGLES') return 1;
    return typeA.localeCompare(typeB);
  }

  // 4. Court number ascending
  const courtA = a.court_number ?? 0;
  const courtB = b.court_number ?? 0;
  return courtA - courtB;
}

export function formatDayOfWeek(day: string): string {
  if (!day) return '';
  const lower = day.toLowerCase();
  return lower.charAt(0).toUpperCase() + lower.slice(1);
}

export interface GeneratedSlot {
  player_id: string;
  player_name: string;
}

export interface GeneratedMatch {
  week_number: number;
  day_of_week: string;
  match_date: string;
  type: 'SINGLES' | 'DOUBLES';
  court_number: number;
  slots: GeneratedSlot[];
}

export interface PlayerQuotaSummary {
  player_id: string;
  full_name: string;
  target_singles: number;
  scheduled_singles: number;
  target_doubles: number;
  scheduled_doubles: number;
  blackout_count: number;
}

export interface ScheduleGenResult {
  matches: GeneratedMatch[];
  summaries: PlayerQuotaSummary[];
  totalSpotsNeeded: { singles: number; doubles: number };
  totalSpotsScheduled: { singles: number; doubles: number };
  weeklyCourtsCount: number;
}

export interface ScheduleGenOptions {
  startDate: string; // YYYY-MM-DD (e.g. Week 1 start date)
  numWeeks?: number; // 24
  dailySchedule?: DayCourtConfig[];
  // Legacy / fallback single-day options
  dayOfWeek?: string;
  singlesCourtsPerWeek?: number;
  doublesCourtsPerWeek?: number;
}

const DAY_INDEXES: Record<string, number> = {
  Sunday: 0,
  Monday: 1,
  Tuesday: 2,
  Wednesday: 3,
  Thursday: 4,
  Friday: 5,
  Saturday: 6,
};

export function getMatchDateForDay(baseStartDateStr: string, weekNum: number, targetDayName: string): string {
  const [year, month, day] = baseStartDateStr.split('-').map(Number);
  const baseDate = new Date(year, month - 1, day);
  const baseDayIdx = baseDate.getDay();
  const targetDayIdx = DAY_INDEXES[targetDayName] ?? baseDayIdx;

  const dayOffset = (targetDayIdx - baseDayIdx + 7) % 7;
  const totalDaysToAdd = (weekNum - 1) * 7 + dayOffset;

  const resultDate = new Date(baseDate);
  resultDate.setDate(resultDate.getDate() + totalDaysToAdd);

  const yyyy = resultDate.getFullYear();
  const mm = String(resultDate.getMonth() + 1).padStart(2, '0');
  const dd = String(resultDate.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

export const MAX_COURTS: number = parseInt(import.meta.env.VITE_MAX_COURTS || '4', 10);

export function calculateCourtsFromShares(
  players: PlayerForScheduling[],
  maxCourts: number = MAX_COURTS
): {
  totalSinglesShares: number;
  totalDoublesShares: number;
  suggestedSinglesCourts: number;
  suggestedDoublesCourts: number;
  totalCourts: number;
  isWithinWeeklyLimit: boolean;
} {
  const totalSinglesShares = players.reduce((acc, p) => acc + Number(p.singles_share || 0), 0);
  const totalDoublesShares = players.reduce((acc, p) => acc + Number(p.doubles_share || 0), 0);

  // 1 Singles court/wk = 2.0 total shares over 24 weeks
  const suggestedSinglesCourts = Math.round(totalSinglesShares / 2.0);
  // 1 Doubles court/wk = 4.0 total shares over 24 weeks
  const suggestedDoublesCourts = Math.round(totalDoublesShares / 4.0);

  const totalCourts = suggestedSinglesCourts + suggestedDoublesCourts;

  return {
    totalSinglesShares,
    totalDoublesShares,
    suggestedSinglesCourts,
    suggestedDoublesCourts,
    totalCourts,
    isWithinWeeklyLimit: totalCourts <= maxCourts,
  };
}

export function generateSeasonSchedule(
  players: PlayerForScheduling[],
  options: ScheduleGenOptions
): ScheduleGenResult {
  const numWeeks = options.numWeeks || 24;

  let activeDailySchedule: DayCourtConfig[] = [];
  if (options.dailySchedule && options.dailySchedule.length > 0) {
    activeDailySchedule = options.dailySchedule.filter(
      (d) => d.singlesCourts > 0 || d.doublesCourts > 0
    );
  }

  // Fallback to legacy single-day if no daily schedule configured
  if (activeDailySchedule.length === 0) {
    activeDailySchedule = [
      {
        dayOfWeek: options.dayOfWeek || 'Sunday',
        singlesCourts: options.singlesCourtsPerWeek ?? 3,
        doublesCourts: options.doublesCourtsPerWeek ?? 2,
      },
    ];
  }

  const weeklyCourtsCount = activeDailySchedule.reduce(
    (acc, d) => acc + d.singlesCourts + d.doublesCourts,
    0
  );

  // Track player match counts
  const singlesCount: Record<string, number> = {};
  const doublesCount: Record<string, number> = {};
  const lastWeekPlayed: Record<string, number> = {};

  players.forEach((p) => {
    singlesCount[p.id] = 0;
    doublesCount[p.id] = 0;
    lastWeekPlayed[p.id] = -5;
  });

  const generatedMatches: GeneratedMatch[] = [];

  for (let w = 1; w <= numWeeks; w++) {
    const availablePlayers = players.filter(
      (p) => !p.blackout_weeks || !p.blackout_weeks.includes(w)
    );

    // Track players who play on each specific day of week w so nobody plays twice on the same day
    const scheduledTodayByDay: Record<string, Set<string>> = {};

    activeDailySchedule.forEach((dayConfig) => {
      const dayName = dayConfig.dayOfWeek;
      if (!scheduledTodayByDay[dayName]) {
        scheduledTodayByDay[dayName] = new Set<string>();
      }
      const dayScheduledSet = scheduledTodayByDay[dayName];
      const matchDate = getMatchDateForDay(options.startDate, w, dayName);

      const dayAvailablePlayers = availablePlayers.filter(
        (p) => !p.blackout_days || !p.blackout_days.includes(dayName)
      );

      // 1. Process Singles Courts for this day
      for (let c = 1; c <= dayConfig.singlesCourts; c++) {
        const eligibleSingles = dayAvailablePlayers.filter(
          (p) => Number(p.singles_share || 0) > 0 && !dayScheduledSet.has(p.id)
        );

        const candidates = [...eligibleSingles].sort((a, b) => {
          const targetA = Math.round(a.singles_share * numWeeks);
          const targetB = Math.round(b.singles_share * numWeeks);
          const remA = targetA - singlesCount[a.id];
          const remB = targetB - singlesCount[b.id];

          const hasQuotaA = remA > 0 ? 1 : 0;
          const hasQuotaB = remB > 0 ? 1 : 0;
          if (hasQuotaA !== hasQuotaB) return hasQuotaB - hasQuotaA;

          const ratioA = targetA > 0 ? (singlesCount[a.id] || 0) / targetA : 1;
          const ratioB = targetB > 0 ? (singlesCount[b.id] || 0) / targetB : 1;
          if (ratioA !== ratioB) return ratioA - ratioB;

          return (lastWeekPlayed[a.id] || 0) - (lastWeekPlayed[b.id] || 0);
        });

        const matchPlayers = candidates.slice(0, 2);
        if (matchPlayers.length > 0) {
          matchPlayers.forEach((p) => {
            singlesCount[p.id] = (singlesCount[p.id] || 0) + 1;
            lastWeekPlayed[p.id] = w;
            dayScheduledSet.add(p.id);
          });

          generatedMatches.push({
            week_number: w,
            day_of_week: dayName,
            match_date: matchDate,
            type: 'SINGLES',
            court_number: c,
            slots: matchPlayers.map((p) => ({
              player_id: p.id,
              player_name: p.full_name,
            })),
          });
        }
      }

      // 2. Process Doubles Courts for this day
      for (let c = 1; c <= dayConfig.doublesCourts; c++) {
        const courtNum = dayConfig.singlesCourts + c;
        const eligibleDoubles = dayAvailablePlayers.filter(
          (p) => Number(p.doubles_share || 0) > 0 && !dayScheduledSet.has(p.id)
        );

        const candidates = [...eligibleDoubles].sort((a, b) => {
          const targetA = Math.round(a.doubles_share * numWeeks);
          const targetB = Math.round(b.doubles_share * numWeeks);
          const remA = targetA - doublesCount[a.id];
          const remB = targetB - doublesCount[b.id];

          const hasQuotaA = remA > 0 ? 1 : 0;
          const hasQuotaB = remB > 0 ? 1 : 0;
          if (hasQuotaA !== hasQuotaB) return hasQuotaB - hasQuotaA;

          const ratioA = targetA > 0 ? (doublesCount[a.id] || 0) / targetA : 1;
          const ratioB = targetB > 0 ? (doublesCount[b.id] || 0) / targetB : 1;
          if (ratioA !== ratioB) return ratioA - ratioB;

          return (lastWeekPlayed[a.id] || 0) - (lastWeekPlayed[b.id] || 0);
        });

        const matchPlayers = candidates.slice(0, 4);
        if (matchPlayers.length > 0) {
          matchPlayers.forEach((p) => {
            doublesCount[p.id] = (doublesCount[p.id] || 0) + 1;
            lastWeekPlayed[p.id] = w;
            dayScheduledSet.add(p.id);
          });

          generatedMatches.push({
            week_number: w,
            day_of_week: dayName,
            match_date: matchDate,
            type: 'DOUBLES',
            court_number: courtNum,
            slots: matchPlayers.map((p) => ({
              player_id: p.id,
              player_name: p.full_name,
            })),
          });
        }
      }
    });
  }

  const summaries: PlayerQuotaSummary[] = players.map((p) => ({
    player_id: p.id,
    full_name: p.full_name,
    target_singles: Math.round(p.singles_share * numWeeks),
    scheduled_singles: singlesCount[p.id] || 0,
    target_doubles: Math.round(p.doubles_share * numWeeks),
    scheduled_doubles: doublesCount[p.id] || 0,
    blackout_count: p.blackout_weeks?.length || 0,
  }));

  const totalSinglesTarget = summaries.reduce((acc, s) => acc + s.target_singles, 0);
  const totalDoublesTarget = summaries.reduce((acc, s) => acc + s.target_doubles, 0);
  const totalSinglesScheduled = summaries.reduce((acc, s) => acc + s.scheduled_singles, 0);
  const totalDoublesScheduled = summaries.reduce((acc, s) => acc + s.scheduled_doubles, 0);

  generatedMatches.sort(compareMatches);

  return {
    matches: generatedMatches,
    summaries,
    totalSpotsNeeded: { singles: totalSinglesTarget, doubles: totalDoublesTarget },
    totalSpotsScheduled: { singles: totalSinglesScheduled, doubles: totalDoublesScheduled },
    weeklyCourtsCount,
  };
}

