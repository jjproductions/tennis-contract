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
  totalCourts: number;
  courtNumbers?: number[];
  
  // Legacy fields for backwards compatibility
  singlesCourts?: number;
  doublesCourts?: number;
  singlesCourtNumbers?: number[];
  doublesCourtNumbers?: number[];
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
  excludedDates?: string[];
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


// --- RULES & PRIORITIES ENGINE TYPES ---

export interface MatchContext {
  week: number;
  day: string;
  date: string;
  type: 'SINGLES' | 'DOUBLES';
  courtNum: number;
  playersAlreadyAssigned: string[]; // Player IDs already drafted onto this specific court
}

export interface ScheduleContext {
  numWeeks: number;
  getMatchesForPlayerInWeek(playerId: string, week: number): GeneratedMatch[];
  getMatchesForPlayerOnDay(playerId: string, week: number, day: string): GeneratedMatch[];
  didPlayersPlaySinglesThisWeek(playerA: string, playerB: string, week: number): boolean;
  getHistoricalMatchupsCount(playerA: string, playerB: string, upToWeek: number): number;
  singlesCount: Record<string, number>;
  doublesCount: Record<string, number>;
  lastWeekPlayed: Record<string, number>;
}

// A Rule determines if a player CAN play. Returns allowed: false if rejected. 
// penaltyScore applies soft limits (higher = worse for player).
export type SchedulingRule = (
  player: PlayerForScheduling,
  matchContext: MatchContext,
  scheduleCtx: ScheduleContext
) => { allowed: boolean; penaltyScore: number };

// A Scorer evaluates how badly a player needs to play (higher = they get priority).
export type SchedulingScorer = (
  player: PlayerForScheduling,
  matchContext: MatchContext,
  scheduleCtx: ScheduleContext
) => number;


// --- RULES IMPLEMENTATIONS ---

const shareRequirementRule: SchedulingRule = (player, ctx) => {
  const share = ctx.type === 'SINGLES' ? player.singles_share : player.doubles_share;
  if (Number(share || 0) <= 0) return { allowed: false, penaltyScore: 0 };
  return { allowed: true, penaltyScore: 0 };
};

const blackoutRule: SchedulingRule = (player, ctx) => {
  if (player.blackout_weeks?.includes(ctx.week)) return { allowed: false, penaltyScore: 0 };
  if (player.blackout_days?.includes(ctx.day)) return { allowed: false, penaltyScore: 0 };
  return { allowed: true, penaltyScore: 0 };
};

const dailyLimitRule: SchedulingRule = (player, ctx, sched) => {
  const matchesToday = sched.getMatchesForPlayerOnDay(player.id, ctx.week, ctx.day);
  if (matchesToday.length >= 1) return { allowed: false, penaltyScore: 0 };
  return { allowed: true, penaltyScore: 0 };
};

const maxWeeklyMatchesRule: SchedulingRule = (player, ctx, sched) => {
  const matchesThisWeek = sched.getMatchesForPlayerInWeek(player.id, ctx.week);
  if (matchesThisWeek.length >= 2) return { allowed: false, penaltyScore: 0 };
  return { allowed: true, penaltyScore: 0 };
};

const softLimitSinglesWeeklyRule: SchedulingRule = (player, ctx, sched) => {
  if (ctx.type !== 'SINGLES') return { allowed: true, penaltyScore: 0 };
  
  const matchesThisWeek = sched.getMatchesForPlayerInWeek(player.id, ctx.week);
  const singlesThisWeek = matchesThisWeek.filter(m => m.type === 'SINGLES');
  
  // They are allowed to play a 2nd singles match, but they receive a massive penalty 
  // so the algorithm will pick almost ANYONE else first. It prevents empty courts.
  if (singlesThisWeek.length >= 1) {
    return { allowed: true, penaltyScore: 10000 };
  }
  return { allowed: true, penaltyScore: 0 };
};

const uniqueSinglesMatchupRule: SchedulingRule = (player, ctx, sched) => {
  if (ctx.type !== 'SINGLES') return { allowed: true, penaltyScore: 0 };
  
  // Ensure this player hasn't already played the assigned opponent(s) in Singles this week
  for (const oppId of ctx.playersAlreadyAssigned) {
    if (sched.didPlayersPlaySinglesThisWeek(player.id, oppId, ctx.week)) {
      return { allowed: false, penaltyScore: 0 };
    }
  }
  return { allowed: true, penaltyScore: 0 };
};


// --- SCORERS IMPLEMENTATIONS ---

const urgencyScorer: SchedulingScorer = (player, ctx, sched) => {
  const isSingles = ctx.type === 'SINGLES';
  const target = Math.round((isSingles ? player.singles_share : player.doubles_share) * sched.numWeeks);
  const played = isSingles ? (sched.singlesCount[player.id] || 0) : (sched.doublesCount[player.id] || 0);
  const remainingMatches = target - played;
  
  // If they have passed their target quota, very low priority (negative score)
  if (remainingMatches <= 0) return -5000 + remainingMatches; 
  
  let remWeeks = 0;
  for (let i = ctx.week; i <= sched.numWeeks; i++) {
     if (!player.blackout_weeks?.includes(i)) remWeeks++;
  }
  
  // Urgency = Matches Needed / Time Left to get them
  const urgency = remWeeks > 0 ? remainingMatches / remWeeks : remainingMatches;
  return urgency * 100; // Scale up for easier math comparison
};

