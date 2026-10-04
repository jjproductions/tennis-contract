import { supabase } from '../supabase';

export interface LeagueConfiguration {
  sub_request_flow: 'maintenance_free' | 'admin_assists';
}

const SETTINGS_KEY = 'league_configuration';
const STORAGE_KEY = 'winter_tennis_league_configuration';

export const DEFAULT_LEAGUE_CONFIG: LeagueConfiguration = {
  sub_request_flow: 'maintenance_free',
};

let cachedConfig: LeagueConfiguration | null = null;

/**
 * Fetch global league configuration from Supabase (with localStorage fallback)
 */
export async function fetchLeagueConfig(): Promise<LeagueConfiguration> {
  try {
    const { data, error } = await supabase
      .from('league_settings')
      .select('value')
      .eq('key', SETTINGS_KEY)
      .maybeSingle();

    if (!error && data?.value) {
      const merged: LeagueConfiguration = {
        ...DEFAULT_LEAGUE_CONFIG,
        ...data.value,
      };
      cachedConfig = merged;
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(merged));
      } catch {
        // ignore storage errors
      }
      return merged;
    }
  } catch {
    // Non-blocking fallback
  }

  // Fallback to localStorage
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      const merged: LeagueConfiguration = { ...DEFAULT_LEAGUE_CONFIG, ...parsed };
      cachedConfig = merged;
      return merged;
    }
  } catch {
    // Fallback
  }

  cachedConfig = { ...DEFAULT_LEAGUE_CONFIG };
  return cachedConfig;
}

/**
 * Save global league configuration to Supabase (and localStorage)
 */
export async function saveLeagueConfig(
  config: Partial<LeagueConfiguration>
): Promise<{ success: boolean; message: string }> {
  const current = await fetchLeagueConfig();
  const updated: LeagueConfiguration = { ...current, ...config };

  cachedConfig = updated;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
  } catch {
    // ignore storage errors
  }

  try {
    const { error } = await supabase.from('league_settings').upsert(
      {
        key: SETTINGS_KEY,
        value: updated,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'key' }
    );

    if (error) {
      return {
        success: true,
        message: 'Saved locally! (To sync globally across all users, check Supabase league_settings table)',
      };
    }

    return {
      success: true,
      message: 'League configuration saved successfully across all users & devices!',
    };
  } catch (err: any) {
    return { success: true, message: `Saved locally! (${err.message || err})` };
  }
}

/**
 * Synchronous getter for in-memory cached league configuration
 */
export function getCachedLeagueConfig(): LeagueConfiguration {
  return cachedConfig || DEFAULT_LEAGUE_CONFIG;
}
