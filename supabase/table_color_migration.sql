-- ============================================================
-- Komo POS — Table Color Migration
-- Run this in Supabase SQL Editor
-- ============================================================

-- Add color column to tables for custom icon background
ALTER TABLE public.tables ADD COLUMN IF NOT EXISTS color text DEFAULT '#162456';

-- Done!
