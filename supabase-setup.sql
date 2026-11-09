-- ══════════════════════════════════════════════════════════════════════
-- IAê Financeiro — Supabase Setup
-- Execute este script no SQL Editor do seu projeto Supabase
-- (supabase.com → seu projeto → SQL Editor → New Query → Cole e Execute)
-- ══════════════════════════════════════════════════════════════════════

-- 1. TABELAS ────────────────────────────────────────────────────────────

-- Empresas / PMEs
create table if not exists companies (
  id         uuid default gen_random_uuid() primary key,
  name       text not null,
  code       char(6) unique not null,   -- código de convite para novos usuários
  created_by uuid references auth.users,
  created_at timestamptz default now()
);

-- Perfis de usuário (estende auth.users)
create table if not exists profiles (
  id         uuid references auth.users primary key,
  name       text not null,
  company_id uuid references companies,
  role       text default 'member',     -- 'owner' | 'member'
  created_at timestamptz default now()
);

-- Sistemas financeiros por empresa (um por cliente da PME)
create table if not exists sistemas (
  id           text primary key,        -- uid gerado pelo app
  company_id   uuid references companies not null,
  nome         text,
  segmento     text,
  responsavel  text,
  ferramentas  jsonb default '[]',
  criado       timestamptz default now()
);

-- Dados dos módulos (substitui localStorage iae_sys_{sid}_{key})
create table if not exists system_data (
  company_id  uuid references companies not null,
  sistema_id  text not null,
  key         text not null,            -- 'crm', 'estoque', 'contas', 'dre', etc.
  value       jsonb,
  updated_at  timestamptz default now(),
  primary key (company_id, sistema_id, key)
);

-- 2. ROW LEVEL SECURITY ────────────────────────────────────────────────

alter table companies   enable row level security;
alter table profiles    enable row level security;
alter table sistemas    enable row level security;
alter table system_data enable row level security;

-- Usuário vê/edita apenas sua própria empresa
create policy "company members only" on companies for all
  using (id = (select company_id from profiles where id = auth.uid()));

-- Usuário vê/edita apenas seu próprio perfil
create policy "own profile only" on profiles for all
  using (auth.uid() = id);

-- Sistemas da mesma empresa
create policy "company sistemas" on sistemas for all
  using (company_id = (select company_id from profiles where id = auth.uid()));

-- Dados dos sistemas da mesma empresa
create policy "company system data" on system_data for all
  using (company_id = (select company_id from profiles where id = auth.uid()));

-- 3. REALTIME ──────────────────────────────────────────────────────────
-- Habilita realtime nas tabelas relevantes
alter publication supabase_realtime add table system_data;
alter publication supabase_realtime add table sistemas;

-- ══════════════════════════════════════════════════════════════════════
-- PRONTO! Após rodar este script:
-- 1. Abra sistema-integrado.html num editor de texto
-- 2. No topo do <script>, substitua:
--      const SUPABASE_URL = 'COLE_SUA_URL_AQUI';
--      const SUPABASE_KEY = 'COLE_SUA_ANON_KEY_AQUI';
--    pelos valores em: supabase.com → seu projeto → Settings → API
-- 3. Salve e abra o arquivo no navegador
-- ══════════════════════════════════════════════════════════════════════