const restScorer: SchedulingScorer = (player, ctx, sched) => {
  const lastPlayed = sched.lastWeekPlayed[player.id] || 0;
  const weeksSincePlayed = ctx.week - lastPlayed;
  // Small bonus for having not played recently (e.g. +2 points per week resting)
  return weeksSincePlayed * 2; 
};

const opponentFatigueScorer: SchedulingScorer = (player, ctx, sched) => {
  let penalty = 0;
  for (const oppId of ctx.playersAlreadyAssigned) {
    const timesPlayed = sched.getHistoricalMatchupsCount(player.id, oppId, ctx.week);
    // Deduct 50 points for every time they've already shared a court this season
    penalty -= (timesPlayed * 50); 
  }
  return penalty;
};

const randomTiebreakerScorer: SchedulingScorer = () => {
  // A tiny random decimal to shuffle players with identical urgency scores
  return Math.random(); 
};

// --- MAIN SCHEDULER ALGORITHM ---

export function generateSeasonSchedule(
  players: PlayerForScheduling[],
  options: ScheduleGenOptions
): ScheduleGenResult {
  const numWeeks = options.numWeeks || 24;

  let activeDailySchedule: DayCourtConfig[] = [];
  if (options.dailySchedule && options.dailySchedule.length > 0) {
    activeDailySchedule = options.dailySchedule.filter(
      (d) => (d.totalCourts ?? (d.singlesCourts! + d.doublesCourts!)) > 0
    );
  }

  // Fallback to legacy single-day if no daily schedule configured
  if (activeDailySchedule.length === 0) {
    activeDailySchedule = [
      {
        dayOfWeek: options.dayOfWeek || 'Sunday',
        totalCourts: (options.singlesCourtsPerWeek ?? 3) + (options.doublesCourtsPerWeek ?? 2),
      },
    ];
  }

  const weeklyCourtsCount = activeDailySchedule.reduce(
    (acc, d) => acc + (d.totalCourts ?? (d.singlesCourts! + d.doublesCourts!)),
    0
  );

  const excludedDatesSet = new Set(options.excludedDates || []);
  const validDatesPerDay: Record<string, string[]> = {};

  activeDailySchedule.forEach((dayConfig) => {
    const dayName = dayConfig.dayOfWeek;
    validDatesPerDay[dayName] = [];
    let weekOffset = 1;
    // generate the next 24 valid dates for this day of the week
    while (validDatesPerDay[dayName].length < numWeeks) {
      const candidateDate = getMatchDateForDay(options.startDate, weekOffset, dayName);
      if (!excludedDatesSet.has(candidateDate)) {
        validDatesPerDay[dayName].push(candidateDate);
      }
      weekOffset++;
      if (weekOffset > numWeeks + 52) break; // sanity check to prevent infinite loop
    }
  });

  const generatedMatches: GeneratedMatch[] = [];

  // Initialize the Schedule Context for the rules engine to query
  const scheduleCtx: ScheduleContext = {
    numWeeks,
    singlesCount: {},
    doublesCount: {},
    lastWeekPlayed: {},
    getMatchesForPlayerInWeek(playerId, week) {
      return generatedMatches.filter(m => m.week_number === week && m.slots.some(s => s.player_id === playerId));
    },
    getMatchesForPlayerOnDay(playerId, week, day) {
      return generatedMatches.filter(m => m.week_number === week && m.day_of_week === day && m.slots.some(s => s.player_id === playerId));
    },
    didPlayersPlaySinglesThisWeek(playerA, playerB, week) {
      const matches = this.getMatchesForPlayerInWeek(playerA, week);
      return matches.some(m => m.type === 'SINGLES' && m.slots.some(s => s.player_id === playerB));
    },
    getHistoricalMatchupsCount(playerA, playerB, upToWeek) {
      const matchesA = generatedMatches.filter(m => m.week_number < upToWeek && m.slots.some(s => s.player_id === playerA));
      return matchesA.filter(m => m.slots.some(s => s.player_id === playerB)).length;
    }
  };

  players.forEach((p) => {
    scheduleCtx.singlesCount[p.id] = 0;
    scheduleCtx.doublesCount[p.id] = 0;
    scheduleCtx.lastWeekPlayed[p.id] = -5; // Default far in past
  });

  // Activate our modular rules and scorers
  const activeRules: SchedulingRule[] = [
    shareRequirementRule,
    blackoutRule,
    dailyLimitRule,
    maxWeeklyMatchesRule,
    softLimitSinglesWeeklyRule,
    uniqueSinglesMatchupRule
  ];

  const activeScorers: SchedulingScorer[] = [
    urgencyScorer,
    restScorer,
    opponentFatigueScorer,
    randomTiebreakerScorer
  ];

  // Calculate season-long demand and capacity for court type balancing
  const totalSinglesShares = players.reduce((acc, p) => acc + Number(p.singles_share || 0), 0);
  const totalDoublesShares = players.reduce((acc, p) => acc + Number(p.doubles_share || 0), 0);
  
  const demandSinglesMatches = (totalSinglesShares * numWeeks) / 2;
  const demandDoublesMatches = (totalDoublesShares * numWeeks) / 4;
  const totalDemand = demandSinglesMatches + demandDoublesMatches;
  
  const totalCapacityMatches = weeklyCourtsCount * numWeeks;
  
  let allocatedSingles = demandSinglesMatches;
  
  if (totalCapacityMatches > 0 && totalDemand > 0) {
    const singlesRatio = demandSinglesMatches / totalDemand;
    allocatedSingles = Math.round(totalCapacityMatches * singlesRatio);
  }
  
  let scheduledSinglesMatches = 0;
  let scheduledDoublesMatches = 0;

  for (let w = 1; w <= numWeeks; w++) {
    activeDailySchedule.forEach((dayConfig) => {
      const dayName = dayConfig.dayOfWeek;
      const matchDate = validDatesPerDay[dayName][w - 1];
      const courtsCount = dayConfig.totalCourts ?? (dayConfig.singlesCourts! + dayConfig.doublesCourts!);

      for (let c = 1; c <= courtsCount; c++) {
        // Fallback logic for court numbers
        let assignedCourtNum = c;
        if (dayConfig.courtNumbers && dayConfig.courtNumbers[c - 1] !== undefined) {
          assignedCourtNum = Number(dayConfig.courtNumbers[c - 1]);
        } else if (dayConfig.singlesCourtNumbers && c <= dayConfig.singlesCourts!) {
          assignedCourtNum = Number(dayConfig.singlesCourtNumbers[c - 1]);
        } else if (dayConfig.doublesCourtNumbers && c - dayConfig.singlesCourts! > 0) {
          assignedCourtNum = Number(dayConfig.doublesCourtNumbers[c - 1 - dayConfig.singlesCourts!]);
        }
        
        // Dynamically decide Match Type for this court based on season allocation
        const expectedSingles = ((scheduledSinglesMatches + scheduledDoublesMatches + 1) / totalCapacityMatches) * allocatedSingles;
        let matchType: 'SINGLES' | 'DOUBLES' = 'DOUBLES';
        
        if (scheduledSinglesMatches < expectedSingles) {
          matchType = 'SINGLES';
        }

        const isSingles = matchType === 'SINGLES';
        const numPlayersNeeded = isSingles ? 2 : 4;
        const matchPlayers: PlayerForScheduling[] = [];

        // Draft players one by one for this court
        for (let pIdx = 0; pIdx < numPlayersNeeded; pIdx++) {
          const matchCtx: MatchContext = {
            week: w,
            day: dayName,
            date: matchDate,
            type: matchType,
            courtNum: assignedCourtNum,
            playersAlreadyAssigned: matchPlayers.map(p => p.id)
          };
          
          let candidates = players.map(player => {
            // Can't pick a player who is already drafted onto this specific court
            if (matchPlayers.some(mp => mp.id === player.id)) return null; 
            
            let totalPenalty = 0;
            let isAllowed = true;
            
            // 1. Pass through Constraints (Rules)
            for (const rule of activeRules) {
              const res = rule(player, matchCtx, scheduleCtx);
              if (!res.allowed) {
                isAllowed = false;
                break; // Hard rejection, stop checking rules
              }
              totalPenalty += res.penaltyScore;
            }
            
            if (!isAllowed) return null;
            
            // 2. Pass through Heuristics (Scorers)
            let totalScore = 0;
            for (const scorer of activeScorers) {
              totalScore += scorer(player, matchCtx, scheduleCtx);
            }
            
            const finalScore = totalScore - totalPenalty;
            return { player, score: finalScore };
          }).filter(c => c !== null) as { player: PlayerForScheduling; score: number }[];
          
          if (candidates.length > 0) {
            // Sort by highest score first
            candidates.sort((a, b) => b.score - a.score);
            matchPlayers.push(candidates[0].player);
          }
        }

        if (matchPlayers.length > 0) {
          // Update Schedule Context trackers with drafted players
          matchPlayers.forEach((p) => {
            if (isSingles) {
              scheduleCtx.singlesCount[p.id] = (scheduleCtx.singlesCount[p.id] || 0) + 1;
            } else {
              scheduleCtx.doublesCount[p.id] = (scheduleCtx.doublesCount[p.id] || 0) + 1;
            }
            scheduleCtx.lastWeekPlayed[p.id] = w;
          });
          
          if (isSingles) scheduledSinglesMatches++;
          else scheduledDoublesMatches++;

          generatedMatches.push({
            week_number: w,
            day_of_week: dayName,
            match_date: matchDate,
            type: matchType,
            court_number: assignedCourtNum,
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
    scheduled_singles: scheduleCtx.singlesCount[p.id] || 0,
    target_doubles: Math.round(p.doubles_share * numWeeks),
    scheduled_doubles: scheduleCtx.doublesCount[p.id] || 0,
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
