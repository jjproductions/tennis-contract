/**
 * Discord Webhook Notification Service for Winter Tennis League
 */
import { supabase } from '../supabase';

export interface DiscordEmbedField {
  name: string;
  value: string;
  inline?: boolean;
}

export interface DiscordEmbed {
  title?: string;
  description?: string;
  url?: string;
  color?: number; // Integer color code (e.g. 0x3B82F6)
  fields?: DiscordEmbedField[];
  footer?: {
    text: string;
    icon_url?: string;
  };
  timestamp?: string;
}

export interface DiscordNotificationConfig {
  new_player_intake: boolean;
  player_approved: boolean;
  schedule_published: boolean;
  sub_requested: boolean;
  sub_claimed: boolean;
}

const STORAGE_KEY = 'winter_tennis_discord_webhook_url';
const CONFIG_STORAGE_KEY = 'winter_tennis_discord_events_config';
const DB_SETTINGS_KEY = 'discord_settings';

const DEFAULT_CONFIG: DiscordNotificationConfig = {
  new_player_intake: true,
  player_approved: true,
  schedule_published: true,
  sub_requested: true,
  sub_claimed: true,
};

let cachedWebhookUrl: string | null = null;
let cachedConfig: DiscordNotificationConfig | null = null;

/**
 * Fetch global Discord settings from Supabase database (with local storage fallback)
 */
export async function fetchGlobalDiscordSettings(): Promise<{
  webhook_url: string;
  events: DiscordNotificationConfig;
}> {
  try {
    const { data, error } = await supabase
      .from('league_settings')
      .select('value')
      .eq('key', DB_SETTINGS_KEY)
      .maybeSingle();

    if (!error && data?.value) {
      const val = data.value;
      if (typeof val.webhook_url === 'string') {
        cachedWebhookUrl = val.webhook_url;
        localStorage.setItem(STORAGE_KEY, val.webhook_url);
      }
      if (val.events) {
        const mergedEvents = { ...DEFAULT_CONFIG, ...val.events };
        cachedConfig = mergedEvents;
        localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(mergedEvents));
      }
    }
  } catch (err) {
    // Non-blocking fallback
  }

  return {
    webhook_url: getWebhookUrl(),
    events: getNotificationConfig(),
  };
}

/**
 * Save global Discord settings to Supabase database (and local storage)
 */
export async function saveGlobalDiscordSettings(
  webhookUrl: string,
  eventsConfig: DiscordNotificationConfig
): Promise<{ success: boolean; message: string }> {
  // Save locally first
  setWebhookUrl(webhookUrl);
  setNotificationConfig(eventsConfig);

  cachedWebhookUrl = webhookUrl.trim();
  cachedConfig = { ...eventsConfig };

  try {
    const { error } = await supabase.from('league_settings').upsert(
      {
        key: DB_SETTINGS_KEY,
        value: {
          webhook_url: webhookUrl.trim(),
          events: eventsConfig,
        },
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'key' }
    );

    if (error) {
      return {
        success: true,
        message: `Saved locally! (To sync globally across all users, create the 'league_settings' table in Supabase)`,
      };
    }

    return { success: true, message: 'Global Discord settings saved successfully across all users & devices!' };
  } catch (err: any) {
    return { success: true, message: `Saved locally! (${err.message || err})` };
  }
}

/**
 * Retrieve event notification toggles configuration
 */
export function getNotificationConfig(): DiscordNotificationConfig {
  if (cachedConfig) return { ...cachedConfig };
  try {
    const raw = localStorage.getItem(CONFIG_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      return { ...DEFAULT_CONFIG, ...parsed };
    }
  } catch (err) {
    // Fallback
  }
  return { ...DEFAULT_CONFIG };
}

/**
 * Save event notification toggles configuration to localStorage
 */
export function setNotificationConfig(config: DiscordNotificationConfig): void {
  cachedConfig = { ...config };
  localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(config));
}

/**
 * Check if a specific notification event type is enabled by admin
 */
export function isNotificationEnabled(eventType: keyof DiscordNotificationConfig): boolean {
  const config = getNotificationConfig();
  return config[eventType] === true;
}

/**
 * Retrieve active Discord Webhook URL from localStorage or env variable
 */
export function getWebhookUrl(): string {
  if (cachedWebhookUrl !== null && cachedWebhookUrl.length > 0) {
    return cachedWebhookUrl;
  }
  const customUrl = localStorage.getItem(STORAGE_KEY);
  if (customUrl && customUrl.trim().length > 0) {
    return customUrl.trim();
  }
  return (import.meta.env.VITE_DISCORD_WEBHOOK_URL || '').trim();
}

