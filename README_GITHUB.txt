SIASCLOUD 3.2.6 - GITHUB PLANO / CONEXION CORREGIDA

Publicar los archivos del frontend directamente en la raiz del repositorio.
index.html debe quedar en la raiz; no hay carpeta contenedora adicional.

Este paquete tambien incluye la actualizacion necesaria de Supabase:
- ACTUALIZACION_TELEFONO_DTE_V3_2_6.sql
- supabase/functions/siascloud-erp/index.ts (un solo archivo)

Si ya desplegaste backend 3.2.6, para este arreglo basta reemplazar el frontend
y recargar con Ctrl+F5. Mantener el backend 3.2.6. Ver
LEEME_CONEXION_CORREGIDA_3_2_6.txt.

Para una instalacion inicial de la actualizacion de telefono: aplicar el SQL
y desplegar ese index.ts en la
Edge Function siascloud-erp existente. Publicar en GitHub por si solo no despliega
el backend. Seguir LEEME_TELEFONO_DTE_3_2_6.txt para completar la actualizacion.

Backend configurado:
https://vjgdftnsdkglhqwggapd.supabase.co/functions/v1/siascloud-erp

Version frontend/backend: 3.2.6. Recargar con Ctrl+F5 despues de publicar.
El PDF A4 mantiene el formato oficial de Facturacion.cl y requiere que su
adicional A2 este vinculado al campo Telefono del impreso personalizado.
