-- ══════════════════════════════════════════════════════════════════════
-- Migration: 001 — Schema inicial IAê Financeiro
-- Aplicar em: supabase.com → SQL Editor
-- ══════════════════════════════════════════════════════════════════════

-- 1. TABELAS
create table if not exists companies (
  id         uuid default gen_random_uuid() primary key,
  name       text not null,
  code       char(6) unique not null,
  created_by uuid references auth.users,
  created_at timestamptz default now()
);

create table if not exists profiles (
  id         uuid references auth.users primary key,
  name       text not null,
  company_id uuid references companies,
  role       text default 'member',
  created_at timestamptz default now()
);

create table if not exists sistemas (
  id           text primary key,
  company_id   uuid references companies not null,
  nome         text,
  segmento     text,
  responsavel  text,
  ferramentas  jsonb default '[]',
  criado       timestamptz default now()
);

create table if not exists system_data (
  company_id  uuid references companies not null,
  sistema_id  text not null,
  key         text not null,
  value       jsonb,
  updated_at  timestamptz default now(),
  primary key (company_id, sistema_id, key)
);

-- 2. ROW LEVEL SECURITY
alter table companies   enable row level security;
alter table profiles    enable row level security;
alter table sistemas    enable row level security;
alter table system_data enable row level security;

-- 3. GRANTS
grant usage on schema public to authenticated;
grant select, insert, update, delete on table companies   to authenticated;
grant select, insert, update, delete on table profiles    to authenticated;
grant select, insert, update, delete on table sistemas    to authenticated;
grant select, insert, update, delete on table system_data to authenticated;
grant usage on schema public to anon;

-- 4. POLÍTICAS RLS
-- Companies: qualquer autenticado pode buscar (necessário para busca por código de convite)
create policy "companies_select" on companies
  for select using (auth.uid() is not null);

-- Companies: qualquer autenticado pode criar empresa
create policy "companies_insert" on companies
  for insert with check (auth.uid() = created_by);

-- Companies: apenas membros podem atualizar
create policy "companies_update" on companies
  for update using (id in (select company_id from profiles where id = auth.uid()));

-- Profiles: usuário insere apenas o próprio perfil
create policy "profiles_insert" on profiles
  for insert with check (auth.uid() = id);

-- Profiles: usuário lê apenas o próprio perfil
create policy "profiles_select" on profiles
  for select using (auth.uid() = id);

-- Profiles: usuário atualiza apenas o próprio perfil
create policy "profiles_update" on profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- Sistemas: apenas membros da empresa
create policy "sistemas_all" on sistemas
  for all using (company_id in (select company_id from profiles where id = auth.uid()));

-- System data: apenas membros da empresa
create policy "system_data_all" on system_data
  for all using (company_id in (select company_id from profiles where id = auth.uid()));

-- 5. REALTIME
alter publication supabase_realtime add table system_data;
alter publication supabase_realtime add table sistemas;