/**
 * Save custom Discord Webhook URL to localStorage
 */
export function setWebhookUrl(url: string): void {
  cachedWebhookUrl = url.trim();
  if (!url || !url.trim()) {
    localStorage.removeItem(STORAGE_KEY);
  } else {
    localStorage.setItem(STORAGE_KEY, url.trim());
  }
}

/**
 * Check if a Discord Webhook URL is configured
 */
export function hasWebhookConfigured(): boolean {
  return getWebhookUrl().length > 0;
}

/**
 * Send raw payload to configured Discord Webhook
 */
export async function sendDiscordPayload(embed: DiscordEmbed, targetUrl?: string): Promise<{ success: boolean; message: string }> {
  const webhookUrl = targetUrl || getWebhookUrl();

  if (!webhookUrl) {
    return { success: false, message: 'No Discord Webhook URL configured.' };
  }

  const payload = {
    username: 'Winter Tennis League Bot',
    avatar_url: 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=128&auto=format&fit=crop&q=80',
    embeds: [
      {
        footer: {
          text: 'Winter Tennis League Notifications 🎾',
        },
        timestamp: new Date().toISOString(),
        ...embed,
      },
    ],
  };

  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (response.ok || response.status === 204) {
      return { success: true, message: 'Notification sent successfully to Discord!' };
    } else {
      const errText = await response.text();
      return { success: false, message: `Discord API error (${response.status}): ${errText || response.statusText}` };
    }
  } catch (err: any) {
    return { success: false, message: `Network error sending Discord notification: ${err.message || err}` };
  }
}

/**
 * Test the Discord Webhook connection
 */
export async function testDiscordWebhook(customUrl?: string): Promise<{ success: boolean; message: string }> {
  const embed: DiscordEmbed = {
    title: '🎾 Discord Webhook Connected!',
    description: 'Winter Tennis League notifications are successfully linked to this channel. You will receive real-time alerts for schedule updates, sub requests, and league announcements.',
    color: 0x10B981, // Emerald Green
    fields: [
      { name: 'Status', value: '✅ Active & Ready', inline: true },
      { name: 'Environment', value: 'Winter Tennis Portal', inline: true },
    ],
  };

  return sendDiscordPayload(embed, customUrl);
}

/**
 * Notify when a new player submits registration intake
 */
export async function notifyNewPlayerIntake(player: {
  full_name: string;
  email: string;
  singles_share: number;
  doubles_share: number;
  blackout_weeks: number[];
  blackout_days?: string[];
}): Promise<void> {
  await fetchGlobalDiscordSettings();
  if (!hasWebhookConfigured() || !isNotificationEnabled('new_player_intake')) return;

  const embed: DiscordEmbed = {
    title: '📝 New Player Registration Received',
    description: `**${player.full_name}** has submitted registration details for the Winter Tennis season!`,
    color: 0x3B82F6, // Blue
    fields: [
      { name: 'Player Name', value: player.full_name, inline: true },
      { name: 'Singles Share', value: `${(player.singles_share * 100 % 1 === 0 ? (player.singles_share * 100).toFixed(0) : (player.singles_share * 100).toFixed(1))}% (${Math.round(player.singles_share * 24)} matches)`, inline: true },
      { name: 'Doubles Share', value: `${(player.doubles_share * 100 % 1 === 0 ? (player.doubles_share * 100).toFixed(0) : (player.doubles_share * 100).toFixed(1))}% (${Math.round(player.doubles_share * 24)} matches)`, inline: true },
      {
        name: 'Blackout Weeks',
        value: player.blackout_weeks?.length ? player.blackout_weeks.map(w => `Week ${w}`).join(', ') : 'None',
        inline: true,
      },
      {
        name: 'Blackout Days',
        value: player.blackout_days?.length ? player.blackout_days.join(', ') : 'None',
        inline: true,
      },
    ],
  };

  await sendDiscordPayload(embed);
}

/**
 * Notify when an admin approves a player registration
 */
export async function notifyPlayerApproved(player: { full_name: string; email: string }): Promise<void> {
  await fetchGlobalDiscordSettings();
  if (!hasWebhookConfigured() || !isNotificationEnabled('player_approved')) return;

  const embed: DiscordEmbed = {
    title: '🎉 Player Approved for Season Roster!',
    description: `Welcome **${player.full_name}** to the Winter Tennis League official roster!`,
    color: 0x10B981, // Green
    fields: [
      { name: 'Player', value: player.full_name, inline: true },
      { name: 'Status', value: '✅ Approved & Added to Schedule Pool', inline: true },
    ],
  };

  await sendDiscordPayload(embed);
}

