// Conexión fija al proyecto Supabase del sistema.
window.SIASCLOUD_CONFIG = {
  functionsBaseUrl: "https://vjgdftnsdkglhqwggapd.supabase.co/functions/v1",
  systemFunction: "siascloud-erp",
  erpFunction: "siascloud-erp",
  portalFunction: "siascloud-erp",
  siiFunction: "siascloud-erp",
  fixedConnection: true,
  appName: "SiasCloud ERP",
  storeFunction: "siascloud-erp",
  storeSlug: "",
  version: "3.2.7",
  checkBackendVersion(backendVersion) {
    const parse=value=>{const match=String(value||'').trim().match(/^(\d+)\.(\d+)\.(\d+)$/);return match?match.slice(1).map(Number):null;};
    const frontend=parse(this.version),backend=parse(backendVersion);
    // Los parches posteriores de la misma rama conservan el contrato del frontend.
    if(!frontend||!backend||frontend[0]!==backend[0]||frontend[1]!==backend[1]||backend[2]<frontend[2]){
      const error=new Error(`Frontend ${this.version||'sin versión'} y backend ${backendVersion||'sin versión'} no son compatibles. Usa el frontend y el index.ts de la misma entrega de SiasCloud.`);
      error.code='BACKEND_VERSION_INCOMPATIBLE';throw error;
    }
  }
};
