-- ============================================================
-- Komo POS — Complete Migration Script
-- Run this ONCE in Supabase SQL Editor
-- Safe to run: uses IF NOT EXISTS / IF EXISTS everywhere
-- ============================================================

-- 0. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. ADD MISSING COLUMNS TO EXISTING TABLES
-- ============================================================

-- Profiles: add columns the app needs
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS outlet_id uuid REFERENCES public.outlets(id);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pin text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_step integer DEFAULT 1;

-- Outlets: add columns the app needs
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS timezone text DEFAULT 'Asia/Jakarta';
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS store_type text;
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS currency text DEFAULT 'MYR';
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS sst integer DEFAULT 6;
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS service_charge integer DEFAULT 10;
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS tax_id text;
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS receipt_header text;
ALTER TABLE public.outlets ADD COLUMN IF NOT EXISTS receipt_footer text;

-- Products: add columns the app needs
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS cost integer;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS barcode text;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

-- Order Items: add variation snapshot
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS variation_snapshot jsonb;

-- ============================================================
-- 2. CREATE MISSING TABLES
-- ============================================================

-- Product Variations table
CREATE TABLE IF NOT EXISTS public.product_variations (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_id uuid REFERENCES public.products ON DELETE CASCADE NOT NULL,
  label text NOT NULL,
  options jsonb NOT NULL DEFAULT '[]',
  sort_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ============================================================
-- 3. ENABLE RLS ON ALL TABLES
-- ============================================================

ALTER TABLE public.outlets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variations ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. RLS POLICIES (drop if exists, then create)
-- ============================================================

-- Helper: safe policy creation (drop first if exists)
-- Outlets
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.outlets;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.outlets;
  DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.outlets;
  CREATE POLICY "Enable read access for authenticated users" ON public.outlets FOR SELECT USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable insert for authenticated users" ON public.outlets FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  CREATE POLICY "Enable update for authenticated users" ON public.outlets FOR UPDATE USING (auth.role() = 'authenticated');
END $$;

-- Profiles
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.profiles;
  DROP POLICY IF EXISTS "Enable insert for service role" ON public.profiles;
  DROP POLICY IF EXISTS "Enable update own profile" ON public.profiles;
  CREATE POLICY "Enable read access for authenticated users" ON public.profiles FOR SELECT USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable insert for service role" ON public.profiles FOR INSERT WITH CHECK (true);
  CREATE POLICY "Enable update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
END $$;

-- Categories
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.categories;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.categories;
  DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.categories;
  DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.categories;
  CREATE POLICY "Enable read access for authenticated users" ON public.categories FOR SELECT USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable insert for authenticated users" ON public.categories FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  CREATE POLICY "Enable update for authenticated users" ON public.categories FOR UPDATE USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable delete for authenticated users" ON public.categories FOR DELETE USING (auth.role() = 'authenticated');
END $$;

-- Products
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.products;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.products;
  DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.products;
  DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.products;
  CREATE POLICY "Enable read access for authenticated users" ON public.products FOR SELECT USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable insert for authenticated users" ON public.products FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  CREATE POLICY "Enable update for authenticated users" ON public.products FOR UPDATE USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable delete for authenticated users" ON public.products FOR DELETE USING (auth.role() = 'authenticated');
END $$;

-- Customers
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.customers;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.customers;
  DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.customers;
  DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.customers;
  CREATE POLICY "Enable read access for authenticated users" ON public.customers FOR SELECT USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable insert for authenticated users" ON public.customers FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  CREATE POLICY "Enable update for authenticated users" ON public.customers FOR UPDATE USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable delete for authenticated users" ON public.customers FOR DELETE USING (auth.role() = 'authenticated');
END $$;

-- Orders
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.orders;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.orders;
  DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.orders;
  CREATE POLICY "Enable read access for authenticated users" ON public.orders FOR SELECT USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable insert for authenticated users" ON public.orders FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  CREATE POLICY "Enable update for authenticated users" ON public.orders FOR UPDATE USING (auth.role() = 'authenticated');
END $$;

-- Order Items
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.order_items;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.order_items;
  CREATE POLICY "Enable read access for authenticated users" ON public.order_items FOR SELECT USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable insert for authenticated users" ON public.order_items FOR INSERT WITH CHECK (auth.role() = 'authenticated');
END $$;

-- Product Variations
DO $$ BEGIN
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.product_variations;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.product_variations;
  DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.product_variations;
  DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.product_variations;
  CREATE POLICY "Enable read access for authenticated users" ON public.product_variations FOR SELECT USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable insert for authenticated users" ON public.product_variations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  CREATE POLICY "Enable update for authenticated users" ON public.product_variations FOR UPDATE USING (auth.role() = 'authenticated');
  CREATE POLICY "Enable delete for authenticated users" ON public.product_variations FOR DELETE USING (auth.role() = 'authenticated');
END $$;

-- ============================================================
-- 5. AUTO-PROFILE + AUTO-OUTLET TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  new_outlet_id uuid;
BEGIN
  -- Create outlet if store_name provided in signup metadata
  IF new.raw_user_meta_data->>'store_name' IS NOT NULL THEN
    INSERT INTO public.outlets (name)
    VALUES (new.raw_user_meta_data->>'store_name')
    RETURNING id INTO new_outlet_id;
  END IF;

  -- Create profile linked to the outlet
  INSERT INTO public.profiles (id, email, full_name, role, outlet_id)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.raw_user_meta_data->>'role', 'admin'),
    new_outlet_id
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ============================================================
-- 6. FIX EXISTING DATA — Link profiles to outlets
-- ============================================================
-- For any profiles that have NULL outlet_id, try to link them
-- to the first outlet that exists (you can adjust this manually after)
UPDATE public.profiles
SET outlet_id = (SELECT id FROM public.outlets ORDER BY created_at ASC LIMIT 1)
WHERE outlet_id IS NULL
  AND (SELECT COUNT(*) FROM public.outlets) > 0;

-- ============================================================
-- DONE! All tables and columns are now in sync.
-- ============================================================