/**
 * Notify when admin generates & publishes season match schedule
 */
export async function notifySchedulePublished(stats: {
  numWeeks: number;
  totalMatches: number;
  totalSlots: number;
  startDate: string;
}): Promise<void> {
  await fetchGlobalDiscordSettings();
  if (!hasWebhookConfigured() || !isNotificationEnabled('schedule_published')) return;

  const embed: DiscordEmbed = {
    title: '📅 New Season Schedule Published!',
    description: `The complete **${stats.numWeeks}-Week Winter Season Match Schedule** has been generated and published!`,
    color: 0x8B5CF6, // Purple
    fields: [
      { name: 'Season Length', value: `${stats.numWeeks} Weeks`, inline: true },
      { name: 'Total Matches', value: `${stats.totalMatches} Matches`, inline: true },
      { name: 'Player Slots', value: `${stats.totalSlots} Slots`, inline: true },
      { name: 'Start Date', value: stats.startDate, inline: false },
    ],
  };

  await sendDiscordPayload(embed);
}

/**
 * Notify when a player requests a substitute for a slot
 */
export async function notifySubRequested(slot: {
  week_number: number;
  day_of_week: string;
  match_date: string;
  type: string;
  court_number: number;
  player_name: string;
}): Promise<void> {
  await fetchGlobalDiscordSettings();
  if (!hasWebhookConfigured() || !isNotificationEnabled('sub_requested')) return;

  const embed: DiscordEmbed = {
    title: '🚨 Open Sub Available!',
    description: `**${slot.player_name}** needs a substitute for an upcoming match!`,
    color: 0xF59E0B, // Amber / Orange
    fields: [
      { name: 'Match Date', value: `${slot.day_of_week}, ${slot.match_date} (Week ${slot.week_number})`, inline: false },
      { name: 'Match Type', value: `${slot.type} - Court ${slot.court_number}`, inline: true },
      { name: 'Original Player', value: slot.player_name, inline: true },
      { name: 'How to Claim', value: 'Log into the Winter Tennis portal and click **Claim Sub** on the schedule page!', inline: false },
    ],
  };

  await sendDiscordPayload(embed);
}

/**
 * Notify when a substitute claims an open sub slot
 */
export async function notifySubClaimed(
  slot: {
    week_number: number;
    day_of_week: string;
    match_date: string;
    type: string;
    court_number: number;
    original_player: string;
  },
  subPlayerName: string
): Promise<void> {
  await fetchGlobalDiscordSettings();
  if (!hasWebhookConfigured() || !isNotificationEnabled('sub_claimed')) return;

  const embed: DiscordEmbed = {
    title: '🤝 Sub Claimed!',
    description: `**${subPlayerName}** has claimed the substitute slot for **${slot.original_player}**!`,
    color: 0x10B981, // Emerald Green
    fields: [
      { name: 'Match Date', value: `${slot.day_of_week}, ${slot.match_date} (Week ${slot.week_number})`, inline: false },
      { name: 'Match Type', value: `${slot.type} - Court ${slot.court_number}`, inline: true },
      { name: 'Substitute Player', value: `✅ ${subPlayerName}`, inline: true },
    ],
  };

  await sendDiscordPayload(embed);
}

/**
 * Admin utility for sending custom broadcast announcements
 */
export async function sendCustomBroadcast(
  title: string,
  message: string,
  alertType: 'info' | 'warning' | 'announcement' | 'urgent' = 'announcement',
  authorName?: string
): Promise<{ success: boolean; message: string }> {
  await fetchGlobalDiscordSettings();
  if (!hasWebhookConfigured()) {
    return { success: false, message: 'No Discord Webhook URL configured.' };
  }

  let color = 0x3B82F6; // Info: Blue
  let icon = '📢';

  if (alertType === 'warning') {
    color = 0xF59E0B; // Amber
    icon = '⚠️';
  } else if (alertType === 'urgent') {
    color = 0xEF4444; // Red
    icon = '🚨';
  } else if (alertType === 'announcement') {
    color = 0x8B5CF6; // Purple
    icon = '📣';
  }

  const embed: DiscordEmbed = {
    title: `${icon} ${title.trim()}`,
    description: message.trim(),
    color: color,
    fields: authorName ? [{ name: 'Posted By', value: authorName, inline: true }] : undefined,
  };

  return sendDiscordPayload(embed);
}
