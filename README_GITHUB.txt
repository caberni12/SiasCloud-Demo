SIASCLOUD 3.2.9 - GITHUB PLANO / MAESTRO DE PRODUCTOS

Los archivos web estan en la raiz, listos para publicar en GitHub.
No subir una carpeta contenedora: index.html debe quedar en la raiz del sitio.

CAMBIO 3.2.8
- Parte de la ultima version 3.2.7 entregada.
- Conserva intacta la emision DTE y la proteccion contra folios duplicados.
- El telefono sigue enviandose en Receptor/Contacto para facturas y en A2 como adicional de impreso.
- documents.list, documents.get y el portal ahora devuelven recipient_phone en los DTE relacionados.
- El estado del portal queda alineado con la version 3.2.8.
- Actualizar PDF consulta el PDF oficial del mismo folio; nunca llama a procesar.

DESPLIEGUE
1. Ejecutar ACTUALIZACION_TELEFONO_DTE_V3_2_8.sql en Supabase.
2. Reemplazar y desplegar el unico supabase/functions/siascloud-erp/index.ts.
   Conservar los secretos existentes de la funcion siascloud-erp.
3. Publicar los archivos web de la raiz en GitHub y recargar con Ctrl+F5.

IMPORTANTE SOBRE EL PDF OFICIAL DE FACTURACION.CL
SiasCloud ya envia el telefono. Para que el PDF A4 oficial lo muestre, la cuenta de Facturacion.cl debe tener configurado:
Administrador > Integracion > Configuracion > Campos de Impreso Adicional
El campo Telefono debe estar asociado al adicional A2.

Version frontend/backend: 3.2.9. Recursos web: 3.2.9-product-delete.


CAMBIO 3.2.9 - ELIMINAR PRODUCTOS
- Maestro de Productos incorpora botón Eliminar para usuarios con PRODUCT_MANAGE.
- Nuevo endpoint products.delete en la misma Edge Function siascloud-erp.
- La eliminación es definitiva solo para productos sin historia operacional.
- Se bloquea el borrado si existen movimientos, documentos, historial de costos, variantes, stock o uso como insumo en recetas.
- En esos casos el sistema indica usar Desactivar para conservar trazabilidad.
- Ejecutar ACTUALIZACION_ELIMINAR_PRODUCTO_V3_2_9.sql antes de desplegar el nuevo index.ts.
