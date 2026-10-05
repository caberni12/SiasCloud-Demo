-- SIASCLOUD 3.0.1 · SQL MAESTRO COMPLETO BASADO EN 2.4.1
-- Para una instalación existente usar ACTUALIZACION_SIASCLOUD_V3_0.sql.

-- SIASCLOUD ERP 2.3.1 · SQL MAESTRO COMPLETO Y ADITIVO
-- BASE NUEVA O EXISTENTE EN SUPABASE: copiar TODO el archivo al SQL Editor.
-- Crea tablas ausentes y agrega columnas que faltan. No borra registros.
-- Conserva usuarios, claves, permisos asignados, stock y configuración existente.
-- Incluye núcleo, SII/DTE, ERP comercial, inventario, costos, pagos y tienda.
-- Puede volver a ejecutarse. Si algo falla, la transacción no aplica cambios.
-- No es necesario ejecutar otros SQL de este paquete después de éste.
begin;
create temp table sias_upgrade_existing_roles(id uuid primary key) on commit drop;
do $$
begin
  if to_regclass('public.sias_roles') is not null then
    insert into sias_upgrade_existing_roles select id from public.sias_roles;
  end if;
end $$;

-- A. ESTRUCTURA BASE COMPLETA Y COMPATIBILIDAD DE COLUMNAS
set local statement_timeout = 0;

create extension if not exists pgcrypto;

create table if not exists public.sias_installation (
  id smallint primary key default 1 check (id = 1),
  product_name text not null default 'SiasCloud ERP',
  version text not null default '2.1.0',
  installed boolean not null default false,
  installed_at timestamptz,
  first_admin_id uuid,
  jwt_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_installation add column if not exists id smallint primary key default 1 check (id = 1);
alter table public.sias_installation add column if not exists product_name text not null default 'SiasCloud ERP';
alter table public.sias_installation add column if not exists version text not null default '2.1.0';
alter table public.sias_installation add column if not exists installed boolean not null default false;
alter table public.sias_installation add column if not exists installed_at timestamptz;
alter table public.sias_installation add column if not exists first_admin_id uuid;
alter table public.sias_installation add column if not exists jwt_enabled boolean not null default false;
alter table public.sias_installation add column if not exists created_at timestamptz not null default now();
alter table public.sias_installation add column if not exists updated_at timestamptz not null default now();

insert into public.sias_installation(id,version,jwt_enabled) values(1,'2.1.0',false) on conflict(id) do nothing;

create table if not exists public.sias_companies (
  id uuid primary key default gen_random_uuid(),
  rut text unique,
  legal_name text not null,
  trade_name text,
  business_activity text,
  address text,
  commune text,
  city text,
  region text,
  phone text,
  email text,
  website text,
  logo_url text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_companies add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_companies add column if not exists rut text unique;
alter table public.sias_companies add column if not exists legal_name text ;
alter table public.sias_companies add column if not exists trade_name text;
alter table public.sias_companies add column if not exists business_activity text;
alter table public.sias_companies add column if not exists address text;
alter table public.sias_companies add column if not exists commune text;
alter table public.sias_companies add column if not exists city text;
alter table public.sias_companies add column if not exists region text;
alter table public.sias_companies add column if not exists phone text;
alter table public.sias_companies add column if not exists email text;
alter table public.sias_companies add column if not exists website text;
alter table public.sias_companies add column if not exists logo_url text;
alter table public.sias_companies add column if not exists active boolean not null default true;
alter table public.sias_companies add column if not exists created_at timestamptz not null default now();
alter table public.sias_companies add column if not exists updated_at timestamptz not null default now();


create table if not exists public.sias_roles (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.sias_companies(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  system boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_roles add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_roles add column if not exists company_id uuid references public.sias_companies(id) on delete cascade;
alter table public.sias_roles add column if not exists code text ;
alter table public.sias_roles add column if not exists name text ;
alter table public.sias_roles add column if not exists description text;
alter table public.sias_roles add column if not exists system boolean not null default false;
alter table public.sias_roles add column if not exists active boolean not null default true;
alter table public.sias_roles add column if not exists created_at timestamptz not null default now();
alter table public.sias_roles add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sias_roles_company_code_unique
  on public.sias_roles(coalesce(company_id,'00000000-0000-0000-0000-000000000000'::uuid), code);

create table if not exists public.sias_permissions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  module text not null,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_permissions add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_permissions add column if not exists code text  unique;
alter table public.sias_permissions add column if not exists module text ;
alter table public.sias_permissions add column if not exists name text ;
alter table public.sias_permissions add column if not exists description text;
alter table public.sias_permissions add column if not exists created_at timestamptz not null default now();


create table if not exists public.sias_role_permissions (
  role_id uuid not null references public.sias_roles(id) on delete cascade,
  permission_id uuid not null references public.sias_permissions(id) on delete cascade,
  primary key(role_id, permission_id)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_role_permissions add column if not exists role_id uuid  references public.sias_roles(id) on delete cascade;
alter table public.sias_role_permissions add column if not exists permission_id uuid  references public.sias_permissions(id) on delete cascade;


create table if not exists public.sias_users (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  full_name text not null,
  profile_photo_url text,
  password_hash text not null,
  active boolean not null default true,
  superadmin boolean not null default false,
  must_change_password boolean not null default false,
  failed_attempts integer not null default 0,
  locked_until timestamptz,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_users add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_users add column if not exists email text ;
alter table public.sias_users add column if not exists full_name text ;
alter table public.sias_users add column if not exists profile_photo_url text;
alter table public.sias_users add column if not exists password_hash text ;
alter table public.sias_users add column if not exists active boolean not null default true;
alter table public.sias_users add column if not exists superadmin boolean not null default false;
alter table public.sias_users add column if not exists must_change_password boolean not null default false;
alter table public.sias_users add column if not exists failed_attempts integer not null default 0;
alter table public.sias_users add column if not exists locked_until timestamptz;
alter table public.sias_users add column if not exists last_login_at timestamptz;
alter table public.sias_users add column if not exists created_at timestamptz not null default now();
alter table public.sias_users add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sias_users_email_unique on public.sias_users(lower(email));

create table if not exists public.sias_user_roles (
  user_id uuid not null references public.sias_users(id) on delete cascade,
  role_id uuid not null references public.sias_roles(id) on delete cascade,
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  primary key(user_id, role_id, company_id)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_user_roles add column if not exists user_id uuid  references public.sias_users(id) on delete cascade;
alter table public.sias_user_roles add column if not exists role_id uuid  references public.sias_roles(id) on delete cascade;
alter table public.sias_user_roles add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;

create index if not exists sias_user_roles_company_idx on public.sias_user_roles(company_id,user_id);

create table if not exists public.sias_user_companies (
  user_id uuid not null references public.sias_users(id) on delete cascade,
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  is_primary boolean not null default false,
  primary key(user_id, company_id)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_user_companies add column if not exists user_id uuid  references public.sias_users(id) on delete cascade;
alter table public.sias_user_companies add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_user_companies add column if not exists is_primary boolean not null default false;


create table if not exists public.sias_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.sias_users(id) on delete cascade,
  company_id uuid references public.sias_companies(id) on delete set null,
  token_hash text not null unique,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked boolean not null default false,
  revoked_at timestamptz,
  ip text,
  user_agent text
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sessions add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_sessions add column if not exists user_id uuid  references public.sias_users(id) on delete cascade;
alter table public.sias_sessions add column if not exists company_id uuid references public.sias_companies(id) on delete set null;
alter table public.sias_sessions add column if not exists token_hash text  unique;
alter table public.sias_sessions add column if not exists created_at timestamptz not null default now();
alter table public.sias_sessions add column if not exists last_seen_at timestamptz not null default now();
alter table public.sias_sessions add column if not exists expires_at timestamptz ;
alter table public.sias_sessions add column if not exists revoked boolean not null default false;
alter table public.sias_sessions add column if not exists revoked_at timestamptz;
alter table public.sias_sessions add column if not exists ip text;
alter table public.sias_sessions add column if not exists user_agent text;

create index if not exists sias_sessions_user_idx on public.sias_sessions(user_id, revoked, expires_at);

create table if not exists public.sias_modules (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  icon text,
  route text,
  sort_order integer not null default 100,
  active boolean not null default true,
  system boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_modules add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_modules add column if not exists code text  unique;
alter table public.sias_modules add column if not exists name text ;
alter table public.sias_modules add column if not exists description text;
alter table public.sias_modules add column if not exists icon text;
alter table public.sias_modules add column if not exists route text;
alter table public.sias_modules add column if not exists sort_order integer not null default 100;
alter table public.sias_modules add column if not exists active boolean not null default true;
alter table public.sias_modules add column if not exists system boolean not null default true;
alter table public.sias_modules add column if not exists created_at timestamptz not null default now();
alter table public.sias_modules add column if not exists updated_at timestamptz not null default now();


create table if not exists public.sias_settings (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.sias_companies(id) on delete cascade,
  module text not null default 'SYSTEM',
  key text not null,
  value jsonb not null default '{}'::jsonb,
  description text,
  updated_by uuid references public.sias_users(id) on delete set null,
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_settings add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_settings add column if not exists company_id uuid references public.sias_companies(id) on delete cascade;
alter table public.sias_settings add column if not exists module text not null default 'SYSTEM';
alter table public.sias_settings add column if not exists key text ;
alter table public.sias_settings add column if not exists value jsonb not null default '{}'::jsonb;
alter table public.sias_settings add column if not exists description text;
alter table public.sias_settings add column if not exists updated_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_settings add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sias_settings_unique on public.sias_settings(coalesce(company_id,'00000000-0000-0000-0000-000000000000'::uuid), module, key);

create table if not exists public.sias_secrets (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references public.sias_companies(id) on delete cascade,
  scope text not null default 'SYSTEM',
  key text not null,
  encrypted_value text not null,
  hint text,
  updated_by uuid references public.sias_users(id) on delete set null,
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_secrets add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_secrets add column if not exists company_id uuid references public.sias_companies(id) on delete cascade;
alter table public.sias_secrets add column if not exists scope text not null default 'SYSTEM';
alter table public.sias_secrets add column if not exists key text ;
alter table public.sias_secrets add column if not exists encrypted_value text ;
alter table public.sias_secrets add column if not exists hint text;
alter table public.sias_secrets add column if not exists updated_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_secrets add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sias_secrets_unique on public.sias_secrets(coalesce(company_id,'00000000-0000-0000-0000-000000000000'::uuid), scope, key);

create table if not exists public.sias_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.sias_users(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null default 'INFO',
  module text,
  reference_id text,
  read boolean not null default false,
  created_at timestamptz not null default now(),
  read_at timestamptz
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_notifications add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_notifications add column if not exists user_id uuid  references public.sias_users(id) on delete cascade;
alter table public.sias_notifications add column if not exists title text ;
alter table public.sias_notifications add column if not exists message text ;
alter table public.sias_notifications add column if not exists type text not null default 'INFO';
alter table public.sias_notifications add column if not exists module text;
alter table public.sias_notifications add column if not exists reference_id text;
alter table public.sias_notifications add column if not exists read boolean not null default false;
alter table public.sias_notifications add column if not exists created_at timestamptz not null default now();
alter table public.sias_notifications add column if not exists read_at timestamptz;

create index if not exists sias_notifications_user_idx on public.sias_notifications(user_id, read, created_at desc);

create table if not exists public.sias_audit (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  user_id uuid references public.sias_users(id) on delete set null,
  company_id uuid references public.sias_companies(id) on delete set null,
  module text,
  action text not null,
  entity text,
  entity_id text,
  detail jsonb not null default '{}'::jsonb,
  ip text,
  user_agent text
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_audit add column if not exists id bigint generated always as identity primary key;
alter table public.sias_audit add column if not exists created_at timestamptz not null default now();
alter table public.sias_audit add column if not exists user_id uuid references public.sias_users(id) on delete set null;
alter table public.sias_audit add column if not exists company_id uuid references public.sias_companies(id) on delete set null;
alter table public.sias_audit add column if not exists module text;
alter table public.sias_audit add column if not exists action text ;
alter table public.sias_audit add column if not exists entity text;
alter table public.sias_audit add column if not exists entity_id text;
alter table public.sias_audit add column if not exists detail jsonb not null default '{}'::jsonb;
alter table public.sias_audit add column if not exists ip text;
alter table public.sias_audit add column if not exists user_agent text;

create index if not exists sias_audit_created_idx on public.sias_audit(created_at desc);

create table if not exists public.sias_sequences (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  code text not null,
  prefix text not null default '',
  current_value bigint not null default 0,
  padding smallint not null default 6,
  updated_at timestamptz not null default now(),
  unique(company_id, code)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sequences add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_sequences add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_sequences add column if not exists code text ;
alter table public.sias_sequences add column if not exists prefix text not null default '';
alter table public.sias_sequences add column if not exists current_value bigint not null default 0;
alter table public.sias_sequences add column if not exists padding smallint not null default 6;
alter table public.sias_sequences add column if not exists updated_at timestamptz not null default now();


create or replace function public.sias_next_sequence(p_company uuid, p_code text)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare
  v bigint;
  p text;
  z integer;
begin
  insert into public.sias_sequences(company_id, code, current_value)
  values(p_company, upper(p_code), 0)
  on conflict(company_id, code) do nothing;

  update public.sias_sequences
     set current_value = current_value + 1, updated_at = now()
   where company_id = p_company and code = upper(p_code)
   returning current_value, prefix, padding into v, p, z;

  return coalesce(p,'') || lpad(v::text, z, '0');
end $$;

insert into public.sias_roles(company_id,code,name,description,system) values
(null,'SUPERADMIN','Superadministrador','Control total de SiasCloud ERP',true),
(null,'ADMIN','Administrador','Administración general',true),
(null,'AUDITOR','Auditor','Consulta y auditoría',true)
on conflict do nothing;

insert into public.sias_permissions(code,module,name,description) values
('DASHBOARD_VIEW','DASHBOARD','Ver dashboard','Acceso al panel principal'),
('COMPANY_VIEW','COMPANIES','Ver empresas','Consultar empresas'),
('COMPANY_MANAGE','COMPANIES','Gestionar empresas','Crear y modificar empresas'),
('USER_VIEW','USERS','Ver usuarios','Consultar usuarios'),
('USER_MANAGE','USERS','Gestionar usuarios','Crear, editar, activar y resetear claves'),
('ROLE_VIEW','SECURITY','Ver roles','Consultar roles y permisos'),
('ROLE_MANAGE','SECURITY','Gestionar roles','Crear roles y asignar permisos'),
('MODULE_MANAGE','MODULES','Gestionar módulos','Activar o desactivar módulos'),
('SETTINGS_VIEW','SETTINGS','Ver configuración','Consultar parámetros'),
('SETTINGS_MANAGE','SETTINGS','Gestionar configuración','Modificar parámetros'),
('SECRETS_MANAGE','SECRETS','Gestionar secretos','Guardar o reemplazar secretos cifrados'),
('AUDIT_VIEW','AUDIT','Ver auditoría','Consultar trazabilidad'),
('NOTIFICATION_VIEW','NOTIFICATIONS','Ver notificaciones','Consultar y marcar notificaciones'),
('SII_VIEW','SII','Ver SII','Consultar configuración tributaria'),
('SII_MANAGE','SII','Gestionar SII','Administrar certificado, CAF, folios y DTE')
on conflict(code) do nothing;

-- Permisos iniciales de roles de sistema. SUPERADMIN obtiene todos por lógica del backend.
insert into public.sias_role_permissions(role_id,permission_id)
select r.id,p.id
from public.sias_roles r
join public.sias_permissions p on p.code = any(case r.code
  when 'ADMIN' then array['DASHBOARD_VIEW','COMPANY_VIEW','COMPANY_MANAGE','USER_VIEW','USER_MANAGE','ROLE_VIEW','ROLE_MANAGE','SETTINGS_VIEW','SETTINGS_MANAGE','AUDIT_VIEW','NOTIFICATION_VIEW','SII_VIEW','SII_MANAGE']::text[]
  when 'AUDITOR' then array['DASHBOARD_VIEW','COMPANY_VIEW','USER_VIEW','ROLE_VIEW','SETTINGS_VIEW','AUDIT_VIEW','NOTIFICATION_VIEW','SII_VIEW']::text[]
  else array[]::text[] end)
where r.company_id is null and r.code in ('ADMIN','AUDITOR')
and not exists(select 1 from sias_upgrade_existing_roles e where e.id=r.id)
on conflict do nothing;

insert into public.sias_modules(code,name,description,icon,route,sort_order) values
('DASHBOARD','Dashboard','Resumen general','▦','#dashboard',10),
('COMPANIES','Empresa','Datos generales de la empresa','⌂','#companies',20),
('USERS','Usuarios','Usuarios internos','♟','#users',30),
('SECURITY','Roles y permisos','Control de acceso','◆','#security',40),
('MODULES','Módulos','Activación de módulos','◫','#modules',50),
('SII','SII / DTE','Facturación electrónica','▤','#sii',60),
('NOTIFICATIONS','Notificaciones','Centro de avisos','●','#notifications',70),
('AUDIT','Auditoría','Trazabilidad del sistema','↻','#audit',80),
('SETTINGS','Configuración','Parámetros y secretos','⚙','#settings',90)
on conflict(code) do nothing;

insert into public.sias_settings(company_id,module,key,value,description) values
(null,'BRANDING','theme','{"primary":"#006CFF","secondary":"#0A2A66","background":"#FFFFFF","button_text":"#FFFFFF"}'::jsonb,'Identidad visual SiasCloud ERP'),
(null,'SECURITY','session','{"minutes":480,"max_failed_attempts":5,"lock_minutes":15,"jwt_enabled":false}'::jsonb,'Sesiones propias del ERP'),
(null,'SYSTEM','locale','{"country":"CL","language":"es-CL","currency":"CLP","timezone":"America/Santiago"}'::jsonb,'Localización por defecto')
on conflict do nothing;

-- Nadie desde el frontend puede leer tablas directamente.
do $$
declare r record;
begin
  for r in
    select tablename from pg_tables where schemaname='public' and tablename like 'sias_%'
  loop
    execute format('alter table public.%I enable row level security', r.tablename);
    execute format('revoke all on table public.%I from anon, authenticated', r.tablename);
  end loop;
end $$;

revoke all on function public.sias_next_sequence(uuid,text) from public,anon,authenticated;
grant execute on function public.sias_next_sequence(uuid,text) to service_role;

-- ============================================================================
-- PARTE B - SII / DTE
-- Fuente: 02_SIASCLOUD_ERP_SII_SQL_MAESTRO.sql
-- ============================================================================
-- =============================================================
-- SiasCloud ERP 2.1.0 - SQL MAESTRO SII / DTE
-- Ejecutar DESPUÉS del SQL maestro del núcleo.
-- =============================================================

create table if not exists public.sias_sii_config (
  company_id uuid primary key references public.sias_companies(id) on delete cascade,
  environment text not null default 'CERTIFICACION' check(environment in ('CERTIFICACION','PRODUCCION')),
  enabled boolean not null default false,
  issuer_rut text,
  resolution_number text,
  resolution_date date,
  sender_email text,
  activity_code text,
  office_code text,
  updated_by uuid references public.sias_users(id) on delete set null,
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sii_config add column if not exists company_id uuid primary key references public.sias_companies(id) on delete cascade;
alter table public.sias_sii_config add column if not exists environment text not null default 'CERTIFICACION' check(environment in ('CERTIFICACION','PRODUCCION'));
alter table public.sias_sii_config add column if not exists enabled boolean not null default false;
alter table public.sias_sii_config add column if not exists issuer_rut text;
alter table public.sias_sii_config add column if not exists resolution_number text;
alter table public.sias_sii_config add column if not exists resolution_date date;
alter table public.sias_sii_config add column if not exists sender_email text;
alter table public.sias_sii_config add column if not exists activity_code text;
alter table public.sias_sii_config add column if not exists office_code text;
alter table public.sias_sii_config add column if not exists updated_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_sii_config add column if not exists updated_at timestamptz not null default now();


create table if not exists public.sias_sii_certificates (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  file_name text not null,
  storage_path text not null,
  password_encrypted text not null,
  subject text,
  serial_number text,
  valid_from timestamptz,
  valid_until timestamptz,
  active boolean not null default true,
  uploaded_by uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sii_certificates add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_sii_certificates add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_sii_certificates add column if not exists file_name text ;
alter table public.sias_sii_certificates add column if not exists storage_path text ;
alter table public.sias_sii_certificates add column if not exists password_encrypted text ;
alter table public.sias_sii_certificates add column if not exists subject text;
alter table public.sias_sii_certificates add column if not exists serial_number text;
alter table public.sias_sii_certificates add column if not exists valid_from timestamptz;
alter table public.sias_sii_certificates add column if not exists valid_until timestamptz;
alter table public.sias_sii_certificates add column if not exists active boolean not null default true;
alter table public.sias_sii_certificates add column if not exists uploaded_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_sii_certificates add column if not exists created_at timestamptz not null default now();

create index if not exists sias_sii_cert_active_idx on public.sias_sii_certificates(company_id,active,created_at desc);

create table if not exists public.sias_sii_cafs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  environment text not null default 'CERTIFICACION' check(environment in ('CERTIFICACION','PRODUCCION')),
  document_type integer not null,
  issuer_rut text,
  folio_from bigint not null,
  folio_to bigint not null,
  current_folio bigint not null,
  caf_xml text not null,
  status text not null default 'ACTIVO' check(status in ('ACTIVO','AGOTADO','INACTIVO')),
  uploaded_by uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now(),
  check(folio_from > 0 and folio_to >= folio_from and current_folio >= folio_from and current_folio <= folio_to + 1)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sii_cafs add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_sii_cafs add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_sii_cafs add column if not exists environment text not null default 'CERTIFICACION' check(environment in ('CERTIFICACION','PRODUCCION'));
alter table public.sias_sii_cafs add column if not exists document_type integer ;
alter table public.sias_sii_cafs add column if not exists issuer_rut text;
alter table public.sias_sii_cafs add column if not exists folio_from bigint ;
alter table public.sias_sii_cafs add column if not exists folio_to bigint ;
alter table public.sias_sii_cafs add column if not exists current_folio bigint ;
alter table public.sias_sii_cafs add column if not exists caf_xml text ;
alter table public.sias_sii_cafs add column if not exists status text not null default 'ACTIVO' check(status in ('ACTIVO','AGOTADO','INACTIVO'));
alter table public.sias_sii_cafs add column if not exists uploaded_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_sii_cafs add column if not exists created_at timestamptz not null default now();

create index if not exists sias_sii_caf_lookup_idx on public.sias_sii_cafs(company_id,environment,document_type,status,folio_from);

create table if not exists public.sias_sii_dte (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  environment text not null default 'CERTIFICACION' check(environment in ('CERTIFICACION','PRODUCCION')),
  document_type integer not null,
  folio bigint,
  issue_date date not null default current_date,
  recipient jsonb not null default '{}'::jsonb,
  items jsonb not null default '[]'::jsonb,
  totals jsonb not null default '{}'::jsonb,
  status text not null default 'BORRADOR',
  xml_unsigned text,
  xml_signed text,
  sii_track_id text,
  sii_status text,
  sii_response jsonb,
  created_by uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id,environment,document_type,folio)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sii_dte add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_sii_dte add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_sii_dte add column if not exists environment text not null default 'CERTIFICACION' check(environment in ('CERTIFICACION','PRODUCCION'));
alter table public.sias_sii_dte add column if not exists document_type integer ;
alter table public.sias_sii_dte add column if not exists folio bigint;
alter table public.sias_sii_dte add column if not exists issue_date date not null default current_date;
alter table public.sias_sii_dte add column if not exists recipient jsonb not null default '{}'::jsonb;
alter table public.sias_sii_dte add column if not exists items jsonb not null default '[]'::jsonb;
alter table public.sias_sii_dte add column if not exists totals jsonb not null default '{}'::jsonb;
alter table public.sias_sii_dte add column if not exists status text not null default 'BORRADOR';
alter table public.sias_sii_dte add column if not exists xml_unsigned text;
alter table public.sias_sii_dte add column if not exists xml_signed text;
alter table public.sias_sii_dte add column if not exists sii_track_id text;
alter table public.sias_sii_dte add column if not exists sii_status text;
alter table public.sias_sii_dte add column if not exists sii_response jsonb;
alter table public.sias_sii_dte add column if not exists created_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_sii_dte add column if not exists created_at timestamptz not null default now();
alter table public.sias_sii_dte add column if not exists updated_at timestamptz not null default now();

create index if not exists sias_sii_dte_status_idx on public.sias_sii_dte(company_id,status,created_at desc);

create table if not exists public.sias_sii_dte_events (
  id bigint generated always as identity primary key,
  dte_id uuid not null references public.sias_sii_dte(id) on delete cascade,
  event text not null,
  detail jsonb not null default '{}'::jsonb,
  user_id uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sii_dte_events add column if not exists id bigint generated always as identity primary key;
alter table public.sias_sii_dte_events add column if not exists dte_id uuid  references public.sias_sii_dte(id) on delete cascade;
alter table public.sias_sii_dte_events add column if not exists event text ;
alter table public.sias_sii_dte_events add column if not exists detail jsonb not null default '{}'::jsonb;
alter table public.sias_sii_dte_events add column if not exists user_id uuid references public.sias_users(id) on delete set null;
alter table public.sias_sii_dte_events add column if not exists created_at timestamptz not null default now();


create table if not exists public.sias_sii_received_dte (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  issuer_rut text,
  issuer_name text,
  document_type integer,
  folio bigint,
  issue_date date,
  total numeric(18,2),
  xml text,
  status text not null default 'RECIBIDO',
  received_at timestamptz not null default now(),
  unique(company_id,issuer_rut,document_type,folio)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sii_received_dte add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_sii_received_dte add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_sii_received_dte add column if not exists issuer_rut text;
alter table public.sias_sii_received_dte add column if not exists issuer_name text;
alter table public.sias_sii_received_dte add column if not exists document_type integer;
alter table public.sias_sii_received_dte add column if not exists folio bigint;
alter table public.sias_sii_received_dte add column if not exists issue_date date;
alter table public.sias_sii_received_dte add column if not exists total numeric(18,2);
alter table public.sias_sii_received_dte add column if not exists xml text;
alter table public.sias_sii_received_dte add column if not exists status text not null default 'RECIBIDO';
alter table public.sias_sii_received_dte add column if not exists received_at timestamptz not null default now();


create table if not exists public.sias_sii_certification_steps (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  status text not null default 'PENDIENTE' check(status in ('PENDIENTE','EN_PROCESO','COMPLETADO','BLOQUEADO')),
  note text,
  updated_by uuid references public.sias_users(id) on delete set null,
  updated_at timestamptz not null default now(),
  unique(company_id,code)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_sii_certification_steps add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_sii_certification_steps add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_sii_certification_steps add column if not exists code text ;
alter table public.sias_sii_certification_steps add column if not exists name text ;
alter table public.sias_sii_certification_steps add column if not exists description text;
alter table public.sias_sii_certification_steps add column if not exists status text not null default 'PENDIENTE' check(status in ('PENDIENTE','EN_PROCESO','COMPLETADO','BLOQUEADO'));
alter table public.sias_sii_certification_steps add column if not exists note text;
alter table public.sias_sii_certification_steps add column if not exists updated_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_sii_certification_steps add column if not exists updated_at timestamptz not null default now();


-- Instalación inicial atómica. Si cualquier paso falla, PostgreSQL revierte todo el bootstrap.
create or replace function public.sias_bootstrap_install(
  p_company_name text,
  p_company_rut text,
  p_admin_name text,
  p_admin_email text,
  p_password_hash text
)
returns table(company_id uuid,user_id uuid)
language plpgsql
security definer
set search_path=public
as $$
declare
  v_company uuid;
  v_user uuid;
  v_role uuid;
  v_installed boolean;
  v_count bigint;
begin
  select i.installed into v_installed
    from public.sias_installation as i
   where i.id=1
   for update;

  select count(*) into v_count
    from public.sias_users as u;

  if coalesce(v_installed,false) or v_count > 0 then
    raise exception 'BOOTSTRAP_CERRADO';
  end if;

  if nullif(trim(p_company_name),'') is null or nullif(trim(p_admin_name),'') is null
     or nullif(trim(p_admin_email),'') is null or nullif(p_password_hash,'') is null then
    raise exception 'DATOS_INVALIDOS';
  end if;

  insert into public.sias_companies(legal_name,trade_name,rut)
  values(trim(p_company_name),trim(p_company_name),nullif(trim(p_company_rut),''))
  returning id into v_company;

  insert into public.sias_users(email,full_name,password_hash,active,superadmin,must_change_password)
  values(lower(trim(p_admin_email)),trim(p_admin_name),p_password_hash,true,true,false)
  returning id into v_user;

  insert into public.sias_user_companies(user_id,company_id,is_primary)
  values(v_user,v_company,true);

  select r.id into v_role
    from public.sias_roles as r
   where r.company_id is null
     and r.code='SUPERADMIN'
   limit 1;

  if v_role is not null then
    insert into public.sias_user_roles(user_id,role_id,company_id)
    values(v_user,v_role,v_company)
    on conflict do nothing;
  end if;

  insert into public.sias_sii_certification_steps(company_id,code,name,description) values
    (v_company,'POSTULACION','Postulación SII','Empresa postulada al ambiente de certificación'),
    (v_company,'CERTIFICADO','Certificado digital','Certificado PFX/P12 cargado y vigente'),
    (v_company,'CAF','CAF / folios','CAF de certificación cargados'),
    (v_company,'SET_PRUEBAS','Set de pruebas','Casos de prueba enviados y aceptados'),
    (v_company,'SIMULACION','Simulación','Simulación SII completada'),
    (v_company,'INTERCAMBIO','Intercambio','Intercambio de DTE validado'),
    (v_company,'DECLARACION','Declaración de cumplimiento','Declaración final')
  on conflict on constraint sias_sii_certification_steps_company_id_code_key do nothing;

  update public.sias_installation as i
     set installed=true, installed_at=now(), first_admin_id=v_user,
         jwt_enabled=false, version='2.2.3', updated_at=now()
   where i.id=1;

  return query select v_company,v_user;
end $$;

create or replace function public.sias_sii_take_folio(p_company uuid, p_document_type integer)
returns bigint
language plpgsql
security definer
set search_path=public
as $$
declare
  v_caf uuid;
  v_folio bigint;
  v_environment text;
begin
  select coalesce(environment,'CERTIFICACION') into v_environment
  from public.sias_sii_config where company_id=p_company;
  v_environment := coalesce(v_environment,'CERTIFICACION');

  select id,current_folio into v_caf,v_folio
  from public.sias_sii_cafs
  where company_id=p_company
    and environment=v_environment
    and document_type=p_document_type
    and status='ACTIVO'
    and current_folio <= folio_to
  order by folio_from
  for update skip locked
  limit 1;

  if v_caf is null then
    raise exception 'SII_SIN_FOLIOS_DISPONIBLES';
  end if;

  update public.sias_sii_cafs
  set current_folio = current_folio + 1,
      status = case when current_folio + 1 > folio_to then 'AGOTADO' else status end
  where id=v_caf;

  return v_folio;
end $$;

-- Bucket privado para certificados y archivos tributarios.
insert into storage.buckets(id,name,public,file_size_limit)
values('siascloud-private','siascloud-private',false,10485760)
on conflict(id) do update set public=false;

-- El navegador no accede directamente a datos tributarios.
do $$
declare r record;
begin
  for r in
    select tablename from pg_tables where schemaname='public' and tablename like 'sias_sii_%'
  loop
    execute format('alter table public.%I enable row level security', r.tablename);
    execute format('revoke all on table public.%I from anon, authenticated', r.tablename);
  end loop;
end $$;
revoke all on function public.sias_sii_take_folio(uuid,integer) from public,anon,authenticated;
revoke all on function public.sias_bootstrap_install(text,text,text,text,text) from public,anon,authenticated;
grant execute on function public.sias_sii_take_folio(uuid,integer) to service_role;
grant execute on function public.sias_bootstrap_install(text,text,text,text,text) to service_role;

-- ============================================================================
-- PARTE C - COMERCIAL / INVENTARIO / FACTURACION / PORTAL MAYORISTA
-- Fuente: 04_SIASCLOUD_ERP_COMERCIAL_V2_2_0.sql
-- ============================================================================
-- =====================================================================
-- SiasCloud ERP 2.2.0 - MODULO COMERCIAL / INVENTARIO / FACTURACION
-- Ejecutar DESPUES de 01_SIASCLOUD_ERP_SQL_MAESTRO.sql y
-- 02_SIASCLOUD_ERP_SII_SQL_MAESTRO.sql.
-- Idempotente: sirve para instalación nueva y actualización desde 2.1.0.
-- =====================================================================

create extension if not exists pgcrypto;

create table if not exists public.sias_warehouses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  code text not null,
  name text not null,
  address text,
  commune text,
  city text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id, code)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_warehouses add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_warehouses add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_warehouses add column if not exists code text ;
alter table public.sias_warehouses add column if not exists name text ;
alter table public.sias_warehouses add column if not exists address text;
alter table public.sias_warehouses add column if not exists commune text;
alter table public.sias_warehouses add column if not exists city text;
alter table public.sias_warehouses add column if not exists active boolean not null default true;
alter table public.sias_warehouses add column if not exists created_at timestamptz not null default now();
alter table public.sias_warehouses add column if not exists updated_at timestamptz not null default now();

create index if not exists sias_warehouses_company_idx on public.sias_warehouses(company_id,active,name);

create table if not exists public.sias_products (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  sku text,
  barcode text,
  name text not null,
  description text,
  category text,
  unit text not null default 'UN',
  cost numeric(18,4) not null default 0 check(cost >= 0),
  price numeric(18,4) not null default 0 check(price >= 0),
  wholesale_price numeric(18,4) not null default 0 check(wholesale_price >= 0),
  tax_rate numeric(7,4) not null default 19 check(tax_rate >= 0 and tax_rate <= 100),
  exempt boolean not null default false,
  min_stock numeric(18,4) not null default 0,
  max_stock numeric(18,4),
  image_url text,
  featured boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_products add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_products add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_products add column if not exists sku text;
alter table public.sias_products add column if not exists barcode text;
alter table public.sias_products add column if not exists name text ;
alter table public.sias_products add column if not exists description text;
alter table public.sias_products add column if not exists category text;
alter table public.sias_products add column if not exists unit text not null default 'UN';
alter table public.sias_products add column if not exists cost numeric(18,4) not null default 0 check(cost >= 0);
alter table public.sias_products add column if not exists price numeric(18,4) not null default 0 check(price >= 0);
alter table public.sias_products add column if not exists wholesale_price numeric(18,4) not null default 0 check(wholesale_price >= 0);
alter table public.sias_products add column if not exists tax_rate numeric(7,4) not null default 19 check(tax_rate >= 0 and tax_rate <= 100);
alter table public.sias_products add column if not exists exempt boolean not null default false;
alter table public.sias_products add column if not exists min_stock numeric(18,4) not null default 0;
alter table public.sias_products add column if not exists max_stock numeric(18,4);
alter table public.sias_products add column if not exists image_url text;
alter table public.sias_products add column if not exists featured boolean not null default false;
alter table public.sias_products add column if not exists active boolean not null default true;
alter table public.sias_products add column if not exists created_at timestamptz not null default now();
alter table public.sias_products add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sias_products_company_sku_unique on public.sias_products(company_id,lower(sku)) where sku is not null and btrim(sku)<>'';
create index if not exists sias_products_company_idx on public.sias_products(company_id,active,name);
create index if not exists sias_products_category_idx on public.sias_products(company_id,category);

create table if not exists public.sias_stock (
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  warehouse_id uuid not null references public.sias_warehouses(id) on delete cascade,
  product_id uuid not null references public.sias_products(id) on delete cascade,
  quantity numeric(18,4) not null default 0,
  updated_at timestamptz not null default now(),
  primary key(company_id, warehouse_id, product_id)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_stock add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_stock add column if not exists warehouse_id uuid  references public.sias_warehouses(id) on delete cascade;
alter table public.sias_stock add column if not exists product_id uuid  references public.sias_products(id) on delete cascade;
alter table public.sias_stock add column if not exists quantity numeric(18,4) not null default 0;
alter table public.sias_stock add column if not exists updated_at timestamptz not null default now();

create index if not exists sias_stock_product_idx on public.sias_stock(company_id,product_id);

create table if not exists public.sias_stock_movements (
  id bigint generated always as identity primary key,
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  warehouse_id uuid not null references public.sias_warehouses(id) on delete restrict,
  product_id uuid not null references public.sias_products(id) on delete restrict,
  movement_type text not null,
  quantity numeric(18,4) not null,
  balance_after numeric(18,4) not null,
  reference_type text,
  reference_id uuid,
  note text,
  created_by uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_stock_movements add column if not exists id bigint generated always as identity primary key;
alter table public.sias_stock_movements add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_stock_movements add column if not exists warehouse_id uuid  references public.sias_warehouses(id) on delete restrict;
alter table public.sias_stock_movements add column if not exists product_id uuid  references public.sias_products(id) on delete restrict;
alter table public.sias_stock_movements add column if not exists movement_type text ;
alter table public.sias_stock_movements add column if not exists quantity numeric(18,4) ;
alter table public.sias_stock_movements add column if not exists balance_after numeric(18,4) ;
alter table public.sias_stock_movements add column if not exists reference_type text;
alter table public.sias_stock_movements add column if not exists reference_id uuid;
alter table public.sias_stock_movements add column if not exists note text;
alter table public.sias_stock_movements add column if not exists created_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_stock_movements add column if not exists created_at timestamptz not null default now();

create index if not exists sias_stock_movements_lookup_idx on public.sias_stock_movements(company_id,product_id,created_at desc);
create index if not exists sias_stock_movements_reference_idx on public.sias_stock_movements(company_id,reference_type,reference_id);

create table if not exists public.sias_customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  rut text,
  legal_name text not null,
  trade_name text,
  business_activity text,
  email text,
  phone text,
  address text,
  commune text,
  city text,
  region text,
  contact_name text,
  credit_limit numeric(18,2) not null default 0,
  wholesale boolean not null default false,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_customers add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_customers add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_customers add column if not exists rut text;
alter table public.sias_customers add column if not exists legal_name text ;
alter table public.sias_customers add column if not exists trade_name text;
alter table public.sias_customers add column if not exists business_activity text;
alter table public.sias_customers add column if not exists email text;
alter table public.sias_customers add column if not exists phone text;
alter table public.sias_customers add column if not exists address text;
alter table public.sias_customers add column if not exists commune text;
alter table public.sias_customers add column if not exists city text;
alter table public.sias_customers add column if not exists region text;
alter table public.sias_customers add column if not exists contact_name text;
alter table public.sias_customers add column if not exists credit_limit numeric(18,2) not null default 0;
alter table public.sias_customers add column if not exists wholesale boolean not null default false;
alter table public.sias_customers add column if not exists active boolean not null default true;
alter table public.sias_customers add column if not exists notes text;
alter table public.sias_customers add column if not exists created_at timestamptz not null default now();
alter table public.sias_customers add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sias_customers_company_rut_unique on public.sias_customers(company_id,upper(regexp_replace(coalesce(rut,''),'[^0-9Kk]','','g'))) where rut is not null and btrim(rut)<>'';
create index if not exists sias_customers_company_idx on public.sias_customers(company_id,active,legal_name);
create index if not exists sias_customers_wholesale_idx on public.sias_customers(company_id,wholesale,active);

create table if not exists public.sias_suppliers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  rut text,
  legal_name text not null,
  trade_name text,
  business_activity text,
  email text,
  phone text,
  address text,
  commune text,
  city text,
  contact_name text,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_suppliers add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_suppliers add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_suppliers add column if not exists rut text;
alter table public.sias_suppliers add column if not exists legal_name text ;
alter table public.sias_suppliers add column if not exists trade_name text;
alter table public.sias_suppliers add column if not exists business_activity text;
alter table public.sias_suppliers add column if not exists email text;
alter table public.sias_suppliers add column if not exists phone text;
alter table public.sias_suppliers add column if not exists address text;
alter table public.sias_suppliers add column if not exists commune text;
alter table public.sias_suppliers add column if not exists city text;
alter table public.sias_suppliers add column if not exists contact_name text;
alter table public.sias_suppliers add column if not exists active boolean not null default true;
alter table public.sias_suppliers add column if not exists notes text;
alter table public.sias_suppliers add column if not exists created_at timestamptz not null default now();
alter table public.sias_suppliers add column if not exists updated_at timestamptz not null default now();

create unique index if not exists sias_suppliers_company_rut_unique on public.sias_suppliers(company_id,upper(regexp_replace(coalesce(rut,''),'[^0-9Kk]','','g'))) where rut is not null and btrim(rut)<>'';
create index if not exists sias_suppliers_company_idx on public.sias_suppliers(company_id,active,legal_name);

create table if not exists public.sias_documents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  document_type text not null check(document_type in ('QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE')),
  number text not null,
  status text not null default 'DRAFT',
  customer_id uuid references public.sias_customers(id) on delete set null,
  supplier_id uuid references public.sias_suppliers(id) on delete set null,
  warehouse_id uuid references public.sias_warehouses(id) on delete set null,
  issue_date date not null default current_date,
  due_date date,
  currency text not null default 'CLP',
  net numeric(18,2) not null default 0,
  exempt numeric(18,2) not null default 0,
  tax numeric(18,2) not null default 0,
  discount numeric(18,2) not null default 0,
  shipping numeric(18,2) not null default 0,
  total numeric(18,2) not null default 0,
  payment_status text not null default 'PENDING',
  payment_method text,
  source text not null default 'DIRECT',
  notes text,
  posted_at timestamptz,
  voided_at timestamptz,
  created_by uuid references public.sias_users(id) on delete set null,
  updated_by uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(company_id,document_type,number)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_documents add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_documents add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_documents add column if not exists document_type text  check(document_type in ('QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE'));
alter table public.sias_documents add column if not exists number text ;
alter table public.sias_documents add column if not exists status text not null default 'DRAFT';
alter table public.sias_documents add column if not exists customer_id uuid references public.sias_customers(id) on delete set null;
alter table public.sias_documents add column if not exists supplier_id uuid references public.sias_suppliers(id) on delete set null;
alter table public.sias_documents add column if not exists warehouse_id uuid references public.sias_warehouses(id) on delete set null;
alter table public.sias_documents add column if not exists issue_date date not null default current_date;
alter table public.sias_documents add column if not exists due_date date;
alter table public.sias_documents add column if not exists currency text not null default 'CLP';
alter table public.sias_documents add column if not exists net numeric(18,2) not null default 0;
alter table public.sias_documents add column if not exists exempt numeric(18,2) not null default 0;
alter table public.sias_documents add column if not exists tax numeric(18,2) not null default 0;
alter table public.sias_documents add column if not exists discount numeric(18,2) not null default 0;
alter table public.sias_documents add column if not exists shipping numeric(18,2) not null default 0;
alter table public.sias_documents add column if not exists total numeric(18,2) not null default 0;
alter table public.sias_documents add column if not exists payment_status text not null default 'PENDING';
alter table public.sias_documents add column if not exists payment_method text;
alter table public.sias_documents add column if not exists source text not null default 'DIRECT';
alter table public.sias_documents add column if not exists notes text;
alter table public.sias_documents add column if not exists posted_at timestamptz;
alter table public.sias_documents add column if not exists voided_at timestamptz;
alter table public.sias_documents add column if not exists created_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_documents add column if not exists updated_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_documents add column if not exists created_at timestamptz not null default now();
alter table public.sias_documents add column if not exists updated_at timestamptz not null default now();

create index if not exists sias_documents_company_type_idx on public.sias_documents(company_id,document_type,created_at desc);
create index if not exists sias_documents_customer_idx on public.sias_documents(company_id,customer_id,created_at desc);
create index if not exists sias_documents_status_idx on public.sias_documents(company_id,status,payment_status,created_at desc);

create table if not exists public.sias_document_items (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.sias_documents(id) on delete cascade,
  line_no integer not null,
  product_id uuid references public.sias_products(id) on delete set null,
  sku text,
  description text not null,
  quantity numeric(18,4) not null default 1 check(quantity > 0),
  unit text not null default 'UN',
  unit_price numeric(18,4) not null default 0,
  discount numeric(18,2) not null default 0,
  tax_rate numeric(7,4) not null default 19,
  exempt boolean not null default false,
  line_net numeric(18,2) not null default 0,
  line_tax numeric(18,2) not null default 0,
  line_total numeric(18,2) not null default 0,
  unique(document_id,line_no)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_document_items add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_document_items add column if not exists document_id uuid  references public.sias_documents(id) on delete cascade;
alter table public.sias_document_items add column if not exists line_no integer ;
alter table public.sias_document_items add column if not exists product_id uuid references public.sias_products(id) on delete set null;
alter table public.sias_document_items add column if not exists sku text;
alter table public.sias_document_items add column if not exists description text ;
alter table public.sias_document_items add column if not exists quantity numeric(18,4) not null default 1 check(quantity > 0);
alter table public.sias_document_items add column if not exists unit text not null default 'UN';
alter table public.sias_document_items add column if not exists unit_price numeric(18,4) not null default 0;
alter table public.sias_document_items add column if not exists discount numeric(18,2) not null default 0;
alter table public.sias_document_items add column if not exists tax_rate numeric(7,4) not null default 19;
alter table public.sias_document_items add column if not exists exempt boolean not null default false;
alter table public.sias_document_items add column if not exists line_net numeric(18,2) not null default 0;
alter table public.sias_document_items add column if not exists line_tax numeric(18,2) not null default 0;
alter table public.sias_document_items add column if not exists line_total numeric(18,2) not null default 0;

create index if not exists sias_document_items_product_idx on public.sias_document_items(product_id);

create table if not exists public.sias_payments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  document_id uuid not null references public.sias_documents(id) on delete cascade,
  amount numeric(18,2) not null check(amount > 0),
  method text not null default 'OTHER',
  reference text,
  paid_at timestamptz not null default now(),
  status text not null default 'CONFIRMED',
  created_by uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_payments add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_payments add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_payments add column if not exists document_id uuid  references public.sias_documents(id) on delete cascade;
alter table public.sias_payments add column if not exists amount numeric(18,2)  check(amount > 0);
alter table public.sias_payments add column if not exists method text not null default 'OTHER';
alter table public.sias_payments add column if not exists reference text;
alter table public.sias_payments add column if not exists paid_at timestamptz not null default now();
alter table public.sias_payments add column if not exists status text not null default 'CONFIRMED';
alter table public.sias_payments add column if not exists created_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_payments add column if not exists created_at timestamptz not null default now();

create index if not exists sias_payments_document_idx on public.sias_payments(company_id,document_id,paid_at desc);

create table if not exists public.sias_billing_config (
  company_id uuid primary key references public.sias_companies(id) on delete cascade,
  active_provider text not null default 'SII_PROPIO' check(active_provider in ('SII_PROPIO','FACTURACION_CL')),
  environment text not null default 'CERTIFICACION' check(environment in ('CERTIFICACION','PRODUCCION')),
  general_tax_rate numeric(7,4) not null default 19 check(general_tax_rate >= 0 and general_tax_rate <= 100),
  facturacion_cl_api_url text not null default 'https://rest.facturacion.cl',
  facturacion_cl_include_link boolean not null default true,
  updated_by uuid references public.sias_users(id) on delete set null,
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_billing_config add column if not exists company_id uuid primary key references public.sias_companies(id) on delete cascade;
alter table public.sias_billing_config add column if not exists active_provider text not null default 'SII_PROPIO' check(active_provider in ('SII_PROPIO','FACTURACION_CL'));
alter table public.sias_billing_config add column if not exists environment text not null default 'CERTIFICACION' check(environment in ('CERTIFICACION','PRODUCCION'));
alter table public.sias_billing_config add column if not exists general_tax_rate numeric(7,4) not null default 19 check(general_tax_rate >= 0 and general_tax_rate <= 100);
alter table public.sias_billing_config add column if not exists facturacion_cl_api_url text not null default 'https://rest.facturacion.cl';
alter table public.sias_billing_config add column if not exists facturacion_cl_include_link boolean not null default true;
alter table public.sias_billing_config add column if not exists updated_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_billing_config add column if not exists updated_at timestamptz not null default now();


create table if not exists public.sias_external_dte (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  document_id uuid references public.sias_documents(id) on delete set null,
  provider text not null,
  environment text not null,
  document_type integer not null,
  folio bigint,
  status text not null default 'PENDING',
  issue_date date not null default current_date,
  recipient_rut text,
  recipient_name text,
  total numeric(18,2) not null default 0,
  reference_document_type integer,
  reference_folio bigint,
  reference_date date,
  request_hash text,
  provider_response jsonb,
  pdf_base64 text,
  provider_link text,
  error_detail text,
  created_by uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_external_dte add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_external_dte add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_external_dte add column if not exists document_id uuid references public.sias_documents(id) on delete set null;
alter table public.sias_external_dte add column if not exists provider text ;
alter table public.sias_external_dte add column if not exists environment text ;
alter table public.sias_external_dte add column if not exists document_type integer ;
alter table public.sias_external_dte add column if not exists folio bigint;
alter table public.sias_external_dte add column if not exists status text not null default 'PENDING';
alter table public.sias_external_dte add column if not exists issue_date date not null default current_date;
alter table public.sias_external_dte add column if not exists recipient_rut text;
alter table public.sias_external_dte add column if not exists recipient_name text;
alter table public.sias_external_dte add column if not exists total numeric(18,2) not null default 0;
alter table public.sias_external_dte add column if not exists reference_document_type integer;
alter table public.sias_external_dte add column if not exists reference_folio bigint;
alter table public.sias_external_dte add column if not exists reference_date date;
alter table public.sias_external_dte add column if not exists request_hash text;
alter table public.sias_external_dte add column if not exists provider_response jsonb;
alter table public.sias_external_dte add column if not exists pdf_base64 text;
alter table public.sias_external_dte add column if not exists provider_link text;
alter table public.sias_external_dte add column if not exists error_detail text;
alter table public.sias_external_dte add column if not exists created_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_external_dte add column if not exists created_at timestamptz not null default now();
alter table public.sias_external_dte add column if not exists updated_at timestamptz not null default now();

create index if not exists sias_external_dte_company_idx on public.sias_external_dte(company_id,created_at desc);
create unique index if not exists sias_external_dte_provider_folio_unique on public.sias_external_dte(company_id,provider,environment,document_type,folio) where folio is not null;
create unique index if not exists sias_external_dte_request_hash_unique on public.sias_external_dte(company_id,provider,request_hash) where request_hash is not null and status in ('INICIADO','INDETERMINADO','EMITIDO');

-- Ajuste atómico de stock con trazabilidad.
create or replace function public.sias_stock_adjust(
  p_company uuid,
  p_warehouse uuid,
  p_product uuid,
  p_delta numeric,
  p_movement_type text,
  p_reference_type text default null,
  p_reference_id uuid default null,
  p_note text default null,
  p_user uuid default null
) returns numeric
language plpgsql
security definer
set search_path=public
as $$
declare
  v_qty numeric(18,4);
  v_prod_company uuid;
  v_wh_company uuid;
  v_stock_policy jsonb;
  v_allow_negative boolean := false;
begin
  if p_delta = 0 then raise exception 'STOCK_DELTA_CERO'; end if;
  select company_id into v_prod_company from public.sias_products where id=p_product and active=true;
  select company_id into v_wh_company from public.sias_warehouses where id=p_warehouse and active=true;
  if v_prod_company is null or v_prod_company<>p_company then raise exception 'PRODUCTO_NO_VALIDO'; end if;
  if v_wh_company is null or v_wh_company<>p_company then raise exception 'BODEGA_NO_VALIDA'; end if;

  insert into public.sias_stock(company_id,warehouse_id,product_id,quantity)
  values(p_company,p_warehouse,p_product,0)
  on conflict(company_id,warehouse_id,product_id) do nothing;

  select quantity into v_qty
    from public.sias_stock
   where company_id=p_company and warehouse_id=p_warehouse and product_id=p_product
   for update;

  select st.value into v_stock_policy
    from public.sias_settings st
   where st.module='INVENTORY'
     and st.key='stock_policy'
     and (st.company_id=p_company or st.company_id is null)
   order by (st.company_id is not null) desc
   limit 1;

  v_allow_negative := coalesce((v_stock_policy->>'allow_negative_stock')::boolean,false);
  if v_qty + p_delta < 0
     and not (v_allow_negative and upper(coalesce(p_movement_type,''))='VENTA')
  then raise exception 'STOCK_INSUFICIENTE'; end if;
  v_qty := v_qty + p_delta;

  update public.sias_stock set quantity=v_qty,updated_at=now()
   where company_id=p_company and warehouse_id=p_warehouse and product_id=p_product;

  insert into public.sias_stock_movements(company_id,warehouse_id,product_id,movement_type,quantity,balance_after,reference_type,reference_id,note,created_by)
  values(p_company,p_warehouse,p_product,upper(coalesce(p_movement_type,'AJUSTE')),p_delta,v_qty,p_reference_type,p_reference_id,p_note,p_user);
  return v_qty;
end $$;

-- Publicar un documento y aplicar inventario en una única transacción.
create or replace function public.sias_post_document(p_company uuid,p_document uuid,p_user uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  d public.sias_documents%rowtype;
  it record;
  delta numeric(18,4);
  movement text;
begin
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
  if d.status='POSTED' then return jsonb_build_object('id',d.id,'status',d.status,'already_posted',true); end if;
  if d.status='VOID' then raise exception 'DOCUMENTO_ANULADO'; end if;

  if d.document_type in ('SALE','WHOLESALE','PURCHASE') and d.warehouse_id is null then raise exception 'BODEGA_REQUERIDA'; end if;
  if d.document_type in ('SALE','WHOLESALE','PURCHASE') then
    for it in select * from public.sias_document_items where document_id=d.id order by line_no loop
      if it.product_id is null then raise exception 'PRODUCTO_CATALOGO_REQUERIDO'; end if;
      if d.document_type='PURCHASE' then delta := it.quantity; movement := 'COMPRA';
      else delta := -it.quantity; movement := case when d.document_type='WHOLESALE' then 'VENTA_MAYORISTA' else 'VENTA' end;
      end if;
      perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,delta,movement,d.document_type,d.id,'Publicación documento',p_user);
    end loop;
  end if;

  update public.sias_documents set status='POSTED',posted_at=now(),updated_by=p_user,updated_at=now() where id=d.id;
  return jsonb_build_object('id',d.id,'status','POSTED');
end $$;

-- Anular un documento publicado, revirtiendo sus movimientos de inventario.
create or replace function public.sias_void_document(p_company uuid,p_document uuid,p_user uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  d public.sias_documents%rowtype;
  it record;
  delta numeric(18,4);
begin
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
  if d.status='VOID' then return jsonb_build_object('id',d.id,'status','VOID','already_void',true); end if;

  if d.status='POSTED' and d.document_type in ('SALE','WHOLESALE','PURCHASE') then
    for it in select * from public.sias_document_items where document_id=d.id order by line_no loop
      if it.product_id is not null then
        delta := case when d.document_type='PURCHASE' then -it.quantity else it.quantity end;
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,delta,'ANULACION',d.document_type,d.id,'Anulación documento',p_user);
      end if;
    end loop;
  end if;

  update public.sias_documents set status='VOID',voided_at=now(),updated_by=p_user,updated_at=now() where id=d.id;
  return jsonb_build_object('id',d.id,'status','VOID');
end $$;

-- Permisos comerciales.
insert into public.sias_permissions(code,module,name,description) values
('PRODUCT_VIEW','PRODUCTS','Ver productos','Consultar catálogo de productos'),
('PRODUCT_MANAGE','PRODUCTS','Gestionar productos','Crear y modificar productos'),
('INVENTORY_VIEW','INVENTORY','Ver inventario','Consultar stock y movimientos'),
('INVENTORY_MANAGE','INVENTORY','Gestionar inventario','Ajustar y transferir stock'),
('CUSTOMER_VIEW','CUSTOMERS','Ver clientes','Consultar clientes'),
('CUSTOMER_MANAGE','CUSTOMERS','Gestionar clientes','Crear y modificar clientes'),
('SUPPLIER_VIEW','SUPPLIERS','Ver proveedores','Consultar proveedores'),
('SUPPLIER_MANAGE','SUPPLIERS','Gestionar proveedores','Crear y modificar proveedores'),
('SALES_VIEW','SALES','Ver ventas','Consultar ventas y pedidos'),
('SALES_MANAGE','SALES','Gestionar ventas','Crear, publicar y anular ventas/pedidos'),
('PURCHASE_VIEW','PURCHASES','Ver compras','Consultar compras'),
('PURCHASE_MANAGE','PURCHASES','Gestionar compras','Crear, publicar y anular compras'),
('WHOLESALE_VIEW','WHOLESALE','Ver mayoristas','Consultar operación mayorista'),
('WHOLESALE_MANAGE','WHOLESALE','Gestionar mayoristas','Gestionar clientes y ventas mayoristas'),
('REPORT_VIEW','REPORTS','Ver reportes','Consultar indicadores y reportes'),
('BILLING_VIEW','BILLING','Ver facturación','Consultar configuración y documentos tributarios'),
('BILLING_MANAGE','BILLING','Gestionar facturación','Configurar proveedor y emitir DTE')
on conflict(code) do nothing;

-- El rol ADMIN global obtiene todos los permisos comerciales.
insert into public.sias_role_permissions(role_id,permission_id)
select r.id,p.id from public.sias_roles r cross join public.sias_permissions p
where r.company_id is null and r.code='ADMIN' and p.code in (
'PRODUCT_VIEW','PRODUCT_MANAGE','INVENTORY_VIEW','INVENTORY_MANAGE','CUSTOMER_VIEW','CUSTOMER_MANAGE',
'SUPPLIER_VIEW','SUPPLIER_MANAGE','SALES_VIEW','SALES_MANAGE','PURCHASE_VIEW','PURCHASE_MANAGE',
'WHOLESALE_VIEW','WHOLESALE_MANAGE','REPORT_VIEW','BILLING_VIEW','BILLING_MANAGE')
and not exists(select 1 from sias_upgrade_existing_roles e where e.id=r.id)
on conflict do nothing;

-- AUDITOR sólo lectura.
insert into public.sias_role_permissions(role_id,permission_id)
select r.id,p.id from public.sias_roles r cross join public.sias_permissions p
where r.company_id is null and r.code='AUDITOR' and p.code in (
'PRODUCT_VIEW','INVENTORY_VIEW','CUSTOMER_VIEW','SUPPLIER_VIEW','SALES_VIEW','PURCHASE_VIEW','WHOLESALE_VIEW','REPORT_VIEW','BILLING_VIEW')
and not exists(select 1 from sias_upgrade_existing_roles e where e.id=r.id)
on conflict do nothing;

insert into public.sias_modules(code,name,description,icon,route,sort_order) values
('PRODUCTS','Productos','Catálogo comercial','▣','#products',25),
('INVENTORY','Inventario','Stock por bodega y movimientos','▥','#inventory',30),
('CUSTOMERS','Clientes','Clientes y mayoristas','♙','#customers',35),
('SALES','Ventas','Cotizaciones, pedidos y ventas','◎','#sales',40),
('PURCHASES','Compras','Proveedores y compras','⇩','#purchases',45),
('WHOLESALE','Mayoristas','Operación mayorista','◇','#wholesale',50),
('REPORTS','Reportes','Indicadores comerciales','▤','#reports',55),
('BILLING','Facturación','SII y Facturacion.cl','⌁','#billing',60)
on conflict(code) do nothing;

insert into public.sias_billing_config(company_id)
select id from public.sias_companies on conflict(company_id) do nothing;

-- Bodega principal por empresa (sin pisar datos existentes).
insert into public.sias_warehouses(company_id,code,name)
select id,'PRINCIPAL','Bodega principal' from public.sias_companies
on conflict(company_id,code) do nothing;

-- Secuencias documentales por empresa.
insert into public.sias_sequences(company_id,code,prefix,current_value,padding)
select c.id,x.code,x.prefix,0,6 from public.sias_companies c
cross join (values
('QUOTE','COT-'),('ORDER','PED-'),('REQUEST','SOL-'),('SALE','VTA-'),('WHOLESALE','MAY-'),('PURCHASE','COM-')
) as x(code,prefix)
on conflict(company_id,code) do nothing;

-- Seguridad: sin acceso directo desde anon/authenticated.
do $$
declare r record;
begin
  for r in select tablename from pg_tables where schemaname='public' and tablename in (
    'sias_warehouses','sias_products','sias_stock','sias_stock_movements','sias_customers','sias_suppliers',
    'sias_documents','sias_document_items','sias_payments','sias_billing_config','sias_external_dte')
  loop
    execute format('alter table public.%I enable row level security',r.tablename);
    execute format('revoke all on table public.%I from anon, authenticated',r.tablename);
  end loop;
end $$;

revoke all on function public.sias_stock_adjust(uuid,uuid,uuid,numeric,text,text,uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.sias_post_document(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.sias_void_document(uuid,uuid,uuid) from public,anon,authenticated;
grant execute on function public.sias_stock_adjust(uuid,uuid,uuid,numeric,text,text,uuid,text,uuid) to service_role;
grant execute on function public.sias_post_document(uuid,uuid,uuid) to service_role;
grant execute on function public.sias_void_document(uuid,uuid,uuid) to service_role;

update public.sias_installation set version='2.2.0',jwt_enabled=false,updated_at=now() where id=1;

-- Transferencia atómica entre bodegas.
create or replace function public.sias_stock_transfer(
  p_company uuid,
  p_product uuid,
  p_from_warehouse uuid,
  p_to_warehouse uuid,
  p_quantity numeric,
  p_note text default null,
  p_user uuid default null
) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_ref uuid := gen_random_uuid();
begin
  if p_from_warehouse=p_to_warehouse or p_quantity<=0 then raise exception 'TRASLADO_INVALIDO'; end if;
  perform public.sias_stock_adjust(p_company,p_from_warehouse,p_product,-abs(p_quantity),'TRASLADO_SALIDA','TRANSFER',v_ref,p_note,p_user);
  perform public.sias_stock_adjust(p_company,p_to_warehouse,p_product,abs(p_quantity),'TRASLADO_ENTRADA','TRANSFER',v_ref,p_note,p_user);
  return v_ref;
end $$;

-- Guardado atómico de cabecera + detalle de documentos.
create or replace function public.sias_save_document(p_company uuid,p_user uuid,p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  v_id uuid;
  v_type text := upper(coalesce(p_payload->>'document_type',''));
  v_number text := nullif(btrim(p_payload->>'number'),'');
  v_existing public.sias_documents%rowtype;
  it jsonb;
  v_line integer := 0;
begin
  if v_type not in ('QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE') then raise exception 'TIPO_DOCUMENTO_INVALIDO'; end if;
  if jsonb_typeof(p_payload->'items')<>'array' or jsonb_array_length(p_payload->'items')=0 then raise exception 'DOCUMENTO_SIN_ITEMS'; end if;
  if v_number is null then v_number := public.sias_next_sequence(p_company,v_type); end if;

  if nullif(p_payload->>'id','') is not null then
    v_id := (p_payload->>'id')::uuid;
    select * into v_existing from public.sias_documents where id=v_id and company_id=p_company for update;
    if v_existing.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
    if v_existing.status<>'DRAFT' then raise exception 'SOLO_BORRADOR_EDITABLE'; end if;
    update public.sias_documents set
      document_type=v_type,number=v_number,customer_id=nullif(p_payload->>'customer_id','')::uuid,
      supplier_id=nullif(p_payload->>'supplier_id','')::uuid,warehouse_id=nullif(p_payload->>'warehouse_id','')::uuid,
      issue_date=coalesce(nullif(p_payload->>'issue_date','')::date,current_date),due_date=nullif(p_payload->>'due_date','')::date,
      currency='CLP',net=coalesce((p_payload->>'net')::numeric,0),exempt=coalesce((p_payload->>'exempt')::numeric,0),
      tax=coalesce((p_payload->>'tax')::numeric,0),discount=coalesce((p_payload->>'discount')::numeric,0),
      shipping=coalesce((p_payload->>'shipping')::numeric,0),total=coalesce((p_payload->>'total')::numeric,0),
      payment_status=coalesce(nullif(p_payload->>'payment_status',''),'PENDING'),payment_method=nullif(p_payload->>'payment_method',''),
      source=coalesce(nullif(p_payload->>'source',''),'DIRECT'),notes=nullif(p_payload->>'notes',''),updated_by=p_user,updated_at=now()
    where id=v_id;
    delete from public.sias_document_items where document_id=v_id;
  else
    insert into public.sias_documents(company_id,document_type,number,status,customer_id,supplier_id,warehouse_id,issue_date,due_date,currency,net,exempt,tax,discount,shipping,total,payment_status,payment_method,source,notes,created_by,updated_by)
    values(p_company,v_type,v_number,'DRAFT',nullif(p_payload->>'customer_id','')::uuid,nullif(p_payload->>'supplier_id','')::uuid,nullif(p_payload->>'warehouse_id','')::uuid,coalesce(nullif(p_payload->>'issue_date','')::date,current_date),nullif(p_payload->>'due_date','')::date,'CLP',coalesce((p_payload->>'net')::numeric,0),coalesce((p_payload->>'exempt')::numeric,0),coalesce((p_payload->>'tax')::numeric,0),coalesce((p_payload->>'discount')::numeric,0),coalesce((p_payload->>'shipping')::numeric,0),coalesce((p_payload->>'total')::numeric,0),coalesce(nullif(p_payload->>'payment_status',''),'PENDING'),nullif(p_payload->>'payment_method',''),coalesce(nullif(p_payload->>'source',''),'DIRECT'),nullif(p_payload->>'notes',''),p_user,p_user)
    returning id into v_id;
  end if;

  for it in select value from jsonb_array_elements(p_payload->'items') loop
    v_line := v_line + 1;
    insert into public.sias_document_items(document_id,line_no,product_id,sku,description,quantity,unit,unit_price,discount,tax_rate,exempt,line_net,line_tax,line_total)
    values(v_id,v_line,nullif(it->>'product_id','')::uuid,nullif(it->>'sku',''),coalesce(nullif(it->>'description',''),'Ítem'),coalesce((it->>'quantity')::numeric,1),coalesce(nullif(it->>'unit',''),'UN'),coalesce((it->>'unit_price')::numeric,0),coalesce((it->>'discount')::numeric,0),coalesce((it->>'tax_rate')::numeric,19),coalesce((it->>'exempt')::boolean,false),coalesce((it->>'line_net')::numeric,0),coalesce((it->>'line_tax')::numeric,0),coalesce((it->>'line_total')::numeric,0));
  end loop;
  return v_id;
end $$;

revoke all on function public.sias_stock_transfer(uuid,uuid,uuid,uuid,numeric,text,uuid) from public,anon,authenticated;
revoke all on function public.sias_save_document(uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.sias_stock_transfer(uuid,uuid,uuid,uuid,numeric,text,uuid) to service_role;
grant execute on function public.sias_save_document(uuid,uuid,jsonb) to service_role;

-- Bucket público sólo para recursos visuales no sensibles (productos/perfiles).
insert into storage.buckets(id,name,public,file_size_limit)
values('siascloud-public','siascloud-public',true,5242880)
on conflict(id) do update set public=true,file_size_limit=5242880;

-- ============================================================================
-- PORTAL MAYORISTA / AUTOSERVICIO CLIENTE
-- ============================================================================
alter table public.sias_customers add column if not exists profile_photo_url text;

create table if not exists public.sias_customer_accounts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  customer_id uuid not null references public.sias_customers(id) on delete cascade,
  email text not null,
  password_hash text not null,
  active boolean not null default true,
  failed_attempts integer not null default 0,
  locked_until timestamptz,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  credential_scope text not null default 'WHOLESALE_PORTAL',
  unique(company_id,customer_id)
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_customer_accounts add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_customer_accounts add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_customer_accounts add column if not exists customer_id uuid  references public.sias_customers(id) on delete cascade;
alter table public.sias_customer_accounts add column if not exists email text ;
alter table public.sias_customer_accounts add column if not exists password_hash text ;
alter table public.sias_customer_accounts add column if not exists active boolean not null default true;
alter table public.sias_customer_accounts add column if not exists failed_attempts integer not null default 0;
alter table public.sias_customer_accounts add column if not exists locked_until timestamptz;
alter table public.sias_customer_accounts add column if not exists last_login_at timestamptz;
alter table public.sias_customer_accounts add column if not exists created_at timestamptz not null default now();
alter table public.sias_customer_accounts add column if not exists updated_at timestamptz not null default now();
alter table public.sias_customer_accounts add column if not exists credential_scope text not null default 'WHOLESALE_PORTAL';

create unique index if not exists sias_customer_accounts_email_unique on public.sias_customer_accounts(company_id,lower(email));

create table if not exists public.sias_customer_sessions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.sias_customer_accounts(id) on delete cascade,
  company_id uuid not null references public.sias_companies(id) on delete cascade,
  customer_id uuid not null references public.sias_customers(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  revoked boolean not null default false,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
-- Compatibilidad aditiva: agrega sólo columnas ausentes, conservando los datos.
alter table public.sias_customer_sessions add column if not exists id uuid primary key default gen_random_uuid();
alter table public.sias_customer_sessions add column if not exists account_id uuid  references public.sias_customer_accounts(id) on delete cascade;
alter table public.sias_customer_sessions add column if not exists company_id uuid  references public.sias_companies(id) on delete cascade;
alter table public.sias_customer_sessions add column if not exists customer_id uuid  references public.sias_customers(id) on delete cascade;
alter table public.sias_customer_sessions add column if not exists token_hash text  unique;
alter table public.sias_customer_sessions add column if not exists expires_at timestamptz ;
alter table public.sias_customer_sessions add column if not exists revoked boolean not null default false;
alter table public.sias_customer_sessions add column if not exists created_at timestamptz not null default now();
alter table public.sias_customer_sessions add column if not exists last_seen_at timestamptz not null default now();

create index if not exists sias_customer_sessions_lookup_idx on public.sias_customer_sessions(account_id,revoked,expires_at);

alter table public.sias_customer_accounts enable row level security;
alter table public.sias_customer_sessions enable row level security;
revoke all on table public.sias_customer_accounts from public,anon,authenticated;
revoke all on table public.sias_customer_sessions from public,anon,authenticated;

-- ============================================================================
-- CIERRE DE INSTALACION Y VALIDACION DE INTEGRIDAD
-- ============================================================================

update public.sias_installation
   set version = '2.2.0',
       jwt_enabled = false,
       updated_at = now()
 where id = 1;

do $$
declare
  v_missing text[] := array[]::text[];
  v_name text;
  v_required text[] := array[
    'sias_installation',
    'sias_companies',
    'sias_roles',
    'sias_permissions',
    'sias_users',
    'sias_sessions',
    'sias_audit',
    'sias_sii_config',
    'sias_sii_cafs',
    'sias_sii_dte',
    'sias_warehouses',
    'sias_products',
    'sias_stock',
    'sias_stock_movements',
    'sias_customers',
    'sias_suppliers',
    'sias_documents',
    'sias_document_items',
    'sias_payments',
    'sias_billing_config',
    'sias_external_dte',
    'sias_customer_accounts',
    'sias_customer_sessions'
  ];
begin
  foreach v_name in array v_required loop
    if to_regclass('public.' || v_name) is null then
      v_missing := array_append(v_missing, v_name);
    end if;
  end loop;

  if coalesce(array_length(v_missing, 1), 0) > 0 then
    raise exception 'SIASCLOUD_INSTALACION_INCOMPLETA. Faltan objetos: %', array_to_string(v_missing, ', ');
  end if;

  if not exists (
    select 1
      from public.sias_installation
     where id = 1
       and version = '2.2.0'
  ) then
    raise exception 'SIASCLOUD_VERSION_NO_CONFIRMADA';
  end if;

  raise notice 'SiasCloud ERP v2.2.0: estructura SQL creada correctamente.';
end $$;


-- ============================================================================
-- FIN - SIASCLOUD ERP v2.2.0 SQL MAESTRO COMPLETO
-- Luego de ejecutar este archivo, continúe con el despliegue de Edge Functions
-- y la configuración inicial del sistema/empresa.
-- ============================================================================

-- B. FIXES DE USUARIO INICIAL Y PERMISOS RPC
-- SiasCloud ERP 2.2.x - HOTFIX primer usuario / RPC
-- Ejecutar UNA VEZ en Supabase > SQL Editor sobre la base ya instalada.
-- Es idempotente y no borra datos.


grant usage on schema public to service_role;

grant execute on function public.sias_next_sequence(uuid,text) to service_role;
grant execute on function public.sias_sii_take_folio(uuid,integer) to service_role;
grant execute on function public.sias_bootstrap_install(text,text,text,text,text) to service_role;
grant execute on function public.sias_stock_adjust(uuid,uuid,uuid,numeric,text,text,uuid,text,uuid) to service_role;
grant execute on function public.sias_post_document(uuid,uuid,uuid) to service_role;
grant execute on function public.sias_void_document(uuid,uuid,uuid) to service_role;
grant execute on function public.sias_stock_transfer(uuid,uuid,uuid,uuid,numeric,text,uuid) to service_role;
grant execute on function public.sias_save_document(uuid,uuid,jsonb) to service_role;

-- Si el bootstrap falló antes de crear usuarios, asegurar que siga abierto.
update public.sias_installation
set installed = false, installed_at = null, first_admin_id = null, updated_at = now()
where id = 1
  and not exists (select 1 from public.sias_users);


-- Diagnóstico final (debe devolver installed=false y users=0 antes de crear el primer usuario)
select
  (select installed from public.sias_installation where id=1) as installed,
  (select count(*) from public.sias_users) as users,
  has_function_privilege('service_role','public.sias_bootstrap_install(text,text,text,text,text)','EXECUTE') as service_role_can_bootstrap;

-- C. FIX BOOTSTRAP SIN AMBIGÜEDAD
-- ============================================================
-- SIASCLOUD ERP 2.2.x
-- FIX BOOTSTRAP: company_id ambiguo (PostgreSQL 42702)
-- Ejecutar UNA VEZ en Supabase > SQL Editor
-- No elimina datos ni recrea tablas.
-- ============================================================


create or replace function public.sias_bootstrap_install(
  p_company_name text,
  p_company_rut text,
  p_admin_name text,
  p_admin_email text,
  p_password_hash text
)
returns table(company_id uuid, user_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company uuid;
  v_user uuid;
  v_role uuid;
  v_installed boolean;
  v_count bigint;
begin
  select i.installed
    into v_installed
    from public.sias_installation as i
   where i.id = 1
   for update;

  select count(*)
    into v_count
    from public.sias_users as u;

  if coalesce(v_installed, false) or v_count > 0 then
    raise exception 'BOOTSTRAP_CERRADO';
  end if;

  if nullif(trim(p_company_name), '') is null
     or nullif(trim(p_admin_name), '') is null
     or nullif(trim(p_admin_email), '') is null
     or nullif(p_password_hash, '') is null then
    raise exception 'DATOS_INVALIDOS';
  end if;

  insert into public.sias_companies(legal_name, trade_name, rut)
  values(
    trim(p_company_name),
    trim(p_company_name),
    nullif(trim(p_company_rut), '')
  )
  returning id into v_company;

  insert into public.sias_users(
    email,
    full_name,
    password_hash,
    active,
    superadmin,
    must_change_password
  )
  values(
    lower(trim(p_admin_email)),
    trim(p_admin_name),
    p_password_hash,
    true,
    true,
    false
  )
  returning id into v_user;

  insert into public.sias_user_companies(user_id, company_id, is_primary)
  values(v_user, v_company, true);

  -- FIX 42702:
  -- company_id debe apuntar explícitamente a la columna de sias_roles,
  -- no al parámetro de salida RETURNS TABLE(company_id,...).
  select r.id
    into v_role
    from public.sias_roles as r
   where r.company_id is null
     and r.code = 'SUPERADMIN'
   limit 1;

  if v_role is not null then
    insert into public.sias_user_roles(user_id, role_id, company_id)
    values(v_user, v_role, v_company)
    on conflict do nothing;
  end if;

  insert into public.sias_sii_certification_steps(
    company_id,
    code,
    name,
    description
  )
  values
    (v_company, 'POSTULACION',  'Postulación SII',                 'Empresa postulada al ambiente de certificación'),
    (v_company, 'CERTIFICADO', 'Certificado digital',             'Certificado PFX/P12 cargado y vigente'),
    (v_company, 'CAF',         'CAF / folios',                    'CAF de certificación cargados'),
    (v_company, 'SET_PRUEBAS', 'Set de pruebas',                  'Casos de prueba enviados y aceptados'),
    (v_company, 'SIMULACION',  'Simulación',                      'Simulación SII completada'),
    (v_company, 'INTERCAMBIO', 'Intercambio',                     'Intercambio de DTE validado'),
    (v_company, 'DECLARACION', 'Declaración de cumplimiento',     'Declaración final')
  -- FIX 42702:
  -- evitar ON CONFLICT(company_id,code), ya que company_id también
  -- existe como variable de salida PL/pgSQL.
  on conflict on constraint sias_sii_certification_steps_company_id_code_key
  do nothing;

  update public.sias_installation as i
     set installed = true,
         installed_at = now(),
         first_admin_id = v_user,
         jwt_enabled = false,
         version = '2.2.3',
         updated_at = now()
   where i.id = 1;

  return query
  select v_company, v_user;
end
$$;

-- La Edge Function siascloud-system invoca este RPC con service_role.
revoke all on function public.sias_bootstrap_install(text,text,text,text,text)
  from public, anon, authenticated;

grant execute on function public.sias_bootstrap_install(text,text,text,text,text)
  to service_role;


-- Verificación: debe devolver true en service_role_can_bootstrap.
select
  i.installed,
  (select count(*) from public.sias_users) as users,
  has_function_privilege(
    'service_role',
    'public.sias_bootstrap_install(text,text,text,text,text)',
    'EXECUTE'
  ) as service_role_can_bootstrap
from public.sias_installation as i
where i.id = 1;

-- D. TODAS LAS OPERACIONES, COSTOS, EMISIÓN Y TIENDA
-- SIASCLOUD 2.3.1 · REPARACIÓN COMPLETA DE LA BASE EXISTENTE 2.2.x / 2.3.x
-- Pegar TODO el archivo en Supabase > SQL Editor y ejecutar.
-- No ejecutar de nuevo el SQL maestro. Puede repetirse sin borrar datos.
-- Crea las columnas, tablas y RPC necesarias para todos los módulos nuevos.

-- SiasCloud 2.3.0. Actualización acumulativa sobre 2.2.x, sin borrar datos.
-- Ejecutar una vez en SQL Editor. También se puede volver a ejecutar.

alter table public.sias_products add column if not exists creation_key uuid;
create unique index if not exists sias_products_creation_key_unique on public.sias_products(company_id,creation_key) where creation_key is not null;
alter table public.sias_products add column if not exists public_visible boolean not null default true;
alter table public.sias_products add column if not exists product_kind text not null default 'PRODUCT';
alter table public.sias_products add column if not exists recipe_yield numeric(18,4) not null default 1;
alter table public.sias_documents add column if not exists destination_warehouse_id uuid references public.sias_warehouses(id);
alter table public.sias_documents add column if not exists source_document_id uuid references public.sias_documents(id);
alter table public.sias_documents add column if not exists request_key uuid;
alter table public.sias_documents add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.sias_document_items add column if not exists acquisition_cost numeric(18,4);
alter table public.sias_documents drop constraint if exists sias_documents_document_type_check;
alter table public.sias_documents add constraint sias_documents_document_type_check
  check(document_type in ('QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','TRANSFER','DELIVERY'));

create unique index if not exists sias_documents_request_key_unique
  on public.sias_documents(company_id,request_key) where request_key is not null;
create unique index if not exists sias_documents_conversion_unique
  on public.sias_documents(company_id,source_document_id,document_type)
  where source_document_id is not null and status<>'VOID';

create table if not exists public.sias_cost_history (
  id bigint generated always as identity primary key,
  company_id uuid not null references public.sias_companies(id),
  product_id uuid not null references public.sias_products(id),
  document_id uuid references public.sias_documents(id),
  old_cost numeric(18,4) not null,
  new_cost numeric(18,4) not null,
  reason text not null,
  created_by uuid references public.sias_users(id),
  created_at timestamptz not null default now()
);
create index if not exists sias_cost_history_product_idx on public.sias_cost_history(company_id,product_id,id desc);

create table if not exists public.sias_product_recipe (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.sias_companies(id),
  product_id uuid not null references public.sias_products(id) on delete cascade,
  supply_id uuid not null references public.sias_products(id),
  quantity numeric(18,4) not null check(quantity>0),
  unit text not null,
  unique(product_id,supply_id),
  check(product_id<>supply_id)
);
alter table public.sias_cost_history enable row level security;
alter table public.sias_product_recipe enable row level security;
revoke all on public.sias_cost_history,public.sias_product_recipe from anon,authenticated;
grant all on public.sias_cost_history,public.sias_product_recipe to service_role;
grant usage,select on sequence public.sias_cost_history_id_seq to service_role;

-- Unidades de insumos compatibles con ALE ATENCIO.
create or replace function public.sias_unit_factor(p_from text,p_to text)
returns numeric language plpgsql immutable set search_path=public as $$
declare a text:=upper(p_from); b text:=upper(p_to);
begin
  if a in ('G','GR') then a:='GR'; end if;
  if b in ('G','GR') then b:='GR'; end if;
  if a in ('UN','UNID') then a:='UN'; end if;
  if b in ('UN','UNID') then b:='UN'; end if;
  if a=b then return 1; end if;
  if a='GR' and b='KG' then return 0.001; end if;
  if a='KG' and b='GR' then return 1000; end if;
  raise exception 'UNIDADES_INCOMPATIBLES';
end $$;

create or replace function public.sias_recalculate_recipe(p_company uuid,p_product uuid,p_user uuid)
returns numeric language plpgsql security definer set search_path=public as $$
declare v_cost numeric(18,4); v_old numeric(18,4); v_yield numeric(18,4);
begin
  select cost,recipe_yield into v_old,v_yield from public.sias_products
    where id=p_product and company_id=p_company for update;
  if not found then raise exception 'PRODUCTO_NO_ENCONTRADO'; end if;
  if not exists(select 1 from public.sias_product_recipe where product_id=p_product and company_id=p_company) then return v_old; end if;
  select round(sum(r.quantity*s.cost*public.sias_unit_factor(r.unit,s.unit))/greatest(v_yield,0.0001),4)
    into v_cost from public.sias_product_recipe r
    join public.sias_products s on s.id=r.supply_id and s.company_id=p_company
    where r.company_id=p_company and r.product_id=p_product;
  update public.sias_products set cost=coalesce(v_cost,0),updated_at=now() where id=p_product;
  if v_old is distinct from v_cost then
    insert into public.sias_cost_history(company_id,product_id,old_cost,new_cost,reason,created_by)
      values(p_company,p_product,v_old,coalesce(v_cost,0),'RECETA',p_user);
  end if;
  return coalesce(v_cost,0);
end $$;

create or replace function public.sias_refresh_supply_recipes(p_company uuid,p_supply uuid,p_user uuid)
returns void language plpgsql security definer set search_path=public as $$
declare r record;
begin
  for r in select distinct product_id from public.sias_product_recipe
    where company_id=p_company and supply_id=p_supply order by product_id loop
    perform public.sias_recalculate_recipe(p_company,r.product_id,p_user);
  end loop;
end $$;

-- Stock y costos de una empresa se serializan en la misma transacción.
-- El bloqueo evita dobles saldos, costos perdidos y traslados cruzados.
create or replace function public.sias_stock_adjust(
  p_company uuid,p_warehouse uuid,p_product uuid,p_delta numeric,p_movement_type text,
  p_reference_type text default null,p_reference_id uuid default null,p_note text default null,p_user uuid default null
) returns numeric language plpgsql security definer set search_path=public as $$
declare v_qty numeric(18,4); v_stock_policy jsonb; v_allow_negative boolean:=false;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if p_delta is null or p_delta=0 or p_delta::text in ('NaN','Infinity','-Infinity') then raise exception 'STOCK_DELTA_INVALIDO'; end if;
  if not exists(select 1 from public.sias_products where id=p_product and company_id=p_company and active=true) then raise exception 'PRODUCTO_NO_VALIDO'; end if;
  if not exists(select 1 from public.sias_warehouses where id=p_warehouse and company_id=p_company and active=true) then raise exception 'BODEGA_NO_VALIDA'; end if;
  insert into public.sias_stock(company_id,warehouse_id,product_id,quantity) values(p_company,p_warehouse,p_product,0)
    on conflict(company_id,warehouse_id,product_id) do nothing;
  select quantity into v_qty from public.sias_stock
    where company_id=p_company and warehouse_id=p_warehouse and product_id=p_product for update;
  select st.value into v_stock_policy from public.sias_settings st
   where st.module='INVENTORY' and st.key='stock_policy'
     and (st.company_id=p_company or st.company_id is null)
   order by (st.company_id is not null) desc limit 1;
  v_allow_negative:=coalesce((v_stock_policy->>'allow_negative_stock')::boolean,false);
  if v_qty+p_delta<0 and not (v_allow_negative and upper(coalesce(p_movement_type,''))='VENTA') then raise exception 'STOCK_INSUFICIENTE'; end if;
  v_qty:=v_qty+p_delta;
  update public.sias_stock set quantity=v_qty,updated_at=now()
    where company_id=p_company and warehouse_id=p_warehouse and product_id=p_product;
  insert into public.sias_stock_movements(company_id,warehouse_id,product_id,movement_type,quantity,balance_after,reference_type,reference_id,note,created_by)
    values(p_company,p_warehouse,p_product,upper(coalesce(p_movement_type,'AJUSTE')),p_delta,v_qty,p_reference_type,p_reference_id,p_note,p_user);
  return v_qty;
end $$;

create or replace function public.sias_post_document(p_company uuid,p_document uuid,p_user uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; it record; v_stock numeric; v_old numeric; v_cost numeric; v_new numeric; v_delta numeric;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
  if d.status='POSTED' then return jsonb_build_object('id',d.id,'status',d.status,'already_posted',true); end if;
  if d.status<>'DRAFT' then raise exception 'DOCUMENTO_ANULADO'; end if;
  if not exists(select 1 from public.sias_document_items where document_id=d.id) then raise exception 'DOCUMENTO_SIN_ITEMS'; end if;
  if d.document_type in ('SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','TRANSFER','DELIVERY') then
    if d.warehouse_id is null then raise exception 'BODEGA_REQUERIDA'; end if;
    if d.document_type='TRANSFER' and (d.destination_warehouse_id is null or d.destination_warehouse_id=d.warehouse_id) then raise exception 'TRASLADO_INVALIDO'; end if;
    for it in select * from public.sias_document_items where document_id=d.id order by product_id,line_no loop
      if it.product_id is null then raise exception 'PRODUCTO_CATALOGO_REQUERIDO'; end if;
      if d.document_type in ('PURCHASE','RECEIPT') then
        select cost into v_old from public.sias_products where id=it.product_id and company_id=p_company for update;
        select coalesce(sum(quantity),0) into v_stock from public.sias_stock where company_id=p_company and product_id=it.product_id;
        v_cost:=coalesce(it.acquisition_cost,case when it.exempt then it.unit_price else it.unit_price/(1+it.tax_rate/100) end);
        v_new:=round((v_stock*v_old+it.quantity*v_cost)/(v_stock+it.quantity),4);
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,it.quantity,'INGRESO',d.document_type,d.id,d.number,p_user);
        update public.sias_products set cost=v_new,updated_at=now() where id=it.product_id and company_id=p_company;
        insert into public.sias_cost_history(company_id,product_id,document_id,old_cost,new_cost,reason,created_by)
          values(p_company,it.product_id,d.id,v_old,v_new,'INGRESO',p_user);
        perform public.sias_refresh_supply_recipes(p_company,it.product_id,p_user);
      elsif d.document_type='TRANSFER' then
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,-it.quantity,'TRASLADO_SALIDA','TRANSFER',d.id,d.number,p_user);
        perform public.sias_stock_adjust(p_company,d.destination_warehouse_id,it.product_id,it.quantity,'TRASLADO_ENTRADA','TRANSFER',d.id,d.number,p_user);
      elsif d.document_type<>'DELIVERY' or coalesce((d.metadata->>'move_stock')::boolean,true) then
        v_delta:=-it.quantity;
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,v_delta,
          case when d.document_type='DELIVERY' then 'DESPACHO' when d.document_type='ISSUE' then 'SALIDA' else 'VENTA' end,
          d.document_type,d.id,d.number,p_user);
      end if;
    end loop;
  end if;
  update public.sias_documents set status='POSTED',posted_at=now(),updated_by=p_user,updated_at=now() where id=d.id;
  return jsonb_build_object('id',d.id,'status','POSTED');
end $$;

create or replace function public.sias_void_document(p_company uuid,p_document uuid,p_user uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; it record; v_stock numeric; v_old numeric; v_cost numeric; v_new numeric;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
  if d.status='VOID' then return jsonb_build_object('id',d.id,'status','VOID','already_void',true); end if;
  if exists(select 1 from public.sias_external_dte where document_id=d.id and company_id=p_company and status in ('INICIADO','INDETERMINADO','EMITIDO')) then
    raise exception 'DOCUMENTO_CON_DTE_REQUIERE_NOTA_TRIBUTARIA';
  end if;
  if exists(select 1 from public.sias_documents where source_document_id=d.id and company_id=p_company and status<>'VOID') then
    raise exception 'DOCUMENTO_CON_DERIVADOS_ACTIVOS';
  end if;
  if exists(select 1 from public.sias_payments where document_id=d.id and company_id=p_company and status='CONFIRMED') then
    raise exception 'DOCUMENTO_CON_PAGOS_CONFIRMADOS';
  end if;
  if d.status='POSTED' then
    for it in select * from public.sias_document_items where document_id=d.id order by product_id,line_no desc loop
      if d.document_type in ('PURCHASE','RECEIPT') then
        select cost into v_old from public.sias_products where id=it.product_id and company_id=p_company for update;
        select coalesce(sum(quantity),0) into v_stock from public.sias_stock where company_id=p_company and product_id=it.product_id;
        v_cost:=coalesce(it.acquisition_cost,case when it.exempt then it.unit_price else it.unit_price/(1+it.tax_rate/100) end);
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,-it.quantity,'ANULACION',d.document_type,d.id,d.number,p_user);
        if v_stock>it.quantity then v_new:=greatest(0,round((v_stock*v_old-it.quantity*v_cost)/(v_stock-it.quantity),4));
        else
          select old_cost into v_new from public.sias_cost_history where company_id=p_company and document_id=d.id and product_id=it.product_id and reason='INGRESO' order by id limit 1;
          v_new:=coalesce(v_new,v_old);
        end if;
        update public.sias_products set cost=v_new,updated_at=now() where id=it.product_id;
        insert into public.sias_cost_history(company_id,product_id,document_id,old_cost,new_cost,reason,created_by)
          values(p_company,it.product_id,d.id,v_old,v_new,'ANULACION_INGRESO',p_user);
        perform public.sias_refresh_supply_recipes(p_company,it.product_id,p_user);
      elsif d.document_type='TRANSFER' then
        perform public.sias_stock_adjust(p_company,d.destination_warehouse_id,it.product_id,-it.quantity,'ANULACION_TRASLADO','TRANSFER',d.id,d.number,p_user);
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,it.quantity,'ANULACION_TRASLADO','TRANSFER',d.id,d.number,p_user);
      elsif d.document_type in ('SALE','WHOLESALE','ISSUE') or (d.document_type='DELIVERY' and coalesce((d.metadata->>'move_stock')::boolean,true)) then
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,it.quantity,'ANULACION',d.document_type,d.id,d.number,p_user);
      end if;
    end loop;
  end if;
  update public.sias_documents set status='VOID',voided_at=now(),updated_by=p_user,updated_at=now() where id=d.id;
  return jsonb_build_object('id',d.id,'status','VOID');
end $$;

-- Cabecera, detalle, folio y publicación se guardan de forma atómica.
create or replace function public.sias_save_document(p_company uuid,p_user uuid,p_payload jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_type text:=upper(coalesce(p_payload->>'document_type','')); v_number text; v_existing public.sias_documents%rowtype;
  v_source public.sias_documents%rowtype; v_source_id uuid:=nullif(p_payload->>'source_document_id','')::uuid;
  v_key uuid:=nullif(p_payload->>'request_key','')::uuid; v_meta jsonb:=coalesce(p_payload->'metadata','{}'::jsonb);
  it jsonb; v_line integer:=0; v_pid uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if v_type not in ('QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','TRANSFER','DELIVERY') then raise exception 'TIPO_DOCUMENTO_INVALIDO'; end if;
  if coalesce(jsonb_typeof(p_payload->'items'),'')<>'array' then raise exception 'DOCUMENTO_SIN_ITEMS'; end if;
  if jsonb_array_length(p_payload->'items') not between 1 and 200 then raise exception 'DOCUMENTO_ITEMS_INVALIDOS'; end if;
  if nullif(p_payload->>'id','') is null and v_key is not null then
    select id into v_id from public.sias_documents where company_id=p_company and request_key=v_key;
    if v_id is not null then return v_id; end if;
  end if;
  if nullif(p_payload->>'customer_id','') is not null and not exists(select 1 from public.sias_customers where id=(p_payload->>'customer_id')::uuid and company_id=p_company and active) then raise exception 'CLIENTE_NO_VALIDO'; end if;
  if nullif(p_payload->>'supplier_id','') is not null and not exists(select 1 from public.sias_suppliers where id=(p_payload->>'supplier_id')::uuid and company_id=p_company and active) then raise exception 'PROVEEDOR_NO_VALIDO'; end if;
  if nullif(p_payload->>'warehouse_id','') is not null and not exists(select 1 from public.sias_warehouses where id=(p_payload->>'warehouse_id')::uuid and company_id=p_company and active) then raise exception 'BODEGA_NO_VALIDA'; end if;
  if nullif(p_payload->>'destination_warehouse_id','') is not null and not exists(select 1 from public.sias_warehouses where id=(p_payload->>'destination_warehouse_id')::uuid and company_id=p_company and active) then raise exception 'BODEGA_DESTINO_NO_VALIDA'; end if;
  if v_source_id is not null then
    select * into v_source from public.sias_documents where id=v_source_id and company_id=p_company for update;
    if v_source.id is null or v_source.status<>'POSTED' then raise exception 'ORIGEN_DEBE_ESTAR_CONFIRMADO'; end if;
    if not ((v_source.document_type='REQUEST' and v_type in ('QUOTE','ORDER','SALE')) or
      (v_source.document_type='QUOTE' and v_type in ('ORDER','SALE')) or
      (v_source.document_type='ORDER' and v_type='SALE') or
      (v_source.document_type in ('SALE','WHOLESALE') and v_type='DELIVERY')) then raise exception 'CONVERSION_NO_VALIDA'; end if;
    if v_source.customer_id is not null and nullif(p_payload->>'customer_id','')::uuid is distinct from v_source.customer_id then raise exception 'CLIENTE_ORIGEN_NO_COINCIDE'; end if;
    if v_type='DELIVERY' then v_meta:=v_meta||jsonb_build_object('move_stock',false); end if;
    if v_type='SALE' and exists(select 1 from public.sias_documents where company_id=p_company and source_document_id=v_source.id and document_type='ORDER' and status<>'VOID') then raise exception 'FACTURAR_DESDE_PEDIDO_DERIVADO'; end if;
  end if;
  if nullif(p_payload->>'id','') is not null then
    v_id:=(p_payload->>'id')::uuid;
    select * into v_existing from public.sias_documents where id=v_id and company_id=p_company for update;
    if v_existing.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
    if v_existing.status<>'DRAFT' then raise exception 'SOLO_BORRADOR_EDITABLE'; end if;
    if v_existing.document_type<>v_type or v_existing.source_document_id is distinct from v_source_id then raise exception 'TIPO_ORIGEN_NO_MODIFICABLE'; end if;
    v_number:=v_existing.number;
    v_meta:=v_existing.metadata||v_meta;
    delete from public.sias_document_items where document_id=v_id;
  else
    v_number:=public.sias_next_sequence(p_company,v_type);
    insert into public.sias_documents(company_id,document_type,number,created_by,updated_by,request_key)
      values(p_company,v_type,v_number,p_user,p_user,v_key) returning id into v_id;
  end if;
  update public.sias_documents set customer_id=nullif(p_payload->>'customer_id','')::uuid,supplier_id=nullif(p_payload->>'supplier_id','')::uuid,
    warehouse_id=nullif(p_payload->>'warehouse_id','')::uuid,destination_warehouse_id=nullif(p_payload->>'destination_warehouse_id','')::uuid,
    source_document_id=v_source_id,metadata=v_meta,issue_date=coalesce(nullif(p_payload->>'issue_date','')::date,current_date),
    due_date=nullif(p_payload->>'due_date','')::date,currency='CLP',net=coalesce((p_payload->>'net')::numeric,0),
    exempt=coalesce((p_payload->>'exempt')::numeric,0),tax=coalesce((p_payload->>'tax')::numeric,0),
    discount=coalesce((p_payload->>'discount')::numeric,0),shipping=coalesce((p_payload->>'shipping')::numeric,0),total=coalesce((p_payload->>'total')::numeric,0),
    payment_method=nullif(p_payload->>'payment_method',''),source=coalesce(nullif(p_payload->>'source',''),'DIRECT'),
    notes=nullif(p_payload->>'notes',''),updated_by=p_user,updated_at=now() where id=v_id;
  for it in select value from jsonb_array_elements(p_payload->'items') loop
    v_line:=v_line+1; v_pid:=nullif(it->>'product_id','')::uuid;
    if v_pid is null or not exists(select 1 from public.sias_products where id=v_pid and company_id=p_company and active) then raise exception 'PRODUCTO_NO_VALIDO'; end if;
    insert into public.sias_document_items(document_id,line_no,product_id,sku,description,quantity,unit,unit_price,discount,tax_rate,exempt,line_net,line_tax,line_total,acquisition_cost)
      values(v_id,v_line,v_pid,nullif(it->>'sku',''),coalesce(nullif(it->>'description',''),'Ítem'),(it->>'quantity')::numeric,
        coalesce(nullif(it->>'unit',''),'UN'),(it->>'unit_price')::numeric,coalesce((it->>'discount')::numeric,0),
        coalesce((it->>'tax_rate')::numeric,19),coalesce((it->>'exempt')::boolean,false),
        (it->>'line_net')::numeric,(it->>'line_tax')::numeric,(it->>'line_total')::numeric,nullif(it->>'acquisition_cost','')::numeric);
  end loop;
  return v_id;
end $$;

create or replace function public.sias_commit_document(p_company uuid,p_user uuid,p_payload jsonb,p_post boolean default false)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  v_id:=public.sias_save_document(p_company,p_user,p_payload);
  if p_post then perform public.sias_post_document(p_company,v_id,p_user); end if;
  return v_id;
end $$;

create or replace function public.sias_save_recipe(p_company uuid,p_user uuid,p_product uuid,p_yield numeric,p_items jsonb)
returns numeric language plpgsql security definer set search_path=public as $$
declare it jsonb; v_supply public.sias_products%rowtype;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if p_yield is null or p_yield<=0 then raise exception 'RENDIMIENTO_INVALIDO'; end if;
  if not exists(select 1 from public.sias_products where id=p_product and company_id=p_company and product_kind='PRODUCT') then raise exception 'PRODUCTO_NO_VALIDO'; end if;
  if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)>100 then raise exception 'RECETA_INVALIDA'; end if;
  delete from public.sias_product_recipe where company_id=p_company and product_id=p_product;
  for it in select value from jsonb_array_elements(p_items) loop
    select * into v_supply from public.sias_products where id=(it->>'supply_id')::uuid and company_id=p_company and product_kind='SUPPLY' and active;
    if v_supply.id is null then raise exception 'INSUMO_NO_VALIDO'; end if;
    perform public.sias_unit_factor(it->>'unit',v_supply.unit);
    insert into public.sias_product_recipe(company_id,product_id,supply_id,quantity,unit)
      values(p_company,p_product,v_supply.id,(it->>'quantity')::numeric,upper(it->>'unit'));
  end loop;
  update public.sias_products set recipe_yield=p_yield,updated_at=now() where id=p_product;
  return public.sias_recalculate_recipe(p_company,p_product,p_user);
end $$;

-- Producto e ingreso de apertura en una única transacción.
create or replace function public.sias_save_product(p_company uuid,p_user uuid,p_payload jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid:=nullif(p_payload->>'id','')::uuid; v_old public.sias_products%rowtype; v_row public.sias_products%rowtype;
  v_qty numeric:=coalesce((p_payload->>'initial_stock')::numeric,0); v_wh uuid:=nullif(p_payload->>'initial_warehouse_id','')::uuid;
  v_rate numeric:=coalesce((p_payload->>'tax_rate')::numeric,19); v_exempt boolean:=coalesce((p_payload->>'exempt')::boolean,false);
  v_price numeric; v_doc uuid; v_payload jsonb; v_key uuid:=nullif(p_payload->>'request_key','')::uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if v_id is null and v_key is not null then
    select id into v_id from public.sias_products where company_id=p_company and creation_key=v_key;
    if v_id is not null then return v_id; end if;
  end if;
  if v_id is not null then
    select * into v_old from public.sias_products where id=v_id and company_id=p_company for update;
    if v_old.id is null then raise exception 'PRODUCTO_NO_ENCONTRADO'; end if;
    if v_qty>0 then raise exception 'STOCK_EXISTENTE_USAR_INGRESO'; end if;
    if v_old.unit is distinct from p_payload->>'unit' and (exists(select 1 from public.sias_stock_movements where product_id=v_id) or exists(select 1 from public.sias_product_recipe where supply_id=v_id)) then raise exception 'UNIDAD_CON_MOVIMIENTOS_NO_MODIFICABLE'; end if;
    if v_old.product_kind is distinct from p_payload->>'product_kind' then raise exception 'TIPO_PRODUCTO_NO_MODIFICABLE'; end if;
  else
    v_id:=gen_random_uuid();
    insert into public.sias_products(id,company_id,name,creation_key) values(v_id,p_company,p_payload->>'name',v_key);
  end if;
  update public.sias_products set name=p_payload->>'name',sku=nullif(p_payload->>'sku',''),barcode=nullif(p_payload->>'barcode',''),
    description=nullif(p_payload->>'description',''),category=nullif(p_payload->>'category',''),unit=coalesce(nullif(p_payload->>'unit',''),'UN'),
    product_kind=coalesce(nullif(p_payload->>'product_kind',''),'PRODUCT'),cost=coalesce((p_payload->>'cost')::numeric,0),
    price=coalesce((p_payload->>'price')::numeric,0),wholesale_price=coalesce((p_payload->>'wholesale_price')::numeric,0),
    tax_rate=v_rate,exempt=v_exempt,min_stock=coalesce((p_payload->>'min_stock')::numeric,0),max_stock=nullif(p_payload->>'max_stock','')::numeric,
    image_url=nullif(p_payload->>'image_url',''),featured=coalesce((p_payload->>'featured')::boolean,false),public_visible=coalesce((p_payload->>'public_visible')::boolean,true),active=coalesce((p_payload->>'active')::boolean,true),updated_at=now()
    where id=v_id returning * into v_row;
  if v_old.id is not null and v_old.cost is distinct from v_row.cost then
    insert into public.sias_cost_history(company_id,product_id,old_cost,new_cost,reason,created_by)
      values(p_company,v_id,v_old.cost,v_row.cost,'EDICION',p_user);
  end if;
  if v_qty>0 then
    if v_wh is null then raise exception 'BODEGA_INICIAL_REQUERIDA'; end if;
    v_price:=case when v_exempt then v_row.cost else v_row.cost*(1+v_rate/100) end;
    v_payload:=jsonb_build_object('document_type','RECEIPT','warehouse_id',v_wh,'issue_date',current_date,
      'net',case when v_exempt then 0 else round(v_qty*v_row.cost) end,'exempt',case when v_exempt then round(v_qty*v_row.cost) else 0 end,
      'tax',case when v_exempt then 0 else round(v_qty*(v_price-v_row.cost)) end,'total',round(v_qty*v_price),
      'metadata',jsonb_build_object('receipt_type','APERTURA'),'notes','Stock inicial · '||v_row.name,
      'items',jsonb_build_array(jsonb_build_object('product_id',v_id,'sku',v_row.sku,'description',v_row.name,'quantity',v_qty,'unit',v_row.unit,
        'unit_price',v_price,'tax_rate',v_rate,'exempt',v_exempt,'line_net',case when v_exempt then 0 else round(v_qty*v_row.cost) end,
        'line_tax',case when v_exempt then 0 else round(v_qty*(v_price-v_row.cost)) end,'line_total',round(v_qty*v_price),'acquisition_cost',v_row.cost)));
    v_doc:=public.sias_commit_document(p_company,p_user,v_payload,true);
  end if;
  perform public.sias_recalculate_recipe(p_company,v_id,p_user);
  perform public.sias_refresh_supply_recipes(p_company,v_id,p_user);
  return v_id;
end $$;

create or replace function public.sias_next_sequence(p_company uuid,p_code text)
returns text language plpgsql security definer set search_path=public as $$
declare v bigint; p text; z integer;
begin
  insert into public.sias_sequences(company_id,code,current_value,prefix,padding)
  values(p_company,upper(p_code),0,case upper(p_code)
    when 'RECEIPT' then 'ING-' when 'ISSUE' then 'SAL-' when 'TRANSFER' then 'TRA-' when 'DELIVERY' then 'GUI-'
    when 'QUOTE' then 'COT-' when 'ORDER' then 'PED-' when 'REQUEST' then 'SOL-' when 'SALE' then 'VTA-'
    when 'WHOLESALE' then 'MAY-' when 'PURCHASE' then 'COM-' else upper(p_code)||'-' end,8)
  on conflict(company_id,code) do nothing;
  update public.sias_sequences set current_value=current_value+1,updated_at=now()
  where company_id=p_company and code=upper(p_code) returning current_value,prefix,padding into v,p,z;
  return coalesce(p,'')||lpad(v::text,z,'0');
end $$;

-- Secuencias disponibles para empresas actuales y futuras.
insert into public.sias_sequences(company_id,code,prefix,current_value,padding)
select c.id,x.code,x.prefix,0,8 from public.sias_companies c cross join (values
  ('RECEIPT','ING-'),('ISSUE','SAL-'),('TRANSFER','TRA-'),('DELIVERY','GUI-')) x(code,prefix)
on conflict(company_id,code) do nothing;

revoke all on function public.sias_unit_factor(text,text) from public,anon,authenticated;
revoke all on function public.sias_recalculate_recipe(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.sias_refresh_supply_recipes(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.sias_commit_document(uuid,uuid,jsonb,boolean) from public,anon,authenticated;
revoke all on function public.sias_save_recipe(uuid,uuid,uuid,numeric,jsonb) from public,anon,authenticated;
revoke all on function public.sias_save_product(uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.sias_unit_factor(text,text) to service_role;
grant execute on function public.sias_recalculate_recipe(uuid,uuid,uuid) to service_role;
grant execute on function public.sias_refresh_supply_recipes(uuid,uuid,uuid) to service_role;
grant execute on function public.sias_commit_document(uuid,uuid,jsonb,boolean) to service_role;
grant execute on function public.sias_save_recipe(uuid,uuid,uuid,numeric,jsonb) to service_role;
grant execute on function public.sias_save_product(uuid,uuid,jsonb) to service_role;

alter table public.sias_payments add column if not exists request_key uuid;
create unique index if not exists sias_payments_request_key_unique on public.sias_payments(company_id,request_key) where request_key is not null;

create or replace function public.sias_register_payment(p_company uuid,p_user uuid,p_document uuid,p_amount numeric,p_method text,p_reference text,p_key uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; v_paid numeric; v_id uuid; v_status text;
begin
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null or d.status<>'POSTED' or d.document_type not in ('SALE','WHOLESALE') then raise exception 'VENTA_CONFIRMADA_REQUERIDA'; end if;
  if p_key is null then raise exception 'PAGO_INVALIDO'; end if;
  select id into v_id from public.sias_payments where company_id=p_company and request_key=p_key;
  if v_id is not null then return jsonb_build_object('payment_id',v_id,'reused',true); end if;
  select coalesce(sum(amount),0) into v_paid from public.sias_payments where company_id=p_company and document_id=p_document and status='CONFIRMED';
  if p_amount is null or p_amount<=0 or p_amount::text in ('NaN','Infinity','-Infinity') or p_amount>d.total-v_paid then raise exception 'PAGO_SUPERA_SALDO'; end if;
  insert into public.sias_payments(company_id,document_id,amount,method,reference,created_by,request_key)
    values(p_company,p_document,p_amount,p_method,nullif(p_reference,''),p_user,p_key) returning id into v_id;
  v_paid:=v_paid+p_amount;v_status:=case when v_paid>=d.total then 'PAID' else 'PARTIAL' end;
  update public.sias_documents set payment_status=v_status,updated_at=now() where id=p_document;
  return jsonb_build_object('payment_id',v_id,'payment_status',v_status,'paid',v_paid);
end $$;
revoke all on function public.sias_register_payment(uuid,uuid,uuid,numeric,text,text,uuid) from public,anon,authenticated;
grant execute on function public.sias_register_payment(uuid,uuid,uuid,numeric,text,text,uuid) to service_role;
create unique index if not exists sias_external_dte_main_unique
  on public.sias_external_dte(company_id,document_id,provider,environment)
  where document_type in (33,34,39,41) and status in ('INICIADO','INDETERMINADO','EMITIDO');

notify pgrst,'reload schema';

-- Tienda pública y solicitudes. No publica información de clientes ni costos.

alter table public.sias_products add column if not exists public_visible boolean not null default true;
create table if not exists public.sias_store_settings (
  company_id uuid primary key references public.sias_companies(id) on delete cascade,
  slug text not null unique,
  enabled boolean not null default false,
  title text not null default 'Nuestra tienda',
  tagline text not null default 'Encuentra lo que necesitas',
  hero_title text not null default 'Productos para cada día',
  hero_text text not null default 'Explora nuestro catálogo y envía tu solicitud de pedido.',
  about_title text not null default 'Estamos para ayudarte',
  about_text text not null default '',
  delivery_text text not null default '',
  terms text not null default '',
  logo_url text,
  hero_image text,
  primary_color text not null default '#2563eb',
  whatsapp text,
  contact_email text,
  contact_address text,
  allow_orders boolean not null default true,
  show_stock boolean not null default false,
  hide_unavailable boolean not null default false,
  warehouse_id uuid references public.sias_warehouses(id),
  updated_at timestamptz not null default now()
);
create table if not exists public.sias_store_rate_limits (
  client_hash text primary key,
  window_at timestamptz not null default now(),
  count integer not null default 0
);
alter table public.sias_store_settings enable row level security;
alter table public.sias_store_rate_limits enable row level security;
revoke all on public.sias_store_settings,public.sias_store_rate_limits from anon,authenticated;
grant all on public.sias_store_settings,public.sias_store_rate_limits to service_role;

insert into public.sias_store_settings(company_id,slug,title)
  select id,'tienda-'||left(id::text,8),coalesce(nullif(trade_name,''),legal_name) from public.sias_companies
  on conflict(company_id) do nothing;

create or replace function public.sias_store_check_rate(p_hash text)
returns boolean language plpgsql security definer set search_path=public as $$
declare n integer;
begin
  delete from public.sias_store_rate_limits where window_at<now()-interval '1 day';
  insert into public.sias_store_rate_limits(client_hash,window_at,count) values(p_hash,now(),1)
  on conflict(client_hash) do update set
    count=case when sias_store_rate_limits.window_at<now()-interval '15 minutes' then 1 else sias_store_rate_limits.count+1 end,
    window_at=case when sias_store_rate_limits.window_at<now()-interval '15 minutes' then now() else sias_store_rate_limits.window_at end
  returning count into n;
  return n<=10;
end $$;

-- Las solicitudes web no alteran stock ni actualizan clientes existentes.
-- El personal vincula un cliente al convertirlas en un documento comercial.
create or replace function public.sias_store_create_request(p_company uuid,p_key uuid,p_contact jsonb,p_items jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_store public.sias_store_settings%rowtype; pr public.sias_products%rowtype; it jsonb; v_items jsonb:='[]'::jsonb;
  v_qty numeric; v_gross numeric; v_net numeric; v_tax numeric; v_total numeric:=0; v_net_total numeric:=0; v_tax_total numeric:=0; v_exempt numeric:=0;
  v_id uuid; v_number text; v_fingerprint text; v_old jsonb;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into v_store from public.sias_store_settings where company_id=p_company and enabled and allow_orders;
  if v_store.company_id is null then raise exception 'TIENDA_NO_DISPONIBLE'; end if;
  if not exists(select 1 from public.sias_companies where id=p_company and active) then raise exception 'TIENDA_NO_DISPONIBLE'; end if;
  if p_key is null then raise exception 'SOLICITUD_INVALIDA'; end if;
  v_fingerprint:=md5(p_contact::text||p_items::text);
  select id,number,metadata into v_id,v_number,v_old from public.sias_documents where company_id=p_company and request_key=p_key;
  if v_id is not null then
    if v_old->>'web_fingerprint' is distinct from v_fingerprint then raise exception 'SOLICITUD_INVALIDA'; end if;
    return jsonb_build_object('number',v_number,'reused',true);
  end if;
  if coalesce(jsonb_typeof(p_items),'')<>'array' then raise exception 'PEDIDO_SIN_ITEMS'; end if;
  if jsonb_array_length(p_items) not between 1 and 60 then raise exception 'PEDIDO_ITEMS_INVALIDOS'; end if;
  for it in select value from jsonb_array_elements(p_items) loop
    select * into pr from public.sias_products where id=(it->>'product_id')::uuid and company_id=p_company and active and public_visible and product_kind='PRODUCT';
    if pr.id is null then raise exception 'PRODUCTO_NO_DISPONIBLE'; end if;
    v_qty:=(it->>'quantity')::numeric;
    if v_qty is null or v_qty<=0 or v_qty>10000 or v_qty::text in ('NaN','Infinity','-Infinity') then raise exception 'CANTIDAD_INVALIDA'; end if;
    v_gross:=round(v_qty*pr.price);v_net:=case when pr.exempt then 0 else round(v_gross/(1+pr.tax_rate/100)) end;
    v_tax:=case when pr.exempt then 0 else v_gross-v_net end;
    v_total:=v_total+v_gross;v_net_total:=v_net_total+v_net;v_tax_total:=v_tax_total+v_tax;
    if pr.exempt then v_exempt:=v_exempt+v_gross; end if;
    v_items:=v_items||jsonb_build_array(jsonb_build_object('product_id',pr.id,'sku',pr.sku,'description',pr.name,'quantity',v_qty,'unit',pr.unit,
      'unit_price',pr.price,'discount',0,'tax_rate',pr.tax_rate,'exempt',pr.exempt,'line_net',v_net,'line_tax',v_tax,'line_total',v_gross));
  end loop;
  v_id:=public.sias_save_document(p_company,null,jsonb_build_object('document_type','REQUEST','request_key',p_key,'warehouse_id',v_store.warehouse_id,
    'source','WEB','issue_date',(now() at time zone 'America/Santiago')::date,'net',v_net_total,'tax',v_tax_total,'exempt',v_exempt,'total',v_total,
    'notes',p_contact->>'notes','metadata',jsonb_build_object('web_contact',p_contact,'web_fingerprint',v_fingerprint),'items',v_items));
  select number into v_number from public.sias_documents where id=v_id;
  insert into public.sias_notifications(user_id,title,message,type,module,reference_id)
    select u.id,'Nueva solicitud web',v_number||' · '||coalesce(p_contact->>'name','Cliente'),'INFO','STORE',v_id::text
    from public.sias_users u where u.active and (u.superadmin or exists(select 1 from public.sias_user_companies uc where uc.user_id=u.id and uc.company_id=p_company));
  return jsonb_build_object('number',v_number,'total',v_total);
end $$;
revoke all on function public.sias_store_check_rate(text) from public,anon,authenticated;
revoke all on function public.sias_store_create_request(uuid,uuid,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.sias_store_check_rate(text) to service_role;
grant execute on function public.sias_store_create_request(uuid,uuid,jsonb,jsonb) to service_role;
notify pgrst,'reload schema';

-- Reservar la emisión antes de contactar al proveedor, bajo bloqueo del documento.

alter table public.sias_external_dte add column if not exists reference_id uuid references public.sias_external_dte(id);
alter table public.sias_external_dte add column if not exists reference_code integer;
create or replace function public.sias_claim_dte(p_company uuid,p_user uuid,p_document uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; existing public.sias_external_dte%rowtype; ref public.sias_external_dte%rowtype;
  v_type integer:=(p_payload->>'document_type')::integer; v_total numeric:=(p_payload->>'total')::numeric; v_credited numeric;
  v_reference uuid:=nullif(p_payload->>'reference_id','')::uuid; v_code integer:=nullif(p_payload->>'reference_code','')::integer;
begin
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null or d.status<>'POSTED' or d.document_type not in ('SALE','WHOLESALE','DELIVERY') then raise exception 'DOCUMENTO_CONFIRMADO_REQUERIDO'; end if;
  select * into existing from public.sias_external_dte where company_id=p_company and provider='FACTURACION_CL' and request_hash=p_payload->>'request_hash';
  if existing.id is not null and existing.status<>'ERROR' then return to_jsonb(existing)||jsonb_build_object('reused',true); end if;
  if v_type in (33,34,39,41) and exists(select 1 from public.sias_external_dte where company_id=p_company and document_id=p_document
    and provider='FACTURACION_CL' and environment=p_payload->>'environment' and document_type in (33,34,39,41) and status in ('INICIADO','INDETERMINADO','EMITIDO')) then raise exception 'DOCUMENTO_YA_TIENE_DTE_PRINCIPAL'; end if;
  if v_type in (56,61) then
    select * into ref from public.sias_external_dte where id=v_reference and company_id=p_company and document_id=p_document and status='EMITIDO'
      and environment=p_payload->>'environment' and document_type in (33,34,39,41,52);
    if ref.id is null or v_code not in (1,2,3) then raise exception 'DTE_REFERENCIA_INVALIDA'; end if;
    if v_type=61 then
      select coalesce(sum(total),0) into v_credited from public.sias_external_dte where company_id=p_company and reference_id=ref.id
        and document_type=61 and status in ('INICIADO','INDETERMINADO','EMITIDO');
      if v_credited+v_total>ref.total then raise exception 'NOTA_SUPERA_SALDO_DTE'; end if;
    end if;
  end if;
  if existing.id is not null then
    update public.sias_external_dte set status='INICIADO',error_detail=null,updated_at=now() where id=existing.id returning * into existing;
  else
    insert into public.sias_external_dte(company_id,document_id,provider,environment,document_type,folio,status,issue_date,recipient_rut,recipient_name,total,
      reference_document_type,reference_folio,reference_date,reference_id,reference_code,request_hash,created_by)
    values(p_company,p_document,'FACTURACION_CL',p_payload->>'environment',v_type,null,'INICIADO',(p_payload->>'issue_date')::date,
      p_payload->>'recipient_rut',p_payload->>'recipient_name',v_total,ref.document_type,ref.folio,ref.issue_date,v_reference,v_code,p_payload->>'request_hash',p_user)
    returning * into existing;
  end if;
  return to_jsonb(existing)||jsonb_build_object('reused',false);
end $$;
revoke all on function public.sias_claim_dte(uuid,uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.sias_claim_dte(uuid,uuid,uuid,jsonb) to service_role;
notify pgrst,'reload schema';

-- La transacción sólo confirma si la estructura completa está presente.
do $$
declare missing text;
begin
  select string_agg(e.tbl||'.'||e.col, ', ') into missing
  from (values
    ('sias_products','product_kind'),('sias_products','public_visible'),('sias_products','recipe_yield'),('sias_products','creation_key'),
    ('sias_documents','destination_warehouse_id'),('sias_documents','source_document_id'),('sias_documents','request_key'),('sias_documents','metadata'),
    ('sias_document_items','acquisition_cost'),('sias_payments','request_key'),
    ('sias_external_dte','reference_id'),('sias_external_dte','reference_code'),
    ('sias_store_settings','slug'),('sias_store_settings','enabled'),('sias_cost_history','new_cost'),('sias_product_recipe','supply_id')
  ) e(tbl,col)
  where not exists(select 1 from information_schema.columns c where c.table_schema='public' and c.table_name=e.tbl and c.column_name=e.col);
  if missing is not null then raise exception 'ACTUALIZACION_INCOMPLETA: %',missing; end if;
  if to_regprocedure('public.sias_commit_document(uuid,uuid,jsonb,boolean)') is null
    or to_regprocedure('public.sias_save_product(uuid,uuid,jsonb)') is null
    or to_regprocedure('public.sias_save_recipe(uuid,uuid,uuid,numeric,jsonb)') is null
    or to_regprocedure('public.sias_register_payment(uuid,uuid,uuid,numeric,text,text,uuid)') is null
    or to_regprocedure('public.sias_claim_dte(uuid,uuid,uuid,jsonb)') is null
    or to_regprocedure('public.sias_store_create_request(uuid,uuid,jsonb,jsonb)') is null then
      raise exception 'ACTUALIZACION_INCOMPLETA: faltan funciones';
  end if;
end $$;
update public.sias_installation set version='2.3.3',updated_at=now() where id=1;
notify pgrst,'reload schema';


-- Catálogo de pantallas nuevas, sin reactivar ni renombrar módulos existentes.
insert into public.sias_modules(code,name,description,icon,route,sort_order) values
('RECEIPTS','Ingresos de mercadería','Recepción de stock y costos','purchases','#receipts',31),
('SUPPLIES','Insumos y costos','Insumos, recetas y costos','products','#supplies',32),
('WAREHOUSES','Bodegas','Administración de bodegas','companies','#warehouses',33),
('SUPPLIERS','Proveedores','Administración de proveedores','purchases','#suppliers',46),
('DOCUMENTS','Documentos','Documentos comerciales e inventario','billing','#documents',41),
('QUOTES','Cotizaciones','Cotizaciones comerciales','billing','#quotes',42),
('ORDERS','Pedidos','Pedidos comerciales','purchases','#orders',43),
('REQUESTS','Solicitudes web','Solicitudes desde la tienda','notifications','#requests',44),
('STORE','Sitio para clientes','Configuración del catálogo público','wholesale','#store',61)
on conflict(code) do nothing;

-- Verificación de TODAS las columnas de la base canónica.
do $$
declare missing text;
begin
  select string_agg(e.tbl||'.'||e.col, ', ') into missing
  from (values
    ('sias_audit','action'),
    ('sias_audit','company_id'),
    ('sias_audit','created_at'),
    ('sias_audit','detail'),
    ('sias_audit','entity'),
    ('sias_audit','entity_id'),
    ('sias_audit','id'),
    ('sias_audit','ip'),
    ('sias_audit','module'),
    ('sias_audit','user_agent'),
    ('sias_audit','user_id'),
    ('sias_billing_config','active_provider'),
    ('sias_billing_config','company_id'),
    ('sias_billing_config','environment'),
    ('sias_billing_config','facturacion_cl_api_url'),
    ('sias_billing_config','facturacion_cl_include_link'),
    ('sias_billing_config','general_tax_rate'),
    ('sias_billing_config','updated_at'),
    ('sias_billing_config','updated_by'),
    ('sias_companies','active'),
    ('sias_companies','address'),
    ('sias_companies','business_activity'),
    ('sias_companies','city'),
    ('sias_companies','commune'),
    ('sias_companies','created_at'),
    ('sias_companies','email'),
    ('sias_companies','id'),
    ('sias_companies','legal_name'),
    ('sias_companies','logo_url'),
    ('sias_companies','phone'),
    ('sias_companies','region'),
    ('sias_companies','rut'),
    ('sias_companies','trade_name'),
    ('sias_companies','updated_at'),
    ('sias_companies','website'),
    ('sias_customer_accounts','active'),
    ('sias_customer_accounts','company_id'),
    ('sias_customer_accounts','created_at'),
    ('sias_customer_accounts','customer_id'),
    ('sias_customer_accounts','email'),
    ('sias_customer_accounts','failed_attempts'),
    ('sias_customer_accounts','id'),
    ('sias_customer_accounts','last_login_at'),
    ('sias_customer_accounts','locked_until'),
    ('sias_customer_accounts','password_hash'),
    ('sias_customer_accounts','updated_at'),
    ('sias_customer_sessions','account_id'),
    ('sias_customer_sessions','company_id'),
    ('sias_customer_sessions','created_at'),
    ('sias_customer_sessions','customer_id'),
    ('sias_customer_sessions','expires_at'),
    ('sias_customer_sessions','id'),
    ('sias_customer_sessions','last_seen_at'),
    ('sias_customer_sessions','revoked'),
    ('sias_customer_sessions','token_hash'),
    ('sias_customers','active'),
    ('sias_customers','address'),
    ('sias_customers','business_activity'),
    ('sias_customers','city'),
    ('sias_customers','commune'),
    ('sias_customers','company_id'),
    ('sias_customers','contact_name'),
    ('sias_customers','created_at'),
    ('sias_customers','credit_limit'),
    ('sias_customers','email'),
    ('sias_customers','id'),
    ('sias_customers','legal_name'),
    ('sias_customers','notes'),
    ('sias_customers','phone'),
    ('sias_customers','region'),
    ('sias_customers','rut'),
    ('sias_customers','trade_name'),
    ('sias_customers','updated_at'),
    ('sias_customers','wholesale'),
    ('sias_document_items','description'),
    ('sias_document_items','discount'),
    ('sias_document_items','document_id'),
    ('sias_document_items','exempt'),
    ('sias_document_items','id'),
    ('sias_document_items','line_net'),
    ('sias_document_items','line_no'),
    ('sias_document_items','line_tax'),
    ('sias_document_items','line_total'),
    ('sias_document_items','product_id'),
    ('sias_document_items','quantity'),
    ('sias_document_items','sku'),
    ('sias_document_items','tax_rate'),
    ('sias_document_items','unit'),
    ('sias_document_items','unit_price'),
    ('sias_documents','company_id'),
    ('sias_documents','created_at'),
    ('sias_documents','created_by'),
    ('sias_documents','currency'),
    ('sias_documents','customer_id'),
    ('sias_documents','discount'),
    ('sias_documents','document_type'),
    ('sias_documents','due_date'),
    ('sias_documents','exempt'),
    ('sias_documents','id'),
    ('sias_documents','issue_date'),
    ('sias_documents','net'),
    ('sias_documents','notes'),
    ('sias_documents','number'),
    ('sias_documents','payment_method'),
    ('sias_documents','payment_status'),
    ('sias_documents','posted_at'),
    ('sias_documents','shipping'),
    ('sias_documents','source'),
    ('sias_documents','status'),
    ('sias_documents','supplier_id'),
    ('sias_documents','tax'),
    ('sias_documents','total'),
    ('sias_documents','updated_at'),
    ('sias_documents','updated_by'),
    ('sias_documents','voided_at'),
    ('sias_documents','warehouse_id'),
    ('sias_external_dte','company_id'),
    ('sias_external_dte','created_at'),
    ('sias_external_dte','created_by'),
    ('sias_external_dte','document_id'),
    ('sias_external_dte','document_type'),
    ('sias_external_dte','environment'),
    ('sias_external_dte','error_detail'),
    ('sias_external_dte','folio'),
    ('sias_external_dte','id'),
    ('sias_external_dte','issue_date'),
    ('sias_external_dte','pdf_base64'),
    ('sias_external_dte','provider'),
    ('sias_external_dte','provider_link'),
    ('sias_external_dte','provider_response'),
    ('sias_external_dte','recipient_name'),
    ('sias_external_dte','recipient_rut'),
    ('sias_external_dte','reference_date'),
    ('sias_external_dte','reference_document_type'),
    ('sias_external_dte','reference_folio'),
    ('sias_external_dte','request_hash'),
    ('sias_external_dte','status'),
    ('sias_external_dte','total'),
    ('sias_external_dte','updated_at'),
    ('sias_installation','created_at'),
    ('sias_installation','first_admin_id'),
    ('sias_installation','id'),
    ('sias_installation','installed'),
    ('sias_installation','installed_at'),
    ('sias_installation','jwt_enabled'),
    ('sias_installation','product_name'),
    ('sias_installation','updated_at'),
    ('sias_installation','version'),
    ('sias_modules','active'),
    ('sias_modules','code'),
    ('sias_modules','created_at'),
    ('sias_modules','description'),
    ('sias_modules','icon'),
    ('sias_modules','id'),
    ('sias_modules','name'),
    ('sias_modules','route'),
    ('sias_modules','sort_order'),
    ('sias_modules','system'),
    ('sias_modules','updated_at'),
    ('sias_notifications','created_at'),
    ('sias_notifications','id'),
    ('sias_notifications','message'),
    ('sias_notifications','module'),
    ('sias_notifications','read'),
    ('sias_notifications','read_at'),
    ('sias_notifications','reference_id'),
    ('sias_notifications','title'),
    ('sias_notifications','type'),
    ('sias_notifications','user_id'),
    ('sias_payments','amount'),
    ('sias_payments','company_id'),
    ('sias_payments','created_at'),
    ('sias_payments','created_by'),
    ('sias_payments','document_id'),
    ('sias_payments','id'),
    ('sias_payments','method'),
    ('sias_payments','paid_at'),
    ('sias_payments','reference'),
    ('sias_payments','status'),
    ('sias_permissions','code'),
    ('sias_permissions','created_at'),
    ('sias_permissions','description'),
    ('sias_permissions','id'),
    ('sias_permissions','module'),
    ('sias_permissions','name'),
    ('sias_products','active'),
    ('sias_products','barcode'),
    ('sias_products','category'),
    ('sias_products','company_id'),
    ('sias_products','cost'),
    ('sias_products','created_at'),
    ('sias_products','description'),
    ('sias_products','exempt'),
    ('sias_products','featured'),
    ('sias_products','id'),
    ('sias_products','image_url'),
    ('sias_products','max_stock'),
    ('sias_products','min_stock'),
    ('sias_products','name'),
    ('sias_products','price'),
    ('sias_products','sku'),
    ('sias_products','tax_rate'),
    ('sias_products','unit'),
    ('sias_products','updated_at'),
    ('sias_products','wholesale_price'),
    ('sias_role_permissions','permission_id'),
    ('sias_role_permissions','role_id'),
    ('sias_roles','active'),
    ('sias_roles','code'),
    ('sias_roles','company_id'),
    ('sias_roles','created_at'),
    ('sias_roles','description'),
    ('sias_roles','id'),
    ('sias_roles','name'),
    ('sias_roles','system'),
    ('sias_roles','updated_at'),
    ('sias_secrets','company_id'),
    ('sias_secrets','encrypted_value'),
    ('sias_secrets','hint'),
    ('sias_secrets','id'),
    ('sias_secrets','key'),
    ('sias_secrets','scope'),
    ('sias_secrets','updated_at'),
    ('sias_secrets','updated_by'),
    ('sias_sequences','code'),
    ('sias_sequences','company_id'),
    ('sias_sequences','current_value'),
    ('sias_sequences','id'),
    ('sias_sequences','padding'),
    ('sias_sequences','prefix'),
    ('sias_sequences','updated_at'),
    ('sias_sessions','company_id'),
    ('sias_sessions','created_at'),
    ('sias_sessions','expires_at'),
    ('sias_sessions','id'),
    ('sias_sessions','ip'),
    ('sias_sessions','last_seen_at'),
    ('sias_sessions','revoked'),
    ('sias_sessions','revoked_at'),
    ('sias_sessions','token_hash'),
    ('sias_sessions','user_agent'),
    ('sias_sessions','user_id'),
    ('sias_settings','company_id'),
    ('sias_settings','description'),
    ('sias_settings','id'),
    ('sias_settings','key'),
    ('sias_settings','module'),
    ('sias_settings','updated_at'),
    ('sias_settings','updated_by'),
    ('sias_settings','value'),
    ('sias_sii_cafs','caf_xml'),
    ('sias_sii_cafs','company_id'),
    ('sias_sii_cafs','created_at'),
    ('sias_sii_cafs','current_folio'),
    ('sias_sii_cafs','document_type'),
    ('sias_sii_cafs','environment'),
    ('sias_sii_cafs','folio_from'),
    ('sias_sii_cafs','folio_to'),
    ('sias_sii_cafs','id'),
    ('sias_sii_cafs','issuer_rut'),
    ('sias_sii_cafs','status'),
    ('sias_sii_cafs','uploaded_by'),
    ('sias_sii_certificates','active'),
    ('sias_sii_certificates','company_id'),
    ('sias_sii_certificates','created_at'),
    ('sias_sii_certificates','file_name'),
    ('sias_sii_certificates','id'),
    ('sias_sii_certificates','password_encrypted'),
    ('sias_sii_certificates','serial_number'),
    ('sias_sii_certificates','storage_path'),
    ('sias_sii_certificates','subject'),
    ('sias_sii_certificates','uploaded_by'),
    ('sias_sii_certificates','valid_from'),
    ('sias_sii_certificates','valid_until'),
    ('sias_sii_certification_steps','code'),
    ('sias_sii_certification_steps','company_id'),
    ('sias_sii_certification_steps','description'),
    ('sias_sii_certification_steps','id'),
    ('sias_sii_certification_steps','name'),
    ('sias_sii_certification_steps','note'),
    ('sias_sii_certification_steps','status'),
    ('sias_sii_certification_steps','updated_at'),
    ('sias_sii_certification_steps','updated_by'),
    ('sias_sii_config','activity_code'),
    ('sias_sii_config','company_id'),
    ('sias_sii_config','enabled'),
    ('sias_sii_config','environment'),
    ('sias_sii_config','issuer_rut'),
    ('sias_sii_config','office_code'),
    ('sias_sii_config','resolution_date'),
    ('sias_sii_config','resolution_number'),
    ('sias_sii_config','sender_email'),
    ('sias_sii_config','updated_at'),
    ('sias_sii_config','updated_by'),
    ('sias_sii_dte','company_id'),
    ('sias_sii_dte','created_at'),
    ('sias_sii_dte','created_by'),
    ('sias_sii_dte','document_type'),
    ('sias_sii_dte','environment'),
    ('sias_sii_dte','folio'),
    ('sias_sii_dte','id'),
    ('sias_sii_dte','issue_date'),
    ('sias_sii_dte','items'),
    ('sias_sii_dte','recipient'),
    ('sias_sii_dte','sii_response'),
    ('sias_sii_dte','sii_status'),
    ('sias_sii_dte','sii_track_id'),
    ('sias_sii_dte','status'),
    ('sias_sii_dte','totals'),
    ('sias_sii_dte','updated_at'),
    ('sias_sii_dte','xml_signed'),
    ('sias_sii_dte','xml_unsigned'),
    ('sias_sii_dte_events','created_at'),
    ('sias_sii_dte_events','detail'),
    ('sias_sii_dte_events','dte_id'),
    ('sias_sii_dte_events','event'),
    ('sias_sii_dte_events','id'),
    ('sias_sii_dte_events','user_id'),
    ('sias_sii_received_dte','company_id'),
    ('sias_sii_received_dte','document_type'),
    ('sias_sii_received_dte','folio'),
    ('sias_sii_received_dte','id'),
    ('sias_sii_received_dte','issue_date'),
    ('sias_sii_received_dte','issuer_name'),
    ('sias_sii_received_dte','issuer_rut'),
    ('sias_sii_received_dte','received_at'),
    ('sias_sii_received_dte','status'),
    ('sias_sii_received_dte','total'),
    ('sias_sii_received_dte','xml'),
    ('sias_stock','company_id'),
    ('sias_stock','product_id'),
    ('sias_stock','quantity'),
    ('sias_stock','updated_at'),
    ('sias_stock','warehouse_id'),
    ('sias_stock_movements','balance_after'),
    ('sias_stock_movements','company_id'),
    ('sias_stock_movements','created_at'),
    ('sias_stock_movements','created_by'),
    ('sias_stock_movements','id'),
    ('sias_stock_movements','movement_type'),
    ('sias_stock_movements','note'),
    ('sias_stock_movements','product_id'),
    ('sias_stock_movements','quantity'),
    ('sias_stock_movements','reference_id'),
    ('sias_stock_movements','reference_type'),
    ('sias_stock_movements','warehouse_id'),
    ('sias_suppliers','active'),
    ('sias_suppliers','address'),
    ('sias_suppliers','business_activity'),
    ('sias_suppliers','city'),
    ('sias_suppliers','commune'),
    ('sias_suppliers','company_id'),
    ('sias_suppliers','contact_name'),
    ('sias_suppliers','created_at'),
    ('sias_suppliers','email'),
    ('sias_suppliers','id'),
    ('sias_suppliers','legal_name'),
    ('sias_suppliers','notes'),
    ('sias_suppliers','phone'),
    ('sias_suppliers','rut'),
    ('sias_suppliers','trade_name'),
    ('sias_suppliers','updated_at'),
    ('sias_user_companies','company_id'),
    ('sias_user_companies','is_primary'),
    ('sias_user_companies','user_id'),
    ('sias_user_roles','company_id'),
    ('sias_user_roles','role_id'),
    ('sias_user_roles','user_id'),
    ('sias_users','active'),
    ('sias_users','created_at'),
    ('sias_users','email'),
    ('sias_users','failed_attempts'),
    ('sias_users','full_name'),
    ('sias_users','profile_photo_url'),
    ('sias_users','id'),
    ('sias_users','last_login_at'),
    ('sias_users','locked_until'),
    ('sias_users','must_change_password'),
    ('sias_users','password_hash'),
    ('sias_users','superadmin'),
    ('sias_users','updated_at'),
    ('sias_warehouses','active'),
    ('sias_warehouses','address'),
    ('sias_warehouses','city'),
    ('sias_warehouses','code'),
    ('sias_warehouses','commune'),
    ('sias_warehouses','company_id'),
    ('sias_warehouses','created_at'),
    ('sias_warehouses','id'),
    ('sias_warehouses','name'),
    ('sias_warehouses','updated_at')
  ) e(tbl,col)
  where not exists(select 1 from information_schema.columns c where c.table_schema='public' and c.table_name=e.tbl and c.column_name=e.col);
  if missing is not null then raise exception 'ESTRUCTURA_INCOMPLETA: %',missing; end if;
end $$;
update public.sias_installation
set installed=installed or exists(select 1 from public.sias_users),
    version='2.4.1',jwt_enabled=false,updated_at=now()
where id=1;
notify pgrst,'reload schema';
commit;
select 'SQL_MAESTRO_OK' as resultado,
  (select version from public.sias_installation where id=1) as version,
  (select count(*) from information_schema.tables where table_schema='public' and table_name like 'sias_%' and table_type='BASE TABLE') as tablas_sias,
  exists(select 1 from information_schema.columns where table_schema='public' and table_name='sias_products' and column_name='product_kind') as product_kind_ok,
  to_regclass('public.sias_store_settings') is not null as tienda_ok,
  to_regprocedure('public.sias_commit_document(uuid,uuid,jsonb,boolean)') is not null as documentos_ok;


begin;


-- ============================================================================
-- SIASCLOUD v2.4.1 · REPARACIÓN DE ACCESOS Y SEPARACIÓN ERP / PORTAL MAYORISTA
-- No modifica las claves existentes. Sólo normaliza datos, desbloquea intentos
-- acumulados y garantiza que ambos accesos sean independientes.
-- ============================================================================

alter table public.sias_users add column if not exists profile_photo_url text;
alter table public.sias_customer_accounts add column if not exists credential_scope text not null default 'WHOLESALE_PORTAL';

update public.sias_users
set email=lower(trim(email)), failed_attempts=0, locked_until=null, updated_at=now()
where email is not null;

update public.sias_customer_accounts
set email=lower(trim(email)), credential_scope='WHOLESALE_PORTAL', failed_attempts=0, locked_until=null, updated_at=now()
where email is not null;

-- El Portal Mayorista jamás debe depender de sias_users.
do $$
declare r record;
begin
  if to_regclass('public.sias_customer_accounts') is not null
     and to_regclass('public.sias_users') is not null then
    for r in
      select c.conname
      from pg_constraint c
      where c.conrelid='public.sias_customer_accounts'::regclass
        and c.contype='f'
        and c.confrelid='public.sias_users'::regclass
    loop
      execute format('alter table public.sias_customer_accounts drop constraint %I',r.conname);
    end loop;
  end if;
end $$;

create unique index if not exists sias_users_email_unique on public.sias_users(lower(email));
create unique index if not exists sias_customer_accounts_email_unique on public.sias_customer_accounts(company_id,lower(email));
create index if not exists sias_customer_accounts_customer_idx on public.sias_customer_accounts(company_id,customer_id);

update public.sias_installation set version='2.4.1',jwt_enabled=false,updated_at=now() where id=1;
notify pgrst,'reload schema';


-- ============================================================================
-- SIASCLOUD v2.4.1 · REPARACIÓN DE ACCESOS MAYORISTAS
-- Crea un registro de portal pendiente para clientes mayoristas activos que
-- tengan correo y aún no posean cuenta. NO crea una contraseña compartida.
-- La clave se define desde Mayoristas → Acceso Portal Mayorista.
-- ============================================================================

update public.sias_customers
set email = lower(trim(email)), updated_at = now()
where email is not null and trim(email) <> '';

update public.sias_customer_accounts
set email = lower(trim(email)),
    credential_scope = 'WHOLESALE_PORTAL',
    failed_attempts = 0,
    locked_until = null,
    updated_at = now()
where email is not null;



update public.sias_customer_accounts
set password_hash = 'RESET_REQUIRED',
    failed_attempts = 0,
    locked_until = null,
    updated_at = now()
where password_hash is null or trim(password_hash) = '';

update public.sias_installation
set version='2.4.1', jwt_enabled=false, updated_at=now()
where id=1;

notify pgrst,'reload schema';

commit;

-- SiasCloud v2.4.2 · Reparación de Portal Mayorista
-- Repara vínculos históricos entre sias_customer_accounts, sias_customers y sias_companies.
-- NO modifica claves válidas. NO mezcla usuarios ERP con cuentas del portal.

begin;

-- 1) Normalizar correos (un correo no debe contener espacios visibles o invisibles).
update public.sias_customers
set email = lower(regexp_replace(btrim(email), '[[:space:]]+', '', 'g')),
    updated_at = now()
where email is not null and btrim(email) <> '';

update public.sias_customer_accounts
set email = lower(regexp_replace(btrim(email), '[[:space:]]+', '', 'g')),
    credential_scope = 'WHOLESALE_PORTAL',
    failed_attempts = 0,
    locked_until = null,
    updated_at = now()
where email is not null and btrim(email) <> '';

-- 2) Si customer_id es correcto pero company_id quedó vacío/desactualizado, recuperar la empresa del cliente.
update public.sias_customer_accounts a
set company_id = c.company_id,
    updated_at = now()
from public.sias_customers c
where a.customer_id = c.id
  and c.company_id is not null
  and a.company_id is distinct from c.company_id
  and not exists (
    select 1 from public.sias_customer_accounts x
    where x.id <> a.id
      and x.company_id = c.company_id
      and lower(regexp_replace(btrim(x.email), '[[:space:]]+', '', 'g')) = lower(regexp_replace(btrim(a.email), '[[:space:]]+', '', 'g'))
  );

-- 3) Reparar customer_id de cuentas antiguas por empresa + correo, sólo cuando existe UNA coincidencia mayorista.
with candidates as (
  select a.id as account_id, min(c.id::text)::uuid as customer_id
  from public.sias_customer_accounts a
  join public.sias_customers c
    on c.company_id = a.company_id
   and c.wholesale = true
   and lower(regexp_replace(btrim(c.email), '[[:space:]]+', '', 'g')) = lower(regexp_replace(btrim(a.email), '[[:space:]]+', '', 'g'))
  where a.customer_id is null
     or not exists (select 1 from public.sias_customers z where z.id=a.customer_id and z.company_id=a.company_id)
  group by a.id
  having count(*) = 1
)
update public.sias_customer_accounts a
set customer_id = c.customer_id,
    updated_at = now()
from candidates c
where a.id = c.account_id;

-- 4) Crear registro de portal pendiente para todo cliente mayorista activo con correo que todavía no tenga cuenta.
-- La clave se crea/cambia desde Mayoristas → Acceso Portal Mayorista.
insert into public.sias_customer_accounts
  (company_id, customer_id, email, password_hash, active, failed_attempts, locked_until, credential_scope, created_at, updated_at)
select
  c.company_id,
  c.id,
  lower(regexp_replace(btrim(c.email), '[[:space:]]+', '', 'g')),
  'RESET_REQUIRED',
  true,
  0,
  null,
  'WHOLESALE_PORTAL',
  now(),
  now()
from public.sias_customers c
where c.wholesale = true
  and c.active = true
  and c.company_id is not null
  and c.email is not null
  and btrim(c.email) <> ''
  and not exists (
    select 1 from public.sias_customer_accounts a
    where a.company_id = c.company_id and a.customer_id = c.id
  )
  and not exists (
    select 1 from public.sias_customer_accounts a
    where a.company_id = c.company_id
      and lower(regexp_replace(btrim(a.email), '[[:space:]]+', '', 'g')) = lower(regexp_replace(btrim(c.email), '[[:space:]]+', '', 'g'))
  )
on conflict do nothing;

-- 5) Mantener el cliente como mayorista si ya tiene una cuenta de portal enlazada.
update public.sias_customers c
set wholesale = true,
    active = true,
    updated_at = now()
from public.sias_customer_accounts a
where a.customer_id = c.id
  and a.company_id = c.company_id
  and a.active = true
  and (c.wholesale is distinct from true or c.active is distinct from true);

update public.sias_installation set version='2.4.2', updated_at=now() where id=1;
notify pgrst,'reload schema';

commit;

-- Actualización aditiva sobre SiasCloud 2.4.1 (accesos, estilos y splash reparados). Ejecutar una sola vez en SQL Editor.
begin;
alter table public.sias_external_dte add column if not exists amounts jsonb;

alter table public.sias_products add column if not exists creation_payload_hash text;
alter table public.sias_products add column if not exists parent_product_id uuid references public.sias_products(id);
alter table public.sias_products add column if not exists attributes jsonb not null default '{}'::jsonb;
alter table public.sias_products add column if not exists brand text;
alter table public.sias_products add column if not exists supplier_id uuid references public.sias_suppliers(id);
alter table public.sias_products add column if not exists pack_quantity numeric(18,4);
alter table public.sias_products add column if not exists pallet_boxes integer;
alter table public.sias_products add column if not exists weight_kg numeric(18,4);
alter table public.sias_products add column if not exists length_cm numeric(18,4);
alter table public.sias_products add column if not exists width_cm numeric(18,4);
alter table public.sias_products add column if not exists height_cm numeric(18,4);
alter table public.sias_products add column if not exists fractional boolean not null default false;
create index if not exists sias_products_parent_idx on public.sias_products(company_id,parent_product_id);
create index if not exists sias_products_barcode_idx on public.sias_products(company_id,barcode);

create table if not exists public.sias_product_changes(
  id bigint generated always as identity primary key, company_id uuid not null references public.sias_companies(id),
  product_id uuid not null references public.sias_products(id), before_value jsonb, after_value jsonb not null,
  created_by uuid references public.sias_users(id),created_at timestamptz not null default now()
);
create table if not exists public.sias_staff(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references public.sias_companies(id),
  name text not null,roles text[] not null default array['SELLER'],active boolean not null default true,
  created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
  check(roles <@ array['SELLER','PREPARER','PACKER']::text[] and cardinality(roles)>0)
);
create table if not exists public.sias_price_lists(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references public.sias_companies(id),
  name text not null,active boolean not null default true,created_at timestamptz not null default now()
);
create table if not exists public.sias_price_list_items(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references public.sias_companies(id),
  price_list_id uuid not null references public.sias_price_lists(id),product_id uuid not null references public.sias_products(id),
  price numeric(18,4) not null check(price>=0),unique(price_list_id,product_id)
);
create table if not exists public.sias_cash_sessions(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references public.sias_companies(id),
  user_id uuid not null references public.sias_users(id),register_code text not null,
  status text not null default 'OPEN' check(status in ('OPEN','CLOSED')),
  opening_cash numeric(18,2) not null check(opening_cash>=0),counted_cash numeric(18,2),expected_cash numeric(18,2),difference numeric(18,2),
  open_key uuid not null,close_key uuid,notes text,opened_at timestamptz not null default now(),closed_at timestamptz,
  unique(company_id,open_key)
);
create unique index if not exists sias_cash_register_open_idx on public.sias_cash_sessions(company_id,register_code) where status='OPEN';
create unique index if not exists sias_cash_operator_open_idx on public.sias_cash_sessions(company_id,user_id) where status='OPEN';
create table if not exists public.sias_cash_movements(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references public.sias_companies(id),
  session_id uuid not null references public.sias_cash_sessions(id),kind text not null check(kind in ('IN','OUT')),
  amount numeric(18,2) not null check(amount>0),reason text not null,request_key uuid not null,
  created_by uuid references public.sias_users(id),created_at timestamptz not null default now(),unique(company_id,request_key)
);
alter table public.sias_documents add column if not exists cash_session_id uuid references public.sias_cash_sessions(id);
alter table public.sias_payments add column if not exists cash_session_id uuid references public.sias_cash_sessions(id);
create index if not exists sias_payments_cash_idx on public.sias_payments(company_id,cash_session_id,status);
create table if not exists public.sias_customer_credits(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references public.sias_companies(id),
  customer_id uuid not null references public.sias_customers(id),dte_id uuid not null unique references public.sias_external_dte(id),
  original_amount numeric(18,2) not null check(original_amount>0),balance numeric(18,2) not null check(balance>=0),
  environment text not null check(environment in ('PRUEBA','PRODUCCION')),
  created_by uuid references public.sias_users(id),created_at timestamptz not null default now(),check(balance<=original_amount)
);
create table if not exists public.sias_credit_applications(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references public.sias_companies(id),
  credit_id uuid not null references public.sias_customer_credits(id),document_id uuid not null references public.sias_documents(id),
  payment_id uuid not null unique references public.sias_payments(id),amount numeric(18,2) not null check(amount>0),
  request_key uuid not null,created_by uuid references public.sias_users(id),created_at timestamptz not null default now(),unique(company_id,request_key)
);
create index if not exists sias_credit_customer_idx on public.sias_customer_credits(company_id,customer_id,created_at);
create table if not exists public.sias_journals(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references public.sias_companies(id),
  source_type text not null,source_id uuid not null,entry_date date not null,description text not null,
  customer_id uuid references public.sias_customers(id),supplier_id uuid references public.sias_suppliers(id),
  created_at timestamptz not null default now(),unique(company_id,source_type,source_id)
);
create table if not exists public.sias_journal_lines(
  id bigint generated always as identity primary key,journal_id uuid not null references public.sias_journals(id),
  account text not null,debit numeric(18,2) not null default 0 check(debit>=0),credit numeric(18,2) not null default 0 check(credit>=0),
  check((debit=0) <> (credit=0))
);
create index if not exists sias_journal_date_idx on public.sias_journals(company_id,entry_date);
create index if not exists sias_journal_account_idx on public.sias_journal_lines(account,journal_id);

create or replace function public.sias_v3_guard(p_company uuid,p_user uuid,p_permission text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not exists(select 1 from sias_users u where u.id=p_user and u.active and not u.must_change_password and
    (u.superadmin or (exists(select 1 from sias_user_companies uc where uc.user_id=u.id and uc.company_id=p_company) and exists(
      select 1 from sias_user_roles ur join sias_role_permissions rp on rp.role_id=ur.role_id
      join sias_permissions pp on pp.id=rp.permission_id join sias_roles rr on rr.id=ur.role_id and rr.active where ur.user_id=u.id and ur.company_id=p_company and pp.code=p_permission))))
    then raise exception 'SIN_PERMISO'; end if;
  if not exists(select 1 from sias_companies where id=p_company and active) then raise exception 'SIN_EMPRESA'; end if;
end $$;

create or replace function public.sias_v3_save_product(p_company uuid,p_user uuid,p_payload jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_hash text; v_old jsonb; v_parent uuid:=nullif(p_payload->>'parent_product_id','')::uuid; v_supplier uuid:=nullif(p_payload->>'supplier_id','')::uuid;
begin
  perform sias_v3_guard(p_company,p_user,'PRODUCT_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if nullif(p_payload->>'id','') is null and nullif(p_payload->>'request_key','') is not null then
    select id,creation_payload_hash into v_id,v_hash from sias_products where company_id=p_company and creation_key=(p_payload->>'request_key')::uuid;
    if found then if v_hash is distinct from md5(p_payload::text) then raise exception 'SOLICITUD_REUTILIZADA_CON_OTROS_DATOS'; end if; return v_id; end if;
  end if;
  if nullif(p_payload->>'id','') is not null then select to_jsonb(p) into v_old from sias_products p where id=(p_payload->>'id')::uuid and company_id=p_company for update; end if;
  if v_parent is not null then
    if v_parent=nullif(p_payload->>'id','')::uuid or not exists(select 1 from sias_products where id=v_parent and company_id=p_company and parent_product_id is null and active) then raise exception 'PRODUCTO_PADRE_INVALIDO'; end if;
    if exists(select 1 from sias_products where company_id=p_company and parent_product_id=nullif(p_payload->>'id','')::uuid) then raise exception 'VARIANTE_NO_PUEDE_TENER_VARIANTES'; end if;
  end if;
  if v_supplier is not null and not exists(select 1 from sias_suppliers where id=v_supplier and company_id=p_company and active) then raise exception 'PROVEEDOR_INVALIDO'; end if;
  if jsonb_typeof(coalesce(p_payload->'attributes','{}'))<>'object' then raise exception 'ATRIBUTOS_INVALIDOS'; end if;
  if nullif(p_payload->>'barcode','') is not null and exists(select 1 from sias_products where company_id=p_company and barcode=p_payload->>'barcode' and id is distinct from nullif(p_payload->>'id','')::uuid) then raise exception 'CODIGO_BARRAS_YA_EXISTE'; end if;
  if v_old is not null and v_old->>'unit' is distinct from p_payload->>'unit' and exists(select 1 from sias_stock_movements where product_id=(v_old->>'id')::uuid and company_id=p_company) then raise exception 'UNIDAD_CON_MOVIMIENTOS_NO_MODIFICABLE'; end if;
  if coalesce((p_payload->>'initial_stock')::numeric,0)>0 then perform sias_v3_guard(p_company,p_user,'INVENTORY_MANAGE'); end if;
  if coalesce((p_payload->>'pack_quantity')::numeric,1)<=0 or coalesce((p_payload->>'pallet_boxes')::integer,1)<=0 then raise exception 'EMPAQUE_INVALIDO'; end if;
  if least(coalesce((p_payload->>'weight_kg')::numeric,0),coalesce((p_payload->>'length_cm')::numeric,0),coalesce((p_payload->>'width_cm')::numeric,0),coalesce((p_payload->>'height_cm')::numeric,0))<0 then raise exception 'DIMENSION_INVALIDA'; end if;
  v_id:=sias_save_product(p_company,p_user,p_payload);
  update sias_products set creation_payload_hash=case when nullif(p_payload->>'id','') is null then md5(p_payload::text) else creation_payload_hash end,parent_product_id=case when p_payload?'parent_product_id' then v_parent else parent_product_id end,
    supplier_id=case when p_payload?'supplier_id' then v_supplier else supplier_id end,attributes=coalesce(p_payload->'attributes',attributes),
    brand=case when p_payload?'brand' then nullif(p_payload->>'brand','') else brand end,
    pack_quantity=case when p_payload?'pack_quantity' then nullif(p_payload->>'pack_quantity','')::numeric else pack_quantity end,
    pallet_boxes=case when p_payload?'pallet_boxes' then nullif(p_payload->>'pallet_boxes','')::integer else pallet_boxes end,
    weight_kg=case when p_payload?'weight_kg' then nullif(p_payload->>'weight_kg','')::numeric else weight_kg end,
    length_cm=case when p_payload?'length_cm' then nullif(p_payload->>'length_cm','')::numeric else length_cm end,
    width_cm=case when p_payload?'width_cm' then nullif(p_payload->>'width_cm','')::numeric else width_cm end,
    height_cm=case when p_payload?'height_cm' then nullif(p_payload->>'height_cm','')::numeric else height_cm end,
    fractional=coalesce((p_payload->>'fractional')::boolean,fractional) where id=v_id and company_id=p_company;
  insert into sias_product_changes(company_id,product_id,before_value,after_value,created_by)
    select p_company,v_id,v_old,to_jsonb(p),p_user from sias_products p where id=v_id;
  return v_id;
end $$;

create or replace function public.sias_v3_cash_open(p_company uuid,p_user uuid,p_code text,p_opening numeric,p_key uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_session sias_cash_sessions%rowtype;
begin
  perform sias_v3_guard(p_company,p_user,'POS_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if p_key is null or p_opening is null or p_opening<0 or p_opening::text in ('NaN','Infinity','-Infinity') or length(btrim(p_code)) not between 1 and 40 then raise exception 'APERTURA_CAJA_INVALIDA'; end if;
  select * into v_session from sias_cash_sessions where company_id=p_company and open_key=p_key;
  if found then
    if v_session.user_id<>p_user or v_session.register_code<>p_code or v_session.opening_cash<>p_opening then raise exception 'SOLICITUD_REUTILIZADA_CON_OTROS_DATOS'; end if;
    return to_jsonb(v_session);
  end if;
  insert into sias_cash_sessions(company_id,user_id,register_code,opening_cash,open_key) values(p_company,p_user,btrim(p_code),p_opening,p_key) returning * into v_session;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'POS','CASH_OPEN','sias_cash_sessions',v_session.id,jsonb_build_object('opening_cash',p_opening));
  return to_jsonb(v_session);
end $$;

create or replace function public.sias_v3_cash_summary(p_company uuid,p_user uuid,p_session uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare s sias_cash_sessions%rowtype; v_methods jsonb; v_cash numeric; v_in numeric; v_out numeric;
begin
  perform sias_v3_guard(p_company,p_user,'POS_VIEW');
  select * into s from sias_cash_sessions where company_id=p_company and id=p_session;
  if s.id is null then raise exception 'CAJA_NO_ENCONTRADA'; end if;
  select coalesce(jsonb_agg(to_jsonb(t)),'[]') into v_methods from (select method,sum(amount) amount,count(*) payments from sias_payments where company_id=p_company and cash_session_id=s.id and status='CONFIRMED' group by method order by method)t;
  select coalesce(sum(amount),0) into v_cash from sias_payments where company_id=p_company and cash_session_id=s.id and status='CONFIRMED' and method='CASH';
  select coalesce(sum(amount)filter(where kind='IN'),0),coalesce(sum(amount)filter(where kind='OUT'),0) into v_in,v_out from sias_cash_movements where session_id=s.id and company_id=p_company;
  return jsonb_build_object('session',to_jsonb(s),'methods',v_methods,'cash_in',v_in,'cash_out',v_out,'expected_cash',s.opening_cash+v_cash+v_in-v_out);
end $$;

create or replace function public.sias_v3_cash_move(p_company uuid,p_user uuid,p_session uuid,p_kind text,p_amount numeric,p_reason text,p_key uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare s sias_cash_sessions%rowtype; v_old sias_cash_movements%rowtype; v_id uuid;
begin
  perform sias_v3_guard(p_company,p_user,'POS_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into v_old from sias_cash_movements where company_id=p_company and request_key=p_key;
  if found then
    if v_old.session_id<>p_session or v_old.kind<>p_kind or v_old.amount<>p_amount or v_old.reason<>btrim(p_reason) or v_old.created_by<>p_user then raise exception 'SOLICITUD_REUTILIZADA_CON_OTROS_DATOS'; end if;
    return v_old.id;
  end if;
  select * into s from sias_cash_sessions where company_id=p_company and id=p_session for update;
  if s.id is null or s.status<>'OPEN' or s.user_id<>p_user then raise exception 'CAJA_ABIERTA_DEL_OPERADOR_REQUERIDA'; end if;
  if p_key is null or p_kind not in ('IN','OUT') or p_amount is null or p_amount<=0 or p_amount::text in ('NaN','Infinity','-Infinity') or length(btrim(p_reason))<5 then raise exception 'MOVIMIENTO_CAJA_INVALIDO'; end if;
  if p_kind='OUT' and p_amount>(sias_v3_cash_summary(p_company,p_user,s.id)->>'expected_cash')::numeric then raise exception 'EFECTIVO_INSUFICIENTE'; end if;
  insert into sias_cash_movements(company_id,session_id,kind,amount,reason,request_key,created_by) values(p_company,s.id,p_kind,p_amount,btrim(p_reason),p_key,p_user) returning id into v_id;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'POS','CASH_MOVE','sias_cash_movements',v_id,jsonb_build_object('kind',p_kind,'amount',p_amount,'reason',p_reason));
  return v_id;
end $$;

create or replace function public.sias_v3_cash_close(p_company uuid,p_user uuid,p_session uuid,p_counted numeric,p_notes text,p_key uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare s sias_cash_sessions%rowtype; v_expected numeric;
begin
  perform sias_v3_guard(p_company,p_user,'POS_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into s from sias_cash_sessions where company_id=p_company and id=p_session for update;
  if s.id is null or s.user_id<>p_user then raise exception 'CAJA_DEL_OPERADOR_REQUERIDA'; end if;
  if s.status='CLOSED' then
    if s.close_key=p_key and s.counted_cash=p_counted then return to_jsonb(s); end if;
    raise exception 'CAJA_YA_CERRADA';
  end if;
  if p_key is null or p_counted is null or p_counted<0 or p_counted::text in ('NaN','Infinity','-Infinity') then raise exception 'CIERRE_CAJA_INVALIDO'; end if;
  v_expected:=(sias_v3_cash_summary(p_company,p_user,s.id)->>'expected_cash')::numeric;
  if p_counted<>v_expected and length(btrim(coalesce(p_notes,'')))<5 then raise exception 'MOTIVO_DIFERENCIA_REQUERIDO'; end if;
  update sias_cash_sessions set status='CLOSED',counted_cash=p_counted,expected_cash=v_expected,difference=p_counted-v_expected,notes=nullif(btrim(p_notes),''),close_key=p_key,closed_at=now() where id=s.id returning * into s;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'POS','CASH_CLOSE','sias_cash_sessions',s.id,to_jsonb(s));
  return to_jsonb(s);
end $$;

create or replace function public.sias_v3_credit_apply(p_company uuid,p_user uuid,p_credit uuid,p_document uuid,p_amount numeric,p_key uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare c sias_customer_credits%rowtype; d sias_documents%rowtype; a sias_credit_applications%rowtype; v_paid numeric; v_payment uuid;
begin
  perform sias_v3_guard(p_company,p_user,'CREDIT_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into a from sias_credit_applications where company_id=p_company and request_key=p_key;
  if found then
    if a.credit_id<>p_credit or a.document_id<>p_document or a.amount<>p_amount then raise exception 'SOLICITUD_REUTILIZADA_CON_OTROS_DATOS'; end if;
    return jsonb_build_object('application',to_jsonb(a),'reused',true);
  end if;
  select * into d from sias_documents where id=p_document and company_id=p_company for update;
  select * into c from sias_customer_credits where id=p_credit and company_id=p_company for update;
  if d.id is null or d.status<>'POSTED' or d.document_type not in ('SALE','WHOLESALE') then raise exception 'VENTA_CONFIRMADA_REQUERIDA'; end if;
  if c.id is null or c.customer_id is distinct from d.customer_id then raise exception 'CREDITO_PERTENECE_A_OTRO_CLIENTE'; end if;
  if c.environment is distinct from (case when coalesce(d.metadata->>'billing_environment',(select environment from sias_billing_config where company_id=p_company),'CERTIFICACION')='PRODUCCION' then 'PRODUCCION' else 'PRUEBA' end) then raise exception 'CREDITO_DE_OTRO_AMBIENTE'; end if;
  if p_key is null or p_amount is null or p_amount<=0 or p_amount::text in ('NaN','Infinity','-Infinity') or p_amount>c.balance then raise exception 'CREDITO_SALDO_INSUFICIENTE'; end if;
  select coalesce(sum(amount),0) into v_paid from sias_payments where company_id=p_company and document_id=d.id and status='CONFIRMED';
  if p_amount>d.total-v_paid then raise exception 'PAGO_SUPERA_SALDO'; end if;
  if d.cash_session_id is not null and not exists(select 1 from sias_cash_sessions where id=d.cash_session_id and company_id=p_company and status='OPEN' and user_id=p_user) then raise exception 'CAJA_CERRADA_NO_MODIFICABLE'; end if;
  insert into sias_payments(company_id,document_id,amount,method,reference,created_by,request_key,cash_session_id) values(p_company,d.id,p_amount,'CLIENT_CREDIT',c.dte_id::text,p_user,p_key,d.cash_session_id) returning id into v_payment;
  insert into sias_credit_applications(company_id,credit_id,document_id,payment_id,amount,request_key,created_by) values(p_company,c.id,d.id,v_payment,p_amount,p_key,p_user) returning * into a;
  update sias_customer_credits set balance=balance-p_amount where id=c.id;
  update sias_documents set payment_status=case when v_paid+p_amount>=total then 'PAID' else 'PARTIAL' end,updated_at=now() where id=d.id;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'CREDITS','APPLY','sias_credit_applications',a.id,to_jsonb(a));
  return jsonb_build_object('application',to_jsonb(a),'balance',c.balance-p_amount);
end $$;

create or replace function public.sias_v3_journal(p_company uuid,p_source text,p_id uuid,p_date date,p_description text,p_customer uuid,p_supplier uuid,p_lines jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_debit numeric; v_credit numeric; l jsonb;
begin
  select id into v_id from sias_journals where company_id=p_company and source_type=p_source and source_id=p_id;
  if found then return v_id; end if;
  select sum(coalesce((value->>'debit')::numeric,0)),sum(coalesce((value->>'credit')::numeric,0)) into v_debit,v_credit from jsonb_array_elements(p_lines);
  if v_debit is null or v_debit<>v_credit or v_debit<0 then raise exception 'ASIENTO_DESCUADRADO'; end if;
  insert into sias_journals(company_id,source_type,source_id,entry_date,description,customer_id,supplier_id) values(p_company,p_source,p_id,p_date,p_description,p_customer,p_supplier) returning id into v_id;
  for l in select value from jsonb_array_elements(p_lines) loop
    if coalesce((l->>'debit')::numeric,0)+coalesce((l->>'credit')::numeric,0)>0 then
      insert into sias_journal_lines(journal_id,account,debit,credit) values(v_id,l->>'account',coalesce((l->>'debit')::numeric,0),coalesce((l->>'credit')::numeric,0));
    end if;
  end loop;
  return v_id;
end $$;

create or replace function public.sias_v3_credit_sync(p_company uuid,p_user uuid,p_dte uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare e sias_external_dte%rowtype; d sias_documents%rowtype; v_id uuid; v_net numeric; v_tax numeric; v_pending numeric;
begin
  perform sias_v3_guard(p_company,p_user,'CREDIT_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select id into v_id from sias_customer_credits where company_id=p_company and dte_id=p_dte;
  if found then return v_id; end if;
  select * into e from sias_external_dte where company_id=p_company and id=p_dte for update;
  if e.id is null or e.status<>'EMITIDO' or e.document_type<>61 or e.total<=0 then raise exception 'NOTA_CREDITO_EMITIDA_REQUERIDA'; end if;
  select * into d from sias_documents where company_id=p_company and id=e.document_id for update;
  if d.customer_id is null then raise exception 'CLIENTE_REQUERIDO'; end if;
  insert into sias_customer_credits(company_id,customer_id,dte_id,original_amount,balance,environment,created_by) values(p_company,d.customer_id,e.id,e.total,e.total,e.environment,p_user) returning id into v_id;
  v_tax:=coalesce((e.amounts->>'tax')::numeric,case when d.tax=0 then 0 when e.reference_code=3 then e.total-round(e.total/1.19) else round(d.tax*e.total/nullif(d.total,0)) end,0);v_net:=e.total-v_tax;
  perform sias_v3_journal(p_company,'CREDIT_NOTE',e.id,e.issue_date,'Nota de crédito '||e.folio,d.customer_id,null,
    jsonb_build_array(jsonb_build_object('account','4100','debit',v_net),jsonb_build_object('account','2110','debit',v_tax),jsonb_build_object('account','2120','credit',e.total)));
  select greatest(0,d.total-coalesce(sum(amount),0)) into v_pending from sias_payments where company_id=p_company and document_id=d.id and status='CONFIRMED';
  if v_pending>0 then perform sias_v3_credit_apply(p_company,p_user,v_id,d.id,least(v_pending,e.total),gen_random_uuid()); end if;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'CREDITS','CREATE_FROM_DTE','sias_customer_credits',v_id,jsonb_build_object('dte_id',e.id,'amount',e.total));
  return v_id;
end $$;

create or replace function public.sias_v3_checkout(p_company uuid,p_user uuid,p_payload jsonb,p_payments jsonb,p_credits jsonb,p_session uuid,p_fingerprint text)
returns uuid language plpgsql security definer set search_path=public as $$
declare s sias_cash_sessions%rowtype; d sias_documents%rowtype; v_id uuid; v_key uuid:=(p_payload->>'request_key')::uuid; v_sum numeric:=0; x jsonb; v_amount numeric; v_payment jsonb; v_meta jsonb;
begin
  perform sias_v3_guard(p_company,p_user,'POS_MANAGE');
  perform sias_v3_guard(p_company,p_user,'SALES_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if exists(select 1 from sias_pos_canceled where company_id=p_company and request_key=v_key) then raise exception 'SOLICITUD_POS_CANCELADA'; end if;
  select * into d from sias_documents where company_id=p_company and request_key=v_key;
  if found then
    if d.created_by<>p_user or d.metadata->>'pos_fingerprint' is distinct from p_fingerprint or d.cash_session_id is distinct from p_session then raise exception 'SOLICITUD_REUTILIZADA_CON_OTROS_DATOS'; end if;
    return d.id;
  end if;
  select * into s from sias_cash_sessions where company_id=p_company and id=p_session for update;
  if s.id is null or s.status<>'OPEN' or s.user_id<>p_user then raise exception 'CAJA_ABIERTA_DEL_OPERADOR_REQUERIDA'; end if;
  if v_key is null or (p_payload->>'document_type')<>'SALE' or coalesce((p_payload->>'total')::numeric,0)<=0 or jsonb_typeof(p_payments)<>'array' or jsonb_typeof(p_credits)<>'array' then raise exception 'VENTA_POS_INVALIDA'; end if;
  if jsonb_array_length(p_payments)>20 or jsonb_array_length(p_credits)>50 then raise exception 'PAGOS_INVALIDOS'; end if;
  for x in select value from jsonb_array_elements(p_payments) union all select value from jsonb_array_elements(p_credits) loop
    v_amount:=(x->>'amount')::numeric;
    if v_amount is null or v_amount<=0 or v_amount<>round(v_amount) or v_amount::text in ('NaN','Infinity','-Infinity') then raise exception 'MONTO_PAGO_INVALIDO'; end if;
    v_sum:=v_sum+v_amount;
  end loop;
  if v_sum<>(p_payload->>'total')::numeric then raise exception 'PAGOS_NO_CUBREN_TOTAL'; end if;
  v_meta:=coalesce(p_payload->'metadata','{}')||jsonb_build_object('pos_fingerprint',p_fingerprint,'pos',true);
  v_id:=sias_commit_document(p_company,p_user,p_payload||jsonb_build_object('source','POS','metadata',v_meta),true);
  update sias_documents set cash_session_id=s.id where id=v_id;
  for x in select value from jsonb_array_elements(p_credits) order by value->>'credit_id' loop
    perform sias_v3_credit_apply(p_company,p_user,(x->>'credit_id')::uuid,v_id,(x->>'amount')::numeric,(x->>'request_key')::uuid);
  end loop;
  for x in select value from jsonb_array_elements(p_payments) loop
    if x->>'method' not in ('CASH','CARD','TRANSFER') then raise exception 'METODO_PAGO_INVALIDO'; end if;
    v_payment:=sias_register_payment(p_company,p_user,v_id,(x->>'amount')::numeric,x->>'method',x->>'reference',(x->>'request_key')::uuid);
    update sias_payments set cash_session_id=s.id where id=(v_payment->>'payment_id')::uuid;
  end loop;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'POS','CHECKOUT','sias_documents',v_id,jsonb_build_object('total',p_payload->'total','session_id',s.id));
  return v_id;
end $$;

create or replace function public.sias_v3_document_operational(p_company uuid,p_user uuid,p_document uuid,p_patch jsonb,p_reason text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d sias_documents%rowtype; v_old jsonb; v_staff uuid; v_role text; v_field text;
begin
  perform sias_v3_guard(p_company,p_user,'SALES_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into d from sias_documents where company_id=p_company and id=p_document for update;
  if d.id is null or d.status='VOID' then raise exception 'DOCUMENTO_NO_EDITABLE'; end if;
  if d.status<>'DRAFT' then
    if not exists(select 1 from sias_users where id=p_user and active and superadmin) and not exists(select 1 from sias_user_roles ur join sias_roles r on r.id=ur.role_id where ur.user_id=p_user and ur.company_id=p_company and r.code='ADMIN' and r.active) then
      perform sias_v3_guard(p_company,p_user,'DOCUMENT_OVERRIDE');
    end if;
    if length(btrim(coalesce(p_reason,'')))<8 then raise exception 'MOTIVO_CORRECCION_REQUERIDO'; end if;
  end if;
  for v_field,v_role in values ('seller_id','SELLER'),('preparer_id','PREPARER'),('packer_id','PACKER') loop
    v_staff:=nullif(p_patch->>v_field,'')::uuid;
    if v_staff is not null and not exists(select 1 from sias_staff where id=v_staff and company_id=p_company and active and v_role=any(roles)) then raise exception 'RESPONSABLE_NO_VALIDO'; end if;
  end loop;
  v_old:=to_jsonb(d);
  update sias_documents set metadata=metadata||jsonb_build_object('seller_id',nullif(p_patch->>'seller_id',''),'preparer_id',nullif(p_patch->>'preparer_id',''),'packer_id',nullif(p_patch->>'packer_id','')),
    notes=case when p_patch?'notes' then nullif(left(p_patch->>'notes',2000),'') else notes end,updated_by=p_user,updated_at=now() where id=d.id returning * into d;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'DOCUMENTS','OPERATIONAL_CORRECTION','sias_documents',d.id,jsonb_build_object('reason',p_reason,'before',v_old,'after',to_jsonb(d)));
  return to_jsonb(d);
end $$;

create or replace function public.sias_v3_close_flow(p_company uuid,p_user uuid,p_document uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d sias_documents%rowtype; v_ids uuid[];
begin
  perform sias_v3_guard(p_company,p_user,'SALES_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into d from sias_documents where company_id=p_company and id=p_document for update;
  if d.id is null or d.status<>'POSTED' or d.document_type not in ('SALE','WHOLESALE') or d.payment_status<>'PAID' then raise exception 'VENTA_CONFIRMADA_Y_PAGADA_REQUERIDA'; end if;
  if not exists(select 1 from sias_external_dte where company_id=p_company and document_id=d.id and status='EMITIDO' and environment='PRODUCCION' and document_type in (33,34,39,41)) then raise exception 'FACTURA_BOLETA_EMITIDA_REQUERIDA'; end if;
  with recursive chain as(select id,source_document_id from sias_documents where id=d.id and company_id=p_company union all select p.id,p.source_document_id from sias_documents p join chain c on p.id=c.source_document_id where p.company_id=p_company) select array_agg(id) into v_ids from chain;
  update sias_documents set metadata=metadata||jsonb_build_object('flow_state','CLOSED','closed_by',p_user,'closed_at',now()),updated_at=now() where company_id=p_company and id=any(v_ids);
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'DOCUMENTS','CLOSE_FLOW','sias_documents',d.id,jsonb_build_object('documents',v_ids));
  return jsonb_build_object('closed',true,'ids',v_ids);
end $$;

-- Los asientos se originan en documentos confirmados y pagos. Reversión por anulación.
create or replace function public.sias_v3_account_document()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_lines jsonb; v_account text; v_cost numeric; v_journal uuid;
begin
  if new.status='POSTED' and old.status is distinct from new.status and new.document_type in ('SALE','WHOLESALE','PURCHASE') then
    if new.document_type='PURCHASE' then
      v_lines:=jsonb_build_array(jsonb_build_object('account','1200','debit',new.net+new.exempt),jsonb_build_object('account','1130','debit',new.tax),jsonb_build_object('account','2100','credit',new.total));
    else
      v_lines:=jsonb_build_array(jsonb_build_object('account','1120','debit',new.total),jsonb_build_object('account','4100','credit',new.net+new.exempt),jsonb_build_object('account','2110','credit',new.tax));
    end if;
    perform sias_v3_journal(new.company_id,'DOCUMENT',new.id,new.issue_date,new.number,new.customer_id,new.supplier_id,v_lines);
  elsif new.status='VOID' and old.status='POSTED' then
    select j.id into v_journal from sias_journals j where j.company_id=new.company_id and j.source_type='DOCUMENT' and j.source_id=new.id;
    if v_journal is not null then
      select jsonb_agg(jsonb_build_object('account',account,'debit',credit,'credit',debit)) into v_lines from sias_journal_lines where journal_id=v_journal;
      perform sias_v3_journal(new.company_id,'VOID_DOCUMENT',new.id,current_date,'Anulación '||new.number,new.customer_id,new.supplier_id,v_lines);
    end if;
  end if;
  return new;
end $$;
drop trigger if exists sias_v3_document_accounting on public.sias_documents;
create trigger sias_v3_document_accounting after update of status on public.sias_documents for each row execute function public.sias_v3_account_document();

create or replace function public.sias_v3_account_payment()
returns trigger language plpgsql security definer set search_path=public as $$
declare d sias_documents%rowtype; v_account text;
begin
  if new.status='CONFIRMED' then
    select * into d from sias_documents where id=new.document_id and company_id=new.company_id;
    v_account:=case new.method when 'CASH' then '1100' when 'CLIENT_CREDIT' then '2120' else '1110' end;
    perform sias_v3_journal(new.company_id,'PAYMENT',new.id,(new.paid_at at time zone 'America/Santiago')::date,'Pago '||d.number,d.customer_id,d.supplier_id,
      jsonb_build_array(jsonb_build_object('account',v_account,'debit',new.amount),jsonb_build_object('account','1120','credit',new.amount)));
  end if;
  return new;
end $$;
drop trigger if exists sias_v3_payment_accounting on public.sias_payments;
create trigger sias_v3_payment_accounting after insert on public.sias_payments for each row execute function public.sias_v3_account_payment();

create or replace function public.sias_save_document(p_company uuid,p_user uuid,p_payload jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_type text:=upper(coalesce(p_payload->>'document_type','')); v_number text; v_existing public.sias_documents%rowtype;
  v_source public.sias_documents%rowtype; v_source_id uuid:=nullif(p_payload->>'source_document_id','')::uuid;
  v_key uuid:=nullif(p_payload->>'request_key','')::uuid; v_meta jsonb:=coalesce(p_payload->'metadata','{}'::jsonb);
  it jsonb; v_line integer:=0; v_pid uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if v_type not in ('QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','TRANSFER','DELIVERY') then raise exception 'TIPO_DOCUMENTO_INVALIDO'; end if;
  if coalesce(jsonb_typeof(p_payload->'items'),'')<>'array' then raise exception 'DOCUMENTO_SIN_ITEMS'; end if;
  if jsonb_array_length(p_payload->'items') not between 1 and 200 then raise exception 'DOCUMENTO_ITEMS_INVALIDOS'; end if;
  if nullif(p_payload->>'id','') is null and v_key is not null then
    select id into v_id from public.sias_documents where company_id=p_company and request_key=v_key;
    if v_id is not null then return v_id; end if;
  end if;
  if nullif(p_payload->>'customer_id','') is not null and not exists(select 1 from public.sias_customers where id=(p_payload->>'customer_id')::uuid and company_id=p_company and active) then raise exception 'CLIENTE_NO_VALIDO'; end if;
  if nullif(p_payload->>'supplier_id','') is not null and not exists(select 1 from public.sias_suppliers where id=(p_payload->>'supplier_id')::uuid and company_id=p_company and active) then raise exception 'PROVEEDOR_NO_VALIDO'; end if;
  if nullif(p_payload->>'warehouse_id','') is not null and not exists(select 1 from public.sias_warehouses where id=(p_payload->>'warehouse_id')::uuid and company_id=p_company and active) then raise exception 'BODEGA_NO_VALIDA'; end if;
  if nullif(p_payload->>'destination_warehouse_id','') is not null and not exists(select 1 from public.sias_warehouses where id=(p_payload->>'destination_warehouse_id')::uuid and company_id=p_company and active) then raise exception 'BODEGA_DESTINO_NO_VALIDA'; end if;
  if v_source_id is not null then
    select * into v_source from public.sias_documents where id=v_source_id and company_id=p_company for update;
    if v_source.id is null or v_source.status<>'POSTED' then raise exception 'ORIGEN_DEBE_ESTAR_CONFIRMADO'; end if;
    if not ((v_source.document_type='REQUEST' and v_type in ('QUOTE','ORDER','SALE')) or
      (v_source.document_type='QUOTE' and v_type in ('ORDER','SALE')) or
      (v_source.document_type='ORDER' and v_type in ('SALE','DELIVERY')) or (v_source.document_type='DELIVERY' and v_type='SALE') or
      (v_source.document_type in ('SALE','WHOLESALE') and v_type='DELIVERY')) then raise exception 'CONVERSION_NO_VALIDA'; end if;
    if exists(select 1 from sias_documents where company_id=p_company and source_document_id=v_source.id and status<>'VOID' and id is distinct from nullif(p_payload->>'id','')::uuid) then raise exception 'ORIGEN_YA_TIENE_DOCUMENTO_DERIVADO'; end if;
    if v_source.metadata->>'flow_state'='CLOSED' then raise exception 'FLUJO_DOCUMENTAL_CERRADO'; end if;
    if v_source.customer_id is not null and nullif(p_payload->>'customer_id','')::uuid is distinct from v_source.customer_id then raise exception 'CLIENTE_ORIGEN_NO_COINCIDE'; end if;
    if (v_type='DELIVERY' and v_source.document_type in ('SALE','WHOLESALE')) or (v_type='SALE' and v_source.document_type='DELIVERY') then v_meta:=v_meta||jsonb_build_object('move_stock',false); end if;
    if v_type='SALE' and v_source.document_type='ORDER' and exists(select 1 from sias_documents where company_id=p_company and source_document_id=v_source.id and document_type='DELIVERY' and status<>'VOID') then raise exception 'FACTURAR_DESDE_GUIA_DERIVADA'; end if;
    if v_type='SALE' and exists(select 1 from public.sias_documents where company_id=p_company and source_document_id=v_source.id and document_type='ORDER' and status<>'VOID') then raise exception 'FACTURAR_DESDE_PEDIDO_DERIVADO'; end if;
  end if;
  if nullif(p_payload->>'id','') is not null then
    v_id:=(p_payload->>'id')::uuid;
    select * into v_existing from public.sias_documents where id=v_id and company_id=p_company for update;
    if v_existing.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
    if v_existing.status<>'DRAFT' then raise exception 'SOLO_BORRADOR_EDITABLE'; end if;
    if v_existing.document_type<>v_type or v_existing.source_document_id is distinct from v_source_id then raise exception 'TIPO_ORIGEN_NO_MODIFICABLE'; end if;
    v_number:=v_existing.number;
    v_meta:=v_existing.metadata||v_meta;
    delete from public.sias_document_items where document_id=v_id;
  else
    v_number:=public.sias_next_sequence(p_company,v_type);
    insert into public.sias_documents(company_id,document_type,number,created_by,updated_by,request_key)
      values(p_company,v_type,v_number,p_user,p_user,v_key) returning id into v_id;
  end if;
  update public.sias_documents set customer_id=nullif(p_payload->>'customer_id','')::uuid,supplier_id=nullif(p_payload->>'supplier_id','')::uuid,
    warehouse_id=nullif(p_payload->>'warehouse_id','')::uuid,destination_warehouse_id=nullif(p_payload->>'destination_warehouse_id','')::uuid,
    source_document_id=v_source_id,metadata=v_meta,issue_date=coalesce(nullif(p_payload->>'issue_date','')::date,current_date),
    due_date=nullif(p_payload->>'due_date','')::date,currency='CLP',net=coalesce((p_payload->>'net')::numeric,0),
    exempt=coalesce((p_payload->>'exempt')::numeric,0),tax=coalesce((p_payload->>'tax')::numeric,0),
    discount=coalesce((p_payload->>'discount')::numeric,0),shipping=coalesce((p_payload->>'shipping')::numeric,0),total=coalesce((p_payload->>'total')::numeric,0),
    payment_method=nullif(p_payload->>'payment_method',''),source=coalesce(nullif(p_payload->>'source',''),'DIRECT'),
    notes=nullif(p_payload->>'notes',''),updated_by=p_user,updated_at=now() where id=v_id;
  for it in select value from jsonb_array_elements(p_payload->'items') loop
    v_line:=v_line+1; v_pid:=nullif(it->>'product_id','')::uuid;
    if v_pid is null or not exists(select 1 from public.sias_products where id=v_pid and company_id=p_company and active) then raise exception 'PRODUCTO_NO_VALIDO'; end if;
    insert into public.sias_document_items(document_id,line_no,product_id,sku,description,quantity,unit,unit_price,discount,tax_rate,exempt,line_net,line_tax,line_total,acquisition_cost)
      values(v_id,v_line,v_pid,nullif(it->>'sku',''),coalesce(nullif(it->>'description',''),'Ítem'),(it->>'quantity')::numeric,
        coalesce(nullif(it->>'unit',''),'UN'),(it->>'unit_price')::numeric,coalesce((it->>'discount')::numeric,0),
        coalesce((it->>'tax_rate')::numeric,19),coalesce((it->>'exempt')::boolean,false),
        (it->>'line_net')::numeric,(it->>'line_tax')::numeric,(it->>'line_total')::numeric,nullif(it->>'acquisition_cost','')::numeric);
  end loop;
  return v_id;
end $$;

create or replace function public.sias_post_document(p_company uuid,p_document uuid,p_user uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; it record; v_stock numeric; v_old numeric; v_cost numeric; v_new numeric; v_delta numeric;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
  if d.status='POSTED' then return jsonb_build_object('id',d.id,'status',d.status,'already_posted',true); end if;
  if d.status<>'DRAFT' then raise exception 'DOCUMENTO_ANULADO'; end if;
  if not exists(select 1 from public.sias_document_items where document_id=d.id) then raise exception 'DOCUMENTO_SIN_ITEMS'; end if;
  if d.document_type in ('SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','TRANSFER','DELIVERY') then
    if d.warehouse_id is null then raise exception 'BODEGA_REQUERIDA'; end if;
    if d.document_type='TRANSFER' and (d.destination_warehouse_id is null or d.destination_warehouse_id=d.warehouse_id) then raise exception 'TRASLADO_INVALIDO'; end if;
    for it in select * from public.sias_document_items where document_id=d.id order by product_id,line_no loop
      if it.product_id is null then raise exception 'PRODUCTO_CATALOGO_REQUERIDO'; end if;
      if d.document_type in ('PURCHASE','RECEIPT') then
        select cost into v_old from public.sias_products where id=it.product_id and company_id=p_company for update;
        select coalesce(sum(quantity),0) into v_stock from public.sias_stock where company_id=p_company and product_id=it.product_id;
        v_cost:=coalesce(it.acquisition_cost,case when it.exempt then it.unit_price else it.unit_price/(1+it.tax_rate/100) end);
        v_new:=round((v_stock*v_old+it.quantity*v_cost)/(v_stock+it.quantity),4);
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,it.quantity,'INGRESO',d.document_type,d.id,d.number,p_user);
        update public.sias_products set cost=v_new,updated_at=now() where id=it.product_id and company_id=p_company;
        insert into public.sias_cost_history(company_id,product_id,document_id,old_cost,new_cost,reason,created_by)
          values(p_company,it.product_id,d.id,v_old,v_new,'INGRESO',p_user);
        perform public.sias_refresh_supply_recipes(p_company,it.product_id,p_user);
      elsif d.document_type='TRANSFER' then
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,-it.quantity,'TRASLADO_SALIDA','TRANSFER',d.id,d.number,p_user);
        perform public.sias_stock_adjust(p_company,d.destination_warehouse_id,it.product_id,it.quantity,'TRASLADO_ENTRADA','TRANSFER',d.id,d.number,p_user);
      elsif coalesce((d.metadata->>'move_stock')::boolean,true) then
        v_delta:=-it.quantity;
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,v_delta,
          case when d.document_type='DELIVERY' then 'DESPACHO' when d.document_type='ISSUE' then 'SALIDA' else 'VENTA' end,
          d.document_type,d.id,d.number,p_user);
      end if;
    end loop;
  end if;
  update public.sias_documents set status='POSTED',posted_at=now(),updated_by=p_user,updated_at=now() where id=d.id;
  return jsonb_build_object('id',d.id,'status','POSTED');
end $$;

create or replace function public.sias_register_payment(p_company uuid,p_user uuid,p_document uuid,p_amount numeric,p_method text,p_reference text,p_key uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; v_paid numeric; v_id uuid; v_status text;
begin
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null or d.status<>'POSTED' or d.document_type not in ('SALE','WHOLESALE') then raise exception 'VENTA_CONFIRMADA_REQUERIDA'; end if;
  if p_key is null then raise exception 'PAGO_INVALIDO'; end if;
  select id into v_id from public.sias_payments where company_id=p_company and request_key=p_key;
  if v_id is not null then
    if not exists(select 1 from sias_payments where id=v_id and document_id=p_document and amount=p_amount and method=p_method) then raise exception 'SOLICITUD_REUTILIZADA_CON_OTROS_DATOS'; end if;
    return jsonb_build_object('payment_id',v_id,'reused',true); end if;
  if p_method='CLIENT_CREDIT' then raise exception 'USAR_APLICACION_DE_CREDITO'; end if;
  if d.cash_session_id is not null and not exists(select 1 from sias_cash_sessions where id=d.cash_session_id and company_id=p_company and status='OPEN') then raise exception 'CAJA_CERRADA_NO_MODIFICABLE'; end if;
  select coalesce(sum(amount),0) into v_paid from public.sias_payments where company_id=p_company and document_id=p_document and status='CONFIRMED';
  if p_amount is null or p_amount<=0 or p_amount::text in ('NaN','Infinity','-Infinity') or p_amount>d.total-v_paid then raise exception 'PAGO_SUPERA_SALDO'; end if;
  insert into public.sias_payments(company_id,document_id,amount,method,reference,created_by,request_key)
    values(p_company,p_document,p_amount,p_method,nullif(p_reference,''),p_user,p_key) returning id into v_id;
  v_paid:=v_paid+p_amount;v_status:=case when v_paid>=d.total then 'PAID' else 'PARTIAL' end;
  update public.sias_documents set payment_status=v_status,updated_at=now() where id=p_document;
  return jsonb_build_object('payment_id',v_id,'payment_status',v_status,'paid',v_paid);
end $$;

create or replace function public.sias_v3_price_save(p_company uuid,p_user uuid,p_payload jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid:=nullif(p_payload->>'id','')::uuid; x jsonb;
begin
  perform sias_v3_guard(p_company,p_user,'PRODUCT_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if length(btrim(coalesce(p_payload->>'name','')))=0 or jsonb_typeof(p_payload->'items')<>'array' or jsonb_array_length(p_payload->'items')>2000 then raise exception 'LISTA_PRECIOS_INVALIDA'; end if;
  if v_id is not null then
    if not exists(select 1 from sias_price_lists where id=v_id and company_id=p_company) then raise exception 'LISTA_PRECIOS_NO_ENCONTRADA'; end if;
    update sias_price_lists set name=left(btrim(p_payload->>'name'),120),active=coalesce((p_payload->>'active')::boolean,true) where id=v_id;
    delete from sias_price_list_items where price_list_id=v_id and company_id=p_company;
  else insert into sias_price_lists(company_id,name,active) values(p_company,left(btrim(p_payload->>'name'),120),coalesce((p_payload->>'active')::boolean,true)) returning id into v_id; end if;
  for x in select value from jsonb_array_elements(p_payload->'items') loop
    if not exists(select 1 from sias_products where id=(x->>'product_id')::uuid and company_id=p_company) or nullif(x->>'price','') is null or (x->>'price')::numeric<0 or (x->>'price')::numeric::text in ('NaN','Infinity','-Infinity') then raise exception 'PRECIO_PRODUCTO_INVALIDO'; end if;
    insert into sias_price_list_items(company_id,price_list_id,product_id,price) values(p_company,v_id,(x->>'product_id')::uuid,(x->>'price')::numeric);
  end loop;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'PRODUCTS','PRICE_LIST_SAVE','sias_price_lists',v_id,jsonb_build_object('name',p_payload->>'name','items',jsonb_array_length(p_payload->'items')));
  return v_id;
end $$;

create or replace function public.sias_v3_flow(p_company uuid,p_user uuid,p_document uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_root uuid; v_result jsonb;
begin
  perform sias_v3_guard(p_company,p_user,'SALES_VIEW');
  with recursive parents as(select id,source_document_id,array[id] path from sias_documents where id=p_document and company_id=p_company
    union all select d.id,d.source_document_id,path||d.id from sias_documents d join parents p on d.id=p.source_document_id where d.company_id=p_company and not d.id=any(path))
    select id into v_root from parents order by cardinality(path) desc limit 1;
  if v_root is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
  with recursive children as(select d.*,array[d.id] path from sias_documents d where d.id=v_root and d.company_id=p_company
    union all select d.*,c.path||d.id from sias_documents d join children c on d.source_document_id=c.id where d.company_id=p_company and not d.id=any(c.path))
    select coalesce(jsonb_agg(jsonb_build_object('id',id,'number',number,'document_type',document_type,'status',status,'payment_status',payment_status,'metadata',metadata,'source_document_id',source_document_id,'total',total) order by cardinality(path),created_at),'[]') into v_result from children;
  return v_result;
end $$;

-- Cargar los documentos y pagos preexistentes en el mayor sin modificar su estado.
do $$ declare d record; p record; v_lines jsonb; begin
  for d in select * from sias_documents where status='POSTED' and document_type in ('SALE','WHOLESALE','PURCHASE') loop
    if d.document_type='PURCHASE' then
      v_lines:=jsonb_build_array(jsonb_build_object('account','1200','debit',d.net+d.exempt),jsonb_build_object('account','1130','debit',d.tax),jsonb_build_object('account','2100','credit',d.total));
    else v_lines:=jsonb_build_array(jsonb_build_object('account','1120','debit',d.total),jsonb_build_object('account','4100','credit',d.net+d.exempt),jsonb_build_object('account','2110','credit',d.tax)); end if;
    perform sias_v3_journal(d.company_id,'DOCUMENT',d.id,d.issue_date,d.number,d.customer_id,d.supplier_id,v_lines);
  end loop;
  for p in select pp.*,doc.number,doc.customer_id,doc.supplier_id from sias_payments pp join sias_documents doc on doc.id=pp.document_id and doc.company_id=pp.company_id where pp.status='CONFIRMED' loop
    perform sias_v3_journal(p.company_id,'PAYMENT',p.id,(p.paid_at at time zone 'America/Santiago')::date,'Pago '||p.number,p.customer_id,p.supplier_id,
      jsonb_build_array(jsonb_build_object('account',case p.method when 'CASH' then '1100' when 'CLIENT_CREDIT' then '2120' else '1110' end,'debit',p.amount),jsonb_build_object('account','1120','credit',p.amount)));
  end loop;
end $$;


create table if not exists public.sias_pos_canceled(
  company_id uuid not null references sias_companies(id),request_key uuid not null,
  user_id uuid not null references sias_users(id),created_at timestamptz not null default now(),primary key(company_id,request_key)
);
alter table public.sias_pos_canceled enable row level security;
revoke all on public.sias_pos_canceled from anon,authenticated;
grant all on public.sias_pos_canceled to service_role;
create or replace function public.sias_v3_pos_cancel(p_company uuid,p_user uuid,p_key uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  perform sias_v3_guard(p_company,p_user,'POS_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if p_key is null then raise exception 'SOLICITUD_POS_REQUERIDA'; end if;
  select id into v_id from sias_documents where company_id=p_company and request_key=p_key and created_by=p_user;
  if found then return jsonb_build_object('canceled',false,'document_id',v_id); end if;
  insert into sias_pos_canceled(company_id,request_key,user_id) values(p_company,p_key,p_user) on conflict do nothing;
  return jsonb_build_object('canceled',true);
end $$;


create or replace function public.sias_void_document(p_company uuid,p_document uuid,p_user uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; it record; v_stock numeric; v_old numeric; v_cost numeric; v_new numeric;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
  if d.status='VOID' then return jsonb_build_object('id',d.id,'status','VOID','already_void',true); end if;
  if exists(select 1 from public.sias_external_dte where document_id=d.id and company_id=p_company and status in ('INICIADO','INDETERMINADO','EMITIDO')) then
    raise exception 'DOCUMENTO_CON_DTE_REQUIERE_NOTA_TRIBUTARIA';
  end if;
  if exists(select 1 from public.sias_documents where source_document_id=d.id and company_id=p_company and status<>'VOID') then
    raise exception 'DOCUMENTO_CON_DERIVADOS_ACTIVOS';
  end if;
  if exists(select 1 from public.sias_payments where document_id=d.id and company_id=p_company and status='CONFIRMED') then
    raise exception 'DOCUMENTO_CON_PAGOS_CONFIRMADOS';
  end if;
  if d.status='POSTED' then
    for it in select * from public.sias_document_items where document_id=d.id order by product_id,line_no desc loop
      if d.document_type in ('PURCHASE','RECEIPT') then
        select cost into v_old from public.sias_products where id=it.product_id and company_id=p_company for update;
        select coalesce(sum(quantity),0) into v_stock from public.sias_stock where company_id=p_company and product_id=it.product_id;
        v_cost:=coalesce(it.acquisition_cost,case when it.exempt then it.unit_price else it.unit_price/(1+it.tax_rate/100) end);
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,-it.quantity,'ANULACION',d.document_type,d.id,d.number,p_user);
        if v_stock>it.quantity then v_new:=greatest(0,round((v_stock*v_old-it.quantity*v_cost)/(v_stock-it.quantity),4));
        else
          select old_cost into v_new from public.sias_cost_history where company_id=p_company and document_id=d.id and product_id=it.product_id and reason='INGRESO' order by id limit 1;
          v_new:=coalesce(v_new,v_old);
        end if;
        update public.sias_products set cost=v_new,updated_at=now() where id=it.product_id;
        insert into public.sias_cost_history(company_id,product_id,document_id,old_cost,new_cost,reason,created_by)
          values(p_company,it.product_id,d.id,v_old,v_new,'ANULACION_INGRESO',p_user);
        perform public.sias_refresh_supply_recipes(p_company,it.product_id,p_user);
      elsif d.document_type='TRANSFER' then
        perform public.sias_stock_adjust(p_company,d.destination_warehouse_id,it.product_id,-it.quantity,'ANULACION_TRASLADO','TRANSFER',d.id,d.number,p_user);
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,it.quantity,'ANULACION_TRASLADO','TRANSFER',d.id,d.number,p_user);
      elsif d.document_type in ('SALE','WHOLESALE','ISSUE','DELIVERY') and coalesce((d.metadata->>'move_stock')::boolean,true) then
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,it.quantity,'ANULACION',d.document_type,d.id,d.number,p_user);
      end if;
    end loop;
  end if;
  update public.sias_documents set status='VOID',voided_at=now(),updated_by=p_user,updated_at=now() where id=d.id;
  return jsonb_build_object('id',d.id,'status','VOID');
end $$;

create table if not exists public.sias_rcv_rows(
  id uuid primary key default gen_random_uuid(),company_id uuid not null references sias_companies(id),
  book text not null check(book in ('SALES','PURCHASES')),document_type integer not null,folio text not null,rut text not null,
  legal_name text,issue_date date not null,net numeric(18,2) not null,exempt numeric(18,2) not null,tax numeric(18,2) not null,total numeric(18,2) not null,
  imported_by uuid references sias_users(id),imported_at timestamptz not null default now(),unique(company_id,book,document_type,rut,folio)
);
create index if not exists sias_rcv_date_idx on public.sias_rcv_rows(company_id,book,issue_date);
alter table public.sias_rcv_rows enable row level security;
revoke all on public.sias_rcv_rows from anon,authenticated;
grant all on public.sias_rcv_rows to service_role;
create or replace function public.sias_v3_rcv_import(p_company uuid,p_user uuid,p_book text,p_rows jsonb)
returns integer language plpgsql security definer set search_path=public as $$
declare x jsonb; v_count integer:=0;
begin
  perform sias_v3_guard(p_company,p_user,'RCV_MANAGE');
  if p_book not in ('SALES','PURCHASES') or jsonb_typeof(p_rows)<>'array' or jsonb_array_length(p_rows) not between 1 and 5000 then raise exception 'RCV_INVALIDO'; end if;
  for x in select value from jsonb_array_elements(p_rows) loop
    if (x->>'document_type')::integer<=0 or nullif(x->>'folio','') is null or nullif(x->>'rut','') is null or least((x->>'net')::numeric,(x->>'exempt')::numeric,(x->>'tax')::numeric,(x->>'total')::numeric)<0 then raise exception 'FILA_RCV_INVALIDA'; end if;
    if exists(select 1 from jsonb_each_text(x) where key in ('net','exempt','tax','total') and value in ('NaN','Infinity','-Infinity')) then raise exception 'MONTO_RCV_INVALIDO'; end if;
    insert into sias_rcv_rows(company_id,book,document_type,folio,rut,legal_name,issue_date,net,exempt,tax,total,imported_by)
      values(p_company,p_book,(x->>'document_type')::integer,left(x->>'folio',40),upper(regexp_replace(x->>'rut','[^0-9Kk]','','g')),left(x->>'legal_name',250),(x->>'issue_date')::date,(x->>'net')::numeric,(x->>'exempt')::numeric,(x->>'tax')::numeric,(x->>'total')::numeric,p_user)
      on conflict(company_id,book,document_type,rut,folio) do update set legal_name=excluded.legal_name,issue_date=excluded.issue_date,net=excluded.net,exempt=excluded.exempt,tax=excluded.tax,total=excluded.total,imported_by=p_user,imported_at=now();
    v_count:=v_count+1;
  end loop;
  insert into sias_audit(company_id,user_id,module,action,detail) values(p_company,p_user,'REPORTS','RCV_IMPORT',jsonb_build_object('book',p_book,'rows',v_count));
  return v_count;
end $$;


create or replace function public.sias_claim_dte(p_company uuid,p_user uuid,p_document uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; existing public.sias_external_dte%rowtype; ref public.sias_external_dte%rowtype;
  v_type integer:=(p_payload->>'document_type')::integer; v_total numeric:=(p_payload->>'total')::numeric; v_credited numeric;
  v_reference uuid:=nullif(p_payload->>'reference_id','')::uuid; v_code integer:=nullif(p_payload->>'reference_code','')::integer;
begin
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null or d.status<>'POSTED' or d.document_type not in ('SALE','WHOLESALE','DELIVERY') then raise exception 'DOCUMENTO_CONFIRMADO_REQUERIDO'; end if;
  if v_type in (33,34,39,41,52) then
    if exists(select 1 from sias_credit_applications a join sias_customer_credits c on c.id=a.credit_id where a.company_id=p_company and a.document_id=d.id and c.environment is distinct from p_payload->>'environment') then raise exception 'DOCUMENTO_CON_CREDITO_DE_OTRO_AMBIENTE'; end if;
    update sias_documents set metadata=metadata||jsonb_build_object('billing_environment',p_payload->>'environment') where id=d.id and company_id=p_company;
  end if;
  select * into existing from public.sias_external_dte where company_id=p_company and provider='FACTURACION_CL' and request_hash=p_payload->>'request_hash';
  if existing.id is not null and existing.status<>'ERROR' then return to_jsonb(existing)||jsonb_build_object('reused',true); end if;
  if v_type in (33,34,39,41) and exists(select 1 from public.sias_external_dte where company_id=p_company and document_id=p_document
    and provider='FACTURACION_CL' and environment=p_payload->>'environment' and document_type in (33,34,39,41) and status in ('INICIADO','INDETERMINADO','EMITIDO')) then raise exception 'DOCUMENTO_YA_TIENE_DTE_PRINCIPAL'; end if;
  if v_type in (56,61) then
    select * into ref from public.sias_external_dte where id=v_reference and company_id=p_company and document_id=p_document and status='EMITIDO'
      and environment=p_payload->>'environment' and document_type in (33,34,39,41,52);
    if ref.id is null or v_code not in (1,2,3) then raise exception 'DTE_REFERENCIA_INVALIDA'; end if;
    if v_type=61 then
      select coalesce(sum(total),0) into v_credited from public.sias_external_dte where company_id=p_company and reference_id=ref.id
        and document_type=61 and status in ('INICIADO','INDETERMINADO','EMITIDO');
      if v_credited+v_total>ref.total then raise exception 'NOTA_SUPERA_SALDO_DTE'; end if;
    end if;
  end if;
  if existing.id is not null then
    update public.sias_external_dte set status='INICIADO',error_detail=null,updated_at=now() where id=existing.id returning * into existing;
  else
    insert into public.sias_external_dte(company_id,document_id,provider,environment,document_type,folio,status,issue_date,recipient_rut,recipient_name,total,
      reference_document_type,reference_folio,reference_date,reference_id,reference_code,request_hash,created_by)
    values(p_company,p_document,'FACTURACION_CL',p_payload->>'environment',v_type,null,'INICIADO',(p_payload->>'issue_date')::date,
      p_payload->>'recipient_rut',p_payload->>'recipient_name',v_total,ref.document_type,ref.folio,ref.issue_date,v_reference,v_code,p_payload->>'request_hash',p_user)
    returning * into existing;
  end if;
  return to_jsonb(existing)||jsonb_build_object('reused',false);
end $$;

-- Permisos nuevos, aplicados al administrador. SUPERADMIN sigue teniendo todos.
insert into public.sias_permissions(code,module,name,description) values
  ('POS_VIEW','SALES','Ver POS','Consultar punto de venta y caja'),('POS_MANAGE','SALES','Operar POS','Vender, abrir y cerrar caja'),
  ('CREDIT_VIEW','SALES','Ver créditos','Consultar créditos de clientes'),('CREDIT_MANAGE','SALES','Aplicar créditos','Aplicar notas de crédito'),
  ('RCV_MANAGE','REPORTS','Importar RCV','Importar registros del SII para conciliación'),
  ('DOCUMENT_OVERRIDE','SALES','Corrección operativa','Corregir datos operativos con motivo y auditoría') on conflict(code) do nothing;
insert into public.sias_role_permissions(role_id,permission_id)
  select r.id,p.id from sias_roles r cross join sias_permissions p where r.code='ADMIN' and p.code in ('POS_VIEW','POS_MANAGE','CREDIT_VIEW','CREDIT_MANAGE','DOCUMENT_OVERRIDE','RCV_MANAGE') on conflict do nothing;

do $$ declare t text; f record; begin
  foreach t in array array['sias_product_changes','sias_staff','sias_price_lists','sias_price_list_items','sias_cash_sessions','sias_cash_movements','sias_customer_credits','sias_credit_applications','sias_journals','sias_journal_lines'] loop
    execute format('alter table public.%I enable row level security',t);
    execute format('revoke all on public.%I from anon,authenticated',t);
    execute format('grant all on public.%I to service_role',t);
  end loop;
  for f in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like 'sias_v3_%' loop
    execute format('revoke all on function %s from public,anon,authenticated',f.signature);
    execute format('grant execute on function %s to service_role',f.signature);
  end loop;
end $$;
grant usage,select on sequence public.sias_product_changes_id_seq,public.sias_journal_lines_id_seq to service_role;
notify pgrst,'reload schema';
commit;

begin;
update public.sias_installation set version='3.0.1',jwt_enabled=false,updated_at=now() where id=1;
notify pgrst,'reload schema';
commit;


-- Importadores 3.1: migración aditiva. No borra registros existentes.
begin;
alter table public.sias_customers add column if not exists import_code text;
alter table public.sias_suppliers add column if not exists import_code text;
alter table public.sias_staff add column if not exists import_code text;
alter table public.sias_price_lists add column if not exists import_code text;
alter table public.sias_documents add column if not exists import_code text;
create unique index if not exists sias_customer_import_code on public.sias_customers(company_id,lower(import_code)) where import_code is not null;
create unique index if not exists sias_supplier_import_code on public.sias_suppliers(company_id,lower(import_code)) where import_code is not null;
create unique index if not exists sias_staff_import_code on public.sias_staff(company_id,lower(import_code)) where import_code is not null;
create unique index if not exists sias_price_list_import_code on public.sias_price_lists(company_id,lower(import_code)) where import_code is not null;
create unique index if not exists sias_document_import_code on public.sias_documents(company_id,lower(import_code)) where import_code is not null;
insert into public.sias_permissions(code,module,name,description) values
 ('IMPORT_VIEW','SETTINGS','Ver importadores','Ver plantillas y cargas de la empresa'),
 ('IMPORT_MANAGE','SETTINGS','Importar datos','Validar y confirmar archivos XLSX; requiere permisos de cada maestro')
on conflict(code) do update set name=excluded.name,description=excluded.description;
insert into public.sias_role_permissions(role_id,permission_id)
select r.id,p.id from sias_roles r cross join sias_permissions p where r.code='ADMIN' and p.code in ('IMPORT_VIEW','IMPORT_MANAGE') on conflict do nothing;
create table if not exists public.sias_import_batches(
 id uuid primary key default gen_random_uuid(),company_id uuid not null references sias_companies(id),
 user_id uuid not null references sias_users(id),filename text not null,mode text not null,strategy text not null,
 status text not null default 'PREVIEWED' check(status in ('PREVIEWED','COMPLETED')),
 payload jsonb not null,baseline text not null,result jsonb not null,created_at timestamptz not null default now(),
 expires_at timestamptz not null default now()+interval '30 minutes',completed_at timestamptz
);
create index if not exists sias_import_batches_company_date on public.sias_import_batches(company_id,created_at desc);
alter table public.sias_import_batches enable row level security;
revoke all on public.sias_import_batches from public,anon,authenticated;
grant all on public.sias_import_batches to service_role;

create or replace function public.sias_import_schema() returns jsonb language sql immutable as $schema$
select $manifest${"version":"3.1.6","maxRows":100000,"maxFileBytes":52428800,"maxCells":2000000,"tables":[{"key":"Empresa","db":"sias_companies","permission":"COMPANY_MANAGE","singleton":true,"fields":{"rut":{"label":"RUT","type":"rut","maxLength":30},"legal_name":{"label":"Razón social","type":"text","maxLength":180,"required":true},"trade_name":{"label":"Nombre comercial","type":"text","maxLength":160},"business_activity":{"label":"Giro","type":"text","maxLength":200},"email":{"label":"Correo","type":"email","maxLength":240},"phone":{"label":"Teléfono","type":"text","maxLength":40},"address":{"label":"Dirección","type":"text","maxLength":300},"commune":{"label":"Comuna","type":"text","maxLength":100},"city":{"label":"Ciudad","type":"text","maxLength":100},"region":{"label":"Región","type":"text","maxLength":100},"website":{"label":"Sitio web","type":"url"},"logo_url":{"label":"Logo URL","type":"url"}}},{"key":"Bodegas","db":"sias_warehouses","permission":"INVENTORY_MANAGE","identity":["code"],"fields":{"code":{"label":"Código bodega","type":"text","maxLength":40,"required":true},"name":{"label":"Nombre","type":"text","maxLength":160,"required":true},"address":{"label":"Dirección","type":"text","maxLength":300},"commune":{"label":"Comuna","type":"text","maxLength":100},"city":{"label":"Ciudad","type":"text","maxLength":100},"active":{"label":"Activo","type":"bool"}}},{"key":"Proveedores","db":"sias_suppliers","permission":"SUPPLIER_MANAGE","identity":["rut","import_code"],"fields":{"import_code":{"label":"Código proveedor","type":"text","maxLength":80},"rut":{"label":"RUT","type":"rut","maxLength":30},"legal_name":{"label":"Razón social","type":"text","maxLength":180,"required":true},"trade_name":{"label":"Nombre comercial","type":"text","maxLength":160},"business_activity":{"label":"Giro","type":"text","maxLength":200},"email":{"label":"Correo","type":"email","maxLength":240},"phone":{"label":"Teléfono","type":"text","maxLength":40},"address":{"label":"Dirección","type":"text","maxLength":300},"commune":{"label":"Comuna","type":"text","maxLength":100},"city":{"label":"Ciudad","type":"text","maxLength":100},"contact_name":{"label":"Contacto","type":"text","maxLength":160},"active":{"label":"Activo","type":"bool"},"notes":{"label":"Notas","type":"text","maxLength":2000}}},{"key":"Clientes","db":"sias_customers","permission":"CUSTOMER_MANAGE","identity":["rut","import_code"],"fields":{"import_code":{"label":"Código cliente","type":"text","maxLength":80},"rut":{"label":"RUT","type":"rut","maxLength":30},"legal_name":{"label":"Razón social","type":"text","maxLength":180,"required":true},"trade_name":{"label":"Nombre comercial","type":"text","maxLength":160},"business_activity":{"label":"Giro","type":"text","maxLength":200},"email":{"label":"Correo","type":"email","maxLength":240},"phone":{"label":"Teléfono","type":"text","maxLength":40},"address":{"label":"Dirección","type":"text","maxLength":300},"commune":{"label":"Comuna","type":"text","maxLength":100},"city":{"label":"Ciudad","type":"text","maxLength":100},"contact_name":{"label":"Contacto","type":"text","maxLength":160},"active":{"label":"Activo","type":"bool"},"notes":{"label":"Notas","type":"text","maxLength":2000},"region":{"label":"Región","type":"text","maxLength":100},"credit_limit":{"label":"Límite crédito","type":"number","min":0,"max":1000000000000},"wholesale":{"label":"Mayorista","type":"bool"}}},{"key":"Responsables","db":"sias_staff","permission":"SETTINGS_MANAGE","identity":["import_code","name"],"fields":{"import_code":{"label":"Código responsable","type":"text","maxLength":80},"name":{"label":"Nombre","type":"text","maxLength":160,"required":true},"roles":{"label":"Funciones","type":"roles"},"active":{"label":"Activo","type":"bool"}}},{"key":"Productos","db":"sias_products","permission":"PRODUCT_MANAGE","identity":["sku"],"fields":{"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"name":{"label":"Nombre","type":"text","maxLength":180,"required":true},"barcode":{"label":"Código barras","type":"text","maxLength":80},"description":{"label":"Descripción","type":"text","maxLength":2000},"category":{"label":"Categoría","type":"text","maxLength":120},"brand":{"label":"Marca","type":"text","maxLength":120},"unit":{"label":"Unidad","type":"unit"},"product_kind":{"label":"Tipo producto","type":"kind"},"cost":{"label":"Costo","type":"number","min":0,"max":1000000000000},"price":{"label":"Precio venta","type":"number","min":0,"max":1000000000000},"wholesale_price":{"label":"Precio mayorista","type":"number","min":0,"max":1000000000000},"tax_rate":{"label":"IVA porcentaje","type":"number","min":0,"max":100},"exempt":{"label":"Exento","type":"bool"},"min_stock":{"label":"Stock mínimo","type":"number","min":0,"max":1000000},"max_stock":{"label":"Stock máximo","type":"number","min":0,"max":1000000},"pack_quantity":{"label":"Cantidad por caja","type":"number","min":0.0001,"max":1000000},"pallet_boxes":{"label":"Cajas por pallet","type":"integer","min":1,"max":1000000},"weight_kg":{"label":"Peso kg","type":"number","min":0,"max":1000000},"length_cm":{"label":"Largo cm","type":"number","min":0,"max":1000000},"width_cm":{"label":"Ancho cm","type":"number","min":0,"max":1000000},"height_cm":{"label":"Alto cm","type":"number","min":0,"max":1000000},"fractional":{"label":"Fraccionable","type":"bool"},"image_url":{"label":"Imagen URL","type":"url"},"featured":{"label":"Destacado","type":"bool"},"public_visible":{"label":"Visible tienda","type":"bool"},"active":{"label":"Activo","type":"bool"},"parent_sku":{"label":"SKU padre","type":"text","maxLength":80,"virtual":true},"supplier_rut":{"label":"RUT proveedor","type":"rut","virtual":true}}},{"key":"Atributos","db":"sias_products","permission":"PRODUCT_MANAGE","special":true,"fields":{"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"attribute":{"label":"Atributo","type":"text","maxLength":80,"required":true},"value":{"label":"Valor","type":"text","maxLength":300,"required":true}}},{"key":"ListasPrecios","db":"sias_price_lists","permission":"PRODUCT_MANAGE","identity":["import_code","name"],"fields":{"import_code":{"label":"Código lista","type":"text","maxLength":80},"name":{"label":"Nombre lista","type":"text","maxLength":160,"required":true},"active":{"label":"Activo","type":"bool"}}},{"key":"Precios","db":"sias_price_list_items","permission":"PRODUCT_MANAGE","special":true,"fields":{"list":{"label":"Lista","type":"text","maxLength":160,"required":true},"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"price":{"label":"Precio","type":"number","min":0,"max":1000000000000,"required":true}}},{"key":"Recetas","db":"sias_product_recipe","permission":"PRODUCT_MANAGE","special":true,"fields":{"sku":{"label":"SKU producto","type":"text","maxLength":80,"required":true},"supply_sku":{"label":"SKU insumo","type":"text","maxLength":80,"required":true},"quantity":{"label":"Cantidad","type":"number","min":0.0001,"max":1000000,"required":true},"unit":{"label":"Unidad","type":"unit"}}},{"key":"StockInicial","db":"sias_stock","permission":"INVENTORY_MANAGE","special":true,"fields":{"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"warehouse":{"label":"Bodega","type":"text","maxLength":40,"required":true},"quantity":{"label":"Cantidad","type":"number","min":0,"max":1000000,"required":true}}},{"key":"Documentos","db":"sias_documents","permission":"SALES_MANAGE","special":true,"fields":{"import_code":{"label":"Referencia","type":"text","maxLength":100,"required":true},"document_type":{"label":"Tipo documento","type":"document","required":true},"issue_date":{"label":"Fecha","type":"date","required":true},"due_date":{"label":"Vencimiento","type":"date"},"customer_rut":{"label":"RUT cliente","type":"rut","virtual":true},"supplier_rut":{"label":"RUT proveedor","type":"rut","virtual":true},"warehouse":{"label":"Bodega","type":"text","maxLength":40,"virtual":true},"notes":{"label":"Notas","type":"text","maxLength":2000}}},{"key":"DetalleDocumentos","db":"sias_document_items","permission":"SALES_MANAGE","special":true,"fields":{"document":{"label":"Referencia documento","type":"text","maxLength":100,"required":true},"line_no":{"label":"Línea","type":"integer","min":1,"max":200,"required":true},"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"quantity":{"label":"Cantidad","type":"number","min":0.0001,"max":1000000,"required":true},"unit_price":{"label":"Precio unitario","type":"number","min":0,"max":1000000000000},"discount":{"label":"Descuento","type":"number","min":0,"max":1000000000000},"tax_rate":{"label":"IVA porcentaje","type":"number","min":0,"max":100},"exempt":{"label":"Exento","type":"bool"}}},{"key":"RCV","db":"sias_rcv_rows","permission":"RCV_MANAGE","special":true,"fields":{"book":{"label":"Libro","type":"book","required":true},"document_type":{"label":"Tipo DTE","type":"integer","min":1,"max":999,"required":true},"folio":{"label":"Folio","type":"text","maxLength":80,"required":true},"rut":{"label":"RUT","type":"rut","required":true},"legal_name":{"label":"Razón social","type":"text","maxLength":180},"issue_date":{"label":"Fecha","type":"date","required":true},"net":{"label":"Neto","type":"number","min":0,"max":1000000000000},"exempt":{"label":"Exento","type":"number","min":0,"max":1000000000000},"tax":{"label":"IVA","type":"number","min":0,"max":1000000000000},"total":{"label":"Total","type":"number","min":0,"max":1000000000000,"required":true}}},{"key":"Tienda","db":"sias_store_settings","permission":"SETTINGS_MANAGE","singleton":true,"fields":{"slug":{"label":"Identificador tienda","type":"text","maxLength":100,"required":true},"enabled":{"label":"Habilitada","type":"bool"},"title":{"label":"Título","type":"text","maxLength":160},"tagline":{"label":"Subtítulo","type":"text","maxLength":300},"hero_title":{"label":"Título principal","type":"text","maxLength":160},"hero_text":{"label":"Texto principal","type":"text","maxLength":2000},"about_title":{"label":"Título nosotros","type":"text","maxLength":160},"about_text":{"label":"Texto nosotros","type":"text","maxLength":4000},"delivery_text":{"label":"Texto despacho","type":"text","maxLength":4000},"terms":{"label":"Condiciones","type":"text","maxLength":6000},"logo_url":{"label":"Logo URL","type":"url"},"hero_image":{"label":"Imagen principal URL","type":"url"},"primary_color":{"label":"Color principal","type":"color"},"whatsapp":{"label":"WhatsApp","type":"text","maxLength":40},"contact_email":{"label":"Correo contacto","type":"email"},"contact_address":{"label":"Dirección contacto","type":"text","maxLength":300},"allow_orders":{"label":"Permitir pedidos","type":"bool"},"show_stock":{"label":"Mostrar stock","type":"bool"},"hide_unavailable":{"label":"Ocultar agotados","type":"bool"},"warehouse":{"label":"Bodega","type":"text","maxLength":40,"virtual":true}}},{"key":"Folios","db":"sias_sequences","permission":"SETTINGS_MANAGE","special":true,"fields":{"code":{"label":"Código","type":"text","maxLength":50,"required":true},"prefix":{"label":"Prefijo","type":"text","maxLength":30},"current_value":{"label":"Último número","type":"integer","min":0,"max":1000000000,"required":true},"padding":{"label":"Dígitos","type":"integer","min":1,"max":12}}}],"maxExpandedBytes":209715200,"batchRows":500,"atomicRows":5000}$manifest$::jsonb
$schema$;

create or replace function public.sias_v31_pos_categories(p_company uuid,p_user uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
 perform sias_v3_guard(p_company,p_user,'POS_VIEW');
 return coalesce((select jsonb_agg(category order by category) from (select distinct category from sias_products where company_id=p_company and active and product_kind='PRODUCT' and nullif(category,'') is not null) s),'[]');
end $$;

create or replace function public.sias_import_lookup(p_company uuid,p_table text,p_keys jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare r record;w text:='';ids uuid[];
begin
 if p_table<>all(array['sias_products','sias_customers','sias_suppliers','sias_warehouses','sias_staff','sias_price_lists','sias_documents','sias_sequences']) then raise exception 'TABLA_NO_PERMITIDA';end if;
 for r in select key,value from jsonb_each_text(p_keys) loop
  if r.key<>all(array['sku','rut','import_code','name','code']) then raise exception 'CLAVE_NO_PERMITIDA';end if;
  if nullif(r.value,'') is not null then w:=w||case when w='' then '' else ' or ' end||case when r.key='rut' then format('lower(replace(replace(%I,''.'',''''),'' '',''''))=lower(replace(replace(%L,''.'',''''),'' '',''''))',r.key,r.value) else format('lower(btrim(%I))=lower(btrim(%L))',r.key,r.value) end;end if;
 end loop;
 if w='' then raise exception 'CLAVE_REQUERIDA';end if;
 execute format('select array_agg(id) from public.%I where company_id=$1 and (%s)',p_table,w) into ids using p_company;
 if cardinality(ids)>1 then raise exception 'CLAVE_AMBIGUA: más de un registro coincide con %',p_keys;end if;
 return ids[1];
end $$;

create or replace function public.sias_import_write(p_company uuid,p_table text,p_id uuid,p_values jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare names text;selects text;sets text;v_id uuid:=coalesce(p_id,gen_random_uuid());
begin
 if p_table<>all(array['sias_companies','sias_warehouses','sias_customers','sias_suppliers','sias_staff','sias_price_lists','sias_products','sias_price_list_items','sias_product_recipe','sias_documents','sias_document_items','sias_rcv_rows','sias_store_settings','sias_sequences']) then raise exception 'TABLA_NO_PERMITIDA';end if;
 p_values:=p_values-'id'-'company_id';
 if p_id is not null and p_table=any(array['sias_companies','sias_warehouses','sias_customers','sias_suppliers','sias_staff','sias_products','sias_documents','sias_store_settings','sias_sequences']) then p_values:=p_values||jsonb_build_object('updated_at',now());end if;
 select string_agg(format('%I',key),',' order by key),string_agg(format('r.%I',key),',' order by key),string_agg(format('%I=r.%I',key,key),',' order by key)
 into names,selects,sets from jsonb_object_keys(p_values) as key;
 if names is null then return v_id;end if;
 if p_table='sias_store_settings' then
  if p_id is null then execute format('insert into public.%I(company_id,%s) select $1,%s from jsonb_populate_record(null::public.%I,$2) r',p_table,names,selects,p_table) using p_company,p_values;
  else execute format('update public.%I t set %s from jsonb_populate_record(null::public.%I,$2) r where t.company_id=$1',p_table,sets,p_table) using p_company,p_values;end if;return p_company;
 end if;
 if p_id is null then
  if p_table='sias_document_items' then
   execute format('insert into public.%I(id,%s) select $1,%s from jsonb_populate_record(null::public.%I,$2) r',p_table,names,selects,p_table) using v_id,p_values;
  else
   execute format('insert into public.%I(id,company_id,%s) select $1,$2,%s from jsonb_populate_record(null::public.%I,$3) r',p_table,names,selects,p_table) using v_id,p_company,p_values;
  end if;
 else
  execute format('update public.%I t set %s from jsonb_populate_record(null::public.%I,$2) r where t.id=$1',p_table,sets,p_table) using v_id,p_values;
 end if;
 return v_id;
end $$;

-- Huella de las tablas de negocio: obliga a revisar nuevamente si cambiaron durante la vista previa.
create or replace function public.sias_import_fingerprint(p_company uuid)
returns text language plpgsql security definer set search_path=public as $$
declare t text;h text;acc text:='';
begin
 for t in select unnest(array['sias_companies','sias_warehouses','sias_customers','sias_suppliers','sias_staff','sias_products','sias_price_lists','sias_price_list_items','sias_product_recipe','sias_stock','sias_documents','sias_document_items','sias_rcv_rows','sias_store_settings','sias_sequences','sias_stock_movements']) loop
  if t='sias_companies' then select md5(to_jsonb(c)::text) into h from sias_companies c where id=p_company;
  elsif t='sias_document_items' then select md5(coalesce(string_agg(md5(to_jsonb(i)::text),'' order by i.id),'')) into h from sias_document_items i join sias_documents d on d.id=i.document_id where d.company_id=p_company;
  else execute format('select md5(coalesce(string_agg(md5(to_jsonb(t)::text),'''' order by md5(to_jsonb(t)::text)),'''')) from public.%I t where company_id=$1',t) into h using p_company;end if;
  acc:=acc||t||coalesce(h,'');
 end loop;return md5(acc);
end $$;

create or replace function public.sias_import_run(p_company uuid,p_user uuid,p_data jsonb,p_mode text,p_strategy text,p_preview boolean,p_expected text default null,p_batch uuid default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare rr record;r jsonb;t jsonb;f record;v jsonb;original jsonb;old jsonb;olditem jsonb;keys jsonb;sid uuid;pid uuid;wid uuid;did uuid;lid uuid;refid uuid;
 field_name text;typ text;n numeric;amount numeric;rate numeric;ex boolean;oldqty numeric;table_name text;sheet_name text;source_name text;row_no integer;
 baseline text;detail text;summary jsonb:='{}';seen jsonb:='{}';identity text;ids uuid[]:='{}';outcome text;result jsonb;dtype text;
begin
 perform sias_v3_guard(p_company,p_user,'IMPORT_MANAGE');
 if p_mode<>all(array['General','Productos','Clientes','Precios']) or p_strategy<>all(array['UPSERT','CREATE']) or jsonb_typeof(p_data)<>'array' or jsonb_array_length(p_data)<1 or jsonb_array_length(p_data)>5000 or octet_length(p_data::text)>10485760 then raise exception 'ARCHIVO_INVALIDO_O_MUY_GRANDE';end if;
 perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
 baseline:=sias_import_fingerprint(p_company);
 if not p_preview and baseline is distinct from p_expected then return jsonb_build_object('ok',false,'errors',jsonb_build_array(jsonb_build_object('sheet','Archivo','row',0,'column','Vista previa','message','Los datos cambiaron desde la revisión. Vuelve a validar antes de confirmar.')));end if;
 begin
 for rr in select d.value from jsonb_array_elements(p_data) with ordinality d(value,ord)
  left join jsonb_array_elements(sias_import_schema()->'tables') with ordinality s(value,ord) on s.value->>'key'=d.value->>'sheet' order by s.ord,d.ord loop
  r:=rr.value;sheet_name:=r->>'sheet';source_name:=coalesce(r->>'source',sheet_name);row_no:=coalesce((r->>'row')::integer,0);field_name:='';
  select value into t from jsonb_array_elements(sias_import_schema()->'tables') where value->>'key'=sheet_name;
  if t is null or (p_mode<>'General' and not(sheet_name=p_mode or p_mode='Productos' and sheet_name='Atributos' or p_mode='Precios' and sheet_name in ('ListasPrecios','Precios'))) then raise exception 'HOJA_NO_PERMITIDA';end if;
  perform sias_v3_guard(p_company,p_user,t->>'permission');
  original:=r->'values';v:=original;table_name:=t->>'db';if jsonb_typeof(v)<>'object' then raise exception 'FILA_INVALIDA';end if;
  for field_name in select jsonb_object_keys(v) loop if not(t->'fields'?field_name) then raise exception 'COLUMNA_NO_PERMITIDA: %',field_name;end if;end loop;
  for f in select key,value from jsonb_each(t->'fields') loop
   field_name:=f.key;typ:=f.value->>'type';
   if coalesce((f.value->>'required')::boolean,false) and (not(v?field_name) or v->field_name='null'::jsonb or nullif(v->>field_name,'') is null) then raise exception 'CAMPO_OBLIGATORIO: %',field_name;end if;
   if not(v?field_name) then continue;end if;
   if v->field_name='null'::jsonb then raise exception 'VALOR_NULO_NO_PERMITIDO';end if;
   if typ in ('number','integer') then
    if jsonb_typeof(v->field_name)<>'number' then raise exception 'NUMERO_INVALIDO';end if;n:=(v->>field_name)::numeric;
    if n<coalesce((f.value->>'min')::numeric,-1e12) or n>coalesce((f.value->>'max')::numeric,1e12) or typ='integer' and n<>trunc(n) then raise exception 'NUMERO_FUERA_DE_RANGO';end if;
   elsif typ='bool' then if jsonb_typeof(v->field_name)<>'boolean' then raise exception 'BOOLEANO_INVALIDO';end if;
   elsif typ='roles' then if jsonb_typeof(v->field_name)<>'array' or jsonb_array_length(v->field_name)<1 or exists(select 1 from jsonb_array_elements_text(v->field_name) x where x<>all(array['SELLER','PREPARER','PACKER','CASHIER'])) then raise exception 'FUNCIONES_INVALIDAS';end if;
   else
    if jsonb_typeof(v->field_name)<>'string' or length(v->>field_name)>coalesce((f.value->>'maxLength')::integer,6000) then raise exception 'TEXTO_INVALIDO';end if;
    if typ='date' then if v->>field_name !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'FECHA_INVALIDA';end if;perform (v->>field_name)::date;end if;
    if typ='unit' and v->>field_name<>all(array['UN','KG','GR','LT','ML','MT','CM','CAJA','PALLET']) then raise exception 'UNIDAD_INVALIDA';end if;
    if typ='kind' and v->>field_name<>all(array['PRODUCT','SUPPLY']) then raise exception 'TIPO_PRODUCTO_INVALIDO';end if;
    if typ='book' and v->>field_name<>all(array['SALES','PURCHASES']) then raise exception 'LIBRO_INVALIDO';end if;
    if typ='rut' and v->>field_name !~ '^[0-9]{1,12}-[0-9Kk]$' then raise exception 'RUT_INVALIDO';end if;
    if typ='url' and v->>field_name !~ '^https?://' then raise exception 'URL_INVALIDA';end if;
    if typ='email' and v->>field_name !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' then raise exception 'CORREO_INVALIDO';end if;
    if typ='color' and v->>field_name !~ '^#[0-9a-fA-F]{6}$' then raise exception 'COLOR_INVALIDO';end if;
   end if;
  end loop;field_name:='Clave';sid:=null;keys:='{}';old:=null;
  if coalesce((t->>'singleton')::boolean,false) then identity:=sheet_name;
  elsif sheet_name in ('Productos','Bodegas','Folios','Documentos') then keys:=jsonb_build_object(case sheet_name when 'Productos' then 'sku' when 'Bodegas' then 'code' when 'Folios' then 'code' else 'import_code' end,v->case sheet_name when 'Productos' then 'sku' when 'Bodegas' then 'code' when 'Folios' then 'code' else 'import_code' end);identity:=keys::text;
  elsif sheet_name in ('Clientes','Proveedores') then keys:=jsonb_strip_nulls(jsonb_build_object('rut',v->'rut','import_code',v->'import_code'));if keys='{}' then raise exception 'RUT_O_CODIGO_REQUERIDO';end if;identity:=keys::text;
  elsif sheet_name in ('Responsables','ListasPrecios') then keys:=jsonb_strip_nulls(jsonb_build_object('import_code',v->'import_code','name',case when not(v?'import_code') then v->'name' end));identity:=keys::text;
  else identity:=case sheet_name when 'Precios' then (v->>'list')||'|'||(v->>'sku') when 'Atributos' then (v->>'sku')||'|'||(v->>'attribute') when 'Recetas' then (v->>'sku')||'|'||(v->>'supply_sku') when 'StockInicial' then (v->>'warehouse')||'|'||(v->>'sku') when 'DetalleDocumentos' then (v->>'document')||'|'||(v->>'line_no') when 'RCV' then (v->>'book')||'|'||(v->>'document_type')||'|'||(v->>'rut')||'|'||(v->>'folio') end;end if;
  identity:=sheet_name||'|'||lower(identity);if seen?identity then raise exception 'REGISTRO_DUPLICADO';end if;seen:=seen||jsonb_build_object(identity,true);
  if keys<>'{}' then sid:=sias_import_lookup(p_company,table_name,keys);end if;
  if sheet_name='Empresa' then sid:=p_company;end if;
  if sheet_name='Tienda' then select company_id into sid from sias_store_settings where company_id=p_company;end if;
  if sid is not null and sheet_name='Tienda' then select to_jsonb(x) into old from sias_store_settings x where company_id=p_company for update;elsif sid is not null then execute format('select to_jsonb(x) from public.%I x where id=$1 for update',table_name) into old using sid;end if;
  if sid is not null and not coalesce((t->>'special')::boolean,false) and seen?(sheet_name||'|id:'||sid::text) then raise exception 'REGISTRO_DUPLICADO_POR_CLAVE';end if;
  outcome:=case when sid is null then 'created' else 'updated' end;
  if sid is not null and p_strategy='CREATE' then outcome:='skipped';
  elsif sheet_name='Productos' then
   field_name:='SKU padre';if v?'parent_sku' then pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'parent_sku'));if pid is null then raise exception 'SKU_PADRE_NO_EXISTE';end if;v:=v||jsonb_build_object('parent_product_id',pid);end if;
   field_name:='RUT proveedor';if v?'supplier_rut' then pid:=sias_import_lookup(p_company,'sias_suppliers',jsonb_build_object('rut',v->'supplier_rut'));if pid is null then raise exception 'PROVEEDOR_NO_EXISTE';end if;v:=v||jsonb_build_object('supplier_id',pid);end if;
   v:=coalesce(old,'{}')||(v-'parent_sku'-'supplier_rut');sid:=sias_v3_save_product(p_company,p_user,v);
  elsif sheet_name='Atributos' then
   sid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));if sid is null then raise exception 'SKU_NO_EXISTE';end if;
   select to_jsonb(p) into old from sias_products p where id=sid for update;
   if p_strategy='CREATE' and old->'attributes'?((v->>'attribute')) then outcome:='skipped';else perform sias_v3_save_product(p_company,p_user,old||jsonb_build_object('attributes',coalesce(old->'attributes','{}')||jsonb_build_object((v->>'attribute'),v->'value')));outcome:='updated';end if;
  elsif sheet_name='Precios' then
   pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));lid:=sias_import_lookup(p_company,'sias_price_lists',jsonb_build_object('import_code',v->'list','name',v->'list'));
   if pid is null or lid is null then raise exception 'SKU_O_LISTA_NO_EXISTE';end if;
   select id into sid from sias_price_list_items where company_id=p_company and product_id=pid and price_list_id=lid for update;
   if sid is not null and p_strategy='CREATE' then outcome:='skipped';else outcome:=case when sid is null then 'created' else 'updated' end;sid:=sias_import_write(p_company,table_name,sid,jsonb_build_object('product_id',pid,'price_list_id',lid,'price',v->'price'));end if;
  elsif sheet_name='Recetas' then
   pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));refid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'supply_sku'));
   if pid is null or refid is null or pid=refid or not exists(select 1 from sias_products where id=refid and product_kind='SUPPLY' and active) then raise exception 'PRODUCTO_O_INSUMO_INVALIDO';end if;
   select id into sid from sias_product_recipe where company_id=p_company and product_id=pid and supply_id=refid for update;
   if sid is not null and p_strategy='CREATE' then outcome:='skipped';else outcome:=case when sid is null then 'created' else 'updated' end;
    select unit into typ from sias_products where id=refid;if v?'unit' then perform sias_unit_factor((v->>'unit'),typ);else v:=v||jsonb_build_object('unit',typ);end if;
    sid:=sias_import_write(p_company,table_name,sid,jsonb_build_object('product_id',pid,'supply_id',refid,'unit',v->'unit','quantity',v->'quantity'));perform sias_recalculate_recipe(p_company,pid,p_user);end if;
  elsif sheet_name='StockInicial' then
   pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));wid:=sias_import_lookup(p_company,'sias_warehouses',jsonb_build_object('code',v->'warehouse'));if pid is null or wid is null then raise exception 'SKU_O_BODEGA_NO_EXISTE';end if;
   if exists(select 1 from sias_stock_movements where company_id=p_company and product_id=pid and warehouse_id=wid and reference_type is distinct from 'IMPORT_INITIAL') then raise exception 'STOCK_CON_OPERACIONES: utiliza ajustes o ingresos';end if;
   select quantity into oldqty from sias_stock where company_id=p_company and product_id=pid and warehouse_id=wid for update;
   if oldqty is not null and p_strategy='CREATE' then outcome:='skipped';else n:=((v->>'quantity'))::numeric-coalesce(oldqty,0);if n<>0 then perform sias_stock_adjust(p_company,wid,pid,n,'APERTURA','IMPORT_INITIAL',p_batch,'Importación de stock inicial',p_user);else insert into sias_stock(company_id,product_id,warehouse_id,quantity) values(p_company,pid,wid,0) on conflict(company_id,warehouse_id,product_id) do nothing;end if;outcome:=case when oldqty is null then 'created' else 'updated' end;end if;
  elsif sheet_name='Documentos' then
   dtype:=(v->>'document_type');if dtype<>all(array['QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','DELIVERY']) then raise exception 'TIPO_DOCUMENTO_NO_PERMITIDO';end if;
   perform sias_v3_guard(p_company,p_user,case when dtype='PURCHASE' then 'PURCHASE_MANAGE' when dtype='WHOLESALE' then 'WHOLESALE_MANAGE' when dtype in ('RECEIPT','ISSUE') then 'INVENTORY_MANAGE' else 'SALES_MANAGE' end);
   if old is not null and ((old->>'status')<>'DRAFT' or (old->>'document_type')<>dtype) then raise exception 'SOLO_BORRADOR_DEL_MISMO_TIPO';end if;
   if v?'customer_rut' then pid:=sias_import_lookup(p_company,'sias_customers',jsonb_build_object('rut',v->'customer_rut'));if pid is null then raise exception 'CLIENTE_NO_EXISTE';end if;v:=v||jsonb_build_object('customer_id',pid);end if;
   if v?'supplier_rut' then pid:=sias_import_lookup(p_company,'sias_suppliers',jsonb_build_object('rut',v->'supplier_rut'));if pid is null then raise exception 'PROVEEDOR_NO_EXISTE';end if;v:=v||jsonb_build_object('supplier_id',pid);end if;
   if v?'warehouse' then wid:=sias_import_lookup(p_company,'sias_warehouses',jsonb_build_object('code',v->'warehouse'));if wid is null then raise exception 'BODEGA_NO_EXISTE';end if;v:=v||jsonb_build_object('warehouse_id',wid);end if;
   v:=v-'customer_rut'-'supplier_rut'-'warehouse';if sid is null then v:=v||jsonb_build_object('number',sias_next_sequence(p_company,dtype),'created_by',p_user,'source','IMPORT');end if;v:=v||jsonb_build_object('updated_by',p_user);sid:=sias_import_write(p_company,table_name,sid,v);ids:=array_append(ids,sid);
  elsif sheet_name='DetalleDocumentos' then
   did:=sias_import_lookup(p_company,'sias_documents',jsonb_build_object('import_code',v->'document'));pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));
   if did is null or pid is null then raise exception 'DOCUMENTO_O_SKU_NO_EXISTE';end if;
   select document_type into dtype from sias_documents where id=did and status='DRAFT' for update;if dtype is null then raise exception 'SOLO_BORRADOR_EDITABLE';end if;
   perform sias_v3_guard(p_company,p_user,case when dtype='PURCHASE' then 'PURCHASE_MANAGE' when dtype='WHOLESALE' then 'WHOLESALE_MANAGE' when dtype in ('RECEIPT','ISSUE') then 'INVENTORY_MANAGE' else 'SALES_MANAGE' end);
   select to_jsonb(p) into old from sias_products p where id=pid and active;if old is null then raise exception 'PRODUCTO_INACTIVO';end if;
   select id into sid from sias_document_items where document_id=did and line_no=((v->>'line_no'))::integer for update;
   if sid is not null and p_strategy='CREATE' then outcome:='skipped';else
    if dtype in ('SALE','WHOLESALE','QUOTE','ORDER','REQUEST','DELIVERY') and old->>'product_kind'='SUPPLY' then raise exception 'INSUMO_NO_DISPONIBLE_PARA_VENTA';end if;
    if old->>'unit'='UN' and not coalesce((old->>'fractional')::boolean,false) and (v->>'quantity')::numeric<>trunc((v->>'quantity')::numeric) then raise exception 'PRODUCTO_REQUIERE_UNIDADES_ENTERAS';end if;
    outcome:=case when sid is null then 'created' else 'updated' end;v:=v||jsonb_build_object('discount',coalesce(v->'discount',olditem->'discount','0'::jsonb),'unit_price',coalesce(v->'unit_price',olditem->'unit_price',old->'price'),'tax_rate',coalesce(v->'tax_rate',olditem->'tax_rate',old->'tax_rate'),'exempt',coalesce(v->'exempt',olditem->'exempt',old->'exempt'));
    amount:=round(((v->>'quantity'))::numeric*((v->>'unit_price'))::numeric)-coalesce(((v->>'discount'))::numeric,0);if amount<0 then raise exception 'DESCUENTO_MAYOR_QUE_TOTAL';end if;
    rate:=((v->>'tax_rate'))::numeric;ex:=((v->>'exempt'))::boolean;n:=case when ex then amount else round(amount/(1+rate/100)) end;
    v:=(v-'document')||jsonb_build_object('document_id',did,'product_id',pid,'description',old->'name','unit',old->'unit','line_total',amount,'line_net',case when ex then 0 else n end,'line_tax',amount-n,'acquisition_cost',case when dtype in ('PURCHASE','RECEIPT') then (v->>'unit_price')::numeric/case when ex then 1 else 1+rate/100 end else null end);sid:=sias_import_write(p_company,table_name,sid,v);ids:=array_append(ids,did);end if;
  elsif sheet_name='RCV' then
   if coalesce(((v->>'net'))::numeric,0)+coalesce(((v->>'exempt'))::numeric,0)+coalesce(((v->>'tax'))::numeric,0)<>((v->>'total'))::numeric then raise exception 'RCV_TOTAL_NO_COINCIDE';end if;
   select id into sid from sias_rcv_rows where company_id=p_company and book=(v->>'book') and document_type=((v->>'document_type'))::integer and folio=(v->>'folio') and rut=(v->>'rut') for update;
   if sid is not null and p_strategy='CREATE' then outcome:='skipped';else outcome:=case when sid is null then 'created' else 'updated' end;v:=jsonb_build_object('net',0,'exempt',0,'tax',0)||v||jsonb_build_object('imported_by',p_user);sid:=sias_import_write(p_company,table_name,sid,v);end if;
  else
   if sheet_name='Folios' and old is not null and ((v->>'current_value'))::bigint<((old->>'current_value'))::bigint then raise exception 'NO_SE_PUEDE_REDUCIR_UN_FOLIO';end if;
   if sheet_name='Tienda' then if (v->>'slug') !~ '^[a-z0-9][a-z0-9-]{1,79}$' then raise exception 'IDENTIFICADOR_TIENDA_INVALIDO';end if;if v?'warehouse' then wid:=sias_import_lookup(p_company,'sias_warehouses',jsonb_build_object('code',v->'warehouse'));if wid is null then raise exception 'BODEGA_NO_EXISTE';end if;v:=(v-'warehouse')||jsonb_build_object('warehouse_id',wid);end if;end if;
   sid:=sias_import_write(p_company,table_name,sid,v);
  end if;
  if sid is not null and not coalesce((t->>'special')::boolean,false) then seen:=seen||jsonb_build_object(sheet_name||'|id:'||sid::text,true);end if;
  summary:=jsonb_set(summary,array[sheet_name],coalesce(summary->sheet_name,'{"created":0,"updated":0,"skipped":0}')||jsonb_build_object(outcome,coalesce((summary->sheet_name->>outcome)::integer,0)+1),true);
 end loop;
 for did in select distinct unnest(ids) loop
  update sias_documents d set net=s.net,exempt=s.exempt,tax=s.tax,discount=s.discount,total=s.total+d.shipping,updated_at=now()
  from (select coalesce(sum(case when exempt then 0 else line_net end),0) net,coalesce(sum(case when exempt then line_total else 0 end),0) exempt,coalesce(sum(line_tax),0) tax,coalesce(sum(discount),0) discount,coalesce(sum(line_total),0) total from sias_document_items where document_id=did) s where d.id=did and d.company_id=p_company;
 end loop;
 result:=jsonb_build_object('ok',true,'summary',summary,'rows',jsonb_array_length(p_data),'baseline',baseline,'errors','[]'::jsonb);
 if p_preview then raise exception using errcode='ZP001',message='PREVIEW_ROLLBACK',detail=result::text;end if;
 return result;
 exception when sqlstate 'ZP001' then get stacked diagnostics detail=PG_EXCEPTION_DETAIL;return detail::jsonb;
 when others then return jsonb_build_object('ok',false,'errors',jsonb_build_array(jsonb_build_object('sheet',source_name,'row',row_no,'column',field_name,'message',SQLERRM)));
 end;
end $$;

create or replace function public.sias_import_preview(p_company uuid,p_user uuid,p_data jsonb,p_mode text,p_strategy text,p_filename text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare r jsonb;b uuid;
begin
 r:=sias_import_run(p_company,p_user,p_data,p_mode,p_strategy,true);
 if coalesce((r->>'ok')::boolean,false) then
  delete from sias_import_batches where company_id=p_company and user_id=p_user and status='PREVIEWED' and expires_at<now();
  if (select count(*) from sias_import_batches where company_id=p_company and user_id=p_user and status='PREVIEWED')>=10 then raise exception 'DEMASIADAS_VISTAS_PREVIAS: espera su vencimiento';end if;
  insert into sias_import_batches(company_id,user_id,filename,mode,strategy,payload,baseline,result) values(p_company,p_user,left(p_filename,200),p_mode,p_strategy,p_data,r->>'baseline',r-'baseline') returning id into b;
  return (r-'baseline')||jsonb_build_object('batch_id',b,'expires_at',now()+interval '30 minutes');
 end if;return r;
end $$;

create or replace function public.sias_import_commit(p_company uuid,p_user uuid,p_batch uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare b sias_import_batches%rowtype;r jsonb;
begin
 perform sias_v3_guard(p_company,p_user,'IMPORT_MANAGE');
 select * into b from sias_import_batches where id=p_batch and company_id=p_company and user_id=p_user for update;
 if b.id is null then raise exception 'CARGA_NO_ENCONTRADA';end if;
 if b.status='COMPLETED' then return b.result||jsonb_build_object('batch_id',b.id,'repeated',true);end if;
 if b.expires_at<now() then raise exception 'VISTA_PREVIA_VENCIDA: vuelve a validar';end if;
 r:=sias_import_run(p_company,p_user,b.payload,b.mode,b.strategy,false,b.baseline,b.id)-'baseline';
 if coalesce((r->>'ok')::boolean,false) then
  update sias_import_batches set status='COMPLETED',result=r,payload='[]',completed_at=now() where id=b.id;
  insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'IMPORT','COMMIT','sias_import_batches',b.id::text,jsonb_build_object('filename',b.filename,'mode',b.mode,'summary',r->'summary'));
 end if;return r||jsonb_build_object('batch_id',b.id);
end $$;

-- Solo la Edge Function autenticada puede ejecutar los importadores.
do $$declare r record;begin for r in select oid::regprocedure as signature from pg_proc where pronamespace='public'::regnamespace and (proname like 'sias_import_%' or proname='sias_v31_pos_categories') loop
 execute format('revoke all on function %s from public,anon,authenticated',r.signature);
 execute format('grant execute on function %s to service_role',r.signature);
end loop;end $$;
update public.sias_installation set version='3.1.0',jwt_enabled=false,updated_at=now() where id=1;
notify pgrst,'reload schema';
commit;


-- SIASCLOUD ERP v3.1.4 · INTERRUPTOR GLOBAL PARA VENDER SIN STOCK
-- Seguro para bases existentes. No borra datos.
begin;

insert into public.sias_settings(company_id,module,key,value,description)
select c.id,'INVENTORY','stock_policy','{"allow_negative_stock":false}'::jsonb,'Política global de stock para ventas'
from public.sias_companies c
where not exists (
  select 1 from public.sias_settings s
  where s.company_id=c.id and s.module='INVENTORY' and s.key='stock_policy'
);

create or replace function public.sias_stock_adjust(
  p_company uuid,
  p_warehouse uuid,
  p_product uuid,
  p_delta numeric,
  p_movement_type text,
  p_reference_type text default null,
  p_reference_id uuid default null,
  p_note text default null,
  p_user uuid default null
) returns numeric
language plpgsql
security definer
set search_path=public
as $$
declare
  v_qty numeric(18,4);
  v_prod_company uuid;
  v_wh_company uuid;
  v_stock_policy jsonb;
  v_allow_negative boolean := false;
begin
  if p_delta = 0 then raise exception 'STOCK_DELTA_CERO'; end if;
  select company_id into v_prod_company from public.sias_products where id=p_product and active=true;
  select company_id into v_wh_company from public.sias_warehouses where id=p_warehouse and active=true;
  if v_prod_company is null or v_prod_company<>p_company then raise exception 'PRODUCTO_NO_VALIDO'; end if;
  if v_wh_company is null or v_wh_company<>p_company then raise exception 'BODEGA_NO_VALIDA'; end if;

  insert into public.sias_stock(company_id,warehouse_id,product_id,quantity)
  values(p_company,p_warehouse,p_product,0)
  on conflict(company_id,warehouse_id,product_id) do nothing;

  select quantity into v_qty
    from public.sias_stock
   where company_id=p_company and warehouse_id=p_warehouse and product_id=p_product
   for update;

  select st.value into v_stock_policy
    from public.sias_settings st
   where st.module='INVENTORY'
     and st.key='stock_policy'
     and (st.company_id=p_company or st.company_id is null)
   order by (st.company_id is not null) desc
   limit 1;

  v_allow_negative := coalesce((v_stock_policy->>'allow_negative_stock')::boolean,false);
  if v_qty + p_delta < 0
     and not (v_allow_negative and upper(coalesce(p_movement_type,''))='VENTA')
  then raise exception 'STOCK_INSUFICIENTE'; end if;

  v_qty := v_qty + p_delta;
  update public.sias_stock set quantity=v_qty,updated_at=now()
   where company_id=p_company and warehouse_id=p_warehouse and product_id=p_product;

  insert into public.sias_stock_movements(company_id,warehouse_id,product_id,movement_type,quantity,balance_after,reference_type,reference_id,note,created_by)
  values(p_company,p_warehouse,p_product,upper(coalesce(p_movement_type,'AJUSTE')),p_delta,v_qty,p_reference_type,p_reference_id,p_note,p_user);
  return v_qty;
end $$;

revoke all on function public.sias_stock_adjust(uuid,uuid,uuid,numeric,text,text,uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.sias_stock_adjust(uuid,uuid,uuid,numeric,text,text,uuid,text,uuid) to service_role;

commit;

-- Verificación opcional:
select c.trade_name, s.value as stock_policy
from public.sias_companies c
left join public.sias_settings s
  on s.company_id=c.id and s.module='INVENTORY' and s.key='stock_policy'
order by c.trade_name;


-- SiasCloud 3.1.5: reparación aditiva. Conserva empresas, usuarios y datos.
begin;

create or replace function public.sias_v315_search_text(p_text text)
returns text language sql immutable parallel safe set search_path=public as $$
  select btrim(regexp_replace(lower(translate(coalesce(p_text,''),
    'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun')), '[^a-z0-9]+', ' ', 'g'));
$$;

create or replace function public.sias_v315_pos_customers(
  p_company uuid,p_user uuid,p_search text default '',p_limit integer default 50
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_search text; v_compact text; v_limit integer; v_rows jsonb;
begin
  perform public.sias_v3_guard(p_company,p_user,'POS_VIEW');
  v_search:=public.sias_v315_search_text(left(coalesce(p_search,''),100));
  v_compact:=replace(v_search,' ','');
  v_limit:=least(100,greatest(1,coalesce(p_limit,50)));
  select coalesce(jsonb_agg(to_jsonb(x) - 'match_rank'),'[]'::jsonb) into v_rows
  from (
    select c.id,c.legal_name,c.trade_name,c.rut,c.email,c.phone,c.active,
      case when v_compact<>'' and replace(public.sias_v315_search_text(c.rut),' ','')=v_compact then 0 else 1 end as match_rank
    from public.sias_customers c
    where c.company_id=p_company and c.active
      and (v_search='' or
        replace(public.sias_v315_search_text(concat_ws(' ',c.rut,c.phone)),' ','') like '%'||v_compact||'%'
        or not exists (
          select 1 from unnest(string_to_array(v_search,' ')) t
          where public.sias_v315_search_text(concat_ws(' ',c.legal_name,c.trade_name,c.rut,c.email,c.phone)) not like '%'||t||'%'
        ))
    order by match_rank,c.legal_name,c.id limit v_limit+1
  ) x;
  return jsonb_build_object('rows',coalesce((select jsonb_agg(value order by ordinality)
    from jsonb_array_elements(v_rows) with ordinality where ordinality<=v_limit),'[]'::jsonb),
    'truncated',jsonb_array_length(v_rows)>v_limit);
end $$;

create or replace function public.sias_v315_pos_products(
  p_company uuid,p_user uuid,p_search text default '',p_category text default ''
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_search text; v_compact text; v_rows jsonb;
begin
  perform public.sias_v3_guard(p_company,p_user,'POS_VIEW');
  v_search:=public.sias_v315_search_text(left(coalesce(p_search,''),100));
  v_compact:=replace(v_search,' ','');
  select coalesce(jsonb_agg(to_jsonb(x) - 'match_rank'),'[]'::jsonb) into v_rows
  from (
    select p.*,case when v_compact<>'' and v_compact in (
      replace(public.sias_v315_search_text(p.sku),' ',''),
      replace(public.sias_v315_search_text(p.barcode),' ','')) then 0 else 1 end as match_rank
    from public.sias_products p
    where p.company_id=p_company and p.active and p.product_kind='PRODUCT'
      and (coalesce(p_category,'')='' or p.category=p_category)
      and (v_search='' or v_compact in (
        replace(public.sias_v315_search_text(p.sku),' ',''),
        replace(public.sias_v315_search_text(p.barcode),' ','')) or not exists (
        select 1 from unnest(string_to_array(v_search,' ')) t
        where public.sias_v315_search_text(concat_ws(' ',p.name,p.sku,p.barcode,p.category,p.description)) not like '%'||t||'%'
      ))
    order by match_rank,p.name,p.id limit 500
  ) x;
  return v_rows;
end $$;

create or replace function public.sias_v315_stock_policy_save(
  p_company uuid,p_user uuid,p_allow boolean
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  perform public.sias_v3_guard(p_company,p_user,'SETTINGS_MANAGE');
  if p_allow is null then raise exception 'POLITICA_STOCK_INVALIDA'; end if;
  insert into public.sias_settings(company_id,module,key,value,description,updated_by)
  values(p_company,'INVENTORY','stock_policy',jsonb_build_object('allow_negative_stock',p_allow),
    'Política global de stock para ventas',p_user)
  on conflict ((coalesce(company_id,'00000000-0000-0000-0000-000000000000'::uuid)),module,key)
  do update set value=excluded.value,updated_by=excluded.updated_by,updated_at=now()
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.sias_stock_adjust(
  p_company uuid,p_warehouse uuid,p_product uuid,p_delta numeric,p_movement_type text,
  p_reference_type text default null,p_reference_id uuid default null,p_note text default null,p_user uuid default null
) returns numeric language plpgsql security definer set search_path=public as $$
declare v_qty numeric(18,4); v_allow_negative boolean:=false;
begin
  -- Mantiene el mismo orden de bloqueo que ventas, ingresos y traslados.
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if p_delta is null or p_delta=0 or p_delta::text in ('NaN','Infinity','-Infinity')
    or abs(p_delta)>1e10 or round(p_delta,4)=0 then raise exception 'STOCK_DELTA_INVALIDO'; end if;
  if not exists(select 1 from public.sias_products where id=p_product and company_id=p_company and active=true) then raise exception 'PRODUCTO_NO_VALIDO'; end if;
  if not exists(select 1 from public.sias_warehouses where id=p_warehouse and company_id=p_company and active=true) then raise exception 'BODEGA_NO_VALIDA'; end if;
  insert into public.sias_stock(company_id,warehouse_id,product_id,quantity) values(p_company,p_warehouse,p_product,0)
    on conflict(company_id,warehouse_id,product_id) do nothing;
  select quantity into v_qty from public.sias_stock
    where company_id=p_company and warehouse_id=p_warehouse and product_id=p_product for update;
  select coalesce(st.value->'allow_negative_stock'='true'::jsonb,false) into v_allow_negative
    from public.sias_settings st where st.module='INVENTORY' and st.key='stock_policy'
      and (st.company_id=p_company or st.company_id is null)
    order by (st.company_id is not null) desc limit 1;
  -- Una entrada siempre puede reducir el déficit, aunque todavía quede negativo.
  if p_delta<0 and v_qty+round(p_delta,4)<0 and not (
    coalesce(v_allow_negative,false) and upper(coalesce(p_movement_type,''))='VENTA'
  ) then raise exception 'STOCK_INSUFICIENTE'; end if;
  v_qty:=v_qty+round(p_delta,4);
  update public.sias_stock set quantity=v_qty,updated_at=now()
    where company_id=p_company and warehouse_id=p_warehouse and product_id=p_product;
  insert into public.sias_stock_movements(company_id,warehouse_id,product_id,movement_type,quantity,balance_after,reference_type,reference_id,note,created_by)
    values(p_company,p_warehouse,p_product,upper(coalesce(p_movement_type,'AJUSTE')),round(p_delta,4),v_qty,p_reference_type,p_reference_id,p_note,p_user);
  return v_qty;
end $$;

-- La recepción se define debajo conservando todas las reglas del flujo actual.

create or replace function public.sias_post_document(p_company uuid,p_document uuid,p_user uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; it record; v_stock numeric; v_old numeric; v_cost numeric; v_new numeric; v_delta numeric;
begin
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null then raise exception 'DOCUMENTO_NO_ENCONTRADO'; end if;
  if d.status='POSTED' then return jsonb_build_object('id',d.id,'status',d.status,'already_posted',true); end if;
  if d.status<>'DRAFT' then raise exception 'DOCUMENTO_ANULADO'; end if;
  if not exists(select 1 from public.sias_document_items where document_id=d.id) then raise exception 'DOCUMENTO_SIN_ITEMS'; end if;
  if d.document_type in ('SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','TRANSFER','DELIVERY') then
    if d.warehouse_id is null then raise exception 'BODEGA_REQUERIDA'; end if;
    if d.document_type='TRANSFER' and (d.destination_warehouse_id is null or d.destination_warehouse_id=d.warehouse_id) then raise exception 'TRASLADO_INVALIDO'; end if;
    for it in select * from public.sias_document_items where document_id=d.id order by product_id,line_no loop
      if it.product_id is null then raise exception 'PRODUCTO_CATALOGO_REQUERIDO'; end if;
      if d.document_type in ('PURCHASE','RECEIPT') then
        select cost into v_old from public.sias_products where id=it.product_id and company_id=p_company for update;
        select coalesce(sum(quantity),0) into v_stock from public.sias_stock where company_id=p_company and product_id=it.product_id;
        v_cost:=coalesce(it.acquisition_cost,case when it.exempt then it.unit_price else it.unit_price/(1+it.tax_rate/100) end);
        v_stock:=greatest(v_stock,0);
        v_new:=round((v_stock*v_old+it.quantity*v_cost)/(v_stock+it.quantity),4);
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,it.quantity,'INGRESO',d.document_type,d.id,d.number,p_user);
        update public.sias_products set cost=v_new,updated_at=now() where id=it.product_id and company_id=p_company;
        insert into public.sias_cost_history(company_id,product_id,document_id,old_cost,new_cost,reason,created_by)
          values(p_company,it.product_id,d.id,v_old,v_new,'INGRESO',p_user);
        perform public.sias_refresh_supply_recipes(p_company,it.product_id,p_user);
      elsif d.document_type='TRANSFER' then
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,-it.quantity,'TRASLADO_SALIDA','TRANSFER',d.id,d.number,p_user);
        perform public.sias_stock_adjust(p_company,d.destination_warehouse_id,it.product_id,it.quantity,'TRASLADO_ENTRADA','TRANSFER',d.id,d.number,p_user);
      elsif coalesce((d.metadata->>'move_stock')::boolean,true) then
        v_delta:=-it.quantity;
        perform public.sias_stock_adjust(p_company,d.warehouse_id,it.product_id,v_delta,
          case when d.document_type='DELIVERY' then 'DESPACHO' when d.document_type='ISSUE' then 'SALIDA' else 'VENTA' end,
          d.document_type,d.id,d.number,p_user);
      end if;
    end loop;
  end if;
  update public.sias_documents set status='POSTED',posted_at=now(),updated_by=p_user,updated_at=now() where id=d.id;
  return jsonb_build_object('id',d.id,'status','POSTED');
end $$;

revoke all on function public.sias_v315_search_text(text) from public,anon,authenticated;
grant execute on function public.sias_v315_search_text(text) to service_role;
revoke all on function public.sias_v315_pos_customers(uuid,uuid,text,integer) from public,anon,authenticated;
grant execute on function public.sias_v315_pos_customers(uuid,uuid,text,integer) to service_role;
revoke all on function public.sias_v315_pos_products(uuid,uuid,text,text) from public,anon,authenticated;
grant execute on function public.sias_v315_pos_products(uuid,uuid,text,text) to service_role;
revoke all on function public.sias_v315_stock_policy_save(uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function public.sias_v315_stock_policy_save(uuid,uuid,boolean) to service_role;
revoke all on function public.sias_stock_adjust(uuid,uuid,uuid,numeric,text,text,uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.sias_stock_adjust(uuid,uuid,uuid,numeric,text,text,uuid,text,uuid) to service_role;
revoke all on function public.sias_post_document(uuid,uuid,uuid) from public,anon,authenticated;
grant execute on function public.sias_post_document(uuid,uuid,uuid) to service_role;

create or replace function public.sias_v315_price_lists(p_company uuid,p_user uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_rows jsonb;
begin
  perform public.sias_v3_guard(p_company,p_user,'PRODUCT_VIEW');
  select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v_rows from (
    select l.*, (select count(*) from public.sias_price_list_items i
      where i.company_id=p_company and i.price_list_id=l.id) as item_count
    from public.sias_price_lists l where l.company_id=p_company order by l.name,l.id
    limit 2000
  ) x;
  return jsonb_build_object('rows',v_rows);
end $$;

create or replace function public.sias_v3_price_save(p_company uuid,p_user uuid,p_payload jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid:=nullif(p_payload->>'id','')::uuid; x jsonb;
  v_remove jsonb:=coalesce(p_payload->'remove_product_ids','[]'::jsonb);
begin
  perform public.sias_v3_guard(p_company,p_user,'PRODUCT_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
  if length(btrim(coalesce(p_payload->>'name','')))=0
    or jsonb_typeof(p_payload->'items') is distinct from 'array'
    or jsonb_typeof(v_remove) is distinct from 'array'
    or jsonb_array_length(p_payload->'items')>2000 or jsonb_array_length(v_remove)>500
  then raise exception 'LISTA_PRECIOS_INVALIDA'; end if;
  if (select count(*) from jsonb_array_elements(p_payload->'items'))<>
     (select count(distinct (value->>'product_id')::uuid) from jsonb_array_elements(p_payload->'items'))
  then raise exception 'PRECIO_PRODUCTO_REPETIDO'; end if;
  for x in select value from jsonb_array_elements(p_payload->'items') loop
    if not exists(select 1 from public.sias_products where id=(x->>'product_id')::uuid and company_id=p_company)
      or nullif(x->>'price','') is null or (x->>'price')::numeric<0
      or (x->>'price')::numeric::text in ('NaN','Infinity','-Infinity')
      or exists(select 1 from jsonb_array_elements_text(v_remove) r where r::uuid=(x->>'product_id')::uuid)
    then raise exception 'PRECIO_PRODUCTO_INVALIDO'; end if;
  end loop;
  for x in select value from jsonb_array_elements(v_remove) loop
    if not exists(select 1 from public.sias_products where id=(x#>>'{}')::uuid and company_id=p_company)
    then raise exception 'PRECIO_PRODUCTO_INVALIDO'; end if;
  end loop;
  if v_id is not null then
    if not exists(select 1 from public.sias_price_lists where id=v_id and company_id=p_company)
    then raise exception 'LISTA_PRECIOS_NO_ENCONTRADA'; end if;
    update public.sias_price_lists set name=left(btrim(p_payload->>'name'),120),
      active=coalesce((p_payload->>'active')::boolean,true) where id=v_id;
  else
    insert into public.sias_price_lists(company_id,name,active)
    values(p_company,left(btrim(p_payload->>'name'),120),coalesce((p_payload->>'active')::boolean,true)) returning id into v_id;
  end if;
  -- Solo se eliminan los precios que el editor pidió retirar expresamente.
  delete from public.sias_price_list_items where company_id=p_company and price_list_id=v_id
    and product_id in (select (value#>>'{}')::uuid from jsonb_array_elements(v_remove));
  for x in select value from jsonb_array_elements(p_payload->'items') loop
    insert into public.sias_price_list_items(company_id,price_list_id,product_id,price)
    values(p_company,v_id,(x->>'product_id')::uuid,(x->>'price')::numeric)
    on conflict(price_list_id,product_id) do update set price=excluded.price;
  end loop;
  insert into public.sias_audit(company_id,user_id,module,action,entity,entity_id,detail)
  values(p_company,p_user,'PRODUCTS','PRICE_LIST_SAVE','sias_price_lists',v_id,
    jsonb_build_object('name',p_payload->>'name','items',jsonb_array_length(p_payload->'items'),'removed',jsonb_array_length(v_remove)));
  return v_id;
end $$;

revoke all on function public.sias_v315_price_lists(uuid,uuid) from public,anon,authenticated;
grant execute on function public.sias_v315_price_lists(uuid,uuid) to service_role;
revoke all on function public.sias_v3_price_save(uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.sias_v3_price_save(uuid,uuid,jsonb) to service_role;

commit;


-- 3.1.6: cargas de hasta 100.000 filas. Cada lote se aplica atómicamente.
begin;
create or replace function public.sias_import_schema() returns jsonb language sql immutable as $schema$
select $manifest${"version":"3.1.6","maxRows":100000,"maxFileBytes":52428800,"maxCells":2000000,"tables":[{"key":"Empresa","db":"sias_companies","permission":"COMPANY_MANAGE","singleton":true,"fields":{"rut":{"label":"RUT","type":"rut","maxLength":30},"legal_name":{"label":"Razón social","type":"text","maxLength":180,"required":true},"trade_name":{"label":"Nombre comercial","type":"text","maxLength":160},"business_activity":{"label":"Giro","type":"text","maxLength":200},"email":{"label":"Correo","type":"email","maxLength":240},"phone":{"label":"Teléfono","type":"text","maxLength":40},"address":{"label":"Dirección","type":"text","maxLength":300},"commune":{"label":"Comuna","type":"text","maxLength":100},"city":{"label":"Ciudad","type":"text","maxLength":100},"region":{"label":"Región","type":"text","maxLength":100},"website":{"label":"Sitio web","type":"url"},"logo_url":{"label":"Logo URL","type":"url"}}},{"key":"Bodegas","db":"sias_warehouses","permission":"INVENTORY_MANAGE","identity":["code"],"fields":{"code":{"label":"Código bodega","type":"text","maxLength":40,"required":true},"name":{"label":"Nombre","type":"text","maxLength":160,"required":true},"address":{"label":"Dirección","type":"text","maxLength":300},"commune":{"label":"Comuna","type":"text","maxLength":100},"city":{"label":"Ciudad","type":"text","maxLength":100},"active":{"label":"Activo","type":"bool"}}},{"key":"Proveedores","db":"sias_suppliers","permission":"SUPPLIER_MANAGE","identity":["rut","import_code"],"fields":{"import_code":{"label":"Código proveedor","type":"text","maxLength":80},"rut":{"label":"RUT","type":"rut","maxLength":30},"legal_name":{"label":"Razón social","type":"text","maxLength":180,"required":true},"trade_name":{"label":"Nombre comercial","type":"text","maxLength":160},"business_activity":{"label":"Giro","type":"text","maxLength":200},"email":{"label":"Correo","type":"email","maxLength":240},"phone":{"label":"Teléfono","type":"text","maxLength":40},"address":{"label":"Dirección","type":"text","maxLength":300},"commune":{"label":"Comuna","type":"text","maxLength":100},"city":{"label":"Ciudad","type":"text","maxLength":100},"contact_name":{"label":"Contacto","type":"text","maxLength":160},"active":{"label":"Activo","type":"bool"},"notes":{"label":"Notas","type":"text","maxLength":2000}}},{"key":"Clientes","db":"sias_customers","permission":"CUSTOMER_MANAGE","identity":["rut","import_code"],"fields":{"import_code":{"label":"Código cliente","type":"text","maxLength":80},"rut":{"label":"RUT","type":"rut","maxLength":30},"legal_name":{"label":"Razón social","type":"text","maxLength":180,"required":true},"trade_name":{"label":"Nombre comercial","type":"text","maxLength":160},"business_activity":{"label":"Giro","type":"text","maxLength":200},"email":{"label":"Correo","type":"email","maxLength":240},"phone":{"label":"Teléfono","type":"text","maxLength":40},"address":{"label":"Dirección","type":"text","maxLength":300},"commune":{"label":"Comuna","type":"text","maxLength":100},"city":{"label":"Ciudad","type":"text","maxLength":100},"contact_name":{"label":"Contacto","type":"text","maxLength":160},"active":{"label":"Activo","type":"bool"},"notes":{"label":"Notas","type":"text","maxLength":2000},"region":{"label":"Región","type":"text","maxLength":100},"credit_limit":{"label":"Límite crédito","type":"number","min":0,"max":1000000000000},"wholesale":{"label":"Mayorista","type":"bool"}}},{"key":"Responsables","db":"sias_staff","permission":"SETTINGS_MANAGE","identity":["import_code","name"],"fields":{"import_code":{"label":"Código responsable","type":"text","maxLength":80},"name":{"label":"Nombre","type":"text","maxLength":160,"required":true},"roles":{"label":"Funciones","type":"roles"},"active":{"label":"Activo","type":"bool"}}},{"key":"Productos","db":"sias_products","permission":"PRODUCT_MANAGE","identity":["sku"],"fields":{"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"name":{"label":"Nombre","type":"text","maxLength":180,"required":true},"barcode":{"label":"Código barras","type":"text","maxLength":80},"description":{"label":"Descripción","type":"text","maxLength":2000},"category":{"label":"Categoría","type":"text","maxLength":120},"brand":{"label":"Marca","type":"text","maxLength":120},"unit":{"label":"Unidad","type":"unit"},"product_kind":{"label":"Tipo producto","type":"kind"},"cost":{"label":"Costo","type":"number","min":0,"max":1000000000000},"price":{"label":"Precio venta","type":"number","min":0,"max":1000000000000},"wholesale_price":{"label":"Precio mayorista","type":"number","min":0,"max":1000000000000},"tax_rate":{"label":"IVA porcentaje","type":"number","min":0,"max":100},"exempt":{"label":"Exento","type":"bool"},"min_stock":{"label":"Stock mínimo","type":"number","min":0,"max":1000000},"max_stock":{"label":"Stock máximo","type":"number","min":0,"max":1000000},"pack_quantity":{"label":"Cantidad por caja","type":"number","min":0.0001,"max":1000000},"pallet_boxes":{"label":"Cajas por pallet","type":"integer","min":1,"max":1000000},"weight_kg":{"label":"Peso kg","type":"number","min":0,"max":1000000},"length_cm":{"label":"Largo cm","type":"number","min":0,"max":1000000},"width_cm":{"label":"Ancho cm","type":"number","min":0,"max":1000000},"height_cm":{"label":"Alto cm","type":"number","min":0,"max":1000000},"fractional":{"label":"Fraccionable","type":"bool"},"image_url":{"label":"Imagen URL","type":"url"},"featured":{"label":"Destacado","type":"bool"},"public_visible":{"label":"Visible tienda","type":"bool"},"active":{"label":"Activo","type":"bool"},"parent_sku":{"label":"SKU padre","type":"text","maxLength":80,"virtual":true},"supplier_rut":{"label":"RUT proveedor","type":"rut","virtual":true}}},{"key":"Atributos","db":"sias_products","permission":"PRODUCT_MANAGE","special":true,"fields":{"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"attribute":{"label":"Atributo","type":"text","maxLength":80,"required":true},"value":{"label":"Valor","type":"text","maxLength":300,"required":true}}},{"key":"ListasPrecios","db":"sias_price_lists","permission":"PRODUCT_MANAGE","identity":["import_code","name"],"fields":{"import_code":{"label":"Código lista","type":"text","maxLength":80},"name":{"label":"Nombre lista","type":"text","maxLength":160,"required":true},"active":{"label":"Activo","type":"bool"}}},{"key":"Precios","db":"sias_price_list_items","permission":"PRODUCT_MANAGE","special":true,"fields":{"list":{"label":"Lista","type":"text","maxLength":160,"required":true},"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"price":{"label":"Precio","type":"number","min":0,"max":1000000000000,"required":true}}},{"key":"Recetas","db":"sias_product_recipe","permission":"PRODUCT_MANAGE","special":true,"fields":{"sku":{"label":"SKU producto","type":"text","maxLength":80,"required":true},"supply_sku":{"label":"SKU insumo","type":"text","maxLength":80,"required":true},"quantity":{"label":"Cantidad","type":"number","min":0.0001,"max":1000000,"required":true},"unit":{"label":"Unidad","type":"unit"}}},{"key":"StockInicial","db":"sias_stock","permission":"INVENTORY_MANAGE","special":true,"fields":{"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"warehouse":{"label":"Bodega","type":"text","maxLength":40,"required":true},"quantity":{"label":"Cantidad","type":"number","min":0,"max":1000000,"required":true}}},{"key":"Documentos","db":"sias_documents","permission":"SALES_MANAGE","special":true,"fields":{"import_code":{"label":"Referencia","type":"text","maxLength":100,"required":true},"document_type":{"label":"Tipo documento","type":"document","required":true},"issue_date":{"label":"Fecha","type":"date","required":true},"due_date":{"label":"Vencimiento","type":"date"},"customer_rut":{"label":"RUT cliente","type":"rut","virtual":true},"supplier_rut":{"label":"RUT proveedor","type":"rut","virtual":true},"warehouse":{"label":"Bodega","type":"text","maxLength":40,"virtual":true},"notes":{"label":"Notas","type":"text","maxLength":2000}}},{"key":"DetalleDocumentos","db":"sias_document_items","permission":"SALES_MANAGE","special":true,"fields":{"document":{"label":"Referencia documento","type":"text","maxLength":100,"required":true},"line_no":{"label":"Línea","type":"integer","min":1,"max":200,"required":true},"sku":{"label":"SKU","type":"text","maxLength":80,"required":true},"quantity":{"label":"Cantidad","type":"number","min":0.0001,"max":1000000,"required":true},"unit_price":{"label":"Precio unitario","type":"number","min":0,"max":1000000000000},"discount":{"label":"Descuento","type":"number","min":0,"max":1000000000000},"tax_rate":{"label":"IVA porcentaje","type":"number","min":0,"max":100},"exempt":{"label":"Exento","type":"bool"}}},{"key":"RCV","db":"sias_rcv_rows","permission":"RCV_MANAGE","special":true,"fields":{"book":{"label":"Libro","type":"book","required":true},"document_type":{"label":"Tipo DTE","type":"integer","min":1,"max":999,"required":true},"folio":{"label":"Folio","type":"text","maxLength":80,"required":true},"rut":{"label":"RUT","type":"rut","required":true},"legal_name":{"label":"Razón social","type":"text","maxLength":180},"issue_date":{"label":"Fecha","type":"date","required":true},"net":{"label":"Neto","type":"number","min":0,"max":1000000000000},"exempt":{"label":"Exento","type":"number","min":0,"max":1000000000000},"tax":{"label":"IVA","type":"number","min":0,"max":1000000000000},"total":{"label":"Total","type":"number","min":0,"max":1000000000000,"required":true}}},{"key":"Tienda","db":"sias_store_settings","permission":"SETTINGS_MANAGE","singleton":true,"fields":{"slug":{"label":"Identificador tienda","type":"text","maxLength":100,"required":true},"enabled":{"label":"Habilitada","type":"bool"},"title":{"label":"Título","type":"text","maxLength":160},"tagline":{"label":"Subtítulo","type":"text","maxLength":300},"hero_title":{"label":"Título principal","type":"text","maxLength":160},"hero_text":{"label":"Texto principal","type":"text","maxLength":2000},"about_title":{"label":"Título nosotros","type":"text","maxLength":160},"about_text":{"label":"Texto nosotros","type":"text","maxLength":4000},"delivery_text":{"label":"Texto despacho","type":"text","maxLength":4000},"terms":{"label":"Condiciones","type":"text","maxLength":6000},"logo_url":{"label":"Logo URL","type":"url"},"hero_image":{"label":"Imagen principal URL","type":"url"},"primary_color":{"label":"Color principal","type":"color"},"whatsapp":{"label":"WhatsApp","type":"text","maxLength":40},"contact_email":{"label":"Correo contacto","type":"email"},"contact_address":{"label":"Dirección contacto","type":"text","maxLength":300},"allow_orders":{"label":"Permitir pedidos","type":"bool"},"show_stock":{"label":"Mostrar stock","type":"bool"},"hide_unavailable":{"label":"Ocultar agotados","type":"bool"},"warehouse":{"label":"Bodega","type":"text","maxLength":40,"virtual":true}}},{"key":"Folios","db":"sias_sequences","permission":"SETTINGS_MANAGE","special":true,"fields":{"code":{"label":"Código","type":"text","maxLength":50,"required":true},"prefix":{"label":"Prefijo","type":"text","maxLength":30},"current_value":{"label":"Último número","type":"integer","min":0,"max":1000000000,"required":true},"padding":{"label":"Dígitos","type":"integer","min":1,"max":12}}}],"maxExpandedBytes":209715200,"batchRows":500,"atomicRows":5000}$manifest$::jsonb
$schema$;
create table if not exists public.sias_import_jobs(
 id uuid primary key, company_id uuid not null references sias_companies(id),user_id uuid not null references sias_users(id),
 filename text not null,file_hash text not null,mode text not null,strategy text not null,total_rows integer not null check(total_rows between 1 and 100000),
 uploaded_rows integer not null default 0,processed_rows integer not null default 0,total_bytes bigint not null default 0,last_rank integer not null default 0,
 status text not null default 'UPLOADING' check(status in ('UPLOADING','READY','RUNNING','FAILED','COMPLETED','CANCELLED')),
 baseline text,summary jsonb not null default '{}',last_error jsonb,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),expires_at timestamptz not null default now()+interval '24 hours',completed_at timestamptz,
 check(processed_rows<=uploaded_rows and uploaded_rows<=total_rows)
);
create table if not exists public.sias_import_job_rows(
 job_id uuid not null references sias_import_jobs(id) on delete cascade,ord integer not null,sheet text not null,source text not null,row_no integer not null,
 values_json jsonb not null,identity text not null,primary key(job_id,ord),unique(job_id,sheet,identity)
);
create table if not exists public.sias_import_job_uploads(
 job_id uuid not null references sias_import_jobs(id) on delete cascade,offset_row integer not null,row_count integer not null,payload_hash text not null,
 primary key(job_id,offset_row)
);
create index if not exists sias_import_jobs_owner_date on public.sias_import_jobs(company_id,user_id,created_at desc);
create index if not exists sias_import_rows_sku on public.sias_import_job_rows(job_id,sheet,lower(btrim(values_json->>'sku')));
create index if not exists sias_import_rows_code on public.sias_import_job_rows(job_id,sheet,lower(btrim(values_json->>'code')));
create index if not exists sias_import_rows_import_code on public.sias_import_job_rows(job_id,sheet,lower(btrim(values_json->>'import_code')));
create index if not exists sias_import_rows_rut on public.sias_import_job_rows(job_id,sheet,lower(replace(replace(values_json->>'rut','.',''),' ','')));
create index if not exists sias_import_rows_name on public.sias_import_job_rows(job_id,sheet,lower(btrim(values_json->>'name')));
create unique index if not exists sias_import_rows_rut_unique on public.sias_import_job_rows(job_id,sheet,lower(values_json->>'rut')) where sheet in ('Clientes','Proveedores') and values_json?'rut';
create unique index if not exists sias_import_rows_code_unique on public.sias_import_job_rows(job_id,sheet,lower(values_json->>'import_code')) where values_json?'import_code';
create unique index if not exists sias_import_rows_barcode_unique on public.sias_import_job_rows(job_id,(values_json->>'barcode')) where sheet='Productos' and nullif(values_json->>'barcode','') is not null;
-- Las expresiones coinciden con el buscador de claves del importador.
do $$declare t text;k text;begin
 foreach t in array array['sias_products','sias_customers','sias_suppliers','sias_warehouses','sias_staff','sias_price_lists','sias_documents','sias_sequences'] loop
  for k in select column_name from information_schema.columns where table_schema='public' and table_name=t and column_name in ('sku','import_code','name','code','rut') loop
   if k='rut' then execute format('create index if not exists %I on public.%I(company_id,lower(replace(replace(rut,''.'',''''),'' '','''')))',t||'_bulk_rut',t);
   else execute format('create index if not exists %I on public.%I(company_id,lower(btrim(%I)))',t||'_bulk_'||k,t,k);end if;
  end loop;
 end loop;
end $$;
alter table public.sias_import_jobs enable row level security;
alter table public.sias_import_job_rows enable row level security;
alter table public.sias_import_job_uploads enable row level security;
revoke all on public.sias_import_jobs,public.sias_import_job_rows,public.sias_import_job_uploads from public,anon,authenticated;
grant all on public.sias_import_jobs,public.sias_import_job_rows,public.sias_import_job_uploads to service_role;

create or replace function public.sias_import_job_public(p_job uuid) returns jsonb language sql security definer set search_path=public as $$
select to_jsonb(j)-'baseline'-'total_bytes'-'last_rank' from sias_import_jobs j where id=p_job
$$;

create or replace function public.sias_import_job_values(p_company uuid,p_user uuid,p_sheet text,p_mode text,p_values jsonb)
returns text language plpgsql security definer set search_path=public as $$
declare t jsonb;f record;k text;typ text;n numeric;identity text;
begin
 select value into t from jsonb_array_elements(sias_import_schema()->'tables') where value->>'key'=p_sheet;
 if t is null or not(p_mode='General' or p_sheet=p_mode or p_mode='Productos' and p_sheet='Atributos' or p_mode='Precios' and p_sheet in ('ListasPrecios','Precios')) then raise exception 'HOJA_NO_PERMITIDA';end if;
 perform sias_v3_guard(p_company,p_user,t->>'permission');
 if jsonb_typeof(p_values) is distinct from 'object' then raise exception 'FILA_INVALIDA';end if;
 for k in select jsonb_object_keys(p_values) loop if not(t->'fields'?k) then raise exception 'COLUMNA_NO_PERMITIDA: %',k;end if;end loop;
 for f in select key,value from jsonb_each(t->'fields') loop
  k:=f.key;typ:=f.value->>'type';
  if coalesce((f.value->>'required')::boolean,false) and (not(p_values?k) or nullif(p_values->>k,'') is null) then raise exception 'CAMPO_OBLIGATORIO: %',k;end if;
  if not(p_values?k) then continue;end if;
  if p_values->k='null'::jsonb then raise exception 'VALOR_NULO_NO_PERMITIDO: %',k;end if;
  if typ in ('number','integer') then
   if jsonb_typeof(p_values->k)<>'number' then raise exception 'NUMERO_INVALIDO: %',k;end if;n:=(p_values->>k)::numeric;
   if n<coalesce((f.value->>'min')::numeric,-1e12) or n>coalesce((f.value->>'max')::numeric,1e12) or typ='integer' and n<>trunc(n) then raise exception 'NUMERO_FUERA_DE_RANGO: %',k;end if;
  elsif typ='bool' then if jsonb_typeof(p_values->k)<>'boolean' then raise exception 'BOOLEANO_INVALIDO: %',k;end if;
  elsif typ='roles' then if jsonb_typeof(p_values->k)<>'array' or jsonb_array_length(p_values->k)<1 or exists(select 1 from jsonb_array_elements_text(p_values->k) x where x<>all(array['SELLER','PREPARER','PACKER','CASHIER'])) then raise exception 'FUNCIONES_INVALIDAS';end if;
  else
   if jsonb_typeof(p_values->k)<>'string' or length(p_values->>k)>coalesce((f.value->>'maxLength')::integer,6000) then raise exception 'TEXTO_INVALIDO: %',k;end if;
   if typ='date' then if p_values->>k !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'FECHA_INVALIDA';end if;perform (p_values->>k)::date;end if;
   if typ='unit' and p_values->>k<>all(array['UN','KG','GR','LT','ML','MT','CM','CAJA','PALLET']) then raise exception 'UNIDAD_INVALIDA';end if;
   if typ='kind' and p_values->>k<>all(array['PRODUCT','SUPPLY']) then raise exception 'TIPO_PRODUCTO_INVALIDO';end if;
   if typ='book' and p_values->>k<>all(array['SALES','PURCHASES']) then raise exception 'LIBRO_INVALIDO';end if;
   if typ='document' and p_values->>k<>all(array['QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','DELIVERY']) then raise exception 'TIPO_DOCUMENTO_NO_PERMITIDO';end if;
   if typ='rut' and p_values->>k !~ '^[0-9]{1,12}-[0-9Kk]$' then raise exception 'RUT_INVALIDO';end if;
   if typ='url' and p_values->>k !~ '^https?://' then raise exception 'URL_INVALIDA';end if;
   if typ='email' and p_values->>k !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' then raise exception 'CORREO_INVALIDO';end if;
   if typ='color' and p_values->>k !~ '^#[0-9a-fA-F]{6}$' then raise exception 'COLOR_INVALIDO';end if;
  end if;
 end loop;
 identity:=case p_sheet
 when 'Empresa' then 'empresa' when 'Tienda' then 'tienda'
 when 'Productos' then p_values->>'sku' when 'Bodegas' then p_values->>'code' when 'Folios' then p_values->>'code'
 when 'Clientes' then coalesce(p_values->>'rut',p_values->>'import_code') when 'Proveedores' then coalesce(p_values->>'rut',p_values->>'import_code')
 when 'Responsables' then coalesce(p_values->>'import_code',p_values->>'name') when 'ListasPrecios' then coalesce(p_values->>'import_code',p_values->>'name')
 when 'Documentos' then p_values->>'import_code' when 'Precios' then (p_values->>'list')||'|'||(p_values->>'sku')
 when 'Atributos' then (p_values->>'sku')||'|'||(p_values->>'attribute') when 'Recetas' then (p_values->>'sku')||'|'||(p_values->>'supply_sku')
 when 'StockInicial' then (p_values->>'warehouse')||'|'||(p_values->>'sku') when 'DetalleDocumentos' then (p_values->>'document')||'|'||(p_values->>'line_no')
 when 'RCV' then (p_values->>'book')||'|'||(p_values->>'document_type')||'|'||(p_values->>'rut')||'|'||(p_values->>'folio') end;
 if nullif(btrim(identity),'') is null then raise exception 'CLAVE_REQUERIDA';end if;return lower(btrim(identity));
end $$;

create or replace function public.sias_import_job_ref(p_company uuid,p_job uuid,p_table text,p_keys jsonb,p_before integer default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare s text;r record;w text:='';yes boolean;
begin
 s:=case p_table when 'sias_products' then 'Productos' when 'sias_customers' then 'Clientes' when 'sias_suppliers' then 'Proveedores' when 'sias_warehouses' then 'Bodegas' when 'sias_documents' then 'Documentos' when 'sias_price_lists' then 'ListasPrecios' end;
 if s is null then raise exception 'TABLA_NO_PERMITIDA';end if;
 if sias_import_lookup(p_company,p_table,p_keys) is not null then return true;end if;
 for r in select key,value from jsonb_each_text(p_keys) loop
  if r.key<>all(array['sku','rut','code','import_code','name']) then raise exception 'CLAVE_NO_PERMITIDA';end if;
  w:=w||case when w='' then '' else ' or ' end||case when r.key='rut' then format('lower(replace(replace(values_json->>%L,''.'',''''),'' '',''''))=lower(replace(replace(%L,''.'',''''),'' '',''''))',r.key,r.value) else format('lower(btrim(values_json->>%L))=lower(btrim(%L))',r.key,r.value) end;
 end loop;
 if w='' then return false;end if;
 execute 'select exists(select 1 from sias_import_job_rows where job_id=$1 and sheet=$2 and ($3 is null or ord<$3) and ('||w||'))' into yes using p_job,s,p_before;return yes;
end $$;

-- Motor privado de un lote: mantiene las reglas del importador transaccional
-- sin recalcular una huella de toda la empresa para cada 500 filas.
create or replace function public.sias_import_apply_chunk(p_company uuid,p_user uuid,p_data jsonb,p_mode text,p_strategy text,p_preview boolean,p_expected text default null,p_batch uuid default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare rr record;r jsonb;t jsonb;f record;v jsonb;original jsonb;old jsonb;olditem jsonb;keys jsonb;sid uuid;pid uuid;wid uuid;did uuid;lid uuid;refid uuid;
 field_name text;typ text;n numeric;amount numeric;rate numeric;ex boolean;oldqty numeric;table_name text;sheet_name text;source_name text;row_no integer;
 baseline text;detail text;summary jsonb:='{}';seen jsonb:='{}';identity text;ids uuid[]:='{}';outcome text;result jsonb;dtype text;
begin
 perform sias_v3_guard(p_company,p_user,'IMPORT_MANAGE');
 if p_mode<>all(array['General','Productos','Clientes','Precios']) or p_strategy<>all(array['UPSERT','CREATE']) or jsonb_typeof(p_data)<>'array' or jsonb_array_length(p_data)<1 or jsonb_array_length(p_data)>5000 or octet_length(p_data::text)>10485760 then raise exception 'ARCHIVO_INVALIDO_O_MUY_GRANDE';end if;
 perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
 baseline:=null;
 if false then return jsonb_build_object('ok',false,'errors',jsonb_build_array(jsonb_build_object('sheet','Archivo','row',0,'column','Vista previa','message','Los datos cambiaron desde la revisión. Vuelve a validar antes de confirmar.')));end if;
 begin
 for rr in select d.value from jsonb_array_elements(p_data) with ordinality d(value,ord)
  left join jsonb_array_elements(sias_import_schema()->'tables') with ordinality s(value,ord) on s.value->>'key'=d.value->>'sheet' order by s.ord,d.ord loop
  r:=rr.value;sheet_name:=r->>'sheet';source_name:=coalesce(r->>'source',sheet_name);row_no:=coalesce((r->>'row')::integer,0);field_name:='';
  select value into t from jsonb_array_elements(sias_import_schema()->'tables') where value->>'key'=sheet_name;
  if t is null or (p_mode<>'General' and not(sheet_name=p_mode or p_mode='Productos' and sheet_name='Atributos' or p_mode='Precios' and sheet_name in ('ListasPrecios','Precios'))) then raise exception 'HOJA_NO_PERMITIDA';end if;
  perform sias_v3_guard(p_company,p_user,t->>'permission');
  original:=r->'values';v:=original;table_name:=t->>'db';if jsonb_typeof(v)<>'object' then raise exception 'FILA_INVALIDA';end if;
  for field_name in select jsonb_object_keys(v) loop if not(t->'fields'?field_name) then raise exception 'COLUMNA_NO_PERMITIDA: %',field_name;end if;end loop;
  for f in select key,value from jsonb_each(t->'fields') loop
   field_name:=f.key;typ:=f.value->>'type';
   if coalesce((f.value->>'required')::boolean,false) and (not(v?field_name) or v->field_name='null'::jsonb or nullif(v->>field_name,'') is null) then raise exception 'CAMPO_OBLIGATORIO: %',field_name;end if;
   if not(v?field_name) then continue;end if;
   if v->field_name='null'::jsonb then raise exception 'VALOR_NULO_NO_PERMITIDO';end if;
   if typ in ('number','integer') then
    if jsonb_typeof(v->field_name)<>'number' then raise exception 'NUMERO_INVALIDO';end if;n:=(v->>field_name)::numeric;
    if n<coalesce((f.value->>'min')::numeric,-1e12) or n>coalesce((f.value->>'max')::numeric,1e12) or typ='integer' and n<>trunc(n) then raise exception 'NUMERO_FUERA_DE_RANGO';end if;
   elsif typ='bool' then if jsonb_typeof(v->field_name)<>'boolean' then raise exception 'BOOLEANO_INVALIDO';end if;
   elsif typ='roles' then if jsonb_typeof(v->field_name)<>'array' or jsonb_array_length(v->field_name)<1 or exists(select 1 from jsonb_array_elements_text(v->field_name) x where x<>all(array['SELLER','PREPARER','PACKER','CASHIER'])) then raise exception 'FUNCIONES_INVALIDAS';end if;
   else
    if jsonb_typeof(v->field_name)<>'string' or length(v->>field_name)>coalesce((f.value->>'maxLength')::integer,6000) then raise exception 'TEXTO_INVALIDO';end if;
    if typ='date' then if v->>field_name !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'FECHA_INVALIDA';end if;perform (v->>field_name)::date;end if;
    if typ='unit' and v->>field_name<>all(array['UN','KG','GR','LT','ML','MT','CM','CAJA','PALLET']) then raise exception 'UNIDAD_INVALIDA';end if;
    if typ='kind' and v->>field_name<>all(array['PRODUCT','SUPPLY']) then raise exception 'TIPO_PRODUCTO_INVALIDO';end if;
    if typ='book' and v->>field_name<>all(array['SALES','PURCHASES']) then raise exception 'LIBRO_INVALIDO';end if;
    if typ='rut' and v->>field_name !~ '^[0-9]{1,12}-[0-9Kk]$' then raise exception 'RUT_INVALIDO';end if;
    if typ='url' and v->>field_name !~ '^https?://' then raise exception 'URL_INVALIDA';end if;
    if typ='email' and v->>field_name !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' then raise exception 'CORREO_INVALIDO';end if;
    if typ='color' and v->>field_name !~ '^#[0-9a-fA-F]{6}$' then raise exception 'COLOR_INVALIDO';end if;
   end if;
  end loop;field_name:='Clave';sid:=null;keys:='{}';old:=null;
  if coalesce((t->>'singleton')::boolean,false) then identity:=sheet_name;
  elsif sheet_name in ('Productos','Bodegas','Folios','Documentos') then keys:=jsonb_build_object(case sheet_name when 'Productos' then 'sku' when 'Bodegas' then 'code' when 'Folios' then 'code' else 'import_code' end,v->case sheet_name when 'Productos' then 'sku' when 'Bodegas' then 'code' when 'Folios' then 'code' else 'import_code' end);identity:=keys::text;
  elsif sheet_name in ('Clientes','Proveedores') then keys:=jsonb_strip_nulls(jsonb_build_object('rut',v->'rut','import_code',v->'import_code'));if keys='{}' then raise exception 'RUT_O_CODIGO_REQUERIDO';end if;identity:=keys::text;
  elsif sheet_name in ('Responsables','ListasPrecios') then keys:=jsonb_strip_nulls(jsonb_build_object('import_code',v->'import_code','name',case when not(v?'import_code') then v->'name' end));identity:=keys::text;
  else identity:=case sheet_name when 'Precios' then (v->>'list')||'|'||(v->>'sku') when 'Atributos' then (v->>'sku')||'|'||(v->>'attribute') when 'Recetas' then (v->>'sku')||'|'||(v->>'supply_sku') when 'StockInicial' then (v->>'warehouse')||'|'||(v->>'sku') when 'DetalleDocumentos' then (v->>'document')||'|'||(v->>'line_no') when 'RCV' then (v->>'book')||'|'||(v->>'document_type')||'|'||(v->>'rut')||'|'||(v->>'folio') end;end if;
  identity:=sheet_name||'|'||lower(identity);if seen?identity then raise exception 'REGISTRO_DUPLICADO';end if;seen:=seen||jsonb_build_object(identity,true);
  if keys<>'{}' then sid:=sias_import_lookup(p_company,table_name,keys);end if;
  if sheet_name='Empresa' then sid:=p_company;end if;
  if sheet_name='Tienda' then select company_id into sid from sias_store_settings where company_id=p_company;end if;
  if sid is not null and sheet_name='Tienda' then select to_jsonb(x) into old from sias_store_settings x where company_id=p_company for update;elsif sid is not null then execute format('select to_jsonb(x) from public.%I x where id=$1 for update',table_name) into old using sid;end if;
  if sid is not null and not coalesce((t->>'special')::boolean,false) and seen?(sheet_name||'|id:'||sid::text) then raise exception 'REGISTRO_DUPLICADO_POR_CLAVE';end if;
  outcome:=case when sid is null then 'created' else 'updated' end;
  if sid is not null and p_strategy='CREATE' then outcome:='skipped';
  elsif sheet_name='Productos' then
   field_name:='SKU padre';if v?'parent_sku' then pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'parent_sku'));if pid is null then raise exception 'SKU_PADRE_NO_EXISTE';end if;v:=v||jsonb_build_object('parent_product_id',pid);end if;
   field_name:='RUT proveedor';if v?'supplier_rut' then pid:=sias_import_lookup(p_company,'sias_suppliers',jsonb_build_object('rut',v->'supplier_rut'));if pid is null then raise exception 'PROVEEDOR_NO_EXISTE';end if;v:=v||jsonb_build_object('supplier_id',pid);end if;
   v:=coalesce(old,'{}')||(v-'parent_sku'-'supplier_rut');sid:=sias_v3_save_product(p_company,p_user,v);
  elsif sheet_name='Atributos' then
   sid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));if sid is null then raise exception 'SKU_NO_EXISTE';end if;
   select to_jsonb(p) into old from sias_products p where id=sid for update;
   if p_strategy='CREATE' and old->'attributes'?((v->>'attribute')) then outcome:='skipped';else perform sias_v3_save_product(p_company,p_user,old||jsonb_build_object('attributes',coalesce(old->'attributes','{}')||jsonb_build_object((v->>'attribute'),v->'value')));outcome:='updated';end if;
  elsif sheet_name='Precios' then
   pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));lid:=sias_import_lookup(p_company,'sias_price_lists',jsonb_build_object('import_code',v->'list','name',v->'list'));
   if pid is null or lid is null then raise exception 'SKU_O_LISTA_NO_EXISTE';end if;
   select id into sid from sias_price_list_items where company_id=p_company and product_id=pid and price_list_id=lid for update;
   if sid is not null and p_strategy='CREATE' then outcome:='skipped';else outcome:=case when sid is null then 'created' else 'updated' end;sid:=sias_import_write(p_company,table_name,sid,jsonb_build_object('product_id',pid,'price_list_id',lid,'price',v->'price'));end if;
  elsif sheet_name='Recetas' then
   pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));refid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'supply_sku'));
   if pid is null or refid is null or pid=refid or not exists(select 1 from sias_products where id=refid and product_kind='SUPPLY' and active) then raise exception 'PRODUCTO_O_INSUMO_INVALIDO';end if;
   select id into sid from sias_product_recipe where company_id=p_company and product_id=pid and supply_id=refid for update;
   if sid is not null and p_strategy='CREATE' then outcome:='skipped';else outcome:=case when sid is null then 'created' else 'updated' end;
    select unit into typ from sias_products where id=refid;if v?'unit' then perform sias_unit_factor((v->>'unit'),typ);else v:=v||jsonb_build_object('unit',typ);end if;
    sid:=sias_import_write(p_company,table_name,sid,jsonb_build_object('product_id',pid,'supply_id',refid,'unit',v->'unit','quantity',v->'quantity'));perform sias_recalculate_recipe(p_company,pid,p_user);end if;
  elsif sheet_name='StockInicial' then
   pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));wid:=sias_import_lookup(p_company,'sias_warehouses',jsonb_build_object('code',v->'warehouse'));if pid is null or wid is null then raise exception 'SKU_O_BODEGA_NO_EXISTE';end if;
   if exists(select 1 from sias_stock_movements where company_id=p_company and product_id=pid and warehouse_id=wid and reference_type is distinct from 'IMPORT_INITIAL') then raise exception 'STOCK_CON_OPERACIONES: utiliza ajustes o ingresos';end if;
   select quantity into oldqty from sias_stock where company_id=p_company and product_id=pid and warehouse_id=wid for update;
   if oldqty is not null and p_strategy='CREATE' then outcome:='skipped';else n:=((v->>'quantity'))::numeric-coalesce(oldqty,0);if n<>0 then perform sias_stock_adjust(p_company,wid,pid,n,'APERTURA','IMPORT_INITIAL',p_batch,'Importación de stock inicial',p_user);else insert into sias_stock(company_id,product_id,warehouse_id,quantity) values(p_company,pid,wid,0) on conflict(company_id,warehouse_id,product_id) do nothing;end if;outcome:=case when oldqty is null then 'created' else 'updated' end;end if;
  elsif sheet_name='Documentos' then
   dtype:=(v->>'document_type');if dtype<>all(array['QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','DELIVERY']) then raise exception 'TIPO_DOCUMENTO_NO_PERMITIDO';end if;
   perform sias_v3_guard(p_company,p_user,case when dtype='PURCHASE' then 'PURCHASE_MANAGE' when dtype='WHOLESALE' then 'WHOLESALE_MANAGE' when dtype in ('RECEIPT','ISSUE') then 'INVENTORY_MANAGE' else 'SALES_MANAGE' end);
   if old is not null and ((old->>'status')<>'DRAFT' or (old->>'document_type')<>dtype) then raise exception 'SOLO_BORRADOR_DEL_MISMO_TIPO';end if;
   if v?'customer_rut' then pid:=sias_import_lookup(p_company,'sias_customers',jsonb_build_object('rut',v->'customer_rut'));if pid is null then raise exception 'CLIENTE_NO_EXISTE';end if;v:=v||jsonb_build_object('customer_id',pid);end if;
   if v?'supplier_rut' then pid:=sias_import_lookup(p_company,'sias_suppliers',jsonb_build_object('rut',v->'supplier_rut'));if pid is null then raise exception 'PROVEEDOR_NO_EXISTE';end if;v:=v||jsonb_build_object('supplier_id',pid);end if;
   if v?'warehouse' then wid:=sias_import_lookup(p_company,'sias_warehouses',jsonb_build_object('code',v->'warehouse'));if wid is null then raise exception 'BODEGA_NO_EXISTE';end if;v:=v||jsonb_build_object('warehouse_id',wid);end if;
   v:=v-'customer_rut'-'supplier_rut'-'warehouse';if sid is null then v:=v||jsonb_build_object('number',sias_next_sequence(p_company,dtype),'created_by',p_user,'source','IMPORT');end if;v:=v||jsonb_build_object('updated_by',p_user);sid:=sias_import_write(p_company,table_name,sid,v);ids:=array_append(ids,sid);
  elsif sheet_name='DetalleDocumentos' then
   did:=sias_import_lookup(p_company,'sias_documents',jsonb_build_object('import_code',v->'document'));pid:=sias_import_lookup(p_company,'sias_products',jsonb_build_object('sku',v->'sku'));
   if did is null or pid is null then raise exception 'DOCUMENTO_O_SKU_NO_EXISTE';end if;
   select document_type into dtype from sias_documents where id=did and status='DRAFT' for update;if dtype is null then raise exception 'SOLO_BORRADOR_EDITABLE';end if;
   perform sias_v3_guard(p_company,p_user,case when dtype='PURCHASE' then 'PURCHASE_MANAGE' when dtype='WHOLESALE' then 'WHOLESALE_MANAGE' when dtype in ('RECEIPT','ISSUE') then 'INVENTORY_MANAGE' else 'SALES_MANAGE' end);
   select to_jsonb(p) into old from sias_products p where id=pid and active;if old is null then raise exception 'PRODUCTO_INACTIVO';end if;
   select id into sid from sias_document_items where document_id=did and line_no=((v->>'line_no'))::integer for update;
   if sid is not null and p_strategy='CREATE' then outcome:='skipped';else
    if dtype in ('SALE','WHOLESALE','QUOTE','ORDER','REQUEST','DELIVERY') and old->>'product_kind'='SUPPLY' then raise exception 'INSUMO_NO_DISPONIBLE_PARA_VENTA';end if;
    if old->>'unit'='UN' and not coalesce((old->>'fractional')::boolean,false) and (v->>'quantity')::numeric<>trunc((v->>'quantity')::numeric) then raise exception 'PRODUCTO_REQUIERE_UNIDADES_ENTERAS';end if;
    outcome:=case when sid is null then 'created' else 'updated' end;v:=v||jsonb_build_object('discount',coalesce(v->'discount',olditem->'discount','0'::jsonb),'unit_price',coalesce(v->'unit_price',olditem->'unit_price',old->'price'),'tax_rate',coalesce(v->'tax_rate',olditem->'tax_rate',old->'tax_rate'),'exempt',coalesce(v->'exempt',olditem->'exempt',old->'exempt'));
    amount:=round(((v->>'quantity'))::numeric*((v->>'unit_price'))::numeric)-coalesce(((v->>'discount'))::numeric,0);if amount<0 then raise exception 'DESCUENTO_MAYOR_QUE_TOTAL';end if;
    rate:=((v->>'tax_rate'))::numeric;ex:=((v->>'exempt'))::boolean;n:=case when ex then amount else round(amount/(1+rate/100)) end;
    v:=(v-'document')||jsonb_build_object('document_id',did,'product_id',pid,'description',old->'name','unit',old->'unit','line_total',amount,'line_net',case when ex then 0 else n end,'line_tax',amount-n,'acquisition_cost',case when dtype in ('PURCHASE','RECEIPT') then (v->>'unit_price')::numeric/case when ex then 1 else 1+rate/100 end else null end);sid:=sias_import_write(p_company,table_name,sid,v);ids:=array_append(ids,did);end if;
  elsif sheet_name='RCV' then
   if coalesce(((v->>'net'))::numeric,0)+coalesce(((v->>'exempt'))::numeric,0)+coalesce(((v->>'tax'))::numeric,0)<>((v->>'total'))::numeric then raise exception 'RCV_TOTAL_NO_COINCIDE';end if;
   select id into sid from sias_rcv_rows where company_id=p_company and book=(v->>'book') and document_type=((v->>'document_type'))::integer and folio=(v->>'folio') and rut=(v->>'rut') for update;
   if sid is not null and p_strategy='CREATE' then outcome:='skipped';else outcome:=case when sid is null then 'created' else 'updated' end;v:=jsonb_build_object('net',0,'exempt',0,'tax',0)||v||jsonb_build_object('imported_by',p_user);sid:=sias_import_write(p_company,table_name,sid,v);end if;
  else
   if sheet_name='Folios' and old is not null and ((v->>'current_value'))::bigint<((old->>'current_value'))::bigint then raise exception 'NO_SE_PUEDE_REDUCIR_UN_FOLIO';end if;
   if sheet_name='Tienda' then if (v->>'slug') !~ '^[a-z0-9][a-z0-9-]{1,79}$' then raise exception 'IDENTIFICADOR_TIENDA_INVALIDO';end if;if v?'warehouse' then wid:=sias_import_lookup(p_company,'sias_warehouses',jsonb_build_object('code',v->'warehouse'));if wid is null then raise exception 'BODEGA_NO_EXISTE';end if;v:=(v-'warehouse')||jsonb_build_object('warehouse_id',wid);end if;end if;
   sid:=sias_import_write(p_company,table_name,sid,v);
  end if;
  if sid is not null and not coalesce((t->>'special')::boolean,false) then seen:=seen||jsonb_build_object(sheet_name||'|id:'||sid::text,true);end if;
  summary:=jsonb_set(summary,array[sheet_name],coalesce(summary->sheet_name,'{"created":0,"updated":0,"skipped":0}')||jsonb_build_object(outcome,coalesce((summary->sheet_name->>outcome)::integer,0)+1),true);
 end loop;
 for did in select distinct unnest(ids) loop
  update sias_documents d set net=s.net,exempt=s.exempt,tax=s.tax,discount=s.discount,total=s.total+d.shipping,updated_at=now()
  from (select coalesce(sum(case when exempt then 0 else line_net end),0) net,coalesce(sum(case when exempt then line_total else 0 end),0) exempt,coalesce(sum(line_tax),0) tax,coalesce(sum(discount),0) discount,coalesce(sum(line_total),0) total from sias_document_items where document_id=did) s where d.id=did and d.company_id=p_company;
 end loop;
 result:=jsonb_build_object('ok',true,'summary',summary,'rows',jsonb_array_length(p_data),'baseline',baseline,'errors','[]'::jsonb);
 if p_preview then raise exception using errcode='ZP001',message='PREVIEW_ROLLBACK',detail=result::text;end if;
 return result;
 exception when sqlstate 'ZP001' then get stacked diagnostics detail=PG_EXCEPTION_DETAIL;return detail::jsonb;
 when others then return jsonb_build_object('ok',false,'errors',jsonb_build_array(jsonb_build_object('sheet',source_name,'row',row_no,'column',field_name,'message',SQLERRM)));
 end;
end $$;



create or replace function public.sias_import_job_command(p_company uuid,p_user uuid,p_action text,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare j sias_import_jobs%rowtype;job_uuid uuid;d record;r jsonb;v jsonb;rank_no integer;identity text;src text;row_no integer;cnt integer;offset_no integer;bytes bigint;old_hash text;old_count integer;data jsonb;res jsonb;refs record;totals_json jsonb;k text;outcome text;snapshot_hash text;
begin
 perform sias_v3_guard(p_company,p_user,'IMPORT_MANAGE');
 if jsonb_typeof(p_payload) is distinct from 'object' then raise exception 'SOLICITUD_INVALIDA';end if;
 if p_action='list' then return jsonb_build_object('jobs',coalesce((select jsonb_agg(public.sias_import_job_public(id) order by created_at desc) from (select id,created_at from sias_import_jobs where company_id=p_company and user_id=p_user order by created_at desc limit 20)s),'[]'));end if;
 job_uuid:=nullif(p_payload->>'job_id','')::uuid;if job_uuid is null then raise exception 'CARGA_NO_ENCONTRADA';end if;
 -- Orden de bloqueo idéntico al resto del ERP.
 perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));
 if p_action='start' then
  cnt:=(p_payload->>'total_rows')::integer;
  if cnt is null or cnt not between 1 and 100000 or p_payload->>'mode'<>all(array['General','Productos','Clientes','Precios']) or p_payload->>'strategy'<>all(array['UPSERT','CREATE']) or nullif(p_payload->>'filename','') is null or coalesce(p_payload->>'file_hash','') !~ '^[0-9a-f]{64}$' then raise exception 'ARCHIVO_INVALIDO_O_MUY_GRANDE';end if;
  if (select count(*) from sias_import_jobs where company_id=p_company and user_id=p_user and status in ('UPLOADING','READY','RUNNING','FAILED') and expires_at>now())>=20 and not exists(select 1 from sias_import_jobs where sias_import_jobs.id=job_uuid) then raise exception 'DEMASIADAS_CARGAS_PENDIENTES';end if;
  insert into sias_import_jobs(id,company_id,user_id,filename,file_hash,mode,strategy,total_rows) values(job_uuid,p_company,p_user,left(p_payload->>'filename',200),p_payload->>'file_hash',p_payload->>'mode',p_payload->>'strategy',cnt) on conflict do nothing;
 end if;
 select * into j from sias_import_jobs x where x.id=job_uuid and company_id=p_company and user_id=p_user for update;
 if j.id is null then raise exception 'CARGA_NO_ENCONTRADA';end if;
 if p_action='start' and (j.file_hash<>p_payload->>'file_hash' or j.total_rows<>(p_payload->>'total_rows')::integer or j.filename<>left(p_payload->>'filename',200) or j.mode<>p_payload->>'mode' or j.strategy<>p_payload->>'strategy') then raise exception 'SOLICITUD_REUTILIZADA_CON_OTROS_DATOS';end if;
 if p_action in ('start','status') then return jsonb_build_object('job',sias_import_job_public(j.id),'validation',jsonb_build_object('ok',true));end if;
 if j.status='COMPLETED' then return jsonb_build_object('job',sias_import_job_public(j.id),'validation',jsonb_build_object('ok',true,'repeated',true));end if;
 if p_action='cancel' then update sias_import_jobs set status='CANCELLED',updated_at=now() where sias_import_jobs.id=j.id;delete from sias_import_job_rows where job_id=j.id;delete from sias_import_job_uploads where job_id=j.id;return jsonb_build_object('job',sias_import_job_public(j.id),'validation',jsonb_build_object('ok',true));end if;
 if j.expires_at<now() then raise exception 'CARGA_VENCIDA';end if;
 if p_action='upload' then
  data:=p_payload->'rows';offset_no:=(p_payload->>'offset')::integer;
  if jsonb_typeof(data) is distinct from 'array' or jsonb_array_length(data) not between 1 and 500 or octet_length(data::text)>2097152 or offset_no is null then raise exception 'LOTE_INVALIDO_O_MUY_GRANDE';end if;
  cnt:=jsonb_array_length(data);bytes:=octet_length(data::text);
  select payload_hash,row_count into old_hash,old_count from sias_import_job_uploads where job_id=j.id and offset_row=offset_no;
  if old_hash is not null then if old_hash<>md5(data::text) or old_count<>cnt then raise exception 'LOTE_REUTILIZADO_CON_OTROS_DATOS';end if;return jsonb_build_object('job',sias_import_job_public(j.id),'validation',jsonb_build_object('ok',true,'repeated',true));end if;
  if j.status<>'UPLOADING' or offset_no<>j.uploaded_rows or j.uploaded_rows+cnt>j.total_rows or j.total_bytes+bytes>209715200 then raise exception 'ORDEN_O_TAMANO_DE_CARGA_INVALIDO';end if;
  for d in select value,ordinality from jsonb_array_elements(data) with ordinality loop
   r:=d.value;src:=coalesce(r->>'source',r->>'sheet');row_no:=(r->>'row')::integer;v:=r->'values';
   if row_no is null or row_no not between 1 and 1048576 or length(src)>120 then raise exception 'FILA_INVALIDA';end if;
   identity:=sias_import_job_values(p_company,p_user,r->>'sheet',j.mode,v);
   select ordinality::integer into rank_no from jsonb_array_elements(sias_import_schema()->'tables') with ordinality where value->>'key'=r->>'sheet';
   if rank_no<j.last_rank then raise exception 'ORDEN_DE_MAESTROS_INVALIDO';end if;j.last_rank:=rank_no;
   insert into sias_import_job_rows(job_id,ord,sheet,source,row_no,values_json,identity) values(j.id,offset_no+d.ordinality-1,r->>'sheet',src,row_no,v,identity);
  end loop;
  insert into sias_import_job_uploads values(j.id,offset_no,cnt,md5(data::text));
  update sias_import_jobs set uploaded_rows=uploaded_rows+cnt,total_bytes=total_bytes+bytes,last_rank=j.last_rank,updated_at=now() where sias_import_jobs.id=j.id;
 elsif p_action='validate' then
  if j.uploaded_rows<>j.total_rows or j.processed_rows<>0 or j.status not in ('UPLOADING','READY','FAILED') then raise exception 'CARGA_INCOMPLETA_O_YA_INICIADA';end if;
  -- Claves diferentes pueden apuntar al mismo maestro existente. Comprobar
  -- el archivo completo antes de aplicar evita actualizarlo en dos lotes.
  for refs in select * from (values
   ('Clientes','sias_customers','rut','import_code'),('Proveedores','sias_suppliers','rut','import_code'),
   ('Responsables','sias_staff','name','import_code'),('ListasPrecios','sias_price_lists','name','import_code')
  ) m(sheet_name,table_name,key_a,key_b) loop
   execute format('select to_jsonb(d) from (select (array_agg(x.source order by x.ord))[2] as source,(array_agg(x.row_no order by x.ord))[2] as row_no
    from sias_import_job_rows x join public.%I t on t.company_id=$2 and (%s or lower(btrim(t.%I))=lower(btrim(x.values_json->>%L)))
    where x.job_id=$1 and x.sheet=%L group by t.id having count(distinct x.ord)>1 limit 1)d',refs.table_name,
    case when refs.key_a='rut' then 'lower(replace(replace(t.rut,''.'',''''),'' '',''''))=lower(replace(replace(x.values_json->>''rut'',''.'',''''),'' '',''''))'
     else format('lower(btrim(t.%I))=lower(btrim(x.values_json->>%L))',refs.key_a,refs.key_a) end,
    refs.key_b,refs.key_b,refs.sheet_name) into r using j.id,p_company;
   if r is not null then src:=r->>'source';row_no:=(r->>'row_no')::integer;raise exception 'DOS_CLAVES_APUNTAN_AL_MISMO_REGISTRO';end if;
  end loop;
  for refs in
   select x.source,x.row_no,x.ord,x.sheet,ref.* from sias_import_job_rows x cross join lateral (values
    ('sku','sias_products',case when x.sheet in ('Precios','Atributos','Recetas','StockInicial','DetalleDocumentos') then x.values_json->>'sku' end,'sku'),
    ('parent_sku','sias_products',case when x.sheet='Productos' then x.values_json->>'parent_sku' end,'sku'),
    ('supply_sku','sias_products',case when x.sheet='Recetas' then x.values_json->>'supply_sku' end,'sku'),
    ('supplier_rut','sias_suppliers',x.values_json->>'supplier_rut','rut'),
    ('customer_rut','sias_customers',x.values_json->>'customer_rut','rut'),
    ('warehouse','sias_warehouses',x.values_json->>'warehouse','code'),
    ('document','sias_documents',case when x.sheet='DetalleDocumentos' then x.values_json->>'document' end,'import_code'),
    ('list','sias_price_lists',case when x.sheet='Precios' then x.values_json->>'list' end,'import_code')
   )ref(field_name,table_name,ref_value,key_name) where x.job_id=j.id and nullif(ref.ref_value,'') is not null order by x.ord
  loop
   src:=refs.source;row_no:=refs.row_no;
   if not sias_import_job_ref(p_company,j.id,refs.table_name,case when refs.field_name='list' then jsonb_build_object('import_code',refs.ref_value,'name',refs.ref_value) else jsonb_build_object(refs.key_name,refs.ref_value) end,case when refs.field_name='parent_sku' then refs.ord end) then raise exception 'REFERENCIA_NO_EXISTE: % = %',refs.field_name,refs.ref_value;end if;
  end loop;
  snapshot_hash:=sias_import_fingerprint(p_company);
  update sias_import_jobs set status='READY',baseline=snapshot_hash,last_error=null,updated_at=now(),expires_at=now()+interval '24 hours' where sias_import_jobs.id=j.id;
 elsif p_action='step' then
  offset_no:=(p_payload->>'offset')::integer;
  if offset_no is null or offset_no>j.processed_rows or j.status not in ('READY','RUNNING','FAILED') then raise exception 'ORDEN_DE_LOTE_INVALIDO';end if;
  if offset_no<j.processed_rows then return jsonb_build_object('job',sias_import_job_public(j.id),'validation',jsonb_build_object('ok',true,'repeated',true));end if;
  if j.processed_rows=0 and sias_import_fingerprint(p_company) is distinct from j.baseline then return jsonb_build_object('job',sias_import_job_public(j.id),'validation',jsonb_build_object('ok',false,'errors',jsonb_build_array(jsonb_build_object('sheet','Archivo','row',0,'column','Vista previa','message','Los datos cambiaron. Valida de nuevo antes de comenzar.'))));end if;
  select jsonb_agg(jsonb_build_object('sheet',s.sheet,'source',s.source,'row',s.row_no,'values',s.values_json) order by s.ord) into data from (select * from sias_import_job_rows where job_id=j.id and ord>=j.processed_rows order by ord limit 500)s;
  if data is null then raise exception 'LOTE_NO_ENCONTRADO';end if;
  res:=sias_import_apply_chunk(p_company,p_user,data,j.mode,j.strategy,false,null,j.id)-'baseline';
  if not coalesce((res->>'ok')::boolean,false) then update sias_import_jobs set status='FAILED',last_error=res->'errors',updated_at=now() where sias_import_jobs.id=j.id;return jsonb_build_object('job',sias_import_job_public(j.id),'validation',res);end if;
  totals_json:=j.summary;
  for k,v in select key,value from jsonb_each(res->'summary') loop
   foreach outcome in array array['created','updated','skipped'] loop
    totals_json:=jsonb_set(totals_json,array[k],coalesce(totals_json->k,'{}')||jsonb_build_object(outcome,coalesce((totals_json->k->>outcome)::integer,0)+coalesce((v->>outcome)::integer,0)),true);
   end loop;
  end loop;
  cnt:=jsonb_array_length(data);
  update sias_import_jobs set processed_rows=processed_rows+cnt,summary=totals_json,status=case when processed_rows+cnt=total_rows then 'COMPLETED' else 'RUNNING' end,last_error=null,updated_at=now(),expires_at=now()+interval '7 days',completed_at=case when processed_rows+cnt=total_rows then now() end where sias_import_jobs.id=j.id;
  delete from sias_import_job_rows where job_id=j.id and ord<j.processed_rows+cnt;
  if j.processed_rows+cnt=j.total_rows then insert into sias_audit(company_id,user_id,module,action,entity,entity_id,detail) values(p_company,p_user,'IMPORT','COMMIT','sias_import_jobs',j.id::text,jsonb_build_object('filename',j.filename,'mode',j.mode,'rows',j.total_rows,'summary',totals_json));end if;
 else raise exception 'ACCION_NO_VALIDA';
 end if;
 return jsonb_build_object('job',sias_import_job_public(j.id),'validation',jsonb_build_object('ok',true));
 exception when others then return jsonb_build_object('validation',jsonb_build_object('ok',false,'errors',jsonb_build_array(jsonb_build_object('sheet',coalesce(src,'Archivo'),'row',coalesce(row_no,0),'column','Carga','message',SQLERRM))));
end $$;
-- Solo el servidor autenticado: staging sin políticas de acceso público.
do $$declare r record;begin for r in select oid::regprocedure signature from pg_proc where pronamespace='public'::regnamespace and (proname like 'sias_import_job_%' or proname='sias_import_apply_chunk') loop execute format('revoke all on function %s from public,anon,authenticated',r.signature);execute format('grant execute on function %s to service_role',r.signature);end loop;end $$;
update sias_installation set version='3.1.6',updated_at=now() where id=1;
notify pgrst,'reload schema';
commit;


begin;
-- Una emisión principal por documento comercial; las notas mantienen su flujo explícito.
create or replace function public.sias_claim_dte(p_company uuid,p_user uuid,p_document uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare d public.sias_documents%rowtype; existing public.sias_external_dte%rowtype; ref public.sias_external_dte%rowtype;
  v_type integer:=(p_payload->>'document_type')::integer; v_total numeric:=(p_payload->>'total')::numeric; v_credited numeric;
  v_reference uuid:=nullif(p_payload->>'reference_id','')::uuid; v_code integer:=nullif(p_payload->>'reference_code','')::integer;
begin
  perform sias_v3_guard(p_company,p_user,'BILLING_MANAGE');
  select * into d from public.sias_documents where id=p_document and company_id=p_company for update;
  if d.id is null or d.status<>'POSTED' or d.document_type not in ('SALE','WHOLESALE','DELIVERY') then raise exception 'DOCUMENTO_CONFIRMADO_REQUERIDO'; end if;
  if v_type in (33,34,39,41,52) then
    select * into existing from sias_external_dte where company_id=p_company and document_id=p_document and provider='FACTURACION_CL' and document_type in (33,34,39,41,52) and status in ('EMITIDO','INICIADO','INDETERMINADO') order by case status when 'EMITIDO' then 0 else 1 end,created_at desc limit 1;
    if existing.id is not null then return to_jsonb(existing)||jsonb_build_object('reused',true);end if;
  end if;
  if v_type in (33,34,39,41,52) then
    if exists(select 1 from sias_credit_applications a join sias_customer_credits c on c.id=a.credit_id where a.company_id=p_company and a.document_id=d.id and c.environment is distinct from p_payload->>'environment') then raise exception 'DOCUMENTO_CON_CREDITO_DE_OTRO_AMBIENTE'; end if;
    update sias_documents set metadata=metadata||jsonb_build_object('billing_environment',p_payload->>'environment') where id=d.id and company_id=p_company;
  end if;
  select * into existing from sias_external_dte where company_id=p_company and provider='FACTURACION_CL' and request_hash=p_payload->>'request_hash';
  if existing.id is not null and existing.status<>'ERROR' then return to_jsonb(existing)||jsonb_build_object('reused',true);end if;
  if v_type in (56,61) then
    select * into ref from public.sias_external_dte where id=v_reference and company_id=p_company and document_id=p_document and status='EMITIDO'
      and environment=p_payload->>'environment' and document_type in (33,34,39,41,52);
    if ref.id is null or v_code not in (1,2,3) then raise exception 'DTE_REFERENCIA_INVALIDA'; end if;
    if v_type=61 then
      select coalesce(sum(total),0) into v_credited from public.sias_external_dte where company_id=p_company and reference_id=ref.id
        and document_type=61 and status in ('INICIADO','INDETERMINADO','EMITIDO');
      if v_credited+v_total>ref.total then raise exception 'NOTA_SUPERA_SALDO_DTE'; end if;
    end if;
  end if;
  if existing.id is not null then
    update public.sias_external_dte set status='INICIADO',error_detail=null,updated_at=now() where id=existing.id returning * into existing;
  else
    insert into public.sias_external_dte(company_id,document_id,provider,environment,document_type,folio,status,issue_date,recipient_rut,recipient_name,total,
      reference_document_type,reference_folio,reference_date,reference_id,reference_code,request_hash,created_by)
    values(p_company,p_document,'FACTURACION_CL',p_payload->>'environment',v_type,null,'INICIADO',(p_payload->>'issue_date')::date,
      p_payload->>'recipient_rut',p_payload->>'recipient_name',v_total,ref.document_type,ref.folio,ref.issue_date,v_reference,v_code,p_payload->>'request_hash',p_user)
    returning * into existing;
  end if;
  return to_jsonb(existing)||jsonb_build_object('reused',false);
end $$;
revoke all on function public.sias_claim_dte(uuid,uuid,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.sias_claim_dte(uuid,uuid,uuid,jsonb) to service_role;
notify pgrst,'reload schema';
commit;


begin;

-- SiasCloud 3.1.7
-- 1) Rol CAJERO como responsable operativo.
-- 2) Cajero asociado a cada sesión POS y, por herencia, a cada documento POS.
-- 3) Arqueo/cierre desglosado por EFECTIVO, TARJETA y TRANSFERENCIA.
-- 4) Campos de cierre auditables y compatibles con las columnas históricas.

-- ---------------------------------------------------------------------------
-- RESPONSABLES / CAJERO
-- ---------------------------------------------------------------------------
alter table public.sias_staff drop constraint if exists sias_staff_roles_check;
alter table public.sias_staff
  add constraint sias_staff_roles_check
  check(roles <@ array['SELLER','PREPARER','PACKER','CASHIER']::text[] and cardinality(roles)>0);

alter table public.sias_cash_sessions
  add column if not exists cashier_id uuid references public.sias_staff(id) on delete set null;
alter table public.sias_cash_sessions
  add column if not exists closed_by uuid references public.sias_users(id) on delete set null;
alter table public.sias_cash_sessions
  add column if not exists expected_breakdown jsonb not null default '{}'::jsonb;
alter table public.sias_cash_sessions
  add column if not exists counted_breakdown jsonb not null default '{}'::jsonb;
alter table public.sias_cash_sessions
  add column if not exists difference_breakdown jsonb not null default '{}'::jsonb;

create index if not exists sias_cash_sessions_cashier_idx
  on public.sias_cash_sessions(company_id,cashier_id,opened_at desc);

-- ---------------------------------------------------------------------------
-- Toda venta POS hereda automáticamente cajero, operador y caja en metadata.
-- También deja trazabilidad para documentos POS antiguos al ejecutar este script.
-- ---------------------------------------------------------------------------
create or replace function public.sias_v317_attach_cashier_to_document()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  s public.sias_cash_sessions%rowtype;
begin
  if new.cash_session_id is null then
    return new;
  end if;

  select * into s
  from public.sias_cash_sessions
  where id=new.cash_session_id and company_id=new.company_id;

  if s.id is not null then
    new.metadata:=coalesce(new.metadata,'{}'::jsonb)||jsonb_build_object(
      'cashier_id',s.cashier_id,
      'cashier_user_id',s.user_id,
      'cash_register',s.register_code
    );
  end if;
  return new;
end $$;

drop trigger if exists sias_v317_document_cashier on public.sias_documents;
create trigger sias_v317_document_cashier
before insert or update of cash_session_id on public.sias_documents
for each row execute function public.sias_v317_attach_cashier_to_document();

update public.sias_documents d
set metadata=coalesce(d.metadata,'{}'::jsonb)||jsonb_build_object(
  'cashier_id',s.cashier_id,
  'cashier_user_id',s.user_id,
  'cash_register',s.register_code
)
from public.sias_cash_sessions s
where d.company_id=s.company_id
  and d.cash_session_id=s.id
  and (
    d.metadata->>'cashier_user_id' is null
    or d.metadata->>'cash_register' is null
    or (s.cashier_id is not null and d.metadata->>'cashier_id' is null)
  );

-- ---------------------------------------------------------------------------
-- Apertura 3.1.7: exige un responsable con rol CAJERO.
-- El usuario autenticado sigue siendo el operador técnico/auditable de la acción.
-- ---------------------------------------------------------------------------
create or replace function public.sias_v317_cash_open(
  p_company uuid,
  p_user uuid,
  p_code text,
  p_opening numeric,
  p_key uuid,
  p_cashier uuid
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_session public.sias_cash_sessions%rowtype;
begin
  perform public.sias_v3_guard(p_company,p_user,'POS_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));

  if p_key is null
     or p_opening is null
     or p_opening<0
     or p_opening::text in ('NaN','Infinity','-Infinity')
     or length(btrim(coalesce(p_code,''))) not between 1 and 40
  then
    raise exception 'APERTURA_CAJA_INVALIDA';
  end if;

  if p_cashier is null or not exists(
    select 1
    from public.sias_staff st
    where st.id=p_cashier
      and st.company_id=p_company
      and st.active
      and 'CASHIER'=any(st.roles)
  ) then
    raise exception 'CAJERO_REQUERIDO';
  end if;

  select * into v_session
  from public.sias_cash_sessions
  where company_id=p_company and open_key=p_key;

  if found then
    if v_session.user_id<>p_user
       or v_session.register_code<>btrim(p_code)
       or v_session.opening_cash<>p_opening
       or v_session.cashier_id is distinct from p_cashier
    then
      raise exception 'SOLICITUD_REUTILIZADA_CON_OTROS_DATOS';
    end if;
    return to_jsonb(v_session);
  end if;

  insert into public.sias_cash_sessions(
    company_id,user_id,cashier_id,register_code,opening_cash,open_key
  ) values(
    p_company,p_user,p_cashier,btrim(p_code),p_opening,p_key
  ) returning * into v_session;

  insert into public.sias_audit(company_id,user_id,module,action,entity,entity_id,detail)
  values(
    p_company,p_user,'POS','CASH_OPEN','sias_cash_sessions',v_session.id,
    jsonb_build_object('opening_cash',p_opening,'cashier_id',p_cashier,'register_code',btrim(p_code))
  );

  return to_jsonb(v_session);
end $$;

-- ---------------------------------------------------------------------------
-- Resumen 3.1.7: totales esperados separados por medio de pago.
-- CASH representa efectivo físico esperado en la caja: apertura + ventas CASH
-- + ingresos manuales - retiros manuales.
-- CARD y TRANSFER representan ventas registradas por cada medio electrónico.
-- ---------------------------------------------------------------------------
create or replace function public.sias_v317_cash_summary(
  p_company uuid,
  p_user uuid,
  p_session uuid
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  s public.sias_cash_sessions%rowtype;
  v_methods jsonb;
  v_cash_sales numeric:=0;
  v_card numeric:=0;
  v_transfer numeric:=0;
  v_in numeric:=0;
  v_out numeric:=0;
  v_expected_cash numeric:=0;
  v_expected jsonb;
begin
  perform public.sias_v3_guard(p_company,p_user,'POS_VIEW');

  select * into s
  from public.sias_cash_sessions
  where company_id=p_company and id=p_session;

  if s.id is null then
    raise exception 'CAJA_NO_ENCONTRADA';
  end if;

  select coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb)
  into v_methods
  from (
    select method,sum(amount) amount,count(*) payments
    from public.sias_payments
    where company_id=p_company
      and cash_session_id=s.id
      and status='CONFIRMED'
    group by method
    order by method
  ) t;

  select
    coalesce(sum(amount) filter(where method='CASH'),0),
    coalesce(sum(amount) filter(where method='CARD'),0),
    coalesce(sum(amount) filter(where method='TRANSFER'),0)
  into v_cash_sales,v_card,v_transfer
  from public.sias_payments
  where company_id=p_company
    and cash_session_id=s.id
    and status='CONFIRMED';

  select
    coalesce(sum(amount) filter(where kind='IN'),0),
    coalesce(sum(amount) filter(where kind='OUT'),0)
  into v_in,v_out
  from public.sias_cash_movements
  where session_id=s.id and company_id=p_company;

  v_expected_cash:=s.opening_cash+v_cash_sales+v_in-v_out;
  v_expected:=jsonb_build_object(
    'CASH',round(v_expected_cash,2),
    'CARD',round(v_card,2),
    'TRANSFER',round(v_transfer,2)
  );

  return jsonb_build_object(
    'session',to_jsonb(s),
    'methods',v_methods,
    'cash_in',v_in,
    'cash_out',v_out,
    'cash_sales',v_cash_sales,
    'expected_cash',v_expected_cash,
    'expected_breakdown',v_expected
  );
end $$;

-- ---------------------------------------------------------------------------
-- Cierre 3.1.7: recibe conteos/declaraciones separados por medio de pago.
-- Conserva counted_cash / expected_cash / difference para compatibilidad.
-- ---------------------------------------------------------------------------
create or replace function public.sias_v317_cash_close(
  p_company uuid,
  p_user uuid,
  p_session uuid,
  p_counted jsonb,
  p_notes text,
  p_key uuid
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  s public.sias_cash_sessions%rowtype;
  v_summary jsonb;
  v_expected jsonb;
  v_counted_cash numeric;
  v_counted_card numeric;
  v_counted_transfer numeric;
  v_expected_cash numeric;
  v_expected_card numeric;
  v_expected_transfer numeric;
  v_counted jsonb;
  v_diff jsonb;
begin
  perform public.sias_v3_guard(p_company,p_user,'POS_MANAGE');
  perform pg_advisory_xact_lock(hashtextextended('sias-stock:'||p_company::text,0));

  select * into s
  from public.sias_cash_sessions
  where company_id=p_company and id=p_session
  for update;

  if s.id is null then raise exception 'CAJA_NO_ENCONTRADA'; end if;
  if s.status='CLOSED' then
    if s.close_key=p_key then return to_jsonb(s); end if;
    raise exception 'CAJA_YA_CERRADA';
  end if;
  if s.user_id<>p_user then raise exception 'CAJA_ABIERTA_DEL_OPERADOR_REQUERIDA'; end if;
  if p_key is null or jsonb_typeof(coalesce(p_counted,'{}'::jsonb))<>'object' then
    raise exception 'CIERRE_CAJA_INVALIDO';
  end if;

  begin
    v_counted_cash:=coalesce((p_counted->>'CASH')::numeric,-1);
    v_counted_card:=coalesce((p_counted->>'CARD')::numeric,-1);
    v_counted_transfer:=coalesce((p_counted->>'TRANSFER')::numeric,-1);
  exception when others then
    raise exception 'CIERRE_CAJA_INVALIDO';
  end;

  if v_counted_cash<0 or v_counted_card<0 or v_counted_transfer<0
     or v_counted_cash::text in ('NaN','Infinity','-Infinity')
     or v_counted_card::text in ('NaN','Infinity','-Infinity')
     or v_counted_transfer::text in ('NaN','Infinity','-Infinity')
  then
    raise exception 'CIERRE_CAJA_INVALIDO';
  end if;

  v_summary:=public.sias_v317_cash_summary(p_company,p_user,s.id);
  v_expected:=v_summary->'expected_breakdown';
  v_expected_cash:=coalesce((v_expected->>'CASH')::numeric,0);
  v_expected_card:=coalesce((v_expected->>'CARD')::numeric,0);
  v_expected_transfer:=coalesce((v_expected->>'TRANSFER')::numeric,0);

  v_counted:=jsonb_build_object(
    'CASH',round(v_counted_cash,2),
    'CARD',round(v_counted_card,2),
    'TRANSFER',round(v_counted_transfer,2)
  );
  v_diff:=jsonb_build_object(
    'CASH',round(v_counted_cash-v_expected_cash,2),
    'CARD',round(v_counted_card-v_expected_card,2),
    'TRANSFER',round(v_counted_transfer-v_expected_transfer,2)
  );

  update public.sias_cash_sessions
  set status='CLOSED',
      counted_cash=v_counted_cash,
      expected_cash=v_expected_cash,
      difference=v_counted_cash-v_expected_cash,
      expected_breakdown=v_expected,
      counted_breakdown=v_counted,
      difference_breakdown=v_diff,
      notes=nullif(btrim(coalesce(p_notes,'')),''),
      close_key=p_key,
      closed_by=p_user,
      closed_at=now()
  where id=s.id
  returning * into s;

  insert into public.sias_audit(company_id,user_id,module,action,entity,entity_id,detail)
  values(
    p_company,p_user,'POS','CASH_CLOSE','sias_cash_sessions',s.id,
    jsonb_build_object(
      'cashier_id',s.cashier_id,
      'expected',v_expected,
      'counted',v_counted,
      'difference',v_diff,
      'notes',s.notes
    )
  );

  return to_jsonb(s);
end $$;

revoke all on function public.sias_v317_cash_open(uuid,uuid,text,numeric,uuid,uuid) from public,anon,authenticated;
revoke all on function public.sias_v317_cash_summary(uuid,uuid,uuid) from public,anon,authenticated;
revoke all on function public.sias_v317_cash_close(uuid,uuid,uuid,jsonb,text,uuid) from public,anon,authenticated;
grant execute on function public.sias_v317_cash_open(uuid,uuid,text,numeric,uuid,uuid) to service_role;
grant execute on function public.sias_v317_cash_summary(uuid,uuid,uuid) to service_role;
grant execute on function public.sias_v317_cash_close(uuid,uuid,uuid,jsonb,text,uuid) to service_role;

notify pgrst,'reload schema';
commit;


-- SiasCloud 3.1.8 · Formatos de impresión DTE
-- La emisión tributaria no cambia. Solo guarda preferencias de representación/impresión.
begin;

alter table public.sias_billing_config
  add column if not exists dte_print_format text not null default 'A4';
alter table public.sias_billing_config
  add column if not exists pos_dte_print_format text not null default '80MM';

do $$
begin
  if not exists (select 1 from pg_constraint where conname='sias_billing_config_dte_print_format_chk') then
    alter table public.sias_billing_config
      add constraint sias_billing_config_dte_print_format_chk
      check (dte_print_format in ('A4','80MM','58MM'));
  end if;
  if not exists (select 1 from pg_constraint where conname='sias_billing_config_pos_dte_print_format_chk') then
    alter table public.sias_billing_config
      add constraint sias_billing_config_pos_dte_print_format_chk
      check (pos_dte_print_format in ('A4','80MM','58MM'));
  end if;
end $$;

update public.sias_billing_config
set dte_print_format=coalesce(nullif(dte_print_format,''),'A4'),
    pos_dte_print_format=coalesce(nullif(pos_dte_print_format,''),'80MM')
where true;

commit;


-- SiasCloud 3.1.9 · Mantenedor central de formatos de impresión
-- No modifica la emisión DTE ni el contenido enviado a Facturacion.cl.
begin;

alter table public.sias_billing_config
  add column if not exists print_formats jsonb not null default '{
    "defaults":{"tributary":"A4","system":"A4","pos":"80MM"},
    "tributary":{"33":"A4","34":"A4","39":"80MM","41":"80MM","52":"A4","56":"A4","61":"A4"},
    "system":{"POS_RECEIPT":"80MM","SALE":"A4","WHOLESALE":"A4","QUOTE":"A4","ORDER":"A4","REQUEST":"A4","PURCHASE":"A4","RECEIPT":"A4","ISSUE":"A4","TRANSFER":"A4","DELIVERY":"A4","CASH_CLOSE":"A4"}
  }'::jsonb;

update public.sias_billing_config
set print_formats = case
  when print_formats is null or jsonb_typeof(print_formats) <> 'object' then '{
    "defaults":{"tributary":"A4","system":"A4","pos":"80MM"},
    "tributary":{"33":"A4","34":"A4","39":"80MM","41":"80MM","52":"A4","56":"A4","61":"A4"},
    "system":{"POS_RECEIPT":"80MM","SALE":"A4","WHOLESALE":"A4","QUOTE":"A4","ORDER":"A4","REQUEST":"A4","PURCHASE":"A4","RECEIPT":"A4","ISSUE":"A4","TRANSFER":"A4","DELIVERY":"A4","CASH_CLOSE":"A4"}
  }'::jsonb
  else print_formats
end;

do $$
begin
  if not exists (select 1 from pg_constraint where conname='sias_billing_config_print_formats_object_chk') then
    alter table public.sias_billing_config
      add constraint sias_billing_config_print_formats_object_chk
      check (jsonb_typeof(print_formats) = 'object');
  end if;
end $$;

commit;


begin;

-- SiasCloud 3.2.1 RC: monitoreo operativo y limitación persistente para acciones críticas.
create table if not exists public.sias_operational_events(
  id bigint generated always as identity primary key,
  company_id uuid references public.sias_companies(id) on delete set null,
  user_id uuid references public.sias_users(id) on delete set null,
  severity text not null default 'INFO' check(severity in ('INFO','WARN','ERROR','CRITICAL')),
  category text not null,
  action text,
  entity text,
  entity_id text,
  message text not null,
  detail jsonb not null default '{}'::jsonb,
  request_id text,
  resolved boolean not null default false,
  resolved_at timestamptz,
  resolved_by uuid references public.sias_users(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists sias_operational_events_company_date on public.sias_operational_events(company_id,created_at desc);
create index if not exists sias_operational_events_open on public.sias_operational_events(company_id,resolved,severity,created_at desc);
alter table public.sias_operational_events enable row level security;
revoke all on public.sias_operational_events from public,anon,authenticated;
grant all on public.sias_operational_events to service_role;

create table if not exists public.sias_api_rate_limits(
  bucket text not null,
  key_hash text not null,
  window_started_at timestamptz not null default now(),
  hits integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key(bucket,key_hash)
);
create index if not exists sias_api_rate_limits_updated on public.sias_api_rate_limits(updated_at);
alter table public.sias_api_rate_limits enable row level security;
revoke all on public.sias_api_rate_limits from public,anon,authenticated;
grant all on public.sias_api_rate_limits to service_role;

create or replace function public.sias_api_rate_check(
  p_bucket text,
  p_key_hash text,
  p_limit integer,
  p_window_seconds integer
) returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare
  v_hits integer;
  v_start timestamptz;
  v_now timestamptz:=clock_timestamp();
begin
  if nullif(btrim(coalesce(p_bucket,'')),'') is null
     or nullif(btrim(coalesce(p_key_hash,'')),'') is null
     or p_limit<1 or p_limit>10000
     or p_window_seconds<1 or p_window_seconds>86400 then
    return false;
  end if;

  insert into public.sias_api_rate_limits(bucket,key_hash,window_started_at,hits,updated_at)
  values(left(p_bucket,80),left(p_key_hash,128),v_now,1,v_now)
  on conflict(bucket,key_hash) do update set
    hits=case when excluded.updated_at-public.sias_api_rate_limits.window_started_at >= make_interval(secs=>p_window_seconds)
              then 1 else public.sias_api_rate_limits.hits+1 end,
    window_started_at=case when excluded.updated_at-public.sias_api_rate_limits.window_started_at >= make_interval(secs=>p_window_seconds)
                           then excluded.updated_at else public.sias_api_rate_limits.window_started_at end,
    updated_at=excluded.updated_at
  returning hits,window_started_at into v_hits,v_start;

  return v_hits<=p_limit;
end $$;
revoke all on function public.sias_api_rate_check(text,text,integer,integer) from public,anon,authenticated;
grant execute on function public.sias_api_rate_check(text,text,integer,integer) to service_role;

create or replace function public.sias_v321_event_dte_failure() returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  if new.status in ('INDETERMINADO','ERROR') and (tg_op='INSERT' or old.status is distinct from new.status or old.error_detail is distinct from new.error_detail) then
    insert into public.sias_operational_events(company_id,user_id,severity,category,action,entity,entity_id,message,detail)
    values(new.company_id,new.created_by,case when new.status='INDETERMINADO' then 'WARN' else 'ERROR' end,
      'DTE','DTE_'||new.status,'sias_external_dte',new.id::text,
      coalesce(nullif(new.error_detail,''),'DTE requiere revisión'),
      jsonb_build_object('provider',new.provider,'environment',new.environment,'document_type',new.document_type,'folio',new.folio,'document_id',new.document_id,'status',new.status));
  end if;
  return new;
end $$;
drop trigger if exists sias_v321_dte_failure_event on public.sias_external_dte;
create trigger sias_v321_dte_failure_event after insert or update of status,error_detail on public.sias_external_dte
for each row execute function public.sias_v321_event_dte_failure();

create or replace function public.sias_v321_event_import_failure() returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  if new.status='FAILED' and (tg_op='INSERT' or old.status is distinct from new.status or old.last_error is distinct from new.last_error) then
    insert into public.sias_operational_events(company_id,user_id,severity,category,action,entity,entity_id,message,detail)
    values(new.company_id,new.user_id,'ERROR','IMPORT','IMPORT_FAILED','sias_import_jobs',new.id::text,
      'Importación masiva fallida',jsonb_build_object('filename',new.filename,'mode',new.mode,'processed_rows',new.processed_rows,'total_rows',new.total_rows,'last_error',new.last_error));
  end if;
  return new;
end $$;
drop trigger if exists sias_v321_import_failure_event on public.sias_import_jobs;
create trigger sias_v321_import_failure_event after insert or update of status,last_error on public.sias_import_jobs
for each row execute function public.sias_v321_event_import_failure();

create or replace function public.sias_v321_event_cash_difference() returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare
  d_cash numeric:=coalesce((new.difference_breakdown->>'CASH')::numeric,0);
  d_card numeric:=coalesce((new.difference_breakdown->>'CARD')::numeric,0);
  d_transfer numeric:=coalesce((new.difference_breakdown->>'TRANSFER')::numeric,0);
begin
  if new.status='CLOSED' and (tg_op='INSERT' or old.status is distinct from new.status)
     and (abs(d_cash)>0.009 or abs(d_card)>0.009 or abs(d_transfer)>0.009) then
    insert into public.sias_operational_events(company_id,user_id,severity,category,action,entity,entity_id,message,detail)
    values(new.company_id,coalesce(new.closed_by,new.user_id),'WARN','CASH','CASH_DIFFERENCE','sias_cash_sessions',new.id::text,
      'Cierre de caja con diferencia',jsonb_build_object('register_code',new.register_code,'cashier_id',new.cashier_id,'expected',new.expected_breakdown,'counted',new.counted_breakdown,'difference',new.difference_breakdown,'notes',new.notes));
  end if;
  return new;
end $$;
drop trigger if exists sias_v321_cash_difference_event on public.sias_cash_sessions;
create trigger sias_v321_cash_difference_event after insert or update of status on public.sias_cash_sessions
for each row execute function public.sias_v321_event_cash_difference();

update public.sias_installation set version='3.2.1',jwt_enabled=false,updated_at=now() where id=1;
notify pgrst,'reload schema';
commit;


-- SiasCloud 3.2.2 · Política de logotipo por empresa
begin;

alter table public.sias_companies
  add column if not exists show_logo_documents boolean default true;

update public.sias_companies
set show_logo_documents = true
where show_logo_documents is null;

alter table public.sias_companies
  alter column show_logo_documents set default true;
alter table public.sias_companies
  alter column show_logo_documents set not null;

comment on column public.sias_companies.show_logo_documents is
  'Controla si el logotipo de la empresa se muestra en documentos generados por SiasCloud. No altera PDF A4 oficial de Facturacion.cl.';

update public.sias_installation
set version='3.2.2', updated_at=now()
where id=1;

notify pgrst,'reload schema';
commit;


-- SiasCloud 3.2.3 · Completar datos enviados a Facturacion.cl
-- No altera tablas ni documentos ya emitidos. Solo marca la versión instalada.
begin;
update public.sias_installation set version='3.2.3', updated_at=now() where id=1;
commit;


-- SiasCloud 3.2.4 · Teléfono del receptor en impreso Facturacion.cl
-- No modifica estructura de tablas. Actualiza únicamente la versión instalada.
update public.sias_installation set version='3.2.4', updated_at=now() where id=1;


-- SiasCloud 3.2.5 · Flujo DTE directo y parámetros de emisión
-- No requiere nuevas columnas: la configuración vive en sias_billing_config.print_formats JSONB.
update public.sias_installation set version='3.2.5', updated_at=now() where id=1;


-- SiasCloud 3.2.6: conservar el teléfono enviado con cada DTE.
-- Ejecutar antes de desplegar el index.ts de esta versión.
begin;
alter table public.sias_external_dte
  add column if not exists recipient_phone text;
comment on column public.sias_external_dte.recipient_phone is
  'Teléfono del receptor enviado al emitir el DTE. No se recalcula al reimprimir.';
update public.sias_installation set version='3.2.6', updated_at=now() where id=1;
commit;


-- SiasCloud 3.2.7: teléfono por emisión y versión del paquete.
-- Idempotente. No altera documentos emitidos ni sus folios.
begin;
alter table public.sias_external_dte
  add column if not exists recipient_phone text;
comment on column public.sias_external_dte.recipient_phone is
  'Teléfono del receptor usado al emitir el DTE. No se recalcula al reimprimir.';
update public.sias_installation set version='3.2.7', updated_at=now() where id=1;
notify pgrst,'reload schema';
commit;
