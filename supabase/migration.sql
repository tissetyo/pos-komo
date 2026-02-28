-- --------------------------------------------------------
-- Komo POS Migration: Product Variations + Order Item Updates
-- Run this in Supabase SQL Editor
-- --------------------------------------------------------

-- 1. Create product_variations table
create table if not exists public.product_variations (
  id uuid default uuid_generate_v4() primary key,
  product_id uuid references public.products on delete cascade not null,
  label text not null,            -- e.g. "Temperature", "Size", "Sugar Level"
  options jsonb not null default '[]',  -- e.g. [{"name":"Hot","price_adj":0},{"name":"Cold","price_adj":200}]
  sort_order integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Add variation_snapshot to order_items (stores selected options at time of order)
alter table public.order_items add column if not exists variation_snapshot jsonb;

-- 3. RLS for product_variations
alter table public.product_variations enable row level security;

create policy "Enable read access for authenticated users" on public.product_variations
  for select using (auth.role() = 'authenticated');

create policy "Enable insert for authenticated users" on public.product_variations
  for insert with check (auth.role() = 'authenticated');

create policy "Enable update for authenticated users" on public.product_variations
  for update using (auth.role() = 'authenticated');

create policy "Enable delete for authenticated users" on public.product_variations
  for delete using (auth.role() = 'authenticated');

-- 4. Create storage bucket for product images (run separately if needed)
-- insert into storage.buckets (id, name, public) values ('product-images', 'product-images', true);

-- Done! You can now use product variations and image uploads.
