-- Migration: Create league_settings table for storing global app configuration (e.g. Discord Webhook & event notification triggers)

CREATE TABLE IF NOT EXISTS public.league_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.league_settings ENABLE ROW LEVEL SECURITY;

-- Allow public read access to settings
CREATE POLICY "Allow public read access on league_settings"
  ON public.league_settings FOR SELECT
  TO public
  USING (true);

-- Allow write access to settings
CREATE POLICY "Allow public write access on league_settings"
  ON public.league_settings FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);
