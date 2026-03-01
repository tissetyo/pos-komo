-- ============================================================
-- Komo POS — Payment Settings Migration
-- Run this in Supabase SQL Editor
-- ============================================================

-- Add payment-related columns to outlets table
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS rounding text DEFAULT 'none';
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS payment_methods jsonb DEFAULT '{"cash": true, "qris": false, "debit": false, "credit": false}';
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS integrations jsonb DEFAULT '{}';

-- Done!
