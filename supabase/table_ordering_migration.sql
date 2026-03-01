-- ============================================================
-- Komo POS — Table Ordering Migration
-- Run this in Supabase SQL Editor
-- ============================================================

-- Enable pgcrypto for gen_random_bytes
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Tables table
CREATE TABLE IF NOT EXISTS public.tables (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  table_number text NOT NULL,
  qr_token text UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(8), 'hex'),
  outlet_id uuid REFERENCES public.outlets NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Add table reference + source to orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS table_id uuid REFERENCES public.tables;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS source text DEFAULT 'cashier';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_name text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_phone text;

-- 3. RLS for tables
ALTER TABLE public.tables ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Public read tables by token" ON public.tables;
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.tables;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.tables;
  DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.tables;
  DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.tables;

  -- Public can read tables (needed for QR scan — unauthenticated)
  CREATE POLICY "Public read tables by token" ON public.tables
    FOR SELECT USING (true);

  -- Authenticated users can manage tables
  CREATE POLICY "Enable insert for authenticated users" ON public.tables
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  CREATE POLICY "Enable update for authenticated users" ON public.tables
    FOR UPDATE USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable delete for authenticated users" ON public.tables
    FOR DELETE USING (auth.role() = 'authenticated');
END $$;

-- 4. Allow public (anon) to read products, categories, outlets for QR ordering
DO $$ BEGIN
  DROP POLICY IF EXISTS "Public read products" ON public.products;
  CREATE POLICY "Public read products" ON public.products
    FOR SELECT USING (true);
END $$;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Public read categories" ON public.categories;
  CREATE POLICY "Public read categories" ON public.categories
    FOR SELECT USING (true);
END $$;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Public read outlets" ON public.outlets;
  CREATE POLICY "Public read outlets" ON public.outlets
    FOR SELECT USING (true);
END $$;

-- 5. Allow anon to insert orders & order_items (for QR orders)
DO $$ BEGIN
  DROP POLICY IF EXISTS "Public insert orders" ON public.orders;
  CREATE POLICY "Public insert orders" ON public.orders
    FOR INSERT WITH CHECK (true);
END $$;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Public insert order_items" ON public.order_items;
  CREATE POLICY "Public insert order_items" ON public.order_items
    FOR INSERT WITH CHECK (true);
END $$;

-- 6. Allow public read on product_variations
DO $$ BEGIN
  DROP POLICY IF EXISTS "Public read product_variations" ON public.product_variations;
  CREATE POLICY "Public read product_variations" ON public.product_variations
    FOR SELECT USING (true);
END $$;

-- Done!
