-- SiasCloud 3.2.6: conservar el teléfono enviado con cada DTE.
-- Ejecutar antes de desplegar el index.ts de esta versión.
begin;
alter table public.sias_external_dte
  add column if not exists recipient_phone text;
comment on column public.sias_external_dte.recipient_phone is
  'Teléfono del receptor enviado al emitir el DTE. No se recalcula al reimprimir.';
update public.sias_installation set version='3.2.6', updated_at=now() where id=1;
commit;
