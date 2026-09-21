interface Fetcher {
    fetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response>;
}

interface KVNamespace {
    get(key: string): Promise<string | null>;
}

export interface Env {
    ASSETS: Fetcher;
    DISCORD_WEBHOOKS: KVNamespace;
}

export interface DiscordEmbedField {
    name: string;
    value: string;
    inline?: boolean;
}

export interface DiscordEmbed {
    title?: string;
    description?: string;
    url?: string;
    color?: number;
    fields?: DiscordEmbedField[];
    footer?: {
        text: string;
        icon_url?: string;
    };
    timestamp?: string;
}

interface NotifyRequest {
    sport?: string;
    leagueId?: string;
    target?: 'public' | 'admin';
    title?: string;
    message?: string;
    author?: string;
    color?: number;
    fields?: DiscordEmbedField[];
    embed?: DiscordEmbed;
}

// In-memory per-isolate IP rate limiter (resets every 60 seconds)
const ipRateLimits = new Map<string, { count: number; resetTime: number }>();

function checkRateLimit(ip: string, limit = 8, windowMs = 60000): boolean {
    const now = Date.now();
    const record = ipRateLimits.get(ip);

    if (!record || now > record.resetTime) {
        ipRateLimits.set(ip, { count: 1, resetTime: now + windowMs });
        return true;
    }

    if (record.count >= limit) {
        return false;
    }

    record.count++;
    return true;
}

// Validate a single embed field
function validateField(f: any, index: number): string | null {
    if (!f || typeof f !== 'object') {
        return `Field at index ${index} must be an object`;
    }
    if (typeof f.name !== 'string' || f.name.trim().length === 0 || f.name.length > 256) {
        return `Field '${index}' name must be a string between 1 and 256 characters`;
    }
    if (typeof f.value !== 'string' || f.value.trim().length === 0 || f.value.length > 1024) {
        return `Field '${index}' value must be a string between 1 and 1024 characters`;
    }
    if (f.inline !== undefined && typeof f.inline !== 'boolean') {
        return `Field '${index}' inline must be a boolean`;
    }
    return null;
}

