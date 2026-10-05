SIASCLOUD ERP 3.3.0 · RELEASE CONSOLIDADA
========================================

BASE
- Consolidada desde la última 3.2.16 + Tienda limpia.
- Un único backend: supabase/functions/siascloud-erp/index.ts
- Frontend / backend / manifiesto de importación alineados en 3.3.0.
- Se retiraron LEEME y SQL de hotfix antiguos para evitar despliegues parciales.

ACTUALIZACIÓN DESDE 3.2.16
1. Ejecutar MIGRACION_3_2_16_A_3_3_0.sql en Supabase SQL Editor.
2. Reemplazar y desplegar supabase/functions/siascloud-erp/index.ts.
3. Publicar TODOS los archivos planos del root en GitHub Pages.
4. Forzar una recarga completa del navegador una vez (Ctrl+F5).

INSTALACIÓN NUEVA
1. Ejecutar SQL_MAESTRO_SIASCLOUD_V3_3_0.sql.
2. Desplegar supabase/functions/siascloud-erp/index.ts.
3. Publicar los archivos planos en GitHub Pages.
4. Configurar config.js con el proyecto Supabase correspondiente si cambia el proyecto.

IMPORTANTE
- No mezclar index.ts 3.2.x con frontend 3.3.0.
- No ejecutar SQL de hotfix 3.2.x sobre esta entrega: ya están integrados.
- Las plantillas XLSX y licencias se mantienen incluidas.
- No se han eliminado datos ni funciones operacionales respecto de 3.2.16.
