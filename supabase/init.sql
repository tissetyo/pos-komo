-- --------------------------------------------------------
-- Komo POS Init Supabase Schema
-- --------------------------------------------------------

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Create Outlets Table
create table public.outlets (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  address text,
  phone text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Create Profiles Table (extends auth.users)
create table public.profiles (
  id uuid references auth.users not null primary key,
  email text,
  full_name text,
  role text check (role in ('admin', 'manager', 'cashier', 'kitchen')),
  outlet_id uuid references public.outlets,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Create Categories Table
create table public.categories (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  outlet_id uuid references public.outlets,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Create Products Table
create table public.products (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  description text,
  price integer not null,
  cost integer,
  sku text,
  barcode text,
  stock integer default 0,
  category_id uuid references public.categories,
  outlet_id uuid references public.outlets,
  image_url text,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Create Customers Table
create table public.customers (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  phone text,
  email text,
  address text,
  outlet_id uuid references public.outlets,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Create Orders Table
create table public.orders (
  id uuid default uuid_generate_v4() primary key,
  receipt_number text not null,
  customer_id uuid references public.customers,
  outlet_id uuid references public.outlets,
  cashier_id uuid references public.profiles,
  subtotal integer not null,
  tax integer not null,
  discount integer default 0,
  total integer not null,
  payment_method text check (payment_method in ('cash', 'qris', 'debit', 'credit')),
  payment_status text check (payment_status in ('pending', 'paid', 'failed', 'refunded')),
  order_status text check (order_status in ('new', 'preparing', 'ready', 'completed', 'cancelled')),
  order_type text check (order_type in ('dine-in', 'takeaway', 'delivery')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. Create Order Items Table
create table public.order_items (
  id uuid default uuid_generate_v4() primary key,
  order_id uuid references public.orders not null,
  product_id uuid references public.products not null,
  quantity integer not null,
  unit_price integer not null,
  total_price integer not null,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- --------------------------------------------------------
-- RLS Policies Setup (Row Level Security)
-- --------------------------------------------------------
alter table public.outlets enable row level security;
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- Basic read-all policies for authenticated users
create policy "Enable read access for authenticated users" on public.outlets for select using (auth.role() = 'authenticated');
create policy "Enable read access for authenticated users" on public.profiles for select using (auth.role() = 'authenticated');
create policy "Enable read access for authenticated users" on public.categories for select using (auth.role() = 'authenticated');
create policy "Enable read access for authenticated users" on public.products for select using (auth.role() = 'authenticated');
create policy "Enable read access for authenticated users" on public.customers for select using (auth.role() = 'authenticated');
create policy "Enable read access for authenticated users" on public.orders for select using (auth.role() = 'authenticated');
create policy "Enable read access for authenticated users" on public.order_items for select using (auth.role() = 'authenticated');

-- Basic insert policies for authenticated users
create policy "Enable insert for authenticated users" on public.categories for insert with check (auth.role() = 'authenticated');
create policy "Enable insert for authenticated users" on public.products for insert with check (auth.role() = 'authenticated');
create policy "Enable insert for authenticated users" on public.customers for insert with check (auth.role() = 'authenticated');
create policy "Enable insert for authenticated users" on public.orders for insert with check (auth.role() = 'authenticated');
create policy "Enable insert for authenticated users" on public.order_items for insert with check (auth.role() = 'authenticated');
create policy "Enable update for authenticated users" on public.orders for update using (auth.role() = 'authenticated');
create policy "Enable update for authenticated users" on public.products for update using (auth.role() = 'authenticated');