export default {
    async fetch(request: Request, env: Env): Promise<Response> {
        const url = new URL(request.url);

        if (url.pathname === '/api/notify-discord' && request.method === 'POST') {
            // 1. IP Rate Limiting (Max 8 notification requests per minute per IP)
            const clientIp = request.headers.get('cf-connecting-ip') || 'unknown';
            if (!checkRateLimit(clientIp, 8, 60000)) {
                return Response.json(
                    { error: 'Rate limit exceeded: Too many notification requests. Please wait a minute.' },
                    { status: 429 }
                );
            }

            // 2. Same-Origin Verification (blocks cross-site script forging)
            const secFetchSite = request.headers.get('sec-fetch-site');
            const origin = request.headers.get('origin');
            const isSameOrigin =
                secFetchSite === 'same-origin' ||
                !origin ||
                origin === url.origin ||
                origin.includes('localhost') ||
                origin.includes('127.0.0.1');

            if (!isSameOrigin) {
                return Response.json(
                    { error: 'Cross-origin requests are forbidden.' },
                    { status: 403 }
                );
            }

            // 3. Parse JSON Body
            let body: NotifyRequest;
            try {
                body = await request.json();
            } catch {
                return Response.json({ error: 'Invalid JSON payload' }, { status: 400 });
            }

            // 4. Strict Field-by-Field Validation
            const sport = body.sport || 'tennis';
            const leagueId = body.leagueId || 'winter-contract-kyle';
            const target = body.target || 'public';

            if (typeof sport !== 'string' || !/^[a-zA-Z0-9_-]{2,30}$/.test(sport)) {
                return Response.json({ error: "Invalid 'sport': must be 2-30 alphanumeric characters/hyphens." }, { status: 400 });
            }

            if (typeof leagueId !== 'string' || !/^[a-zA-Z0-9_-]{2,50}$/.test(leagueId)) {
                return Response.json({ error: "Invalid 'leagueId': must be 2-50 alphanumeric characters/hyphens." }, { status: 400 });
            }

            if (target !== 'public' && target !== 'admin') {
                return Response.json({ error: "Invalid 'target': must be 'public' or 'admin'." }, { status: 400 });
            }

            if (body.title !== undefined) {
                if (typeof body.title !== 'string' || body.title.length > 100) {
                    return Response.json({ error: "'title' must be a string up to 100 characters." }, { status: 400 });
                }
            }

            if (body.author !== undefined) {
                if (typeof body.author !== 'string' || body.author.length > 64) {
                    return Response.json({ error: "'author' must be a string up to 64 characters." }, { status: 400 });
                }
            }

            // Enforce max length = 100 characters on message
            if (body.message !== undefined) {
                if (typeof body.message !== 'string') {
                    return Response.json({ error: "'message' must be a string." }, { status: 400 });
                }
                if (body.message.length > 100) {
                    return Response.json({ error: "'message' exceeds maximum length of 100 characters." }, { status: 400 });
                }
            }

            if (body.color !== undefined) {
                if (typeof body.color !== 'number' || !Number.isInteger(body.color) || body.color < 0 || body.color > 0xffffff) {
                    return Response.json({ error: "'color' must be a valid integer between 0 and 16777215 (0xFFFFFF)." }, { status: 400 });
                }
            }

            if (body.fields !== undefined) {
                if (!Array.isArray(body.fields) || body.fields.length > 25) {
                    return Response.json({ error: "'fields' must be an array of at most 25 items." }, { status: 400 });
                }
                for (let i = 0; i < body.fields.length; i++) {
                    const err = validateField(body.fields[i], i);
                    if (err) return Response.json({ error: err }, { status: 400 });
                }
            }

            // Validate nested embed if supplied
            if (body.embed !== undefined) {
                if (!body.embed || typeof body.embed !== 'object') {
                    return Response.json({ error: "'embed' must be an object." }, { status: 400 });
                }
                // Enforce max length = 100 characters on embed.title
                if (body.embed.title !== undefined && (typeof body.embed.title !== 'string' || body.embed.title.length > 100)) {
                    return Response.json({ error: "'embed.title' must be a string up to 100 characters." }, { status: 400 });
                }
                // Enforce max length = 100 characters on embed.description as well
                if (body.embed.description !== undefined) {
                    if (typeof body.embed.description !== 'string') {
                        return Response.json({ error: "'embed.description' must be a string." }, { status: 400 });
                    }
                    if (body.embed.description.length > 100) {
                        return Response.json({ error: "'embed.description' exceeds maximum length of 100 characters." }, { status: 400 });
                    }
                }
                // Enforce max length = 100 characters on embed.footer.text
                if (body.embed.footer !== undefined) {
                    if (!body.embed.footer || typeof body.embed.footer !== 'object') {
                        return Response.json({ error: "'embed.footer' must be an object." }, { status: 400 });
                    }
                    if (body.embed.footer.text !== undefined) {
                        if (typeof body.embed.footer.text !== 'string' || body.embed.footer.text.length > 100) {
                            return Response.json({ error: "'embed.footer.text' must be a string up to 100 characters." }, { status: 400 });
                        }
                    }
                }
                if (body.embed.color !== undefined && (typeof body.embed.color !== 'number' || body.embed.color < 0 || body.embed.color > 0xffffff)) {
                    return Response.json({ error: "'embed.color' must be a valid integer between 0 and 0xFFFFFF." }, { status: 400 });
                }
                if (body.embed.fields !== undefined) {
                    if (!Array.isArray(body.embed.fields) || body.embed.fields.length > 25) {
                        return Response.json({ error: "'embed.fields' must be an array of at most 25 items." }, { status: 400 });
                    }
                    for (let i = 0; i < body.embed.fields.length; i++) {
                        const err = validateField(body.embed.fields[i], i);
                        if (err) return Response.json({ error: err }, { status: 400 });
                    }
                }
            }

            // Must have either an embed, a title, or a message
            if (!body.embed && !body.message && !body.title) {
                return Response.json(
                    { error: 'A message, title, or embed payload is required.' },
                    { status: 400 }
                );
            }

            // 5. Resolve Webhook URL from KV
            const kvKey = `${sport}:${leagueId}:${target}`;
            const webhookUrl =
                (await env.DISCORD_WEBHOOKS.get(kvKey)) ||
                (await env.DISCORD_WEBHOOKS.get(`${sport}:${leagueId}-${target}`));

            if (!webhookUrl) {
                return Response.json(
                    { error: `No webhook configured for ${sport}:${leagueId}:${target}` },
                    { status: 404 }
                );
            }

            // 6. Assemble Discord Embed
            const isUrgentAdmin = target === 'admin';
            const embedToUse = body.embed
                ? {
                      ...body.embed,
                      description: body.embed.description ? body.embed.description.slice(0, 100) : undefined,
                      footer: body.embed.footer || { text: 'Winter Tennis League Notifications 🎾' },
                      timestamp: body.embed.timestamp || new Date().toISOString(),
                  }
                : {
                      title: body.title || (isUrgentAdmin ? '🚨 Admin Alert' : '📢 League Notification'),
                      description: (body.message || '').trim().slice(0, 100),
                      color: body.color || (isUrgentAdmin ? 0xed4245 : 0x5865f2),
                      fields: [
                          { name: 'League', value: leagueId, inline: true },
                          { name: 'Sport', value: sport, inline: true },
                          ...(body.fields || []),
                      ],
                      footer: { text: body.author ? `Sent by ${body.author}` : 'Winter Tennis League Bot 🎾' },
                      timestamp: new Date().toISOString(),
                  };

            const discordPayload = {
                username: 'Winter Tennis League Bot',
                avatar_url: 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=128&auto=format&fit=crop&q=80',
                embeds: [embedToUse],
            };

            // 7. Dispatch to Discord
            const res = await fetch(webhookUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(discordPayload),
            });

            if (!res.ok) {
                const errText = await res.text().catch(() => '');
                return Response.json(
                    { error: `Failed to deliver to Discord (${res.status}): ${errText}` },
                    { status: 502 }
                );
            }

            return Response.json({ ok: true }, { status: 200 });
        }

        return env.ASSETS.fetch(request);
    },
};