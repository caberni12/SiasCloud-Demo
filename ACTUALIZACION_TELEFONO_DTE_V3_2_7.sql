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
