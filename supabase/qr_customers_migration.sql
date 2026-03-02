-- ============================================================
-- Komo POS — QR Customers Migration
-- Run this in Supabase SQL Editor
-- ============================================================

-- Allow anonymous users to READ customers (so we can check if they exist by phone)
DROP POLICY IF EXISTS "Public read customers" ON public.customers;
CREATE POLICY "Public read customers" ON public.customers
  FOR SELECT USING (true);

-- Allow anonymous users to INSERT customers (for new QR customers)
DROP POLICY IF EXISTS "Public insert customers" ON public.customers;
CREATE POLICY "Public insert customers" ON public.customers
  FOR INSERT WITH CHECK (true);

-- Allow anonymous users to UPDATE customers (to update their name on repeat orders)
DROP POLICY IF EXISTS "Public update customers" ON public.customers;
CREATE POLICY "Public update customers" ON public.customers
  FOR UPDATE USING (true);

-- Done! QR customers will now auto-save.
