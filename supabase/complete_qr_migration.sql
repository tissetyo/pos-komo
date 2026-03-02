-- ============================================================
-- QUICK FIX: Allow public (anonymous) order placement
-- Run this in Supabase SQL Editor NOW to fix the RLS error
-- ============================================================

-- Allow anonymous users to INSERT orders (for QR table ordering)
DROP POLICY IF EXISTS "Public insert orders" ON public.orders;
CREATE POLICY "Public insert orders" ON public.orders
  FOR INSERT WITH CHECK (true);

-- Allow anonymous users to INSERT order items
DROP POLICY IF EXISTS "Public insert order_items" ON public.order_items;
CREATE POLICY "Public insert order_items" ON public.order_items
  FOR INSERT WITH CHECK (true);

-- Allow anonymous users to READ tables (needed to resolve QR token)
DROP POLICY IF EXISTS "Public read tables by token" ON public.tables;
CREATE POLICY "Public read tables by token" ON public.tables
  FOR SELECT USING (true);

-- Allow anonymous users to READ products, categories, outlets for the menu
DROP POLICY IF EXISTS "Public read products" ON public.products;
CREATE POLICY "Public read products" ON public.products
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read categories" ON public.categories;
CREATE POLICY "Public read categories" ON public.categories
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read outlets" ON public.outlets;
CREATE POLICY "Public read outlets" ON public.outlets
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read product_variations" ON public.product_variations;
CREATE POLICY "Public read product_variations" ON public.product_variations
  FOR SELECT USING (true);

-- Add table ordering columns if not present
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS table_id uuid;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS source text DEFAULT 'cashier';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_name text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_phone text;

-- Add color column for tables
ALTER TABLE public.tables ADD COLUMN IF NOT EXISTS color text DEFAULT '#162456';

-- Done! QR ordering should now work.
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
