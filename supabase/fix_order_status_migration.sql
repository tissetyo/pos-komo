-- ============================================================
-- Komo POS — Fix Order Status Constraint
-- Run this in Supabase SQL Editor
-- ============================================================

-- Drop the existing check constraint on order_status
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_order_status_check;

-- Add a new check constraint that includes the 'processing' and 'ready' statuses
ALTER TABLE public.orders ADD CONSTRAINT orders_order_status_check 
CHECK (order_status IN ('new', 'processing', 'ready', 'completed', 'cancelled', 'refunded'));
