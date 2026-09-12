export interface PlayerForScheduling {
  id: string;
  full_name: string;
  email?: string;
  singles_share: number;
  doubles_share: number;
  blackout_weeks: number[];
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
}

export interface ScheduleGenOptions {
  startDate: string; // YYYY-MM-DD
  dayOfWeek: string; // e.g. 'Sunday'
  numWeeks?: number; // 24
  singlesCourtsPerWeek?: number; // Default 3
  doublesCourtsPerWeek?: number; // Default 2
}

export function generateSeasonSchedule(
  players: PlayerForScheduling[],
  options: ScheduleGenOptions
): ScheduleGenResult {
  const numWeeks = options.numWeeks || 24;
  const singlesCourts = options.singlesCourtsPerWeek ?? 3;
  const doublesCourts = options.doublesCourtsPerWeek ?? 2;

  const singlesSpotsPerWeek = singlesCourts * 2; // 2 players per singles match
  const doublesSpotsPerWeek = doublesCourts * 4; // 4 players per doubles match

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
  const baseDate = new Date(options.startDate);

  for (let w = 1; w <= numWeeks; w++) {
    // Calculate week date
    const weekDate = new Date(baseDate);
    weekDate.setDate(baseDate.getDate() + (w - 1) * 7);
    const dateStr = weekDate.toISOString().split('T')[0];

    // Filter available players (not blacked out this week)
    const availablePlayers = players.filter(
      (p) => !p.blackout_weeks || !p.blackout_weeks.includes(w)
    );

    // 1. Assign Singles Players
    // Rank available players by: remaining singles target (desc), then least recent week played
    const singlesCandidates = [...availablePlayers].sort((a, b) => {
      const remA = Math.round(a.singles_share * numWeeks) - singlesCount[a.id];
      const remB = Math.round(b.singles_share * numWeeks) - singlesCount[b.id];
      if (remB !== remA) return remB - remA;
      return (lastWeekPlayed[a.id] || 0) - (lastWeekPlayed[b.id] || 0);
    });

    const chosenSingles = singlesCandidates.slice(0, singlesSpotsPerWeek);
    chosenSingles.forEach((p) => {
      singlesCount[p.id] = (singlesCount[p.id] || 0) + 1;
      lastWeekPlayed[p.id] = w;
    });

    // Create Singles Matches (Courts 1..singlesCourts)
    for (let c = 1; c <= singlesCourts; c++) {
      const matchPlayers = chosenSingles.slice((c - 1) * 2, c * 2);
      if (matchPlayers.length > 0) {
        generatedMatches.push({
          week_number: w,
          day_of_week: options.dayOfWeek,
          match_date: dateStr,
          type: 'SINGLES',
          court_number: c,
          slots: matchPlayers.map((p) => ({
            player_id: p.id,
            player_name: p.full_name,
          })),
        });
      }
    }

    // 2. Assign Doubles Players
    // Prefer players who didn't play singles this week, but fall back to anyone available
    const nonSinglesPlayers = availablePlayers.filter(
      (p) => !chosenSingles.some((s) => s.id === p.id)
    );

    const doublesCandidates = [...nonSinglesPlayers, ...chosenSingles].sort((a, b) => {
      const isSinglesA = chosenSingles.some((s) => s.id === a.id) ? 1 : 0;
      const isSinglesB = chosenSingles.some((s) => s.id === b.id) ? 1 : 0;
      if (isSinglesA !== isSinglesB) return isSinglesA - isSinglesB; // Non-singles first

      const remA = Math.round(a.doubles_share * numWeeks) - doublesCount[a.id];
      const remB = Math.round(b.doubles_share * numWeeks) - doublesCount[b.id];
      if (remB !== remA) return remB - remA;

      return (lastWeekPlayed[a.id] || 0) - (lastWeekPlayed[b.id] || 0);
    });

    const chosenDoubles = doublesCandidates.slice(0, doublesSpotsPerWeek);
    chosenDoubles.forEach((p) => {
      doublesCount[p.id] = (doublesCount[p.id] || 0) + 1;
      lastWeekPlayed[p.id] = w;
    });

    // Create Doubles Matches (Courts singlesCourts+1 .. singlesCourts+doublesCourts)
    for (let c = 1; c <= doublesCourts; c++) {
      const courtNum = singlesCourts + c;
      const matchPlayers = chosenDoubles.slice((c - 1) * 4, c * 4);
      if (matchPlayers.length > 0) {
        generatedMatches.push({
          week_number: w,
          day_of_week: options.dayOfWeek,
          match_date: dateStr,
          type: 'DOUBLES',
          court_number: courtNum,
          slots: matchPlayers.map((p) => ({
            player_id: p.id,
            player_name: p.full_name,
          })),
        });
      }
    }
  }

  // Calculate summaries
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

  return {
    matches: generatedMatches,
    summaries,
    totalSpotsNeeded: { singles: totalSinglesTarget, doubles: totalDoublesTarget },
    totalSpotsScheduled: { singles: totalSinglesScheduled, doubles: totalDoublesScheduled },
  };
}
