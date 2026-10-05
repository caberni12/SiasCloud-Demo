SIASCLOUD 3.2.7 - GITHUB PLANO / TELEFONO DTE

Los archivos web estan en la raiz, listos para publicar en GitHub.
No subir una carpeta contenedora: index.html debe quedar en la raiz del sitio.

Esta entrega requiere actualizar frontend y backend a 3.2.7:
1. Ejecutar ACTUALIZACION_TELEFONO_DTE_V3_2_7.sql en Supabase.
2. Reemplazar el unico supabase/functions/siascloud-erp/index.ts en la funcion
   existente siascloud-erp y desplegarlo. Conservar los secretos existentes.
3. Publicar los archivos web y recargar con Ctrl+F5.

Subir archivos a GitHub NO actualiza el backend de Supabase.
El SQL es idempotente y no cambia folios ni DTE anteriores.
Para instalaciones nuevas usar SQL_MAESTRO_SIASCLOUD_V3_1_COMPLETO.sql.

Leer LEEME_TELEFONO_DTE_3_2_7.txt para la comprobacion del campo Telefono.
El historial y el visor A4 muestran Telefono de emision.
Actualizar PDF consulta el documento oficial del MISMO folio, sin reemitirlo.
El campo del impreso de Facturacion.cl debe estar asociado a A2.

Version frontend/backend: 3.2.7. Recursos web: 3.2.7-telefono1.
