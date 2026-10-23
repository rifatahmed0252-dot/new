-- Thai Glass Inventory: initial Supabase schema draft
-- Review and run in Supabase SQL Editor only after creating your project.
create extension if not exists pgcrypto;

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Thai Glass Inventory',
  currency text not null default 'BDT' check (currency = 'BDT'),
  default_language text not null default 'bn' check (default_language in ('bn','en')),
  created_at timestamptz not null default now()
);

create table if not exists public.business_members (
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','manager','employee')),
  created_at timestamptz not null default now(),
  primary key (business_id, user_id)
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (business_id, name)
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  sku text,
  name text not null,
  category_id uuid references public.categories(id) on delete set null,
  unit text not null,
  length_ft numeric(12,3),
  purchase_price numeric(14,2) not null default 0 check (purchase_price >= 0),
  selling_price numeric(14,2) not null default 0 check (selling_price >= 0),
  low_stock_threshold numeric(14,3) not null default 0 check (low_stock_threshold >= 0),
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_id uuid not null references public.products(id),
  movement_type text not null check (movement_type in ('opening','purchase','sale','adjustment_in','adjustment_out','return_in','return_out')),
  quantity_delta numeric(14,3) not null check (quantity_delta <> 0),
  unit_cost numeric(14,2) not null default 0,
  reference_type text,
  reference_id uuid,
  note text,
  created_by uuid references auth.users(id),
  device_id text,
  created_at timestamptz not null default now(),
  client_created_at timestamptz
);

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  invoice_number text,
  supplier_name text,
  total_amount numeric(14,2) not null default 0,
  status text not null default 'posted' check (status in ('draft','posted','void')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases(id) on delete cascade,
  product_id uuid not null references public.products(id),
  quantity numeric(14,3) not null check (quantity > 0),
  unit_cost numeric(14,2) not null check (unit_cost >= 0),
  line_total numeric(14,2) not null check (line_total >= 0)
);

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  invoice_number text not null,
  customer_name text,
  total_amount numeric(14,2) not null default 0,
  status text not null default 'posted' check (status in ('draft','posted','void')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (business_id, invoice_number)
);

create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  product_id uuid not null references public.products(id),
  product_name_snapshot text not null,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  unit_cost_snapshot numeric(14,2) not null default 0,
  line_total numeric(14,2) not null check (line_total >= 0)
);

create table if not exists public.price_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  product_id uuid not null references public.products(id),
  old_purchase_price numeric(14,2),
  new_purchase_price numeric(14,2),
  old_selling_price numeric(14,2),
  new_selling_price numeric(14,2),
  changed_by uuid references auth.users(id),
  changed_at timestamptz not null default now()
);

create index if not exists products_business_idx on public.products(business_id);
create index if not exists movements_business_date_idx on public.stock_movements(business_id, created_at desc);
create index if not exists sales_business_date_idx on public.sales(business_id, created_at desc);

-- IMPORTANT before production:
-- Enable RLS on every table, add policies scoped to business_members,
-- and perform stock validation + sale posting in a database transaction/RPC.
-- Never expose a service_role key in browser code.

-- V4: browser app login + shared workspace JSON sync.
-- Run this complete file in Supabase SQL Editor after creating a project.
create table if not exists public.business_app_state (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.business_app_state enable row level security;

-- Members can only see workspaces where they are members.
drop policy if exists businesses_member_select on public.businesses;
create policy businesses_member_select on public.businesses for select to authenticated
using (exists (select 1 from public.business_members bm where bm.business_id=id and bm.user_id=auth.uid()));

drop policy if exists business_members_workspace_select on public.business_members;
create policy business_members_workspace_select on public.business_members for select to authenticated
using (user_id=auth.uid());

drop policy if exists business_state_member_select on public.business_app_state;
create policy business_state_member_select on public.business_app_state for select to authenticated
using (exists (select 1 from public.business_members bm where bm.business_id=business_app_state.business_id and bm.user_id=auth.uid()));

drop policy if exists business_state_member_insert on public.business_app_state;
create policy business_state_member_insert on public.business_app_state for insert to authenticated
with check (exists (select 1 from public.business_members bm where bm.business_id=business_app_state.business_id and bm.user_id=auth.uid()));

drop policy if exists business_state_member_update on public.business_app_state;
create policy business_state_member_update on public.business_app_state for update to authenticated
using (exists (select 1 from public.business_members bm where bm.business_id=business_app_state.business_id and bm.user_id=auth.uid()))
with check (exists (select 1 from public.business_members bm where bm.business_id=business_app_state.business_id and bm.user_id=auth.uid()));

create or replace function public.create_business_workspace(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'Login required'; end if;
  insert into public.businesses(name) values (coalesce(nullif(trim(p_name),''),'Thai Glass Shop')) returning id into new_id;
  insert into public.business_members(business_id,user_id,role) values (new_id,auth.uid(),'owner');
  return new_id;
end;
$$;
revoke all on function public.create_business_workspace(text) from public;
grant execute on function public.create_business_workspace(text) to authenticated;

create or replace function public.add_business_member_by_email(p_business_id uuid, p_email text, p_role text default 'employee')
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare target_user uuid;
begin
  if auth.uid() is null then raise exception 'Login required'; end if;
  if not exists (select 1 from public.business_members where business_id=p_business_id and user_id=auth.uid() and role='owner') then
    raise exception 'Only the workspace owner can add members';
  end if;
  if p_role not in ('employee','manager') then raise exception 'Invalid role'; end if;
  select id into target_user from auth.users where lower(email)=lower(trim(p_email)) limit 1;
  if target_user is null then raise exception 'That email has not created an account in this Supabase project yet'; end if;
  insert into public.business_members(business_id,user_id,role) values (p_business_id,target_user,p_role)
  on conflict (business_id,user_id) do update set role=excluded.role;
end;
$$;
revoke all on function public.add_business_member_by_email(uuid,text,text) from public;
grant execute on function public.add_business_member_by_email(uuid,text,text) to authenticated;

-- The app uses business_app_state for shared data. Do not put service_role keys in the website.
-- NOTE: the legacy normalized tables above are not used by the current front-end JSON sync.

-- Explicit API permissions: only the current app-state workflow is exposed to normal users.
grant select on public.businesses, public.business_members to authenticated;
grant select, insert, update on public.business_app_state to authenticated;

-- Legacy normalized tables are not used by this version's front-end. Keep them closed until
-- table-specific policies and transaction-safe posting routines are added.
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.stock_movements enable row level security;
alter table public.purchases enable row level security;
alter table public.purchase_items enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.price_history enable row level security;
revoke all on public.categories, public.products, public.stock_movements, public.purchases,
  public.purchase_items, public.sales, public.sale_items, public.price_history from anon, authenticated;
