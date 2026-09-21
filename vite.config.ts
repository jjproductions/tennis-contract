import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  return {
    plugins: [
      vue(),
      tailwindcss(),
      {
        name: 'local-discord-dev-proxy',
        configureServer(server) {
          server.middlewares.use('/api/notify-discord', async (req, res) => {
            if (req.method === 'POST') {
              let bodyStr = '';
              req.on('data', (chunk) => {
                bodyStr += chunk;
              });
              req.on('end', async () => {
                try {
                  const body = JSON.parse(bodyStr || '{}');
                  const target = body.target || 'public';

                  // Use local env webhooks if available during dev
                  const webhookUrl =
                    (target === 'admin' ? env.VITE_DISCORD_ADMIN_WEBHOOK_URL : null) ||
                    env.VITE_DISCORD_WEBHOOK_URL;

                  if (webhookUrl) {
                    const discordPayload = {
                      username: 'Winter Tennis League Bot (Dev)',
                      avatar_url: 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=128&auto=format&fit=crop&q=80',
                      embeds: [body.embed || { title: body.title, description: body.message }],
                    };

                    const discordRes = await fetch(webhookUrl, {
                      method: 'POST',
                      headers: { 'Content-Type': 'application/json' },
                      body: JSON.stringify(discordPayload),
                    });

                    res.statusCode = discordRes.ok ? 200 : discordRes.status;
                    res.setHeader('Content-Type', 'application/json');
                    res.end(JSON.stringify({ ok: true, devForwarded: true }));
                    return;
                  }

                  // If no local webhook in .env, mock gracefully and log to terminal
                  console.log(
                    `\x1b[35m[Local Dev Notification - ${target.toUpperCase()}]\x1b[0m`,
                    body.title || body.embed?.title || body.message
                  );
                  res.statusCode = 200;
                  res.setHeader('Content-Type', 'application/json');
                  res.end(JSON.stringify({ ok: true, devMock: true }));
                } catch (err: any) {
                  res.statusCode = 400;
                  res.setHeader('Content-Type', 'application/json');
                  res.end(JSON.stringify({ error: err.message }));
                }
              });
            } else {
              res.statusCode = 405;
              res.end('Method Not Allowed');
            }
          });
        },
      },
    ],
  };
});