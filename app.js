(() => {
  "use strict";
  const $ = (s, root=document) => root.querySelector(s);
  const $$ = (s, root=document) => [...root.querySelectorAll(s)];
  const esc = (v) => String(v ?? "").replace(/[&<>'"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]));
  const fmtDate = (v) => v ? new Date(v).toLocaleString("es-CL") : "—";
  function formData(form){ if(!form || String(form.tagName).toUpperCase()!=="FORM") throw new Error("Formulario inválido. Recarga la página con Ctrl + F5."); return new FormData(form); }

  function bindPasswordToggles(root=document){
    $$("[data-password-toggle]",root).forEach(btn=>{
      if(btn.dataset.bound==="1") return;
      btn.dataset.bound="1";
      btn.addEventListener("click",()=>{
        const input=document.querySelector(btn.dataset.passwordToggle);
        if(!input) return;
        const showing=input.type==="text";
        input.type=showing?"password":"text";
        btn.classList.toggle("showing",!showing);
        btn.setAttribute("aria-label",showing?"Mostrar contraseña":"Ocultar contraseña");
        btn.innerHTML=showing
          ? '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>'
          : '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 3l18 18"/><path d="M10.6 6.2A11 11 0 0 1 12 6c6.5 0 10 6 10 6a18 18 0 0 1-3 3.8M6.6 6.6C3.6 8.5 2 12 2 12s3.5 6 10 6c1.8 0 3.4-.5 4.8-1.2"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/></svg>';
      });
    });
  }
  function hideErpSplash(){
    window.SiasSplash.finishBoot();
  }

  const ICONS={
    dashboard:'<svg viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="5" rx="2"/><rect x="14" y="12" width="7" height="9" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/></svg>',
    products:'<svg viewBox="0 0 24 24"><path d="m12 3 8 4-8 4-8-4 8-4Z"/><path d="m4 12 8 4 8-4"/><path d="m4 17 8 4 8-4"/></svg>',
    inventory:'<svg viewBox="0 0 24 24"><path d="M4 7h16v14H4z"/><path d="M8 7V3h8v4"/><path d="M8 12h8"/></svg>',
    customers:'<svg viewBox="0 0 24 24"><circle cx="9" cy="8" r="3"/><path d="M3.5 19a5.5 5.5 0 0 1 11 0"/><path d="M16 6.5a3 3 0 0 1 0 5.8"/><path d="M17 15a5 5 0 0 1 3.5 4"/></svg>',
    sales:'<svg viewBox="0 0 24 24"><path d="M4 19V9"/><path d="M10 19V5"/><path d="M16 19v-7"/><path d="M22 19H2"/></svg>',
    purchases:'<svg viewBox="0 0 24 24"><path d="M6 6h15l-2 8H8L6 3H3"/><circle cx="9" cy="19" r="1.5"/><circle cx="18" cy="19" r="1.5"/></svg>',
    wholesale:'<svg viewBox="0 0 24 24"><path d="M3 10h18"/><path d="M5 10V7l2-3h10l2 3v3"/><path d="M5 10v10h14V10"/><path d="M9 20v-6h6v6"/></svg>',
    reports:'<svg viewBox="0 0 24 24"><path d="M4 20V10"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M22 20H2"/></svg>',
    billing:'<svg viewBox="0 0 24 24"><path d="M6 3h12v18l-3-2-3 2-3-2-3 2V3Z"/><path d="M9 8h6M9 12h6M9 16h3"/></svg>',
    companies:'<svg viewBox="0 0 24 24"><path d="M4 21V5h10v16"/><path d="M14 9h6v12"/><path d="M8 9h2M8 13h2M8 17h2M17 13h1M17 17h1"/></svg>',
    users:'<svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>',
    security:'<svg viewBox="0 0 24 24"><path d="M12 3 5 6v5c0 4.5 2.8 8.4 7 10 4.2-1.6 7-5.5 7-10V6l-7-3Z"/><path d="m9 12 2 2 4-4"/></svg>',
    modules:'<svg viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><path d="M17.5 14v7M14 17.5h7"/></svg>',
    sii:'<svg viewBox="0 0 24 24"><path d="M6 2h9l4 4v16H6z"/><path d="M14 2v5h5M9 12h6M9 16h6"/></svg>',
    notifications:'<svg viewBox="0 0 24 24"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/><path d="M10 21h4"/></svg>',
    audit:'<svg viewBox="0 0 24 24"><path d="M12 8v5l3 2"/><circle cx="12" cy="12" r="9"/><path d="M3 4v5h5"/></svg>',
    settings:'<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-2.83 2.83-.06-.06A1.7 1.7 0 0 0 15 19.4a1.7 1.7 0 0 0-1 .6 1.7 1.7 0 0 0-.4 1.1V21H9.6v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.88.34l-.06.06-2.83-2.83.06-.06A1.7 1.7 0 0 0 4.6 15a1.7 1.7 0 0 0-.6-1 1.7 1.7 0 0 0-1.1-.4H3V9.6h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.34-1.88l-.06-.06 2.83-2.83.06.06A1.7 1.7 0 0 0 9 4.6a1.7 1.7 0 0 0 1-.6 1.7 1.7 0 0 0 .4-1.1V3h4v.1A1.7 1.7 0 0 0 15 4.6a1.7 1.7 0 0 0 1.88-.34l.06-.06 2.83 2.83-.06.06A1.7 1.7 0 0 0 19.4 9c.3.1.0.7.6 1 .3.3.7.4 1.1.4h.1v4h-.1a1.7 1.7 0 0 0-1.7.6Z"/></svg>'
  };
  function icon(name){return ICONS[name]||ICONS.dashboard;}
  function friendlyValue(v){
    if(v===null||v===undefined||v==='') return '<span class="muted">Sin configurar</span>';
    if(typeof v==='boolean') return `<span class="badge ${v?'ok':'off'}">${v?'Activado':'Desactivado'}</span>`;
    if(typeof v==='string'||typeof v==='number') return `<span class="setting-value">${esc(v)}</span>`;
    if(Array.isArray(v)) return v.length?`<div class="value-chips">${v.slice(0,6).map(x=>`<span>${esc(typeof x==='object'?'Elemento':x)}</span>`).join('')}${v.length>6?`<span>+${v.length-6}</span>`:''}</div>`:'<span class="muted">Sin elementos</span>';
    if(typeof v==='object'){const entries=Object.entries(v).slice(0,5);return entries.length?`<div class="value-summary">${entries.map(([k,val])=>`<span><b>${esc(k.replace(/_/g,' '))}</b>${esc(typeof val==='object'?'Configurado':String(val))}</span>`).join('')}</div>`:'<span class="muted">Sin configurar</span>';}
    return `<span class="setting-value">${esc(String(v))}</span>`;
  }
  function settingSignature(x){ return `${String(x?.module||'').toUpperCase()}:${String(x?.key||'')}`; }
  function settingName(x){
    const sig=settingSignature(x);
    return ({'BRANDING:theme':'Apariencia del sistema','SECURITY:session':'Seguridad de sesión','SYSTEM:locale':'Región e idioma'})[sig] || `${x.module} · ${x.key}`;
  }
  function themeSwatch(label,color){return `<span class="theme-chip"><i style="background:${esc(color)}"></i>${esc(label)}</span>`;}
  function settingPreview(x){
    const v=x?.value||{}, sig=settingSignature(x);
    if(sig==='BRANDING:theme') return `<div class="theme-preview-list">${themeSwatch('Principal',v.primary||'#2563EB')}${themeSwatch('Menú',v.secondary||'#0B1830')}${themeSwatch('Fondo',v.background||'#F5F7FB')}${themeSwatch('Texto botón',v.button_text||'#FFFFFF')}</div>`;
    if(sig==='SECURITY:session') return `<div class="value-summary"><span><b>Duración</b>${esc(v.minutes??480)} min</span><span><b>Bloqueo</b>${esc(v.lock_minutes??15)} min</span><span><b>Intentos</b>${esc(v.max_failed_attempts??5)}</span><span><b>Autenticación</b>Sesión SiasCloud</span></div>`;
    if(sig==='SYSTEM:locale') return `<div class="value-summary"><span><b>País</b>${esc(v.country||'CL')}</span><span><b>Moneda</b>${esc(v.currency||'CLP')}</span><span><b>Idioma</b>${esc(v.language||'es-CL')}</span><span><b>Zona horaria</b>${esc(v.timezone||'America/Santiago')}</span></div>`;
    return friendlyValue(v);
  }
  function shadeColor(hex,percent){
    const h=String(hex||'').replace('#',''); if(!/^[0-9a-f]{6}$/i.test(h)) return hex;
    const n=parseInt(h,16), amt=Math.round(2.55*percent), r=Math.max(0,Math.min(255,(n>>16)+amt)), g=Math.max(0,Math.min(255,((n>>8)&255)+amt)), b=Math.max(0,Math.min(255,(n&255)+amt));
    return '#'+((1<<24)+(r<<16)+(g<<8)+b).toString(16).slice(1).toUpperCase();
  }
  function applyTheme(value={}){
    const root=document.documentElement, primary=value.primary||'#2563EB', secondary=value.secondary||'#0B1830', background=value.background||'#F5F7FB', buttonText=value.button_text||'#FFFFFF';
    root.style.setProperty('--primary',primary); root.style.setProperty('--primary-hover',shadeColor(primary,-12)); root.style.setProperty('--primary-soft',shadeColor(primary,43));
    root.style.setProperty('--sidebar',secondary); root.style.setProperty('--sidebar-2',shadeColor(secondary,6)); root.style.setProperty('--bg',background); root.style.setProperty('--button-text',buttonText);
    localStorage.setItem('sias_theme_cache',JSON.stringify({primary,secondary,background,button_text:buttonText}));
  }
  function applyCachedTheme(){try{const v=JSON.parse(localStorage.getItem('sias_theme_cache')||'{}');if(v&&Object.keys(v).length)applyTheme(v)}catch{}}
  applyCachedTheme();
  async function loadThemeSettings(){
    if(!can('SETTINGS_VIEW')) return;
    try{const r=await call('settings.list');const row=(r.rows||[]).find(x=>settingSignature(x)==='BRANDING:theme');if(row?.value)applyTheme(row.value)}catch{}
  }

  const cfg = window.SIASCLOUD_CONFIG || {};
  if(cfg.fixedConnection && cfg.functionsBaseUrl) localStorage.removeItem("sias_functions_url");
  const state = { token: sessionStorage.getItem("sias_token") || "", me:null, route:"dashboard", moduleRoute:null, viewRevision:0, cache:{}, notificationTimer:null, notificationKnown:null, notificationBusy:false };
  const viewStamp=()=>({revision:state.viewRevision,route:state.route,company:state.me?.companyId,token:state.token});
  const sameView=s=>s.revision===state.viewRevision&&s.route===state.route&&s.company===state.me?.companyId&&s.token===state.token;


  const DRAFT_PREFIX="sias_draft_v2";
  const DRAFT_MAX_AGE=14*24*60*60*1000;
  const draftScope=()=>`${state.me?.companyId||"none"}:${state.me?.user?.id||"anon"}`;
  function draftKey(kind,id=""){return `${DRAFT_PREFIX}:${draftScope()}:${String(kind||"general")}:${String(id||"default")}`;}
  function saveDraft(key,data){if(!key||!state.me)return;try{localStorage.setItem(key,JSON.stringify({saved_at:Date.now(),route:state.route,data}))}catch{}}
  function loadDraft(key){if(!key)return null;try{const raw=localStorage.getItem(key);if(!raw)return null;const box=JSON.parse(raw);if(!box||Date.now()-Number(box.saved_at||0)>DRAFT_MAX_AGE){localStorage.removeItem(key);return null;}return box.data??null;}catch{return null;}}
  function clearDraft(key){if(key)try{localStorage.removeItem(key)}catch{}}
  function isSensitiveControl(el){
    if(!el||!el.name||el.disabled)return true;
    const type=String(el.type||"").toLowerCase(),auto=String(el.autocomplete||"").toLowerCase(),name=String(el.name||"").toLowerCase();
    return type==="password"||type==="file"||auto.includes("password")||/(password|clave|secret|token|credential|api[_-]?key|^confirm_|^accept_|acknowledge|approval)/.test(name);
  }
  function serializeFormDraft(form){
    const out={},controls=[...form.elements];
    controls.forEach(el=>{
      if(isSensitiveControl(el))return;
      const type=String(el.type||"").toLowerCase(),same=controls.filter(x=>x.name===el.name&&!isSensitiveControl(x));
      if(type==="radio"){if(el.checked)out[el.name]={type:"radio",value:el.value};return;}
      if(type==="checkbox"&&same.length>1){if(!out[el.name])out[el.name]={type:"checkbox-group",value:[]};if(el.checked)out[el.name].value.push(el.value);return;}
      if(type==="checkbox"){out[el.name]={type,checked:el.checked,value:el.value};return;}
      if(el.tagName==="SELECT"&&el.multiple){out[el.name]={type:"select-multiple",value:[...el.selectedOptions].map(o=>o.value)};return;}
      out[el.name]={type,value:el.value};
    });
    return out;
  }
  function restoreFormDraft(form,data){
    if(!data||typeof data!=="object")return;
    [...form.elements].forEach(el=>{
      if(isSensitiveControl(el)||!Object.prototype.hasOwnProperty.call(data,el.name))return;
      const item=data[el.name]||{},type=String(el.type||"").toLowerCase();
      if(type==="radio")el.checked=String(el.value)===String(item.value);
      else if(type==="checkbox"&&item.type==="checkbox-group")el.checked=new Set(Array.isArray(item.value)?item.value:[]).has(el.value);
      else if(type==="checkbox")el.checked=Boolean(item.checked);
      else if(el.tagName==="SELECT"&&el.multiple){const set=new Set(Array.isArray(item.value)?item.value:[]);[...el.options].forEach(o=>o.selected=set.has(o.value));}
      else if(item.value!==undefined)el.value=item.value;
      el.dispatchEvent(new Event("input",{bubbles:true}));
      el.dispatchEvent(new Event("change",{bubbles:true}));
    });
  }
  let draftTimer=null;
  function modalDraftId(title){
    const hiddenId=$("#modalBody input[name='id']")?.value||"";
    return `${state.route}:${title}:${hiddenId||"new"}`;
  }
  function initModalDraft(title){
    const hasSensitive=$$("#modalForm input[type='password']").length>0;
    const hasEditable=[...modalForm.elements].some(el=>el.name&&!isSensitiveControl(el));
    delete modal.dataset.draftKey;delete modal.dataset.extraDraftKey;
    if(hasSensitive||!hasEditable)return;
    const key=draftKey("modal",modalDraftId(title));
    modal.dataset.draftKey=key;
    const saved=loadDraft(key);
    if(saved)queueMicrotask(()=>{if(modal.open&&modal.dataset.draftKey===key)restoreFormDraft(modalForm,saved);});
  }
  function saveActiveModalDraft(){
    const key=modal?.dataset?.draftKey;if(!key||!modal.open)return;
    clearTimeout(draftTimer);draftTimer=setTimeout(()=>saveDraft(key,serializeFormDraft(modalForm)),100);
  }
  function attachModalDraft(key){if(modal?.open&&key)modal.dataset.extraDraftKey=key;}
  function contentFormKey(form){return form?.id?draftKey("form",`${state.route}:${form.id}`):"";}
  function initContentFormDraft(form){
    if(!form?.id||["serverForm","setupForm","loginForm","modalForm"].includes(form.id))return;
    if(form.querySelector('input[type="password"]'))return;
    const key=contentFormKey(form),saved=loadDraft(key);
    form.dataset.siasDraftKey=key;
    if(saved)restoreFormDraft(form,saved);
  }
  function clearContentFormDraft(form){clearDraft(form?.dataset?.siasDraftKey||contentFormKey(form));}

  function serverUrl(){ return (cfg.functionsBaseUrl || localStorage.getItem("sias_functions_url") || "").replace(/\/$/, ""); }
  function endpoint(sii=false){ const base=serverUrl(); if(!base) throw new Error("SERVIDOR_NO_CONFIGURADO"); return `${base}/${sii ? (cfg.siiFunction||"siascloud-sii") : (cfg.systemFunction||"siascloud-system")}`; }
  function erpEndpoint(){ const base=serverUrl(); if(!base) throw new Error("SERVIDOR_NO_CONFIGURADO"); return `${base}/${cfg.erpFunction||"siascloud-erp"}`; }
  function setBusy(btn,on,label="Procesando…"){
    if(!btn)return;
    if(on){
      if(btn.dataset.busy==="1")return;
      btn.dataset.oldHtml=btn.innerHTML;
      btn.dataset.wasDisabled=String(btn.disabled);
      btn.dataset.busy="1";
      btn.classList.add("is-loading");
      btn.innerHTML=`<span class="button-spinner" aria-hidden="true"></span><span class="button-loading-text">${esc(label)}</span>`;
      btn.disabled=true;
      btn.setAttribute("aria-busy","true");
    }else{
      if(btn.dataset.busy!=="1")return;
      btn.innerHTML=btn.dataset.oldHtml||btn.innerHTML;
      btn.disabled=btn.dataset.wasDisabled==="true";
      btn.classList.remove("is-loading");
      btn.removeAttribute("aria-busy");
      delete btn.dataset.busy;
      delete btn.dataset.oldHtml;
      delete btn.dataset.wasDisabled;
    }
  }
  function toast(msg, error=false){ if(!msg)return;const t=$("#toast"); t.textContent=msg; t.className=`toast show${error?" error":""}`; clearTimeout(toast.t); toast.t=setTimeout(()=>t.className="toast",3200); }
  function bootMessage(msg=""){ $("#bootMessage").textContent=msg; }
  function errorText(v,fallback="Error inesperado"){ if(v?.code==='OBSOLETE_VIEW')return '';if(typeof v==="string"&&v.trim()) return v; if(v&&typeof v==="object"){ const a=[v.message,v.details,v.hint,v.code].filter(x=>typeof x==="string"&&x.trim()); if(a.length) return a.join(" | "); console.error("SiasCloud error detail:",v); } return fallback; }
  async function apiFetch(url,action,payload={},scope="erp"){
    const abort=new AbortController(),timeout=setTimeout(()=>abort.abort(),action.startsWith('imports.bulk.')?60000:90000);
    try{
    const stamp=viewStamp(),screenRead=action!=='notifications.list'&&/(?:\.(?:list|get|catalog|summary|sessions|search|flow|meta|items)$|^dashboard$)/.test(action);
    const headers={"Content-Type":"application/json"}; if(state.token) headers["X-Sias-Session"]=state.token;
    const res=await fetch(url,{method:"POST",headers,body:JSON.stringify({scope,action,payload}),cache:"no-store",signal:abort.signal});
    let data={}; try{data=await res.json();}catch{throw new Error(`Respuesta inválida del servidor (${res.status})`)}
    if(stamp.token!==state.token||(screenRead&&!sameView(stamp)))throw Object.assign(new Error(''),{code:'OBSOLETE_VIEW'});
    if(!res.ok||!data.ok){ if(res.status===401 && state.token){ sessionStorage.removeItem("sias_token"); state.token=""; state.me=null; showLogin("La sesión expiró. Ingresa nuevamente."); } throw new Error(errorText(data.message ?? data.error ?? data, data.code||`Error ${res.status}`)); }
    return data;
    }catch(error){if(abort.signal.aborted)throw new Error("La respuesta tardó demasiado. Revisa el estado de la operación antes de continuar.");throw error;}finally{clearTimeout(timeout);}
  }
  async function call(action,payload={},sii=false){ return apiFetch(endpoint(sii),action,payload,sii?"sii":"system"); }
  async function erpCall(action,payload={}){ return apiFetch(erpEndpoint(),action,payload); }
  function hideAuthForms(){ ["#serverForm","#setupForm","#loginForm"].forEach(x=>$(x).classList.add("hidden")); $("#bootLoading").classList.add("hidden"); }
  function showServer(msg=""){ hideAuthForms(); $("#serverForm").classList.remove("hidden"); $("#serverForm [name=functions_url]").value=serverUrl(); bootMessage(msg); hideErpSplash(); }
  function showLogin(msg=""){ state.viewRevision++;if(modal?.open)closeModal(true);$("#app").classList.add("hidden"); $("#boot").classList.remove("hidden"); hideAuthForms(); $("#loginForm").classList.remove("hidden"); bootMessage(msg); bindPasswordToggles($("#loginForm")); hideErpSplash(); }
  function showSetup(){ hideAuthForms(); $("#setupForm").classList.remove("hidden"); bootMessage(""); bindPasswordToggles($("#setupForm")); hideErpSplash(); }

  async function boot(){
    if(!serverUrl()){ showServer(); return; }
    try{
      const s=await call("status");
      if(typeof cfg.checkBackendVersion!=='function')throw new Error('Actualiza config.js y recarga el sitio con Ctrl+F5.');
      cfg.checkBackendVersion(s.function_version);
      if(!s.installed){ showSetup(); return; }
      if(state.token){ try{ const me=await call("me"); state.me=me; startApp(); return; }catch{} }
      showLogin();
    }catch(e){ const m=errorText(e,"Error de conexión"); if(cfg.fixedConnection){ hideAuthForms(); bootMessage(e.code==='BACKEND_VERSION_INCOMPATIBLE'?m:`No fue posible conectar con el servidor configurado: ${m}`); hideErpSplash(); } else { showServer(e.code==='BACKEND_VERSION_INCOMPATIBLE'?m:`No fue posible conectar: ${m}`); } }
  }

  $("#serverForm").addEventListener("submit",async e=>{ e.preventDefault(); const btn=e.submitter; setBusy(btn,true,"Comprobando…"); try{ const v=formData(e.currentTarget).get("functions_url").trim().replace(/\/$/,""); if(!/^https:\/\/.+\/functions\/v1$/i.test(v)) throw new Error("Usa una URL como https://TU-PROYECTO.supabase.co/functions/v1"); localStorage.setItem("sias_functions_url",v); const s=await call("status"); s.installed?showLogin("Servidor conectado correctamente."):showSetup(); }catch(err){bootMessage(errorText(err,"No se pudo completar la operación"))}finally{setBusy(btn,false)} });
  $("#changeServerBtn").addEventListener("click",()=>showServer());
  if(cfg.fixedConnection) $("#changeServerBtn").classList.add("hidden");
  $("#setupForm").addEventListener("submit",async e=>{ e.preventDefault(); const btn=e.submitter; setBusy(btn,true,"Creando sistema…"); bootMessage(""); try{ const f=Object.fromEntries(formData(e.currentTarget)); await call("bootstrap",f); toast("Instalación inicial completada"); showLogin("Sistema creado. Ingresa con la clave que acabas de definir."); }catch(err){bootMessage(errorText(err,"No se pudo completar la operación"))}finally{setBusy(btn,false)} });
  $("#loginForm").addEventListener("submit",async e=>{ e.preventDefault(); const btn=e.submitter; setBusy(btn,true,"Ingresando…"); bootMessage(""); try{ const f=Object.fromEntries(formData(e.currentTarget)); const r=await call("login",f); state.token=r.token; sessionStorage.setItem("sias_token",r.token); state.me={user:r.user,companyId:r.companyId,companies:r.companies||[],permissions:r.permissions}; startApp(); }catch(err){bootMessage(errorText(err,"No se pudo completar la operación"))}finally{setBusy(btn,false)} });

  const navItems=[
    ["importer","products","Importadores XLSX","IMPORT_VIEW","Administración"],
    ["billing-provider","billing","Proveedor de facturación","BILLING_VIEW","Administración"],
    ["pos","purchases","Punto de venta","POS_VIEW","Operación"],
    ["cash","billing","Caja y cierres","POS_VIEW","Operación"],
    ["credits","billing","Créditos de clientes","CREDIT_VIEW","Comercial"],
    ["prices","products","Listas de precios","PRODUCT_VIEW","Comercial"],
    ["staff","users","Responsables","SALES_VIEW","Comercial"],
    ["books","reports","Libros y mayor","REPORT_VIEW","Análisis"],
    ["dashboard","dashboard","Dashboard","DASHBOARD_VIEW","Operación"],
    ["products","products","Maestro de Productos","PRODUCT_VIEW","Operación"],
    ["inventory","inventory","Inventario","INVENTORY_VIEW","Operación"],
    ["movements","inventory","Libro de Movimientos","INVENTORY_VIEW","Operación"],
    ["receipts","purchases","Ingresos de mercadería","INVENTORY_VIEW","Operación"],
    ["supplies","products","Insumos y costos","PRODUCT_VIEW","Operación"],
    ["warehouses","inventory","Bodegas","INVENTORY_VIEW","Operación"],
    ["customers","customers","Clientes","CUSTOMER_VIEW","Comercial"],
    ["sales","sales","Ventas","SALES_VIEW","Comercial"],
    ["documents","billing","Documentos","SALES_VIEW","Comercial"],
    ["quotes","billing","Cotizaciones","SALES_VIEW","Comercial"],
    ["orders","purchases","Pedidos","SALES_VIEW","Comercial"],
    ["requests","notifications","Solicitudes web","SALES_VIEW","Comercial"],
    ["purchases","purchases","Compras","PURCHASE_VIEW","Comercial"],
    ["suppliers","purchases","Proveedores","SUPPLIER_VIEW","Comercial"],
    ["wholesale","wholesale","Mayoristas","WHOLESALE_VIEW","Comercial"],
    ["reports","reports","Reportes","REPORT_VIEW","Análisis"],
    ["billing","billing","Emitir documentos","BILLING_VIEW","Documentos y web"],
    ["store","wholesale","Sitio para clientes","SETTINGS_VIEW","Documentos y web"],
    ["companies","companies","Empresa","COMPANY_VIEW","Administración"],
    ["users","users","Usuarios","USER_VIEW","Administración"],
    ["security","security","Roles y permisos","ROLE_VIEW","Administración"],
    ["modules","modules","Módulos","MODULE_MANAGE","Administración"],
    ["sii","sii","SII / DTE","SII_VIEW","Administración"],
    ["audit","audit","Auditoría","AUDIT_VIEW","Sistema"],
    ["print-formats","billing","Formatos de impresión","SETTINGS_VIEW","Sistema"],
    ["settings","settings","Configuración","SETTINGS_VIEW","Sistema"]
  ];
  const hiddenRoutes=[["notifications","notifications","Notificaciones","NOTIFICATION_VIEW","Sistema"]];
  const allRoutes=[...navItems,...hiddenRoutes];
  function can(code){ return state.me?.user?.superadmin || state.me?.permissions?.includes(code); }
  function userInitials(user={}){return String(user.full_name||user.email||"SC").trim().split(/\s+/).slice(0,2).map(x=>x[0]||"").join("").toUpperCase()||"SC";}
  function avatarInner(user={}){const initials=userInitials(user),url=String(user.profile_photo_url||"").trim();return `<span>${esc(initials)}</span>${url?`<img src="${esc(url)}" alt="" loading="lazy">`:""}`;}
  function refreshIdentity(){
    if(!state.me?.user)return;
    $("#sessionUser").innerHTML=`<div class="session-avatar">${avatarInner(state.me.user)}</div><div class="session-meta"><strong>${esc(state.me.user.full_name)}</strong><span>${esc(state.me.user.email)}</span></div>`;
    const top=$("#topProfileAvatar"); if(top) top.innerHTML=avatarInner(state.me.user);
  }
  function activeCompany(){return (state.me?.companies||[]).find(x=>x.id===state.me?.companyId)||{};}
  function companyInitials(c={}){return String(c.trade_name||c.legal_name||"EMP").trim().split(/\s+/).slice(0,2).map(x=>x[0]||"").join("").toUpperCase()||"EMP";}
  function refreshCompanyIdentity(){
    const c=activeCompany(),name=$("#activeCompanyName"),rut=$("#activeCompanyRut"),img=$("#activeCompanyLogo"),fallback=$("#activeCompanyFallback");
    if(!name||!rut||!img||!fallback)return;
    name.textContent=c.trade_name||c.legal_name||"Empresa no seleccionada";
    rut.textContent=`RUT ${c.rut||"—"}`;
    fallback.textContent=companyInitials(c);
    const url=String(c.logo_url||"").trim();
    if(url){
      img.onload=()=>{img.classList.remove("hidden");fallback.classList.add("hidden")};
      img.onerror=()=>{img.classList.add("hidden");fallback.classList.remove("hidden")};
      img.src=url;
      img.alt=`Logo ${c.trade_name||c.legal_name||"empresa"}`;
    }else{img.removeAttribute("src");img.classList.add("hidden");fallback.classList.remove("hidden");}
  }
  async function refreshNotificationBell(openDropdown=false){
    const bell=$("#notificationBell"),drop=$("#notificationDropdown"),badge=$("#notificationBadge");
    if(!bell||!drop||!badge)return;
    if(state.notificationBusy){
      // Si el usuario pulsa la campana mientras corre el refresco automático,
      // abrimos el último contenido disponible en vez de ignorar el clic.
      if(openDropdown){drop.classList.remove("hidden");bell.setAttribute("aria-expanded","true");}
      return;
    }
    const allowed=can("NOTIFICATION_VIEW")&&!state.me?.user?.must_change_password;
    bell.classList.toggle("hidden",!allowed); if(!allowed){drop.classList.add("hidden");return;}
    state.notificationBusy=true;
    try{
      const r=await call("notifications.list"),rows=r.rows||[],unreadRows=rows.filter(x=>!x.read),unread=Number(r.unread_count??unreadRows.length);
      const currentIds=unreadRows.map(x=>String(x.id));
      const previous=Array.isArray(state.notificationKnown)?state.notificationKnown:null;
      const fresh=previous?unreadRows.filter(x=>!previous.includes(String(x.id))):[];
      state.notificationKnown=currentIds;
      badge.textContent=unread>99?"99+":String(unread);badge.classList.toggle("hidden",unread===0);
      drop.innerHTML=`<div class="notification-dropdown-head"><strong>Notificaciones</strong>${unread?'<button type="button" id="headerReadAll">Marcar leídas</button>':''}</div><div class="notification-mini-list">${rows.slice(0,7).map(x=>`<button type="button" class="notification-mini ${x.read?'':'unread'}" data-id="${esc(x.id)}" data-module="${esc(x.module||'')}" data-ref="${esc(x.reference_id||'')}"><i class="notification-mini-dot"></i><span class="notification-mini-copy"><strong>${esc(x.title)}</strong><span>${esc(x.message)}</span><small>${esc(fmtDate(x.created_at))}</small></span></button>`).join("")||'<div class="empty">Sin notificaciones.</div>'}</div><div class="notification-dropdown-foot"><button type="button" class="btn secondary small" id="openNotifications">Ver todas</button></div>`;
      $("#headerReadAll",drop)?.addEventListener("click",async e=>{e.stopPropagation();const b=e.currentTarget;setBusy(b,true,"Actualizando…");try{await call("notifications.readAll");await refreshNotificationBell(true);if(state.route==="notifications")render();}finally{if(b.isConnected)setBusy(b,false);}});
      $$(".notification-mini",drop).forEach(b=>b.addEventListener("click",async()=>{setBusy(b,true,"Abriendo…");try{if(b.classList.contains("unread"))await call("notifications.read",{id:b.dataset.id});drop.classList.add("hidden");bell.setAttribute("aria-expanded","false");const mod=String(b.dataset.module||"").toUpperCase();navigate(mod==="WHOLESALE"?"wholesale":mod==="ORDERS"?"orders":"notifications");}finally{if(b.isConnected)setBusy(b,false);}}));
      $("#openNotifications",drop)?.addEventListener("click",()=>{drop.classList.add("hidden");bell.setAttribute("aria-expanded","false");navigate("notifications")});
      if(fresh.length){
        const newest=fresh[0],isOrder=String(newest.module||"").toUpperCase()==="WHOLESALE"||/pedido mayorista/i.test(String(newest.title||""));
        toast(`${newest.title}${newest.message?` · ${newest.message}`:""}`);
        if(isOrder&&["wholesale","orders"].includes(state.route))render();
      }
      if(openDropdown){drop.classList.remove("hidden");bell.setAttribute("aria-expanded","true");}
    }catch(e){console.warn("No se pudo actualizar la campana",e);}
    finally{state.notificationBusy=false;}
  }
  function startApp(){
    hideErpSplash();
    $("#boot").classList.add("hidden"); $("#app").classList.remove("hidden");
    loadThemeSettings();
    refreshIdentity();
    refreshCompanyIdentity();
    const companySwitcher=$("#companySwitcher"), companies=state.me.companies||[];
    companySwitcher.innerHTML=companies.map(x=>`<option value="${esc(x.id)}" ${x.id===state.me.companyId?'selected':''}>${esc(x.trade_name||x.legal_name)}</option>`).join("");
    companySwitcher.classList.toggle("hidden",companies.length<=1||state.me.user.must_change_password);
    const groups=new Map();
    for(const item of navItems.filter(x=>can(x[3]))){if(!groups.has(item[4]))groups.set(item[4],[]);groups.get(item[4]).push(item);}
    $("#nav").innerHTML=[...groups].map(([label,items],i)=>`<details class="nav-group" data-nav-group="${esc(label)}"><summary class="nav-group-toggle" title="${esc(label)}" aria-controls="nav-group-${i}" aria-expanded="false"><span class="nav-icon">${icon(items[0][1])}</span><span class="nav-group-title">${esc(label)}</span><svg class="nav-group-chevron" viewBox="0 0 24 24" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg></summary><div class="nav-group-items" id="nav-group-${i}">${items.map(x=>`<button type="button" class="nav-btn" data-route="${x[0]}" title="${esc(x[2])}"><span class="nav-icon">${icon(x[1])}</span><span class="nav-label">${esc(x[2])}</span></button>`).join("")}</div></details>`).join("");
    $$("#nav .nav-group").forEach(group=>{
      group.addEventListener("toggle",()=>{
        $("summary",group).setAttribute("aria-expanded",String(group.open));
        if(group.open) $$("#nav .nav-group").forEach(other=>{if(other!==group)other.open=false;});
      });
      $("summary",group).addEventListener("click",()=>{
        if(!window.matchMedia("(max-width: 820px)").matches&&appShell.classList.contains("sidebar-collapsed")){
          appShell.classList.remove("sidebar-collapsed");
        }
      });
    });
    $$(".nav-btn").forEach(b=>b.addEventListener("click",()=>navigate(b.dataset.route)));
    if(state.me.user.must_change_password){
      $("#pageTitle").textContent="Cambio de clave obligatorio";
      $("#pageSub").textContent="Seguridad de la cuenta";
      $("#content").innerHTML='<div class="card"><h2>Debes definir una nueva clave</h2><p class="muted">Hasta completar este cambio no se habilitarán los módulos del ERP.</p></div>';
      forcePasswordChange();
      return;
    }
    state.notificationKnown=null;
    refreshNotificationBell();
    clearInterval(state.notificationTimer);state.notificationTimer=setInterval(()=>{if(state.token&&state.me)refreshNotificationBell()},10000);
    navigate(location.hash.replace("#","")||"dashboard");
  }
  function navigate(route){
    if(!allRoutes.some(x=>x[0]===route && can(x[3]))) route=allRoutes.find(x=>x[0]==="dashboard"&&can(x[3]))?.[0]||allRoutes.find(x=>can(x[3]))?.[0]||"";
    const openingModule=state.moduleRoute!==route;
    state.route=route;
    state.moduleRoute=route;
    history.replaceState(null,"",`#${route}`);
    $$(".nav-btn").forEach(b=>b.classList.toggle("active",b.dataset.route===route));
    $$("#nav .nav-group").forEach(group=>group.classList.toggle("active-group",Boolean(group.querySelector(".nav-btn.active"))));
    const item=allRoutes.find(x=>x[0]===route);
    $("#pageTitle").textContent=item?.[2]||"SiasCloud ERP";
    $("#pageSub").textContent=item?.[4]?`${item[4]} · SiasCloud ERP`:"SiasCloud ERP";
    $("#sidebar").classList.remove("open");document.body.classList.remove("menu-open");
    $("#notificationDropdown")?.classList.add("hidden");$("#notificationBell")?.setAttribute("aria-expanded","false");
    render(openingModule);
  }
  async function render(showModuleSplash=false){
    const item=allRoutes.find(x=>x[0]===state.route),endModuleSplash=showModuleSplash?window.SiasSplash.beginModule(`Abriendo ${item?.[2]||'módulo'}…`,{minimum:220}):()=>{};
    state.viewRevision++;const stamp=viewStamp(),c=$("#content");
    if(!state.route){c.innerHTML='<div class="card"><h3>Sin módulos asignados</h3><p class="muted">Solicita al administrador los permisos para tu trabajo.</p></div>';endModuleSplash();return;}
    c.innerHTML=`<div class="center"><span class="spinner"></span><p>Cargando…</p></div>`;
    try{
      await ({importer:()=>window.SiasImporters.render(),'billing-provider':()=>window.SiasOperations.billingProvider(),pos:()=>window.SiasRetail.pos(),cash:()=>window.SiasRetail.cash(),credits:()=>window.SiasRetail.credits(),prices:()=>window.SiasRetail.prices(),staff:()=>window.SiasRetail.staff(),books:()=>window.SiasRetail.books(),dashboard:renderDashboard,products:renderProducts,inventory:renderInventory,movements:()=>window.SiasRetail.movements(),receipts:()=>window.SiasOperations.documents("RECEIPTS"),supplies:()=>window.SiasOperations.products("SUPPLY"),warehouses:()=>window.SiasOperations.warehouses(),documents:()=>window.SiasOperations.documents("ALL"),quotes:()=>window.SiasOperations.documents("QUOTE"),orders:()=>window.SiasOperations.documents("ORDER"),requests:()=>window.SiasOperations.documents("REQUEST"),suppliers:()=>window.SiasOperations.suppliers(),store:()=>window.SiasOperations.store(),customers:renderCustomers,sales:renderSales,purchases:renderPurchases,wholesale:renderWholesale,reports:renderReports,billing:renderBilling,companies:renderCompanies,users:renderUsers,security:renderSecurity,modules:renderModules,sii:renderSii,notifications:renderNotifications,audit:renderAudit,'print-formats':renderPrintFormats,settings:renderSettings}[state.route]||renderDashboard)();
      if(!sameView(stamp))return;
      window.SiasImporters.attach(state.route);
    }catch(e){
      if(!sameView(stamp)||e?.code==='OBSOLETE_VIEW')return;
      const detail=errorText(e,"No fue posible cargar este módulo"),schemaMissing=/(?:column|relation|function).*does not exist|could not find.*(?:column|table|function)|schema cache/i.test(detail);
      if(schemaMissing)console.error("SiasCloud: estructura pendiente de actualizar",e);
      c.innerHTML=`<div class="card"><h3>${schemaMissing?"Actualización de la base requerida":"Error"}</h3><p class="danger-text">${esc(schemaMissing?"Aplica las actualizaciones SQL indicadas en LEEME_PRIMERO.md, incluida ACTUALIZACION_REVISION_V3_1_5.sql, y vuelve a intentar.":detail)}</p><button class="btn primary" id="retry">Reintentar</button></div>`;
      $("#retry")?.addEventListener("click",()=>render(false));
    }finally{endModuleSplash();}
  }
  $("#refreshBtn").addEventListener("click",()=>{render();refreshNotificationBell();});
  const appShell=$("#app"), sidebar=$("#sidebar"), sidebarBackdrop=$("#sidebarBackdrop"), sidebarMenuBtn=$("#sidebarMenuBtn");
  const isMobileMenu=()=>window.matchMedia("(max-width: 820px)").matches;
  const canHoverSidebar=()=>window.matchMedia("(min-width: 821px) and (hover: hover) and (pointer: fine)").matches;
  function setDesktopSidebar(collapsed){
    if(isMobileMenu()) return;
    appShell.classList.toggle("sidebar-collapsed",Boolean(collapsed));
    sidebarMenuBtn?.setAttribute("aria-expanded",String(!collapsed));
  }
  function applySidebarState(){
    if(isMobileMenu()){
      appShell.classList.remove("sidebar-collapsed");
      sidebar.classList.remove("open");
      document.body.classList.remove("menu-open");
      sidebarMenuBtn?.setAttribute("aria-expanded","true");
    }else if(canHoverSidebar()){
      /* Escritorio con mouse: cerrado en reposo, se abre al entrar al menú. */
      setDesktopSidebar(true);
    }else{
      setDesktopSidebar(localStorage.getItem("sias_sidebar_collapsed")==="1");
    }
  }
  applySidebarState();
  window.addEventListener("resize",applySidebarState);

  /* Menú inteligente: en escritorio con mouse se expande al entrar y se contrae al salir. */
  sidebar.addEventListener("mouseenter",()=>{if(canHoverSidebar())setDesktopSidebar(false)});
  sidebar.addEventListener("mouseleave",()=>{if(canHoverSidebar())setDesktopSidebar(true)});
  sidebar.addEventListener("focusin",()=>{if(!isMobileMenu())setDesktopSidebar(false)});
  sidebar.addEventListener("focusout",e=>{if(!isMobileMenu()&&!sidebar.contains(e.relatedTarget))setDesktopSidebar(true)});

  $("#menuBtn").addEventListener("click",()=>{
    if(isMobileMenu()){const open=sidebar.classList.toggle("open");document.body.classList.toggle("menu-open",open);}
  });
  sidebarMenuBtn?.addEventListener("click",()=>{
    if(isMobileMenu()) return;
    const collapsed=!appShell.classList.contains("sidebar-collapsed");
    setDesktopSidebar(collapsed);
    if(!canHoverSidebar())localStorage.setItem("sias_sidebar_collapsed",collapsed?"1":"0");
  });
  sidebarBackdrop?.addEventListener("click",()=>{sidebar.classList.remove("open");document.body.classList.remove("menu-open")});
  $("#logoutBtn").addEventListener("click",async e=>{const b=e.currentTarget;setBusy(b,true,"Saliendo…");try{try{await call("logout")}catch{}sessionStorage.removeItem("sias_token");state.token="";state.me=null;showLogin("Sesión cerrada.");}finally{if(b.isConnected)setBusy(b,false);}});
  $("#changePasswordBtn")?.addEventListener("click",()=>passwordModal(false));
  $("#profileBtn")?.addEventListener("click",()=>profileModal());
  $("#sessionUser")?.addEventListener("click",()=>profileModal());
  $("#notificationBell")?.addEventListener("click",e=>{
    e.stopPropagation();
    const b=e.currentTarget,drop=$("#notificationDropdown"),open=drop.classList.contains("hidden");
    if(!open){drop.classList.add("hidden");b.setAttribute("aria-expanded","false");return;}

    // Abrir inmediatamente con el último contenido disponible.
    // La red nunca bloquea la apertura de la campana.
    if(!drop.innerHTML.trim())drop.innerHTML='<div class="empty notification-quick-loading">Actualizando notificaciones…</div>';
    drop.classList.remove("hidden");
    b.setAttribute("aria-expanded","true");

    // Refresco silencioso en segundo plano. Si ya existe un refresco automático,
    // refreshNotificationBell() reutiliza el contenido actual sin bloquear al usuario.
    Promise.resolve(refreshNotificationBell(false)).catch(err=>{
      console.warn("No se pudo actualizar la campana",err);
      if(drop.querySelector(".notification-quick-loading"))
        drop.innerHTML='<div class="empty">No fue posible actualizar las notificaciones.</div>';
    });
  });
  document.addEventListener("click",e=>{const wrap=$(".notification-menu-wrap");if(wrap&&!wrap.contains(e.target)){ $("#notificationDropdown")?.classList.add("hidden");$("#notificationBell")?.setAttribute("aria-expanded","false"); }});
  window.addEventListener("focus",()=>{if(state.token&&state.me)refreshNotificationBell();});
  document.addEventListener("visibilitychange",()=>{if(document.visibilityState==="visible"&&state.token&&state.me)refreshNotificationBell();});
  $("#companySwitcher")?.addEventListener("change",async e=>{const select=e.currentTarget;const old=state.me?.companyId;state.viewRevision++;closeModal(true);select.disabled=true;try{await call("companies.switch",{company_id:select.value});const me=await call("me");state.me=me;state.cache={};startApp();toast("Empresa activa actualizada");}catch(err){select.value=old||"";toast(errorText(err),true)}finally{select.disabled=false}});

  const modal=$("#modal"), modalForm=$("#modalForm"); let modalHandler=null;
  function openModal(title,html,handler,saveLabel="Guardar",locked=false){
    const save=$("#modalActions .primary");
    $("#modalTitle").textContent=title; $("#modalBody").innerHTML=html; save.textContent=saveLabel; save.type="submit"; save.onclick=null; modalHandler=handler;
    modal.dataset.locked=locked?"1":"0"; $("#modalClose").classList.toggle("hidden",locked); $("#modalCancel").classList.toggle("hidden",locked); modal.showModal();
    initModalDraft(title);
  }
  function closeModal(force=false,preserveDraft=false){
    if(!force&&modal.dataset.submitting==="1")return;if(modal.dataset.locked==="1"&&!force)return;
    if(!preserveDraft){clearDraft(modal.dataset.draftKey);clearDraft(modal.dataset.extraDraftKey);}
    clearTimeout(draftTimer);modal.close();modalHandler=null;modal.dataset.locked="0";delete modal.dataset.draftKey;delete modal.dataset.extraDraftKey;
  }
  $("#modalClose").addEventListener("click",()=>closeModal()); $("#modalCancel").addEventListener("click",()=>closeModal());
  modal.addEventListener("cancel",e=>{if(modal.dataset.locked==="1"||modal.dataset.submitting==="1")e.preventDefault();else{e.preventDefault();closeModal();}});
  modalForm.addEventListener("input",saveActiveModalDraft,true);modalForm.addEventListener("change",saveActiveModalDraft,true);
  const contentDraftObserver=new MutationObserver(()=>{$$("#content form[id]").forEach(form=>{if(form.dataset.siasDraftReady!=="1"){form.dataset.siasDraftReady="1";initContentFormDraft(form);}})});
  contentDraftObserver.observe($("#content"),{childList:true,subtree:true});
  const saveContentDraft=e=>{const form=e.target?.closest?.("#content form[id]");if(!form||!form.dataset.siasDraftKey)return;saveDraft(form.dataset.siasDraftKey,serializeFormDraft(form));};
  document.addEventListener("input",saveContentDraft,true);document.addEventListener("change",saveContentDraft,true);
  modalForm.addEventListener("submit",async e=>{
    e.preventDefault();if(!modalHandler||modal.dataset.submitting==="1")return;
    const handler=modalHandler,btn=$("#modalActions .primary");modal.dataset.submitting="1";setBusy(btn,true);
    try{const outcome=await handler(formData(e.currentTarget));closeModal(true);await render();setBusy(btn,false);modal.dataset.submitting="0";toast(outcome?.toast||"Cambios guardados");if(typeof outcome?.afterSave==="function")await outcome.afterSave();}
    catch(err){toast(errorText(err),true);}
    finally{modal.dataset.submitting="0";if(btn.disabled)setBusy(btn,false);}
  });

  function fileToDataUrl(file){return new Promise((resolve,reject)=>{const r=new FileReader();r.onload=()=>resolve(String(r.result||""));r.onerror=()=>reject(new Error("No fue posible leer la imagen"));r.readAsDataURL(file);});}
  async function prepareProfilePhoto(file){
    if(!(file instanceof File)||!file.size)return null;
    if(!["image/jpeg","image/png","image/webp"].includes(file.type))throw new Error("Usa una imagen JPG, PNG o WEBP");
    if(file.size>8*1024*1024)throw new Error("La fotografía no puede superar 8 MB");
    const src=await fileToDataUrl(file);
    return await new Promise((resolve,reject)=>{const img=new Image();img.onload=()=>{try{const max=720,scale=Math.min(1,max/Math.max(img.naturalWidth,img.naturalHeight)),w=Math.max(1,Math.round(img.naturalWidth*scale)),h=Math.max(1,Math.round(img.naturalHeight*scale)),canvas=document.createElement("canvas");canvas.width=w;canvas.height=h;const ctx=canvas.getContext("2d");ctx.fillStyle="#fff";ctx.fillRect(0,0,w,h);ctx.drawImage(img,0,0,w,h);resolve(canvas.toDataURL("image/jpeg",.88));}catch(e){reject(e)}};img.onerror=()=>reject(new Error("La imagen seleccionada no es válida"));img.src=src;});
  }
  function bindProfilePreview(){const input=$("#profilePhotoInput"),preview=$("#profilePhotoPreview"),placeholder=$("#profilePhotoPlaceholder"),remove=$("#profilePhotoRemove");input?.addEventListener("change",()=>{const f=input.files?.[0];if(!f)return;const url=URL.createObjectURL(f);if(preview){preview.src=url;preview.classList.remove("hidden")}placeholder?.classList.add("hidden");if(remove)remove.checked=false;});remove?.addEventListener("change",()=>{if(remove.checked){preview?.classList.add("hidden");placeholder?.classList.remove("hidden")}});}
  async function prepareCompanyLogo(file,zoom=1.06){
    if(!(file instanceof File)||!file.size)return null;
    if(file.size>8*1024*1024)throw new Error("El logotipo no puede superar 8 MB antes de optimizarse");
    zoom=Math.max(1,Math.min(1.65,Number(zoom)||1.06));
    const src=await fileToDataUrl(file);
    return await new Promise((resolve,reject)=>{
      const img=new Image();
      img.onload=()=>{
        try{
          if(!img.naturalWidth||!img.naturalHeight)throw new Error("IMAGEN_INVALIDA");
          const scanMax=1400,scanScale=Math.min(1,scanMax/Math.max(img.naturalWidth,img.naturalHeight));
          const sw=Math.max(1,Math.round(img.naturalWidth*scanScale)),sh=Math.max(1,Math.round(img.naturalHeight*scanScale));
          const scan=document.createElement("canvas");scan.width=sw;scan.height=sh;
          const sctx=scan.getContext("2d",{willReadFrequently:true,alpha:true});if(!sctx)throw new Error("CANVAS_NO_DISPONIBLE");
          sctx.clearRect(0,0,sw,sh);sctx.drawImage(img,0,0,sw,sh);
          const data=sctx.getImageData(0,0,sw,sh).data;
          const corner=(x,y)=>{const i=(y*sw+x)*4;return [data[i],data[i+1],data[i+2],data[i+3]]};
          const cs=[corner(0,0),corner(sw-1,0),corner(0,sh-1),corner(sw-1,sh-1)];
          const bg=[0,0,0,0];for(const c of cs){for(let k=0;k<4;k++)bg[k]+=c[k]/4;}
          const alphaBg=bg[3]<40;
          let minX=sw,minY=sh,maxX=-1,maxY=-1;
          const step=Math.max(1,Math.floor(Math.max(sw,sh)/900));
          for(let y=0;y<sh;y+=step){for(let x=0;x<sw;x+=step){const i=(y*sw+x)*4,a=data[i+3];let fg=false;if(alphaBg){fg=a>28;}else if(a>24){const dr=data[i]-bg[0],dg=data[i+1]-bg[1],db=data[i+2]-bg[2];const dist=Math.sqrt(dr*dr+dg*dg+db*db);const chroma=Math.max(data[i],data[i+1],data[i+2])-Math.min(data[i],data[i+1],data[i+2]);fg=dist>31||chroma>34;}if(fg){if(x<minX)minX=x;if(x>maxX)maxX=x;if(y<minY)minY=y;if(y>maxY)maxY=y;}}}
          if(maxX<minX||maxY<minY){minX=0;minY=0;maxX=sw-1;maxY=sh-1;}
          const inv=1/scanScale;let x=minX*inv,y=minY*inv,w=(maxX-minX+1)*inv,h=(maxY-minY+1)*inv;
          const pad=Math.max(8,Math.round(Math.max(w,h)*.07));x=Math.max(0,x-pad);y=Math.max(0,y-pad);w=Math.min(img.naturalWidth-x,w+pad*2);h=Math.min(img.naturalHeight-y,h+pad*2);
          const zw=w/zoom,zh=h/zoom;x+=Math.max(0,(w-zw)/2);y+=Math.max(0,(h-zh)/2);w=zw;h=zh;
          const maxOut=1000,scale=Math.min(1,maxOut/Math.max(w,h)),ow=Math.max(1,Math.round(w*scale)),oh=Math.max(1,Math.round(h*scale));
          const canvas=document.createElement("canvas");canvas.width=ow;canvas.height=oh;const ctx=canvas.getContext("2d",{alpha:true});if(!ctx)throw new Error("CANVAS_NO_DISPONIBLE");
          ctx.clearRect(0,0,ow,oh);const radius=Math.max(8,Math.min(ow,oh)*.075);ctx.beginPath();ctx.moveTo(radius,0);ctx.arcTo(ow,0,ow,oh,radius);ctx.arcTo(ow,oh,0,oh,radius);ctx.arcTo(0,oh,0,0,radius);ctx.arcTo(0,0,ow,0,radius);ctx.closePath();ctx.clip();ctx.drawImage(img,x,y,w,h,0,0,ow,oh);
          // Quita únicamente el fondo conectado a los bordes. Así un lienzo blanco queda transparente
          // sin borrar detalles blancos/plata internos del logotipo.
          if(!alphaBg){
            const image=ctx.getImageData(0,0,ow,oh),px=image.data,seen=new Uint8Array(ow*oh),queue=new Int32Array(ow*oh);let head=0,tail=0;
            const threshold=44,nearBg=i=>{const dr=px[i]-bg[0],dg=px[i+1]-bg[1],db=px[i+2]-bg[2];return px[i+3]>0&&Math.sqrt(dr*dr+dg*dg+db*db)<=threshold;};
            const push=(xx,yy)=>{if(xx<0||yy<0||xx>=ow||yy>=oh)return;const pos=yy*ow+xx;if(seen[pos])return;const i=pos*4;if(!nearBg(i))return;seen[pos]=1;queue[tail++]=pos;};
            for(let xx=0;xx<ow;xx++){push(xx,0);push(xx,oh-1)}for(let yy=0;yy<oh;yy++){push(0,yy);push(ow-1,yy)}
            while(head<tail){const pos=queue[head++],xx=pos%ow,yy=(pos/ow)|0,i=pos*4;px[i+3]=0;push(xx-1,yy);push(xx+1,yy);push(xx,yy-1);push(xx,yy+1)}
            ctx.putImageData(image,0,0);
          }
          let out=canvas.toDataURL("image/webp",.93);if(!out.startsWith("data:image/webp;base64,"))out=canvas.toDataURL("image/png");
          const approx=Math.ceil((out.length-(out.indexOf(',')+1))*3/4);if(approx>3*1024*1024)throw new Error("LOGO_RESULTANTE_MUY_GRANDE");
          resolve(out);
        }catch(err){reject(err)}
      };
      img.onerror=()=>reject(new Error("El archivo no contiene una imagen JPG, PNG o WebP válida"));img.src=src;
    }).catch(err=>{if(String(err?.message||err).includes("MUY_GRANDE"))throw new Error("El logotipo optimizado supera 3 MB. Usa una imagen más pequeña.");throw err;});
  }
  function bindCompanyLogoPreview(){
    const input=$("#companyLogoInput"),preview=$("#companyLogoPreview"),fallback=$("#companyLogoFallback"),remove=$("#companyLogoRemove"),meta=$("#companyLogoMeta"),zoom=$("#companyLogoZoom");
    let ticket=0;
    const update=async()=>{const f=input?.files?.[0];if(!f)return;const mine=++ticket;if(meta)meta.textContent="Optimizando y recortando márgenes…";try{const out=await prepareCompanyLogo(f,zoom?.value||1.06);if(mine!==ticket)return;if(preview){preview.src=out;preview.classList.remove("hidden")}fallback?.classList.add("hidden");if(remove)remove.checked=false;if(meta)meta.textContent=`${f.name} · encuadre ${Math.round(Number(zoom?.value||1.06)*100)}% · márgenes recortados automáticamente`;}catch(err){if(meta)meta.textContent=String(err?.message||err);}};
    input?.addEventListener("change",update);zoom?.addEventListener("input",update);
    remove?.addEventListener("change",()=>{if(remove.checked){preview?.classList.add("hidden");fallback?.classList.remove("hidden");if(meta)meta.textContent="Se quitará el logotipo actual"}});
  }
  function profileModal(){
    const u=state.me.user||{},initials=userInitials(u),hasPhoto=Boolean(u.profile_photo_url);
    openModal("Mi perfil",`<div class="profile-editor"><div class="profile-photo-panel"><img id="profilePhotoPreview" class="profile-photo-preview ${hasPhoto?'':'hidden'}" src="${esc(u.profile_photo_url||'')}" alt="Foto de perfil"><div id="profilePhotoPlaceholder" class="profile-photo-placeholder ${hasPhoto?'hidden':''}">${esc(initials)}</div><label class="btn secondary small profile-upload-label">Cambiar foto<input id="profilePhotoInput" name="profile_photo" type="file" accept="image/jpeg,image/png,image/webp"></label>${hasPhoto?'<label class="switch-row"><input id="profilePhotoRemove" type="checkbox" name="remove_photo"> Quitar foto</label>':''}<small>JPG, PNG o WEBP. El sistema optimiza la imagen automáticamente.</small></div><div class="profile-fields"><label>Nombre completo<input name="full_name" required value="${esc(u.full_name||'')}"></label><label>Correo<input name="email" type="email" required value="${esc(u.email||'')}"></label><div class="profile-role-note">Desde aquí puedes actualizar tus datos y fotografía. Los roles se administran en <strong>Administración → Roles y permisos</strong>.</div></div></div>`,async fd=>{const file=fd.get("profile_photo"),payload={full_name:fd.get("full_name"),email:fd.get("email"),profile_photo_remove:fd.get("remove_photo")==="on"};if(file instanceof File&&file.size)payload.profile_photo_data=await prepareProfilePhoto(file);const r=await call("profile.save",payload);return{toast:"Perfil actualizado",afterSave:async()=>{state.me=await call("me");refreshIdentity();await refreshNotificationBell();}}});
    bindProfilePreview();
  }

  function passwordModal(locked=false){
    openModal(locked?"Cambio de clave obligatorio":"Cambiar mi clave",`<div class="form-stack"><label>Clave actual<input name="current_password" type="password" required autocomplete="current-password"></label><label>Nueva clave<input name="new_password" type="password" required minlength="10" autocomplete="new-password" placeholder="Mayúscula + minúscula + número"></label><label>Repetir nueva clave<input name="confirm_password" type="password" required minlength="10" autocomplete="new-password"></label><div class="section-note">La clave debe tener mínimo 10 caracteres, una mayúscula, una minúscula y un número.</div></div>`,async fd=>{const current=String(fd.get("current_password")||"");const next=String(fd.get("new_password")||"");const confirm=String(fd.get("confirm_password")||"");if(next!==confirm)throw new Error("Las nuevas claves no coinciden");await call("password.change",{current_password:current,new_password:next});state.me.user.must_change_password=false;if(locked)navigate("dashboard");},"Cambiar clave",locked);
  }
  function forcePasswordChange(){passwordModal(true)}

  async function renderSystemDashboardLegacy(){ const r=await call("dashboard"); const k=r.kpis; $("#content").innerHTML=`<div class="grid kpis"><div class="card kpi"><span>Usuarios activos</span><strong>${k.users}</strong></div><div class="card kpi"><span>Empresas</span><strong>${k.companies}</strong></div><div class="card kpi"><span>Módulos activos</span><strong>${k.modules}</strong></div><div class="card kpi"><span>Notificaciones</span><strong>${k.unread}</strong></div></div><div class="card mt"><div class="toolbar"><h2>Actividad reciente</h2></div>${tableAudit(r.recentAudit)}</div>`; }
  function tableAudit(rows){ if(!rows?.length)return`<div class="empty">Sin actividad registrada.</div>`;return`<div class="table-wrap"><table><thead><tr><th>Fecha</th><th>Módulo</th><th>Acción</th><th>Entidad</th></tr></thead><tbody>${rows.map(x=>`<tr><td>${esc(fmtDate(x.created_at))}</td><td>${esc(x.module||"—")}</td><td>${esc(x.action)}</td><td>${esc(x.entity||"—")} ${esc(x.entity_id||"")}</td></tr>`).join("")}</tbody></table></div>`; }

  async function renderCompanies(){ const r=await call("companies.list"); state.cache.companies=r.rows; $("#content").innerHTML=`<div class="card"><div class="toolbar"><h2>Empresas</h2>${can("COMPANY_MANAGE")&&state.me.user.superadmin?'<button class="btn primary" id="newCompany">+ Nueva empresa</button>':""}</div>${r.rows.length?`<div class="table-wrap"><table><thead><tr><th>RUT</th><th>Razón social</th><th>Ciudad</th><th>Correo</th><th>Estado</th><th></th></tr></thead><tbody>${r.rows.map(x=>`<tr><td>${esc(x.rut||"—")}</td><td><strong>${esc(x.legal_name)}</strong><br><span class="muted">${esc(x.trade_name||"")}</span></td><td>${esc(x.city||x.commune||"—")}</td><td>${esc(x.email||"—")}</td><td>${x.active?'<span class="badge ok">ACTIVA</span>':'<span class="badge off">INACTIVA</span>'}</td><td><button class="btn secondary small editCompany" data-id="${x.id}">Editar</button></td></tr>`).join("")}</tbody></table></div>`:'<div class="empty">No hay empresas.</div>'}</div>`; $("#newCompany")?.addEventListener("click",()=>companyModal(null)); $$(".editCompany").forEach(b=>b.addEventListener("click",()=>companyModal(r.rows.find(x=>x.id===b.dataset.id)))); }
  function companyModal(x){
    x=x||{};
    const companyName=x.trade_name||x.legal_name||"Empresa",initials=companyName.split(/\s+/).filter(Boolean).slice(0,2).map(v=>v[0]).join("").toUpperCase()||"EM";
    openModal(x.id?"Editar empresa":"Nueva empresa",`<div class="form-grid"><input type="hidden" name="id" value="${esc(x.id||"")}"><label>RUT<input name="rut" value="${esc(x.rut||"")}"></label><label>Razón social<input name="legal_name" required value="${esc(x.legal_name||"")}"></label><label>Nombre fantasía<input name="trade_name" value="${esc(x.trade_name||"")}"></label><label>Giro<input name="business_activity" value="${esc(x.business_activity||"")}"></label><label class="full">Dirección<input name="address" value="${esc(x.address||"")}"></label><label>Comuna<input name="commune" value="${esc(x.commune||"")}"></label><label>Ciudad<input name="city" value="${esc(x.city||"")}"></label><label>Región<input name="region" value="${esc(x.region||"")}"></label><label>Teléfono<input name="phone" value="${esc(x.phone||"")}"></label><label>Correo<input name="email" type="email" value="${esc(x.email||"")}"></label><label>Web<input name="website" value="${esc(x.website||"")}"></label><div class="full company-logo-editor"><div class="company-logo-preview-wrap"><img id="companyLogoPreview" class="company-logo-preview ${x.logo_url?'':'hidden'}" src="${esc(x.logo_url||'')}" alt="Logotipo de la empresa"><div id="companyLogoFallback" class="company-logo-fallback ${x.logo_url?'hidden':''}">${esc(initials)}</div></div><div class="company-logo-copy"><strong>Logotipo de la empresa</strong><label class="btn secondary small company-logo-upload">Seleccionar imagen<input id="companyLogoInput" name="logo_file" type="file" accept="image/*,.png,.jpg,.jpeg,.webp"></label><small id="companyLogoMeta">SiasCloud recorta márgenes vacíos y redondea suavemente el logo antes de guardarlo.</small><label class="company-logo-zoom">Encuadre <input id="companyLogoZoom" type="range" min="1" max="1.65" step="0.05" value="1.06"><span>Acerca el contenido si aún queda pequeño</span></label>${x.logo_url?'<label class="switch-row"><input id="companyLogoRemove" name="logo_remove" type="checkbox"> Quitar logotipo actual</label>':''}</div></div><label class="toggle-card full"><input name="show_logo_documents" type="checkbox" ${x.show_logo_documents!==false?"checked":""}><span><strong>Mostrar logotipo en documentos</strong><small>Aplica a documentos internos y formatos A4/80/58 generados por SiasCloud. El PDF A4 oficial de Facturacion.cl no se modifica.</small></span></label><label class="switch"><input name="active" type="checkbox" ${x.active!==false?"checked":""}> Empresa activa</label></div>`,async fd=>{
      const o=Object.fromEntries([...fd].filter(([k])=>k!=="logo_file"));
      o.active=fd.get("active")==="on";o.show_logo_documents=fd.get("show_logo_documents")==="on";o.logo_url=x.logo_url||null;o.logo_remove=fd.get("logo_remove")==="on";
      const file=fd.get("logo_file");if(file instanceof File&&file.size)o.logo_data=await prepareCompanyLogo(file,$("#companyLogoZoom")?.value||1.06);
      await call("companies.save",o);const me=await call("me");state.me=me;refreshCompanyIdentity();
    });
    bindCompanyLogoPreview();
  }

  async function getRoles(){ const r=await call("roles.list"); state.cache.roles=r; return r; }
  async function renderUsers(){
    const [u,rr]=await Promise.all([call("users.list"),getRoles()]); state.cache.users=u.rows;
    $("#content").innerHTML=`<div class="card"><div class="toolbar"><div><h2>Usuarios</h2><div class="muted">Edita datos, fotografía, roles, clave y estado de acceso.</div></div>${can("USER_MANAGE")?'<button class="btn primary" id="newUser">+ Nuevo usuario</button>':""}</div><div class="table-wrap"><table><thead><tr><th>Usuario</th><th>Roles</th><th>Último ingreso</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>${u.rows.map(x=>{const editable=can("USER_MANAGE")&&(!x.superadmin||state.me.user.superadmin);const canToggle=editable&&x.id!==state.me.user.id&&!x.superadmin;return `<tr><td><div class="user-cell"><div class="avatar-frame">${avatarInner(x)}</div><div class="user-cell-copy"><strong>${esc(x.full_name)}</strong><span class="muted">${esc(x.email)}</span></div></div></td><td>${x.superadmin?'<span class="badge warn">SUPERADMIN</span>':(x.roles||[]).map(z=>`<span class="badge off">${esc(z.name)}</span>`).join(" ")||"—"}</td><td>${esc(fmtDate(x.last_login_at))}</td><td>${x.active?'<span class="badge ok">ACTIVO</span>':'<span class="badge off">INACTIVO</span>'}</td><td><div class="row-actions">${editable?`<button class="btn secondary small editUser" data-id="${x.id}">Editar</button>${x.id!==state.me.user.id?`<button class="btn secondary small resetUser" data-id="${x.id}">Clave</button>`:''}${canToggle?`<button class="btn ${x.active?'danger':'primary'} small toggleUser" data-id="${x.id}" data-active="${!x.active}">${x.active?'Desactivar':'Activar'}</button>`:''}`:"—"}</div></td></tr>`}).join("")}</tbody></table></div></div>`;
    $("#newUser")?.addEventListener("click",()=>userModal(null,rr.roles));
    $$(".editUser").forEach(b=>b.addEventListener("click",()=>userModal(u.rows.find(x=>x.id===b.dataset.id),rr.roles)));
    $$(".resetUser").forEach(b=>b.addEventListener("click",()=>resetPassword(b.dataset.id)));
    $$(".toggleUser").forEach(b=>b.addEventListener("click",async()=>{setBusy(b,true,"Actualizando…");try{await call("users.toggle",{id:b.dataset.id,active:b.dataset.active==="true"});toast("Estado actualizado");render()}catch(e){toast(errorText(e),true)}finally{if(b.isConnected)setBusy(b,false)}}));
  }
  function userModal(x,roles){
    x=x||{};const selected=new Set((x.roles||[]).map(z=>z.code)),hasPhoto=Boolean(x.profile_photo_url),initials=userInitials(x),roleOptions=roles.filter(r=>r.code!=="SUPERADMIN"&&r.active!==false);
    openModal(x.id?"Editar usuario":"Nuevo usuario",`<div class="profile-editor"><div class="profile-photo-panel"><img id="profilePhotoPreview" class="profile-photo-preview ${hasPhoto?'':'hidden'}" src="${esc(x.profile_photo_url||'')}" alt="Foto de perfil"><div id="profilePhotoPlaceholder" class="profile-photo-placeholder ${hasPhoto?'hidden':''}">${esc(initials)}</div><label class="btn secondary small profile-upload-label">${hasPhoto?'Cambiar foto':'Agregar foto'}<input id="profilePhotoInput" name="profile_photo" type="file" accept="image/jpeg,image/png,image/webp"></label>${hasPhoto?'<label class="switch-row"><input id="profilePhotoRemove" type="checkbox" name="remove_photo"> Quitar foto</label>':''}<small>La foto se optimiza antes de enviarse.</small></div><div class="profile-fields"><input type="hidden" name="id" value="${esc(x.id||'')}"><label>Nombre<input name="full_name" required value="${esc(x.full_name||'')}"></label><label>Correo<input name="email" type="email" required value="${esc(x.email||'')}"></label>${!x.id?'<label>Clave inicial<input name="password" type="password" required minlength="10" placeholder="Mayúscula + minúscula + número"></label>':""}${x.superadmin?'<div class="profile-role-note">Este usuario es SUPERADMIN. Sus permisos globales no dependen de roles de empresa.</div>':`<div><strong>Roles de empresa</strong><div class="perm-grid mt">${roleOptions.map(r=>`<label class="perm-item"><input type="checkbox" name="roles" value="${r.id}" ${selected.has(r.code)?"checked":""}> ${esc(r.name)}</label>`).join("")||'<span class="muted">No hay roles activos.</span>'}</div></div>`}<label class="switch-row"><input name="active" type="checkbox" ${x.active!==false?"checked":""} ${x.id===state.me.user.id?'disabled':''}> Usuario activo</label>${!x.id?'<label class="switch-row"><input name="must_change_password" type="checkbox" checked> Solicitar cambio de clave</label>':""}</div></div>`,async fd=>{const o={id:fd.get("id"),full_name:fd.get("full_name"),email:fd.get("email"),active:x.id===state.me.user.id?true:fd.get("active")==="on",must_change_password:fd.get("must_change_password")==="on",role_ids:x.superadmin?undefined:fd.getAll("roles"),profile_photo_remove:fd.get("remove_photo")==="on"};if(!x.id)o.password=fd.get("password");const file=fd.get("profile_photo");if(file instanceof File&&file.size)o.profile_photo_data=await prepareProfilePhoto(file);await call("users.save",o);if(x.id===state.me.user.id){state.me=await call("me");refreshIdentity();}});
    bindProfilePreview();
  }
  function resetPassword(id){openModal("Restablecer clave",`<div class="form-stack"><label>Nueva clave<input name="password" type="password" required minlength="10"></label><label class="switch-row"><input name="must_change_password" type="checkbox" checked> Solicitar cambio al próximo ingreso</label><div class="section-note">Al guardar se revocarán las sesiones existentes de este usuario.</div></div>`,async fd=>call("users.resetPassword",{id,password:fd.get("password"),must_change_password:fd.get("must_change_password")==="on"}),"Restablecer");}

  async function renderSecurity(){
    const r=await getRoles();
    $("#content").innerHTML=`<div class="card"><div class="toolbar"><div><h2>Roles y permisos</h2><div class="muted">Los roles personalizados son por empresa. Los roles de sistema sólo los puede editar el SUPERADMIN.</div></div>${can("ROLE_MANAGE")?'<button class="btn primary" id="newRole">+ Nuevo rol</button>':""}</div><div class="table-wrap"><table><thead><tr><th>Código</th><th>Rol</th><th>Permisos</th><th>Tipo</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>${r.roles.map(x=>{const editable=can("ROLE_MANAGE")&&(!x.system||state.me.user.superadmin);return `<tr><td class="mono">${esc(x.code)}</td><td><strong>${esc(x.name)}</strong><br><span class="muted">${esc(x.description||"")}</span></td><td>${x.permission_ids.length}</td><td>${x.system?'<span class="badge warn">SISTEMA</span>':'<span class="badge off">PERSONALIZADO</span>'}</td><td>${x.active!==false?'<span class="badge ok">ACTIVO</span>':'<span class="badge off">INACTIVO</span>'}</td><td>${editable?`<button class="btn secondary small editRole" data-id="${x.id}">Editar</button>`:"—"}</td></tr>`}).join("")}</tbody></table></div></div>`;
    $("#newRole")?.addEventListener("click",()=>roleModal(null,r));
    $$(".editRole").forEach(b=>b.addEventListener("click",()=>roleModal(r.roles.find(x=>x.id===b.dataset.id),r)));
  }
  function roleModal(x,r){
    x=x||{};const selected=new Set(x.permission_ids||[]),isSystem=Boolean(x.system);
    openModal(x.id?"Editar rol":"Nuevo rol",`<div class="form-grid"><input type="hidden" name="id" value="${esc(x.id||'')}"><label>Código<input name="code" required value="${esc(x.code||'')}" ${isSystem?'readonly':''}></label><label>Nombre<input name="name" required value="${esc(x.name||'')}"></label><label class="full">Descripción<input name="description" value="${esc(x.description||'')}"></label>${isSystem?'<div class="full role-system-note">Rol de sistema global. Como SUPERADMIN puedes editar su nombre, descripción y permisos; el código permanece protegido para no romper integraciones.</div>':''}<div class="full"><strong>Permisos</strong><div class="perm-grid mt">${r.permissions.map(p=>`<label class="perm-item"><input type="checkbox" name="permissions" value="${p.id}" ${selected.has(p.id)?"checked":""}> <strong>${esc(p.module)}</strong> · ${esc(p.name)}</label>`).join("")}</div></div>${!isSystem?`<label class="switch-row"><input name="active" type="checkbox" ${x.active!==false?'checked':''}> Rol activo</label>`:''}</div>`,async fd=>call("roles.save",{...Object.fromEntries(fd),active:isSystem?true:fd.get("active")==="on",permission_ids:fd.getAll("permissions")}));
  }

  async function renderModules(){const r=await call("modules.list");$("#content").innerHTML=`<div class="card"><div class="toolbar"><h2>Módulos del sistema</h2></div><div class="list">${r.rows.map(x=>`<div class="list-item"><div><strong>${esc(x.name)}</strong><div class="muted">${esc(x.description||"")} · <span class="mono">${esc(x.code)}</span></div></div><button class="btn ${x.active?'danger':'primary'} small modToggle" data-code="${x.code}" data-active="${!x.active}" ${(!state.me.user.superadmin||(["DASHBOARD","SETTINGS"].includes(x.code)&&x.active))?'disabled':''}>${x.active?'Desactivar':'Activar'}</button></div>`).join("")}</div></div>`;$$('.modToggle').forEach(b=>b.addEventListener('click',async()=>{setBusy(b,true,'Actualizando…');try{await call('modules.toggle',{code:b.dataset.code,active:b.dataset.active==='true'});toast('Módulo actualizado');render()}catch(e){toast(errorText(e),true)}finally{if(b.isConnected)setBusy(b,false)}}));}

  async function renderNotifications(){const r=await call("notifications.list");$("#content").innerHTML=`<div class="card"><div class="toolbar"><div><h2>Notificaciones</h2><div class="muted">Centro completo de avisos del sistema.</div></div><button class="btn secondary" id="readAll">Marcar todas como leídas</button></div><div class="list">${r.rows.length?r.rows.map(x=>`<div class="list-item"><div><strong>${esc(x.title)}</strong><div>${esc(x.message)}</div><small class="muted">${esc(fmtDate(x.created_at))}</small></div>${x.read?'<span class="badge off">LEÍDA</span>':`<button class="btn primary small readOne" data-id="${x.id}">Marcar leída</button>`}</div>`).join(""):'<div class="empty">Sin notificaciones.</div>'}</div></div>`;$("#readAll")?.addEventListener("click",async e=>{const b=e.currentTarget;setBusy(b,true,"Actualizando…");try{await call("notifications.readAll");toast("Notificaciones actualizadas");await refreshNotificationBell();render()}finally{if(b.isConnected)setBusy(b,false)}});$$(".readOne").forEach(b=>b.addEventListener("click",async()=>{setBusy(b,true,"Actualizando…");try{await call("notifications.read",{id:b.dataset.id});await refreshNotificationBell();render()}finally{if(b.isConnected)setBusy(b,false)}}));}
  async function renderAudit(){
    const [r,m]=await Promise.all([call("audit.list",{limit:150}),call("monitoring.list",{limit:100,open_only:false}).catch(()=>({rows:[]}))]);
    const severityBadge=v=>{const s=String(v||"INFO").toUpperCase(),cl=s==="CRITICAL"||s==="ERROR"?"off":s==="WARN"?"warn":"ok";return `<span class="badge ${cl}">${esc(s)}</span>`};
    const incidents=(m.rows||[]).length?`<div class="table-wrap"><table><thead><tr><th>Fecha</th><th>Nivel</th><th>Categoría</th><th>Incidencia</th><th>Referencia</th><th>Estado</th></tr></thead><tbody>${m.rows.map(x=>`<tr><td>${esc(fmtDate(x.created_at))}</td><td>${severityBadge(x.severity)}</td><td><strong>${esc(x.category||"—")}</strong><br><span class="muted">${esc(x.action||"")}</span></td><td>${esc(x.message||"—")}${x.request_id?`<br><small class="mono muted">Req: ${esc(x.request_id)}</small>`:""}</td><td>${esc(x.entity||"—")} ${esc(x.entity_id||"")}</td><td>${x.resolved?'<span class="badge ok">RESUELTA</span>':can("SETTINGS_MANAGE")?`<button class="btn secondary small resolveIncident" data-id="${x.id}">Resolver</button>`:'<span class="badge warn">ABIERTA</span>'}</td></tr>`).join("")}</tbody></table></div>`:'<div class="empty">Sin incidencias operativas registradas.</div>';
    $("#content").innerHTML=`<div class="card"><div class="toolbar"><div><h2>Monitoreo operativo</h2><div class="muted">DTE indeterminados/erróneos, importaciones fallidas y diferencias de caja.</div></div><span class="badge ${m.rows?.some(x=>!x.resolved)?'warn':'ok'}">${(m.rows||[]).filter(x=>!x.resolved).length} abiertas</span></div>${incidents}</div><div class="card mt"><div class="toolbar"><h2>Auditoría</h2><span class="muted">Últimos ${r.rows.length} movimientos</span></div>${tableAudit(r.rows)}</div>`;
    $$(".resolveIncident").forEach(b=>b.addEventListener("click",async()=>{setBusy(b,true,"Resolviendo…");try{await call("monitoring.resolve",{id:b.dataset.id});toast("Incidencia marcada como resuelta");await renderAudit()}catch(e){toast(errorText(e),true)}finally{if(b.isConnected)setBusy(b,false)}}));
  }

  const PRINT_FORMAT_LABELS={A4:'A4 · 210 × 297 mm','80MM':'Térmico · 80 mm','58MM':'Térmico · 57/58 mm'};
  const PRINT_DTE_TYPES=[['33','Factura electrónica'],['34','Factura exenta'],['39','Boleta electrónica'],['41','Boleta exenta'],['52','Guía de despacho electrónica'],['56','Nota de débito'],['61','Nota de crédito']];
  const PRINT_SYSTEM_TYPES=[['POS_RECEIPT','Comprobante POS'],['SALE','Venta'],['WHOLESALE','Venta mayorista'],['QUOTE','Cotización'],['ORDER','Pedido'],['REQUEST','Solicitud web'],['PURCHASE','Compra'],['RECEIPT','Ingreso de mercadería'],['ISSUE','Salida de productos'],['TRANSFER','Traslado entre bodegas'],['DELIVERY','Guía / despacho interno'],['CASH_CLOSE','Cierre y arqueo de caja']];
  const printOptions=selected=>Object.entries(PRINT_FORMAT_LABELS).map(([v,l])=>`<option value="${v}" ${selected===v?'selected':''}>${esc(l)}</option>`).join('');
  const printDefaults=()=>({defaults:{tributary:'A4',system:'A4',pos:'80MM'},issuance:{POS:39,SALE:33,WHOLESALE:33},tributary:{'33':'A4','34':'A4','39':'80MM','41':'80MM','52':'A4','56':'A4','61':'A4'},system:{POS_RECEIPT:'80MM',SALE:'A4',WHOLESALE:'A4',QUOTE:'A4',ORDER:'A4',REQUEST:'A4',PURCHASE:'A4',RECEIPT:'A4',ISSUE:'A4',TRANSFER:'A4',DELIVERY:'A4',CASH_CLOSE:'A4'}});
  function normalizePrintUi(value){const base=printDefaults(),v=value&&typeof value==='object'?value:{};for(const k of Object.keys(base.defaults))if(PRINT_FORMAT_LABELS[v.defaults?.[k]])base.defaults[k]=v.defaults[k];for(const k of Object.keys(base.issuance))if([33,34,39,41].includes(Number(v.issuance?.[k])))base.issuance[k]=Number(v.issuance[k]);for(const group of ['tributary','system'])for(const k of Object.keys(base[group]))if(PRINT_FORMAT_LABELS[v[group]?.[k]])base[group][k]=v[group][k];return base;}
  async function renderPrintFormats(){
    const company=state.me.companyId,r=await erpCall('printing.config.get'),formats=normalizePrintUi(r.formats),editable=can('SETTINGS_MANAGE');
    state.cache.printFormats=formats;
    const rows=(defs,group)=>defs.map(([key,label])=>`<div class="print-format-row"><div class="print-format-doc"><strong>${esc(label)}</strong><small>${group==='tributary'?`DTE ${esc(key)} · mismo folio/TED del emisor`:'Documento interno de SiasCloud'}</small></div><select class="print-format-select" data-print-group="${group}" data-print-key="${esc(key)}" ${editable?'':'disabled'}>${printOptions(formats[group][key])}</select><span class="print-paper-chip" data-paper-chip>${esc(formats[group][key].replace('MM',' mm'))}</span></div>`).join('');
    $('#content').innerHTML=`<section class="print-manager-head"><div><span class="eyebrow">SISTEMA · IMPRESIÓN</span><h2>Mantenedor de formatos de impresión</h2><p>Define el papel predeterminado por tipo de documento. El formato cambia solamente la representación impresa; nunca vuelve a emitir un DTE ni consume otro folio.</p></div>${editable?'<button type="button" class="btn primary" id="savePrintFormats">Guardar formatos</button>':''}</section><div class="print-defaults card"><div><h3>Reglas generales</h3><p class="muted">Se usan como respaldo para documentos nuevos que aún no tengan una regla individual.</p></div><div class="print-default-grid"><label>Tributarios por defecto<select id="printDefaultTributary" ${editable?'':'disabled'}>${printOptions(formats.defaults.tributary)}</select></label><label>Documentos internos por defecto<select id="printDefaultSystem" ${editable?'':'disabled'}>${printOptions(formats.defaults.system)}</select></label><label>POS por defecto<select id="printDefaultPos" ${editable?'':'disabled'}>${printOptions(formats.defaults.pos)}</select></label></div></div><div class="card mt"><div class="toolbar"><div><h3>Emisión predeterminada</h3><p class="muted">Define qué DTE aparece seleccionado desde el primer modal. El papel se toma automáticamente de la regla del DTE.</p></div></div><div class="print-default-grid"><label>POS<select id="printIssuePos" ${editable?'':'disabled'}>${[[39,'39 · Boleta electrónica'],[41,'41 · Boleta exenta'],[33,'33 · Factura electrónica'],[34,'34 · Factura exenta']].map(([v,l])=>`<option value="${v}" ${Number(formats.issuance.POS)===v?'selected':''}>${l}</option>`).join('')}</select></label><label>Venta<select id="printIssueSale" ${editable?'':'disabled'}>${[[33,'33 · Factura electrónica'],[34,'34 · Factura exenta'],[39,'39 · Boleta electrónica'],[41,'41 · Boleta exenta']].map(([v,l])=>`<option value="${v}" ${Number(formats.issuance.SALE)===v?'selected':''}>${l}</option>`).join('')}</select></label><label>Venta mayorista<select id="printIssueWholesale" ${editable?'':'disabled'}>${[[33,'33 · Factura electrónica'],[34,'34 · Factura exenta'],[39,'39 · Boleta electrónica'],[41,'41 · Boleta exenta']].map(([v,l])=>`<option value="${v}" ${Number(formats.issuance.WHOLESALE)===v?'selected':''}>${l}</option>`).join('')}</select></label></div></div><div class="two-col print-manager-grid"><section class="card"><div class="toolbar"><div><h3>Documentos tributarios</h3><p class="muted">Facturacion.cl continúa siendo el emisor. A4 usa el PDF oficial y los térmicos reutilizan el mismo DTE/TED.</p></div><div class="print-quick"><select id="bulkDteFormat" ${editable?'':'disabled'}>${printOptions(formats.defaults.tributary)}</select>${editable?'<button class="btn secondary small" type="button" id="applyDteFormat">Aplicar a todos</button>':''}</div></div><div class="print-format-list">${rows(PRINT_DTE_TYPES,'tributary')}</div></section><section class="card"><div class="toolbar"><div><h3>Documentos del sistema</h3><p class="muted">Comprobantes comerciales, inventario, POS y caja. Cada documento puede usar su propio papel.</p></div><div class="print-quick"><select id="bulkSystemFormat" ${editable?'':'disabled'}>${printOptions(formats.defaults.system)}</select>${editable?'<button class="btn secondary small" type="button" id="applySystemFormat">Aplicar a todos</button>':''}</div></div><div class="print-format-list">${rows(PRINT_SYSTEM_TYPES,'system')}</div></section></div><div class="card mt print-paper-guide"><div><div class="paper-shape a4"><span>A4</span></div><strong>A4</strong><small>Documentos extensos y archivo PDF.</small></div><div><div class="paper-shape p80"><span>80</span></div><strong>80 mm</strong><small>POS y térmica estándar.</small></div><div><div class="paper-shape p58"><span>58</span></div><strong>57/58 mm</strong><small>Impresoras térmicas compactas.</small></div><div class="section-note">Los formatos DTE térmicos respetan el documento ya emitido. El timbre/TED no se reemplaza ni se vuelve a generar por cambiar el ancho del papel.</div></div>`;
    const syncChip=select=>{const chip=select.closest('.print-format-row')?.querySelector('[data-paper-chip]');if(chip)chip.textContent=select.value.replace('MM',' mm');};
    $$('.print-format-select').forEach(x=>x.addEventListener('change',()=>syncChip(x)));
    $('#applyDteFormat')?.addEventListener('click',()=>{$$('.print-format-select[data-print-group="tributary"]').forEach(x=>{x.value=$('#bulkDteFormat').value;syncChip(x);});});
    $('#applySystemFormat')?.addEventListener('click',()=>{$$('.print-format-select[data-print-group="system"]').forEach(x=>{x.value=$('#bulkSystemFormat').value;syncChip(x);});});
    $('#savePrintFormats')?.addEventListener('click',async e=>{const btn=e.currentTarget;setBusy(btn,true,'Guardando…');try{const payload=printDefaults();payload.defaults={tributary:$('#printDefaultTributary').value,system:$('#printDefaultSystem').value,pos:$('#printDefaultPos').value};payload.issuance={POS:Number($('#printIssuePos').value),SALE:Number($('#printIssueSale').value),WHOLESALE:Number($('#printIssueWholesale').value)};$$('.print-format-select').forEach(x=>payload[x.dataset.printGroup][x.dataset.printKey]=x.value);const saved=await erpCall('printing.config.save',{formats:payload});state.cache.printFormats=normalizePrintUi(saved.formats);toast('Formatos de impresión guardados');if(state.me.companyId===company&&state.route==='print-formats')await renderPrintFormats();}catch(err){toast(errorText(err),true);}finally{if(btn.isConnected)setBusy(btn,false);}});
  }

  async function renderSettings(){
    const company=state.me.companyId;
    const [s,secrets,health]=await Promise.all([call("settings.list"),can("SECRETS_MANAGE")?call("secrets.list"):Promise.resolve({rows:[]}),call("status").catch(()=>({security:{}}))]);
    state.cache.settings=s.rows;
    const theme=(s.rows||[]).find(x=>settingSignature(x)==='BRANDING:theme'); if(theme?.value) applyTheme(theme.value);
    const stockRows=(s.rows||[]).filter(x=>settingSignature(x)==='INVENTORY:stock_policy');
    const stockPolicy=stockRows.find(x=>x.company_id===state.me.companyId)||stockRows.find(x=>!x.company_id)||null;
    const allowNegative=stockPolicy?.value?.allow_negative_stock===true;
    const visibleSettings=(s.rows||[]).filter(x=>settingSignature(x)!=='INVENTORY:stock_policy');
    const sec=health.security||{},productionReady=sec.production_mode&&sec.allowed_origin_configured;
    const productionCard=`<div class="card production-readiness-card"><div class="toolbar"><div><span class="eyebrow">SEGURIDAD DE DESPLIEGUE</span><h2>Estado de producción</h2><p class="muted">SiasCloud mantiene autenticación propia; <span class="mono">verify_jwt=false</span> es intencional.</p></div><span class="badge ${productionReady?'ok':'warn'}">${productionReady?'PRODUCCIÓN PROTEGIDA':sec.production_mode?'FALTA ORIGEN':'MODO DESARROLLO'}</span></div><div class="production-readiness-grid"><div><small>Autenticación</small><strong>Sesión SiasCloud</strong></div><div><small>JWT Supabase</small><strong>Desactivado por diseño</strong></div><div><small>Origen permitido</small><strong>${sec.allowed_origin_configured?'Configurado':'Pendiente para producción'}</strong></div><div><small>Backend</small><strong>${esc(health.function_version||'—')}</strong></div></div>${sec.production_mode&&!sec.allowed_origin_configured?'<div class="section-note warn mt">Configura <span class="mono">SIASCLOUD_ALLOWED_ORIGIN</span> con el dominio real antes de operar con clientes.</div>':''}</div>`;
    $("#content").innerHTML=productionCard+`<div class="card stock-policy-card"><div class="toolbar"><div><span class="eyebrow">INVENTARIO · POS</span><h2>Política global de stock</h2><p class="muted">Este interruptor controla todas las ventas de la empresa. No necesitas habilitarlo producto por producto.</p></div><span class="badge ${allowNegative?'warn':'ok'}" id="stockPolicyBadge">${allowNegative?'VENTA SIN STOCK ACTIVA':'STOCK PROTEGIDO'}</span></div><label class="toggle-card stock-global-switch"><input type="checkbox" id="allowNegativeStock" ${allowNegative?'checked':''} ${can("SETTINGS_MANAGE")?'':'disabled'}><span><strong>Permitir vender sin stock suficiente</strong><small>Al activarlo, una venta podrá dejar el inventario en negativo. Traslados y salidas manuales seguirán exigiendo stock disponible.</small></span></label><div class="section-note mt">Recomendación: mantenerlo desactivado salvo que tu operación necesite venta anticipada, regularización posterior o stock aún no recepcionado.</div></div><div class="two-col settings-layout"><div class="card"><div class="toolbar"><div><h2>Configuración visual y general</h2><p class="muted">Administra el sistema con controles visuales. No necesitas editar JSON ni códigos técnicos.</p></div>${can("SETTINGS_MANAGE")?'<button class="btn primary small" id="newSetting">+ Parámetro</button>':""}</div><div class="list settings-list">${visibleSettings.map(x=>`<div class="list-item setting-card"><div class="setting-card-main"><strong>${esc(settingName(x))}</strong><div class="muted">${esc(x.description||"")}</div><div class="setting-preview">${settingPreview(x)}</div></div>${can("SETTINGS_MANAGE")?`<button class="btn secondary small editSetting" data-id="${x.id}">Editar</button>`:""}</div>`).join("")}</div></div><div class="card"><div class="toolbar"><div><h2>Credenciales protegidas</h2><p class="muted">Contraseñas y claves se cifran en el servidor.</p></div>${can("SECRETS_MANAGE")?'<button class="btn primary small" id="newSecret">+ Guardar secreto</button>':""}</div><div class="section-note">Los valores protegidos nunca se muestran nuevamente en el navegador.</div><div class="list mt">${secrets.rows.map(x=>`<div class="list-item"><div><strong>${esc(x.scope)} · ${esc(x.key)}</strong><div class="muted">${esc(x.hint||"Configurado")} · ${esc(fmtDate(x.updated_at))}</div></div><span class="badge ok">PROTEGIDO</span></div>`).join("")||'<div class="empty">Sin secretos.</div>'}</div></div></div>`;
    $("#allowNegativeStock")?.addEventListener("change",async e=>{const input=e.currentTarget;input.disabled=true;try{await call("settings.save",{id:stockPolicy?.company_id===state.me.companyId?stockPolicy.id:undefined,module:"INVENTORY",key:"stock_policy",description:"Política global de stock para ventas",value:{allow_negative_stock:input.checked},global:false,company_id:company});toast(input.checked?"Venta sin stock habilitada":"Protección de stock habilitada");if(input.isConnected&&state.me?.companyId===company&&state.route==='settings')await render();}catch(err){input.checked=!input.checked;toast(errorText(err),true);input.disabled=false;}});
    $("#newSetting")?.addEventListener("click",()=>settingModal(null));
    $$('.editSetting').forEach(b=>b.addEventListener('click',()=>settingModal(visibleSettings.find(x=>x.id===b.dataset.id))));
    $("#newSecret")?.addEventListener("click",secretModal);
  }
  function genericSettingRows(value={}){
    const rows=Object.entries(value||{}); if(!rows.length) rows.push(['','']);
    return rows.map(([k,v])=>`<div class="setting-builder-row"><input data-setting-key placeholder="Nombre del campo" value="${esc(k)}"><select data-setting-type><option value="text" ${typeof v==='string'?'selected':''}>Texto</option><option value="number" ${typeof v==='number'?'selected':''}>Número</option><option value="boolean" ${typeof v==='boolean'?'selected':''}>Sí / No</option></select><input data-setting-value value="${esc(typeof v==='boolean'?(v?'true':'false'):v??'')}" placeholder="Valor"><button type="button" class="btn secondary small remove-setting-field">×</button></div>`).join('');
  }
  function settingEditorBody(x){
    const v=x.value||{}, sig=settingSignature(x), base=`<input type="hidden" name="id" value="${esc(x.id||'')}"><div class="form-grid setting-meta"><label>Módulo<input name="module" required ${x.id?'readonly':''} value="${esc(x.module||'SYSTEM')}"></label><label>Clave<input name="key" required ${x.id?'readonly':''} value="${esc(x.key||'')}"></label><label class="full">Descripción<input name="description" value="${esc(x.description||'')}"></label></div>`;
    let body='';
    if(sig==='BRANDING:theme') body=`<div class="visual-config-section"><div class="config-section-head"><div><h3>Colores de SiasCloud</h3><p>Haz clic sobre cada muestra para elegir el color visualmente.</p></div></div><div class="color-picker-grid">${[['primary','Color principal','Botones, selección y acciones',v.primary||'#2563EB'],['secondary','Menú lateral','Navegación principal',v.secondary||'#0B1830'],['background','Fondo general','Área de trabajo del sistema',v.background||'#F5F7FB'],['button_text','Texto de botones','Texto sobre botones principales',v.button_text||'#FFFFFF']].map(([k,l,d,c])=>`<label class="color-picker-card"><span class="color-preview" style="background:${esc(c)}"></span><span class="color-picker-copy"><strong>${esc(l)}</strong><small>${esc(d)}</small></span><input type="color" name="cfg_${k}" value="${esc(c)}" aria-label="${esc(l)}"></label>`).join('')}</div><div class="theme-live-preview"><div class="theme-preview-sidebar">SiasCloud</div><div class="theme-preview-canvas"><span>Vista previa</span><button type="button">Acción principal</button></div></div></div>`;
    else if(sig==='SECURITY:session') body=`<div class="visual-config-section"><div class="config-section-head"><div><h3>Seguridad de sesión</h3><p>Define tiempos y límites de la autenticación propia de SiasCloud.</p></div></div><div class="form-grid"><label>Duración de sesión (minutos)<input type="number" min="5" max="10080" name="cfg_minutes" value="${esc(v.minutes??480)}"></label><label>Bloqueo temporal (minutos)<input type="number" min="1" max="1440" name="cfg_lock_minutes" value="${esc(v.lock_minutes??15)}"></label><label>Intentos fallidos permitidos<input type="number" min="1" max="50" name="cfg_max_failed_attempts" value="${esc(v.max_failed_attempts??5)}"></label><div class="security-architecture-note"><strong>Autenticación propia SiasCloud</strong><small>La Edge Function se mantiene con verify_jwt=false por diseño. Cada ruta protegida valida la sesión, empresa y permisos de SiasCloud.</small></div></div></div>`;
    else if(sig==='SYSTEM:locale') body=`<div class="visual-config-section"><div class="config-section-head"><div><h3>Región e idioma</h3><p>Selecciona los valores desde listas.</p></div></div><div class="form-grid"><label>País<select name="cfg_country"><option value="CL" ${(v.country||'CL')==='CL'?'selected':''}>Chile</option><option value="AR" ${v.country==='AR'?'selected':''}>Argentina</option><option value="PE" ${v.country==='PE'?'selected':''}>Perú</option><option value="CO" ${v.country==='CO'?'selected':''}>Colombia</option><option value="MX" ${v.country==='MX'?'selected':''}>México</option></select></label><label>Moneda<select name="cfg_currency"><option value="CLP" ${(v.currency||'CLP')==='CLP'?'selected':''}>Peso chileno (CLP)</option><option value="USD" ${v.currency==='USD'?'selected':''}>Dólar (USD)</option><option value="EUR" ${v.currency==='EUR'?'selected':''}>Euro (EUR)</option></select></label><label>Idioma<select name="cfg_language"><option value="es-CL" ${(v.language||'es-CL')==='es-CL'?'selected':''}>Español (Chile)</option><option value="es" ${v.language==='es'?'selected':''}>Español</option><option value="en" ${v.language==='en'?'selected':''}>English</option></select></label><label>Zona horaria<select name="cfg_timezone"><option value="America/Santiago" ${(v.timezone||'America/Santiago')==='America/Santiago'?'selected':''}>Santiago, Chile</option><option value="America/Argentina/Buenos_Aires" ${v.timezone==='America/Argentina/Buenos_Aires'?'selected':''}>Buenos Aires</option><option value="America/Lima" ${v.timezone==='America/Lima'?'selected':''}>Lima</option><option value="America/Bogota" ${v.timezone==='America/Bogota'?'selected':''}>Bogotá</option><option value="America/Mexico_City" ${v.timezone==='America/Mexico_City'?'selected':''}>Ciudad de México</option></select></label></div></div>`;
    else body=`<div class="visual-config-section"><div class="config-section-head"><div><h3>Campos del parámetro</h3><p>Agrega los valores uno por uno. No necesitas escribir JSON.</p></div><button type="button" class="btn secondary small" id="addSettingField">+ Agregar campo</button></div><div id="settingFields" class="setting-builder">${genericSettingRows(v)}</div></div>`;
    return `${base}${body}<label class="toggle-card global-setting-toggle"><input name="global" type="checkbox" ${x.company_id?'':'checked'}><span><strong>Parámetro global</strong><small>Aplicar esta configuración a todas las empresas.</small></span></label>`;
  }
  function parseGenericSetting(){
    const value={}; $$('#settingFields .setting-builder-row',modalForm).forEach(row=>{const key=$('[data-setting-key]',row)?.value.trim();if(!key)return;const type=$('[data-setting-type]',row)?.value||'text';let raw=$('[data-setting-value]',row)?.value??'';if(type==='number'){const n=Number(raw);if(!Number.isFinite(n))throw new Error(`El campo ${key} debe ser numérico`);raw=n}else if(type==='boolean')raw=/^(true|1|si|sí|yes|on)$/i.test(String(raw).trim());value[key]=raw}); return value;
  }
  function settingModal(x){
    x=x||{module:'SYSTEM',key:'',value:{}}; const sig=settingSignature(x);
    openModal(x.id?`Editar · ${settingName(x)}`:'Nuevo parámetro',settingEditorBody(x),async fd=>{
      const currentSig=`${String(fd.get('module')||'SYSTEM').toUpperCase()}:${String(fd.get('key')||'')}`; let value;
      if(currentSig==='BRANDING:theme') value={primary:String(fd.get('cfg_primary')||'#2563EB'),secondary:String(fd.get('cfg_secondary')||'#0B1830'),background:String(fd.get('cfg_background')||'#F5F7FB'),button_text:String(fd.get('cfg_button_text')||'#FFFFFF')};
      else if(currentSig==='SECURITY:session') value={minutes:Number(fd.get('cfg_minutes')||480),max_failed_attempts:Number(fd.get('cfg_max_failed_attempts')||5),lock_minutes:Number(fd.get('cfg_lock_minutes')||15),jwt_enabled:false};
      else if(currentSig==='SYSTEM:locale') value={country:String(fd.get('cfg_country')||'CL'),language:String(fd.get('cfg_language')||'es-CL'),currency:String(fd.get('cfg_currency')||'CLP'),timezone:String(fd.get('cfg_timezone')||'America/Santiago')};
      else value=parseGenericSetting();
      await call('settings.save',{id:fd.get('id')||undefined,module:fd.get('module'),key:fd.get('key'),description:fd.get('description'),value,global:fd.get('global')==='on'}); if(currentSig==='BRANDING:theme') applyTheme(value);
    });
    const add=$('#addSettingField',modalForm); add?.addEventListener('click',()=>{$('#settingFields',modalForm).insertAdjacentHTML('beforeend',genericSettingRows({'':''}));bindSettingBuilder()});
    function bindSettingBuilder(){ $$('.remove-setting-field',modalForm).forEach(b=>b.onclick=()=>{const rows=$$('#settingFields .setting-builder-row',modalForm);if(rows.length>1)b.closest('.setting-builder-row').remove();else{const r=b.closest('.setting-builder-row');$('[data-setting-key]',r).value='';$('[data-setting-value]',r).value='';}}); }
    bindSettingBuilder();
    if(sig==='BRANDING:theme'){
      const refreshPreview=()=>{const p=$('[name=cfg_primary]',modalForm)?.value||'#2563EB',sec=$('[name=cfg_secondary]',modalForm)?.value||'#0B1830',bg=$('[name=cfg_background]',modalForm)?.value||'#F5F7FB',bt=$('[name=cfg_button_text]',modalForm)?.value||'#FFFFFF';$$('.color-picker-card',modalForm).forEach(card=>{const i=$('input[type=color]',card),sw=$('.color-preview',card);if(i&&sw)sw.style.background=i.value});const side=$('.theme-preview-sidebar',modalForm),canvas=$('.theme-preview-canvas',modalForm),btn=$('.theme-preview-canvas button',modalForm);if(side)side.style.background=sec;if(canvas)canvas.style.background=bg;if(btn){btn.style.background=p;btn.style.color=bt}};
      $$('input[type=color]',modalForm).forEach(i=>i.addEventListener('input',refreshPreview));refreshPreview();
    }
  }
  function secretModal(){openModal("Guardar / reemplazar secreto",`<div class="form-grid"><label>Ámbito<input name="scope" value="SYSTEM" required></label><label>Nombre<input name="key" required placeholder="MI_SECRET_KEY"></label><label class="full">Valor secreto<input name="value" type="password" required autocomplete="off"></label><label class="full">Pista opcional<input name="hint" maxlength="120" placeholder="Ej: clave producción terminada en ****"></label><label class="switch"><input name="global" type="checkbox"> Secreto global</label></div><div class="section-note mt">El valor no podrá visualizarse después. Para cambiarlo debes reemplazarlo.</div>`,async fd=>call("secrets.save",{...Object.fromEntries(fd),global:fd.get("global")==="on"}));}

  async function renderSii(){
    const r=await call("summary",{},true); state.cache.sii=r; const c=r.config||{};
    const canManage=can("SII_MANAGE");
    $("#content").innerHTML=`
      <div class="grid kpis">
        <div class="card kpi"><span>Ambiente</span><strong style="font-size:20px">${esc(c.environment||"CERTIFICACION")}</strong></div>
        <div class="card kpi"><span>Integración</span><strong style="font-size:20px">${c.enabled?'ACTIVA':'INACTIVA'}</strong></div>
        <div class="card kpi"><span>Certificado</span><strong style="font-size:20px">${r.certificate?'CARGADO':'PENDIENTE'}</strong></div>
        <div class="card kpi"><span>CAF</span><strong>${r.cafs.length}</strong></div>
        <div class="card kpi"><span>DTE locales</span><strong>${r.dtes.length}</strong></div>
      </div>
      <div class="two-col mt">
        <div class="card">
          <div class="toolbar"><h2>Configuración SII</h2>${canManage?'<button class="btn primary small" id="siiConfig">Configurar</button>':''}</div>
          <div class="list"><div class="list-item"><span>RUT emisor</span><strong>${esc(c.issuer_rut||"—")}</strong></div><div class="list-item"><span>Resolución</span><strong>${esc(c.resolution_number||"—")}</strong></div><div class="list-item"><span>Correo envío</span><strong>${esc(c.sender_email||"—")}</strong></div></div>
        </div>
        <div class="card">
          <div class="toolbar"><h2>Certificado digital</h2>${canManage?'<button class="btn primary small" id="uploadCert">Cargar PFX/P12</button>':''}</div>
          ${r.certificate?`<div class="section-note"><strong>${esc(r.certificate.file_name)}</strong><br>Cargado: ${esc(fmtDate(r.certificate.created_at))}${r.certificate.valid_until?`<br>Vence: ${esc(fmtDate(r.certificate.valid_until))}`:""}</div>`:'<div class="empty">No hay certificado activo.</div>'}
        </div>
      </div>
      <div class="two-col mt">
        <div class="card">
          <div class="toolbar"><h2>CAF / Folios</h2>${canManage?'<button class="btn primary small" id="uploadCaf">Importar CAF XML</button>':''}</div>
          ${r.cafs.length?`<div class="table-wrap"><table><thead><tr><th>Ambiente</th><th>DTE</th><th>Desde</th><th>Hasta</th><th>Siguiente</th><th>Estado</th></tr></thead><tbody>${r.cafs.map(x=>`<tr><td><span class="badge off">${esc(x.environment||"CERTIFICACION")}</span></td><td>${x.document_type}</td><td>${x.folio_from}</td><td>${x.folio_to}</td><td>${x.current_folio}</td><td>${esc(x.status)}</td></tr>`).join("")}</tbody></table></div>`:'<div class="empty">Sin CAF cargados.</div>'}
        </div>
        <div class="card">
          <div class="toolbar"><h2>Certificación</h2></div>
          <div class="list">${r.steps.map(x=>`<div class="list-item"><div><strong>${esc(x.name)}</strong><div class="muted">${esc(x.description||"")}</div></div>${canManage?`<button class="btn secondary small certStep" data-id="${x.id}">${esc(x.status)}</button>`:`<span class="badge off">${esc(x.status)}</span>`}</div>`).join("")||'<div class="empty">Ejecuta ambos SQL maestros antes de la instalación inicial.</div>'}</div>
        </div>
      </div>
      <div class="card mt">
        <div class="toolbar"><h2>DTE locales</h2>${canManage?'<button class="btn primary small" id="newDte">+ Crear borrador DTE</button>':''}</div>
        <div class="section-note">Los PDF generados desde esta pantalla son representaciones locales. Solo un DTE con aceptación del SII acredita transmisión tributaria efectiva.</div>
        ${r.dtes.length?`<div class="table-wrap mt"><table><thead><tr><th>Ambiente</th><th>Tipo</th><th>Folio</th><th>Fecha</th><th>Estado</th><th>Track ID</th><th></th></tr></thead><tbody>${r.dtes.map(x=>`<tr><td>${esc(x.environment||"CERTIFICACION")}</td><td>${x.document_type}</td><td>${x.folio??"—"}</td><td>${esc(x.issue_date)}</td><td><span class="badge off">${esc(x.status)}</span></td><td>${esc(x.sii_track_id||"—")}</td><td><button class="btn secondary small viewDte" data-id="${x.id}">Ver / PDF</button></td></tr>`).join("")}</tbody></table></div>`:'<div class="empty">Aún no hay DTE.</div>'}
      </div>`;
    $("#siiConfig")?.addEventListener("click",()=>siiConfigModal(c));
    $("#uploadCert")?.addEventListener("click",certificateModal);
    $("#uploadCaf")?.addEventListener("click",cafModal);
    $("#newDte")?.addEventListener("click",dteModal);
    $$('.certStep').forEach(b=>b.addEventListener('click',()=>certStepModal(r.steps.find(x=>x.id===b.dataset.id))));
    $$('.viewDte').forEach(b=>b.addEventListener('click',()=>openDtePreview(b.dataset.id)));
  }
  function siiConfigModal(c){openModal("Configuración tributaria",`<div class="form-grid"><label>Ambiente<select name="environment"><option ${c.environment==='CERTIFICACION'?'selected':''}>CERTIFICACION</option><option ${c.environment==='PRODUCCION'?'selected':''}>PRODUCCION</option></select></label><label>RUT emisor<input name="issuer_rut" value="${esc(c.issuer_rut||"")}"></label><label>N° resolución<input name="resolution_number" value="${esc(c.resolution_number||"")}"></label><label>Fecha resolución<input name="resolution_date" type="date" value="${esc(c.resolution_date||"")}"></label><label>Correo envío<input name="sender_email" type="email" value="${esc(c.sender_email||"")}"></label><label>Código actividad<input name="activity_code" value="${esc(c.activity_code||"")}"></label><label>Código sucursal<input name="office_code" value="${esc(c.office_code||"")}"></label><label class="switch"><input name="enabled" type="checkbox" ${c.enabled?'checked':''}> Integración habilitada</label></div>`,async fd=>call("config.save",{...Object.fromEntries(fd),enabled:fd.get("enabled")==="on"},true));}
  function bytesToB64(bytes){let out="";const chunk=0x8000;for(let i=0;i<bytes.length;i+=chunk)out+=String.fromCharCode(...bytes.subarray(i,i+chunk));return btoa(out)}
  function certificateModal(){openModal("Cargar certificado digital",`<div class="form-stack"><label>Certificado .PFX / .P12<input name="file" type="file" accept=".pfx,.p12" required></label><label>Contraseña certificado<input name="password" type="password" required autocomplete="off"></label><label>Vigencia hasta (opcional)<input name="valid_until" type="date"></label><div class="section-note">El certificado se guarda de forma privada y su contraseña se cifra de forma segura en el backend.</div></div>`,async fd=>{const file=fd.get("file");if(!(file instanceof File)||!file.size)throw new Error("Selecciona el certificado");const b64=bytesToB64(new Uint8Array(await file.arrayBuffer()));await call("certificate.upload",{file_name:file.name,file_base64:b64,password:fd.get("password"),valid_until:fd.get("valid_until")||null},true)},"Cargar");}
  function cafModal(){openModal("Importar CAF",`<div class="form-stack"><label>Archivo CAF XML<input name="file" type="file" accept=".xml,text/xml" required></label><div class="section-note">El CAF se asociará al ambiente SII actualmente seleccionado y SiasCloud validará que su RUT emisor coincida con la configuración.</div></div>`,async fd=>{const file=fd.get("file");if(!(file instanceof File)||!file.size)throw new Error("Selecciona el CAF XML");await call("caf.upload",{xml:await file.text()},true)},"Importar");}
  function certStepModal(x){openModal("Actualizar certificación",`<div class="form-stack"><label>Etapa<input value="${esc(x.name)}" disabled></label><label>Estado<select name="status">${["PENDIENTE","EN_PROCESO","COMPLETADO","BLOQUEADO"].map(z=>`<option ${x.status===z?'selected':''}>${z}</option>`).join("")}</select></label><label>Nota<textarea name="note">${esc(x.note||"")}</textarea></label></div>`,async fd=>call("certification.update",{id:x.id,...Object.fromEntries(fd)},true));}
  function dteModal(){
    openModal("Crear borrador DTE",`<div class="dte-form-modern">
      <div class="form-section-title"><div><span class="eyebrow">DOCUMENTO</span><h4>Datos generales</h4></div></div>
      <div class="form-grid">
        <label>Tipo DTE<select name="document_type"><option value="33">33 · Factura electrónica</option><option value="34">34 · Factura exenta</option><option value="39">39 · Boleta electrónica</option><option value="41">41 · Boleta exenta</option><option value="52">52 · Guía de despacho</option><option value="56">56 · Nota de débito</option><option value="61">61 · Nota de crédito</option></select></label>
        <label>Fecha de emisión<input name="issue_date" type="date" value="${new Date().toISOString().slice(0,10)}"></label>
      </div>
      <div class="form-section-title mt"><div><span class="eyebrow">RECEPTOR</span><h4>Datos del cliente</h4></div></div>
      <div class="form-grid">
        <label>RUT<input name="recipient_rut" placeholder="76.123.456-7"></label>
        <label>Razón social<input name="recipient_name" placeholder="Empresa o cliente"></label>
        <label>Giro<input name="recipient_business" placeholder="Actividad comercial"></label>
        <label>Correo<input name="recipient_email" type="email" placeholder="cliente@empresa.cl"></label>
        <label class="full">Dirección<input name="recipient_address" placeholder="Dirección comercial"></label>
        <label>Comuna<input name="recipient_commune"></label>
        <label>Ciudad<input name="recipient_city"></label>
      </div>
      <div class="form-section-title mt"><div><span class="eyebrow">DETALLE</span><h4>Ítems del documento</h4></div><button id="addDteLine" class="btn secondary small" type="button">+ Agregar ítem</button></div>
      <div id="dteFriendlyLines" class="dte-friendly-lines"></div>
      <div class="dte-totals-card">
        <div><span>Neto</span><strong id="dteNeto">$0</strong></div>
        <div><span>IVA 19%</span><strong id="dteIva">$0</strong></div>
        <div class="grand"><span>Total</span><strong id="dteTotal">$0</strong></div>
      </div>
    </div>`,async fd=>{
      const items=$$('.dte-friendly-line',modal).map(row=>({
        nombre:$('.dte-item-name',row).value.trim(),
        cantidad:Number($('.dte-item-qty',row).value||0),
        precio:Number($('.dte-item-price',row).value||0),
        exento:$('.dte-item-exempt',row).checked
      })).filter(x=>x.nombre&&x.cantidad>0);
      if(!items.length) throw new Error('Agrega al menos un ítem al documento');
      const recipient={
        rut:fd.get('recipient_rut')||'',razon_social:fd.get('recipient_name')||'',giro:fd.get('recipient_business')||'',
        email:fd.get('recipient_email')||'',direccion:fd.get('recipient_address')||'',comuna:fd.get('recipient_commune')||'',ciudad:fd.get('recipient_city')||''
      };
      let neto=0,iva=0;
      items.forEach(x=>{const base=x.cantidad*x.precio;neto+=base;if(!x.exento)iva+=Math.round(base*.19)});
      const totals={neto:Math.round(neto),iva:Math.round(iva),total:Math.round(neto+iva)};
      await call('dte.create',{document_type:Number(fd.get('document_type')),issue_date:fd.get('issue_date'),recipient,items,totals},true)
    },"Crear borrador");
    const lines=$('#dteFriendlyLines');
    const recalc=()=>{let neto=0,iva=0;$$('.dte-friendly-line',modal).forEach(row=>{const q=Number($('.dte-item-qty',row).value||0),p=Number($('.dte-item-price',row).value||0),base=q*p;neto+=base;if(!$('.dte-item-exempt',row).checked)iva+=Math.round(base*.19)});$('#dteNeto').textContent=money(neto);$('#dteIva').textContent=money(iva);$('#dteTotal').textContent=money(neto+iva)};
    const addLine=()=>{const row=document.createElement('div');row.className='dte-friendly-line';row.innerHTML=`<label>Descripción<input class="dte-item-name" placeholder="Producto o servicio" required></label><label>Cantidad<input class="dte-item-qty" type="number" min="0.001" step="0.001" value="1" required></label><label>Precio unitario<input class="dte-item-price" type="number" min="0" step="1" value="0" required></label><label class="dte-exempt"><input class="dte-item-exempt" type="checkbox"><span>Exento</span></label><button class="icon-btn dte-remove" type="button" title="Quitar ítem">×</button>`;lines.appendChild(row);$$('input',row).forEach(i=>i.addEventListener('input',recalc));$('.dte-remove',row).addEventListener('click',()=>{if($$('.dte-friendly-line',modal).length>1){row.remove();recalc()}});recalc()};
    $('#addDteLine').addEventListener('click',addLine);addLine();
  }
  function money(v){return new Intl.NumberFormat('es-CL',{style:'currency',currency:'CLP',maximumFractionDigits:0}).format(Number(v||0))}
  function dteTypeName(t){return ({33:'Factura electrónica',34:'Factura exenta',39:'Boleta electrónica',41:'Boleta exenta',52:'Guía de despacho',56:'Nota de débito',61:'Nota de crédito'})[Number(t)]||`DTE ${t}`}
  async function openDtePreview(id){
    const r=await call("dte.get",{id},true),d=r.dte,c=r.company||{};
    const recipient=d.recipient||{},items=Array.isArray(d.items)?d.items:[],tot=d.totals||{};
    openModal("DTE · Vista / PDF",`<div class="form-stack"><div class="section-note"><strong>${esc(dteTypeName(d.document_type))} N° ${esc(d.folio||"—")}</strong><br>${esc(d.environment||"CERTIFICACION")} · ${esc(d.status)} · ${esc(d.issue_date)}</div><div class="list"><div class="list-item"><span>Emisor</span><strong>${esc(c.legal_name||c.trade_name||"—")}</strong></div><div class="list-item"><span>Receptor</span><strong>${esc(recipient.razon_social||recipient.nombre||recipient.rut||"—")}</strong></div><div class="list-item"><span>Total</span><strong>${esc(money(tot.total))}</strong></div></div><label>Formato<select name="format"><option value="A4">A4</option><option value="80MM">Ticket 80 mm</option><option value="58MM">Ticket 57/58 mm</option></select></label><div class="section-note">Al elegir “Imprimir / Guardar PDF”, el navegador abrirá la representación imprimible. Puedes seleccionar “Guardar como PDF” en el diálogo de impresión.</div></div>`,async fd=>printDte(r,String(fd.get("format")||"A4")),"Imprimir / Guardar PDF");
  }
  function printDte(r,format){
    const d=r.dte||{},c=r.company||{},recipient=d.recipient||{},items=Array.isArray(d.items)?d.items:[],tot=d.totals||{};
    const logo=(c.show_logo_documents!==false&&c.logo_url)?c.logo_url:'';
    const isTicket=['80MM','58MM'].includes(format);
    const is58=format==='58MM';
    const pageWidth=is58?'58mm':isTicket?'80mm':'210mm';
    const pad=is58?'3mm':isTicket?'6mm':'14mm';
    const rows=items.map((it,i)=>{
      const qty=Number(it.cantidad??it.qty??1),
        price=Number(it.precio??it.price??0),
        line=Number(it.total??qty*price);
      return `<tr><td>${i+1}</td><td>${esc(it.nombre??it.descripcion??'Ítem')}</td><td>${qty}</td><td>${money(price)}</td><td>${money(line)}</td></tr>`
    }).join('');

    const w=window.open('','_blank');
    if(!w) throw new Error('El navegador bloqueó la ventana de impresión');

    w.document.write(`<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(dteTypeName(d.document_type))} ${esc(d.folio||'')}</title>
<style>
  @page{size:${isTicket?pageWidth+' auto':'A4 portrait'};margin:${isTicket?'0':'12mm'}}
  *{box-sizing:border-box}
  html,body{margin:0;padding:0}
  body{
    font-family:Arial,sans-serif;
    margin:0;
    color:#111;
    background:#eef2f7;
    overflow-x:hidden
  }
  .sheet{
    width:min(calc(100% - ${isTicket?'0px':'24px'}),${pageWidth});
    max-width:${pageWidth};
    min-height:${isTicket?'auto':'297mm'};
    padding:${pad};
    margin:${isTicket?'0':'14px auto 24px'};
    background:#fff;
    box-shadow:${isTicket?'none':'0 8px 28px rgba(15,23,42,.12)'};
    overflow:hidden
  }
  img{
    display:block;
    max-width:${isTicket?'42mm':'58mm'};
    max-height:30mm;
    object-fit:contain
  }
  h1{
    font-size:${isTicket?'16px':'22px'};
    line-height:1.15;
    margin:12px 0 4px;
    overflow-wrap:anywhere
  }
  h2{font-size:${isTicket?'13px':'16px'};margin:12px 0 4px}
  .meta,.notice{
    font-size:11px;
    line-height:1.45;
    overflow-wrap:anywhere;
    word-break:break-word
  }
  .notice{border:1px solid #999;padding:7px;margin:10px 0}
  .cols{
    display:grid;
    grid-template-columns:${isTicket?'1fr':'minmax(0,1fr) minmax(0,1fr)'};
    gap:12px
  }
  .cols>div{min-width:0}
  table{
    width:100%;
    border-collapse:collapse;
    table-layout:fixed;
    font-size:${isTicket?'9px':'11px'};
    margin-top:10px
  }
  th,td{
    border-bottom:1px solid #ddd;
    padding:5px;
    text-align:left;
    vertical-align:top;
    overflow-wrap:anywhere;
    word-break:break-word
  }
  th:nth-child(1),td:nth-child(1){width:7%}
  th:nth-child(2),td:nth-child(2){width:43%}
  th:nth-child(3),td:nth-child(3){width:14%}
  th:nth-child(4),td:nth-child(4){width:18%}
  th:nth-child(5),td:nth-child(5){width:18%}
  th:nth-last-child(-n+2),td:nth-last-child(-n+2){text-align:right}
  .totals{
    margin-left:auto;
    width:${isTicket?'100%':'min(100%,310px)'};
    font-size:12px
  }
  .totals div{display:flex;justify-content:space-between;gap:16px;padding:4px 0}
  .total{font-size:15px;font-weight:bold;border-top:2px solid #111}
  .foot{margin-top:16px;font-size:10px;text-align:center;overflow-wrap:anywhere}

  @media (max-width:700px){
    body{background:#fff}
    .sheet{
      width:100%;
      max-width:100%;
      min-height:0;
      margin:0;
      padding:${isTicket?'6mm':'16px 12px'};
      box-shadow:none
    }
    ${isTicket?'':'.cols{grid-template-columns:1fr} table{font-size:10px}'}
  }

  @media print{
    html,body{background:#fff!important}
    body{overflow:visible}
    .sheet{
      width:auto;
      max-width:none;
      min-height:0;
      margin:0;
      padding:${isTicket?pad:'0'};
      box-shadow:none;
      overflow:visible
    }
    tr{page-break-inside:avoid}
    thead{display:table-header-group}
    .cols,.notice,.totals,.foot{break-inside:avoid}
  }
</style>
</head>
<body>
<div class="sheet">
  ${logo?`<img src="${esc(logo)}" alt="Logotipo de ${esc(c.trade_name||c.legal_name||'empresa')}">`:''}
  <h1>${esc(dteTypeName(d.document_type))}</h1>
  <div class="meta">Folio: <strong>${esc(d.folio||'—')}</strong> · Fecha: ${esc(d.issue_date||'—')} · Ambiente: ${esc(d.environment||'CERTIFICACION')} · Estado: ${esc(d.status||'—')}</div>
  <div class="notice">Representación local generada por SiasCloud ERP. Mientras el documento no registre aceptación del SII, esta impresión no acredita recepción tributaria por parte del SII.</div>

  <div class="cols">
    <div>
      <h2>Emisor</h2>
      <div class="meta">
        <strong>${esc(c.legal_name||c.trade_name||'—')}</strong><br>
        RUT: ${esc(c.rut||r.config?.issuer_rut||'—')}<br>
        ${esc(c.business_activity||'')}<br>
        ${esc([c.address,c.commune,c.city].filter(Boolean).join(', '))}
      </div>
    </div>
    <div>
      <h2>Receptor</h2>
      <div class="meta">
        <strong>${esc(recipient.razon_social||recipient.nombre||'—')}</strong><br>
        RUT: ${esc(recipient.rut||'—')}<br>
        ${esc(recipient.giro||'')}<br>
        ${esc([recipient.direccion,recipient.comuna].filter(Boolean).join(', '))}
      </div>
    </div>
  </div>

  <table>
    <thead><tr><th>#</th><th>Detalle</th><th>Cant.</th><th>Precio</th><th>Total</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>

  <div class="totals">
    <div><span>Neto</span><strong>${money(tot.neto)}</strong></div>
    <div><span>IVA</span><strong>${money(tot.iva)}</strong></div>
    <div class="total"><span>Total</span><strong>${money(tot.total)}</strong></div>
  </div>

  <div class="foot">SiasCloud ERP · ${new Date().toLocaleString('es-CL')}</div>
</div>
<script>window.onload=()=>{setTimeout(()=>window.print(),250)}<\/script>
</body>
</html>`);
    w.document.close();
  }

  // ========================= SIASCLOUD ERP 2.2.0 · OPERACIÓN COMERCIAL =========================
  const docLabels={RECEIPT:"Ingreso de mercadería",ISSUE:"Salida",TRANSFER:"Traslado",DELIVERY:"Guía de despacho",QUOTE:"Cotización",ORDER:"Pedido",REQUEST:"Solicitud",SALE:"Venta",WHOLESALE:"Venta mayorista",PURCHASE:"Compra"};
  const statusLabels={DRAFT:"Borrador",POSTED:"Publicado",VOID:"Anulado",PENDING:"Pendiente",PAID:"Pagado",PARTIAL:"Parcial",EMITIDO:"Emitido",INICIADO:"En proceso",INDETERMINADO:"Revisar",ERROR:"Error"};
  const fmtQty=v=>new Intl.NumberFormat("es-CL",{maximumFractionDigits:4}).format(Number(v||0));
  const badge=(value)=>{const v=String(value||"").toUpperCase(),cl=["POSTED","PAID","EMITIDO","ACTIVO"].includes(v)?"ok":["DRAFT","PENDING","PARTIAL","INICIADO","INDETERMINADO"].includes(v)?"warn":"off";return `<span class="badge ${cl}">${esc(statusLabels[v]||value||"—")}</span>`};
  const emptyRow=(cols,msg="Sin registros")=>`<tr><td colspan="${cols}" class="empty">${esc(msg)}</td></tr>`;
  const inputValue=(fd,name)=>String(fd.get(name)||"").trim();
  async function fileToBase64(file){
    if(!file||!file.size)return "";
    if(file.size>5*1024*1024)throw new Error("La imagen supera 5 MB");
    if(!["image/jpeg","image/png","image/webp"].includes(file.type))throw new Error("Usa una imagen JPG, PNG o WEBP");
    return await new Promise((resolve,reject)=>{const r=new FileReader();r.onerror=()=>reject(new Error("No fue posible leer la imagen"));r.onload=()=>resolve(String(r.result||"").split(",")[1]||"");r.readAsDataURL(file)});
  }

  async function renderDashboard(){
    const r=await erpCall("dashboard");
    const today=new Intl.DateTimeFormat("es-CL",{weekday:"long",day:"numeric",month:"long"}).format(new Date());
    $("#content").innerHTML=`
      <section class="dashboard-hero">
        <div><span class="eyebrow">PANEL GENERAL</span><h2>Resumen del negocio</h2><p>${esc(today.charAt(0).toUpperCase()+today.slice(1))} · Datos actualizados en tiempo real</p></div>
        <div class="hero-actions"><button class="btn secondary" data-go="reports">Ver reportes</button><button class="btn primary" data-go="sales">Nueva venta</button></div>
      </section>
      <div class="operation-shortcuts">${[["billing","billing","Emitir documentos","Facturas, boletas, guías y notas","BILLING_VIEW"],["receipts","inventory","Ingresar productos","Recepciones, folios y costos","INVENTORY_VIEW"],["store","wholesale","Sitio para clientes","Catálogo y pedidos web","SETTINGS_VIEW"],["documents","sales","Documentos","Cotizaciones, pedidos y ventas","SALES_VIEW"]].filter(x=>can(x[4])).map(x=>`<button type="button" class="card operation-shortcut" data-go="${x[0]}"><span>${icon(x[1])}</span><div><strong>${x[2]}</strong><small>${x[3]}</small></div><b>↗</b></button>`).join("")}</div>
      <div class="grid kpis commercial-kpis modern-kpis">
        <div class="card kpi premium-kpi"><div class="kpi-icon blue">${icon('sales')}</div><div><span>Ventas del mes</span><strong>${money(r.sales_month)}</strong><small>Movimiento comercial</small></div></div>
        <div class="card kpi premium-kpi"><div class="kpi-icon violet">${icon('purchases')}</div><div><span>Compras del mes</span><strong>${money(r.purchases_month)}</strong><small>Abastecimiento</small></div></div>
        <div class="card kpi premium-kpi"><div class="kpi-icon cyan">${icon('products')}</div><div><span>Productos activos</span><strong>${fmtQty(r.products)}</strong><small>Catálogo vigente</small></div></div>
        <div class="card kpi premium-kpi"><div class="kpi-icon green">${icon('customers')}</div><div><span>Clientes</span><strong>${fmtQty(r.customers)}</strong><small>Base comercial</small></div></div>
        <div class="card kpi premium-kpi"><div class="kpi-icon amber">${icon('inventory')}</div><div><span>Unidades en stock</span><strong>${fmtQty(r.stock_units)}</strong><small>Disponibilidad total</small></div></div>
      </div>
      <div class="dashboard-grid mt">
        <div class="card dashboard-panel">
          <div class="toolbar panel-head"><div><span class="eyebrow">MOVIMIENTOS</span><h2>Actividad reciente</h2><p class="muted">Últimos documentos registrados en el sistema.</p></div><button class="btn secondary small" data-go="sales">Ver ventas</button></div>
          ${(r.recent||[]).length?`<div class="table-wrap modern-table"><table><thead><tr><th>Fecha</th><th>Documento</th><th>Estado</th><th class="right">Total</th></tr></thead><tbody>${(r.recent||[]).map(x=>`<tr><td>${esc(x.issue_date||"")}</td><td><strong>${esc(docLabels[x.document_type]||x.document_type)}</strong><br><span class="muted">${esc(x.number)}</span></td><td>${badge(x.status)}</td><td class="right"><strong>${money(x.total)}</strong></td></tr>`).join("")}</tbody></table></div>`:`<div class="empty-state"><div class="empty-icon">${icon('sales')}</div><strong>Aún no hay actividad</strong><p>Cuando registres ventas o documentos, aparecerán aquí automáticamente.</p><button class="btn primary small" data-go="sales">Registrar primera venta</button></div>`}
        </div>
        <div class="card dashboard-panel stock-panel">
          <div class="toolbar panel-head"><div><span class="eyebrow">INVENTARIO</span><h2>Stock bajo</h2><p class="muted">Productos que requieren atención.</p></div><button class="btn secondary small" data-go="inventory">Inventario</button></div>
          <div class="stock-list">${(r.low_stock||[]).map(x=>`<div class="stock-item"><div class="stock-item-icon">${icon('inventory')}</div><div><strong>${esc(x.name)}</strong><span>Mínimo ${fmtQty(x.min_stock)}</span></div><span class="badge warn">Reponer</span></div>`).join("")||`<div class="empty-state compact"><div class="empty-icon success">${icon('inventory')}</div><strong>Stock saludable</strong><p>No hay alertas de stock en este momento.</p></div>`}</div>
        </div>
      </div>`;
    $$('[data-go]').forEach(b=>b.addEventListener('click',()=>navigate(b.dataset.go)));
  }

  async function renderProducts(){return window.SiasOperations.products();}

  function productModal(x={}){return window.SiasOperations.productModal(x);}

  async function renderInventory(){return window.SiasOperations.inventory();}

  async function inventoryMovementChart(productId,warehouseId){
    try{const r=await erpCall('inventory.history',{product_id:productId,warehouse_id:warehouseId||null,limit:300}),rows=r.rows||[];if(!rows.length){toast('No hay historial para este producto');return;}const vals=rows.map(x=>Number(x.balance_after||0)),min=Math.min(0,...vals),max=Math.max(1,...vals),W=760,H=240,P=28,dx=(W-P*2)/Math.max(1,rows.length-1),y=v=>H-P-((v-min)/(max-min||1))*(H-P*2),points=rows.map((x,i)=>`${P+i*dx},${y(Number(x.balance_after||0))}`).join(' '),last=rows[rows.length-1],first=rows[0];openModal(`Movimientos · ${esc(last.sias_products?.name||'Producto')}`,`<div class="inventory-chart"><svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Evolución de stock"><line x1="${P}" y1="${H-P}" x2="${W-P}" y2="${H-P}" class="chart-axis"/><polyline points="${points}" class="chart-line" fill="none"/></svg><div class="chart-stats"><div><span>Saldo inicial</span><strong>${fmtQty(first.balance_after)}</strong></div><div><span>Saldo actual</span><strong>${fmtQty(last.balance_after)}</strong></div><div><span>Movimientos</span><strong>${rows.length}</strong></div></div></div><div class="table-wrap mt"><table><thead><tr><th>Fecha</th><th>Tipo</th><th class="right">Movimiento</th><th class="right">Saldo</th><th>Nota</th></tr></thead><tbody>${rows.slice().reverse().map(x=>`<tr><td>${fmtDate(x.created_at)}</td><td>${esc(x.movement_type)}</td><td class="right ${Number(x.quantity)<0?'danger-text':'positive-text'}">${Number(x.quantity)>0?'+':''}${fmtQty(x.quantity)}</td><td class="right">${fmtQty(x.balance_after)}</td><td>${esc(x.note||'—')}</td></tr>`).join('')}</tbody></table></div>`,null,'Cerrar');}
    catch(e){toast(errorText(e),true)}
  }
  function stockAdjustModal(products,warehouses){openModal("Ajustar stock",`<div class="form-stack"><label>Producto<select name="product_id" required><option value="">Seleccionar…</option>${products.map(x=>`<option value="${x.id}">${esc(x.sku?`${x.sku} · `:'')}${esc(x.name)}</option>`).join('')}</select></label><label>Bodega<select name="warehouse_id" required>${warehouses.filter(x=>x.active).map(x=>`<option value="${x.id}">${esc(x.name)}</option>`).join('')}</select></label><label>Ajuste<input name="delta" type="number" step="0.0001" required placeholder="Ej: 10 o -3"></label><label>Motivo<textarea name="note" required placeholder="Motivo del ajuste"></textarea></label><div class="section-note">Usa cantidades positivas para ingresar stock y negativas para descontar.</div></div>`,async fd=>erpCall("inventory.adjust",{product_id:fd.get('product_id'),warehouse_id:fd.get('warehouse_id'),delta:Number(fd.get('delta')),note:fd.get('note')}),"Aplicar ajuste");}
  function stockTransferModal(products,warehouses){openModal("Trasladar stock",`<div class="form-stack"><label>Producto<select name="product_id" required><option value="">Seleccionar…</option>${products.map(x=>`<option value="${x.id}">${esc(x.name)}</option>`).join('')}</select></label><div class="form-grid"><label>Desde<select name="from_warehouse_id" required>${warehouses.filter(x=>x.active).map(x=>`<option value="${x.id}">${esc(x.name)}</option>`).join('')}</select></label><label>Hacia<select name="to_warehouse_id" required>${warehouses.filter(x=>x.active).map(x=>`<option value="${x.id}">${esc(x.name)}</option>`).join('')}</select></label></div><label>Cantidad<input name="quantity" type="number" min="0.0001" step="0.0001" required></label><label>Nota<textarea name="note"></textarea></label></div>`,async fd=>erpCall("inventory.transfer",{product_id:fd.get('product_id'),from_warehouse_id:fd.get('from_warehouse_id'),to_warehouse_id:fd.get('to_warehouse_id'),quantity:Number(fd.get('quantity')),note:fd.get('note')}),"Trasladar");}
  function warehousesModal(rows){openModal("Bodegas",`<div class="form-stack"><div class="list">${rows.map(x=>`<div class="list-item"><div><strong>${esc(x.name)}</strong><div class="muted">${esc(x.code)} · ${x.active?'Activa':'Inactiva'}</div></div></div>`).join('')}</div><hr class="soft"><div class="form-grid"><label>Código<input name="code" required maxlength="50"></label><label>Nombre<input name="name" required maxlength="180"></label><label class="full">Dirección<input name="address"></label><label>Comuna<input name="commune"></label><label>Ciudad<input name="city"></label></div></div>`,async fd=>erpCall("warehouses.save",Object.fromEntries(fd)),"Crear bodega");}

  async function renderCustomers(){
    const r=await erpCall("customers.list",{limit:500}),rows=r.rows||[];
    $("#content").innerHTML=`<div class="card"><div class="toolbar"><div><h2>Clientes</h2><div class="muted">Datos comerciales, crédito y condición mayorista</div></div><div class="toolbar-actions">${can('CUSTOMER_MANAGE')?'<button id="newCustomer" class="btn primary">Nuevo cliente</button>':''}</div></div><div class="table-wrap"><table><thead><tr><th>Cliente</th><th>RUT</th><th>Contacto</th><th>Ubicación</th><th class="right">Límite crédito</th><th>Tipo</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>${rows.map(x=>`<tr><td><strong>${esc(x.legal_name)}</strong><br><span class="muted">${esc(x.trade_name||'')}</span></td><td>${esc(x.rut||'—')}</td><td>${esc(x.email||'—')}<br><span class="muted">${esc(x.phone||'')}</span></td><td>${esc([x.commune,x.city].filter(Boolean).join(', ')||'—')}</td><td class="right">${money(x.credit_limit)}</td><td>${x.wholesale?'<span class="badge ok">Mayorista</span>':'<span class="badge off">Normal</span>'}</td><td>${x.active?'<span class="badge ok">Activo</span>':'<span class="badge off">Inactivo</span>'}</td><td><button class="btn secondary small editCustomer" data-id="${x.id}">Editar</button></td></tr>`).join('')||emptyRow(8)}</tbody></table></div></div>`;
    $("#newCustomer")?.addEventListener("click",()=>customerModal());$$('.editCustomer').forEach(b=>b.addEventListener('click',()=>customerModal(rows.find(x=>x.id===b.dataset.id))));
  }
  function customerModal(x={},options={}){const company=state.me.companyId;openModal(options.title||(x.id?"Editar cliente":"Nuevo cliente"),`<div class="form-grid"><label>RUT<input name="rut" value="${esc(x.rut||'')}"></label><label>Razón social<input name="legal_name" required value="${esc(x.legal_name||'')}"></label><label>Nombre de fantasía<input name="trade_name" value="${esc(x.trade_name||'')}"></label><label>Giro<input name="business_activity" value="${esc(x.business_activity||'')}"></label><label>Email<input name="email" type="email" value="${esc(x.email||'')}"></label><label>Teléfono<input name="phone" value="${esc(x.phone||'')}"></label><label class="full">Dirección<input name="address" value="${esc(x.address||'')}"></label><label>Comuna<input name="commune" value="${esc(x.commune||'')}"></label><label>Ciudad<input name="city" value="${esc(x.city||'')}"></label><label>Región<input name="region" value="${esc(x.region||'')}"></label><label>Contacto<input name="contact_name" value="${esc(x.contact_name||'')}"></label><label>Límite de crédito<input name="credit_limit" type="number" min="0" value="${esc(x.credit_limit??0)}"></label><label class="full">Notas<textarea name="notes">${esc(x.notes||'')}</textarea></label><label class="toggle-card"><input name="wholesale" type="checkbox" ${x.wholesale?'checked':''}><span><strong>Cliente mayorista</strong><small>Habilita operación mayorista.</small></span></label><label class="toggle-card"><input name="active" type="checkbox" ${x.active!==false?'checked':''}><span><strong>Cliente activo</strong></span></label></div>`,async fd=>{if(state.me.companyId!==company)throw new Error('La empresa activa cambió. Abre el formulario nuevamente.');const r=await erpCall("customers.save",{id:x.id,...Object.fromEntries(fd),credit_limit:Number(fd.get('credit_limit')||0),wholesale:fd.get('wholesale')==='on',active:fd.get('active')==='on',company_id:company});if(typeof options.onSaved==='function')options.onSaved(r.row);return {toast:options.toast||'Cliente guardado'};},options.saveLabel||'Guardar');}

  async function renderSales(){return window.SiasOperations.documents("SALES");}
  async function renderPurchases(){return window.SiasOperations.documents("PURCHASE");}

  async function renderWholesale(){
    const [docs,clients,accounts]=await Promise.all([
      erpCall("documents.list",{document_type:"WHOLESALE",limit:500}),
      erpCall("customers.list",{wholesale:true,limit:500}),
      erpCall("wholesale.accounts.list")
    ]);
    const rows=docs.rows||[],crows=clients.rows||[],arows=accounts.rows||[];
    const activePortal=arows.filter(x=>x.portal_account_exists&&x.active&&x.portal_password_ready).length;
    const pendingPortal=arows.filter(x=>!x.portal_account_exists||!x.portal_password_ready).length;

    $("#content").innerHTML=`<div class="grid kpis wholesale-kpis">
      <div class="card kpi"><span>Clientes mayoristas</span><strong>${crows.length}</strong></div>
      <div class="card kpi"><span>Portal activo</span><strong>${activePortal}</strong></div>
      <div class="card kpi"><span>Accesos por completar</span><strong>${pendingPortal}</strong></div>
      <div class="card kpi"><span>Ventas mayoristas</span><strong>${money(rows.filter(x=>x.status==='POSTED').reduce((s,x)=>s+Number(x.total||0),0))}</strong></div>
    </div>
    <div class="card mt">
      <div class="toolbar"><div><h2>Mayoristas</h2><div class="muted">Ventas y línea de crédito mayorista</div></div>
      ${can('WHOLESALE_MANAGE')?'<button id="newWholesale" class="btn primary">Nueva venta mayorista</button>':''}</div>
      ${documentsTable(rows)}
    </div>
    <div class="two-col mt">
      <div class="card">
        <div class="toolbar"><h2>Clientes habilitados</h2></div>
        <div class="list">${crows.map(x=>`<div class="list-item"><div><strong>${esc(x.legal_name)}</strong><div class="muted">${esc(x.rut||'—')} · ${esc(x.email||'sin correo')}</div></div><div class="right"><strong>${money(x.credit_limit)}</strong><div class="muted">Límite crédito</div></div></div>`).join('')||'<div class="empty">No hay clientes mayoristas.</div>'}</div>
      </div>
      <div class="card">
        <div class="toolbar"><div><h2>Acceso Portal Mayorista</h2><div class="muted">Cuenta y clave independientes del ERP.</div></div>
        ${can('WHOLESALE_MANAGE')?'<button id="newPortalAccount" class="btn secondary">Crear acceso</button>':''}</div>
        <div class="list">${arows.map(x=>{
          const status=!x.portal_account_exists?'<span class="badge off">Sin cuenta</span>':!x.portal_password_ready?'<span class="badge warn">Falta clave</span>':x.active?'<span class="badge ok">Portal activo</span>':'<span class="badge off">Portal inactivo</span>';
          return `<div class="list-item portal-access-row">
            <div><strong>${esc(x.sias_customers?.legal_name||x.email||'Mayorista')}</strong>
            <div class="muted">${esc(x.email||x.sias_customers?.email||'sin correo')}${x.last_login_at?` · último acceso ${fmtDate(x.last_login_at)}`:''}</div></div>
            <div class="toolbar-actions">${status}
            ${x.same_email_internal_user?'<span class="badge" title="También existe como usuario ERP, pero la clave es independiente">Correo usado en ERP</span>':''}
            ${can('WHOLESALE_MANAGE')?`<button class="btn secondary small portalAccessEdit" data-customer="${x.customer_id}">${x.portal_password_ready?'Cambiar clave':'Crear clave'}</button>`:''}
            </div></div>`;
        }).join('')||'<div class="empty">No hay clientes mayoristas.</div>'}</div>
        <div class="section-note mt"><strong>Importante:</strong> el Portal Mayorista usa <strong>sias_customer_accounts</strong>. No depende de Administración → Usuarios. Aunque el correo coincida con un SUPERADMIN, la clave del portal es otra.</div>
      </div>
    </div>`;

    bindDocumentActions(rows);
    $("#newWholesale")?.addEventListener('click',()=>documentModal('WHOLESALE'));
    $("#newPortalAccount")?.addEventListener('click',()=>portalAccountModal(crows,arows));
    $$(".portalAccessEdit").forEach(b=>b.addEventListener("click",()=>portalAccountModal(crows,arows,b.dataset.customer)));
  }

  function portalAccountModal(customers,accounts,selectedCustomerId=""){
    const current=accounts.find(a=>a.customer_id===selectedCustomerId)||null;
    openModal(current?.portal_password_ready?'Cambiar clave Portal Mayorista':'Crear acceso Portal Mayorista',`
      <div class="form-stack">
        <label>Cliente<select name="customer_id" id="portalCustomer" required>
          <option value="">Seleccionar…</option>
          ${customers.map(x=>`<option value="${x.id}" data-email="${esc(x.email||'')}" ${x.id===selectedCustomerId?'selected':''}>${esc(x.legal_name)} · ${esc(x.rut||'')}</option>`).join('')}
        </select></label>
        <label>Correo de acceso<input name="email" id="portalEmail" type="email" required value="${esc(current?.email||current?.sias_customers?.email||'')}"></label>
        <label>${current?.portal_password_ready?'Nueva clave':'Crear clave'}<input name="password" type="password" autocomplete="new-password" ${current?.portal_password_ready?'':'required'} minlength="10" placeholder="Mín. 10 caracteres, mayúscula, minúscula y número"></label>
        <label class="toggle-card"><input name="active" type="checkbox" ${current?.portal_account_exists&&current?.active===false?'':'checked'}><span><strong>Acceso activo</strong><small>El cliente podrá iniciar sesión en portal.html.</small></span></label>
        <div class="section-note"><strong>Acceso independiente.</strong> Esta clave no es la del SUPERADMIN ni la de ningún usuario interno del ERP.</div>
      </div>`,
      async fd=>{
        await erpCall('wholesale.account.save',{
          customer_id:fd.get('customer_id'),
          email:fd.get('email'),
          password:fd.get('password'),
          active:fd.get('active')==='on'
        });
        return {toast:'Acceso mayorista actualizado'};
      },
      current?.portal_password_ready?'Cambiar clave':'Guardar acceso'
    );

    const select=$("#portalCustomer"),emailInput=$("#portalEmail");
    const sync=()=>{
      const id=select?.value||"",op=select?.selectedOptions?.[0],existing=accounts.find(a=>a.customer_id===id);
      if(emailInput)emailInput.value=existing?.email||existing?.sias_customers?.email||op?.dataset.email||"";
      const check=$('#modalBody input[name=active]');
      if(check)check.checked=existing?.portal_account_exists?existing?.active!==false:true;
    };
    select?.addEventListener('change',sync);
    if(selectedCustomerId)sync();
  }
  async function renderDocumentModule(types,title,sub){
    const all=(await Promise.all(types.map(t=>erpCall("documents.list",{document_type:t,limit:250})))).flatMap(x=>x.rows||[]).sort((a,b)=>new Date(b.created_at)-new Date(a.created_at));
    $("#content").innerHTML=`<div class="card"><div class="toolbar"><div><h2>${esc(title)}</h2><div class="muted">${esc(sub)}</div></div><div class="toolbar-actions">${can('SALES_MANAGE')?'<button class="btn secondary newDoc" data-type="QUOTE">Cotización</button><button class="btn secondary newDoc" data-type="ORDER">Pedido</button><button class="btn primary newDoc" data-type="SALE">Venta directa</button>':''}</div></div>${documentsTable(all)}</div>`;bindDocumentActions(all);$$('.newDoc').forEach(b=>b.addEventListener('click',()=>documentModal(b.dataset.type)));
  }
  function documentsTable(rows){return window.SiasOperations.documentsTable(rows);}
  function bindDocumentActions(rows){return window.SiasOperations.bindDocuments(rows);}

  async function documentModal(type,existing=null){return window.SiasOperations.editDocument(type,existing);}

  async function documentPreview(id){return window.SiasOperations.preview(id);}
  function paymentModal(d){return window.SiasOperations.paymentModal(d);}

  function supplierModal(x={}){openModal(x.id?"Editar proveedor":"Nuevo proveedor",`<div class="form-grid"><label>RUT<input name="rut" value="${esc(x.rut||'')}"></label><label>Razón social<input name="legal_name" required value="${esc(x.legal_name||'')}"></label><label>Nombre de fantasía<input name="trade_name" value="${esc(x.trade_name||'')}"></label><label>Giro<input name="business_activity" value="${esc(x.business_activity||'')}"></label><label>Email<input name="email" type="email" value="${esc(x.email||'')}"></label><label>Teléfono<input name="phone" value="${esc(x.phone||'')}"></label><label class="full">Dirección<input name="address" value="${esc(x.address||'')}"></label><label>Comuna<input name="commune" value="${esc(x.commune||'')}"></label><label>Ciudad<input name="city" value="${esc(x.city||'')}"></label><label class="full">Notas<textarea name="notes">${esc(x.notes||'')}</textarea></label><label class="toggle-card"><input name="active" type="checkbox" ${x.active!==false?'checked':''}><span><strong>Proveedor activo</strong></span></label></div>`,async fd=>erpCall('suppliers.save',{id:x.id,...Object.fromEntries(fd),active:fd.get('active')==='on'}));}

  async function renderReports(){const r=await erpCall('reports.summary',{});state.cache.report=r;renderReportsFromData(r,true);}
  function renderReportsFromData(r,filters=false){
    const limit=state.cache.reportRankLimit??10,cut=a=>limit==='ALL'?(a||[]):(a||[]).slice(0,Number(limit)),products=cut(r.top_products),customers=cut(r.top_customers);
    $('#content').innerHTML=`<div class="grid kpis"><div class="card kpi"><span>Ventas período</span><strong>${money(r.sales)}</strong></div><div class="card kpi"><span>Compras período</span><strong>${money(r.purchases)}</strong></div><div class="card kpi"><span>IVA débito</span><strong>${money(r.tax_output)}</strong></div><div class="card kpi"><span>IVA crédito</span><strong>${money(r.tax_input)}</strong></div><div class="card kpi"><span>Movimientos comerciales</span><strong>${fmtQty(r.activity_count)}</strong><small class="muted">${fmtQty(r.posted_count)} publicados</small></div></div><div class="card mt"><div class="toolbar"><div><h2>Resumen comercial</h2><div class="muted">${esc(r.from)} a ${esc(r.to)}</div></div><div class="toolbar-actions"><input id="reportFrom" type="date" value="${esc(r.from)}"><input id="reportTo" type="date" value="${esc(r.to)}"><button id="applyReport" class="btn primary">Aplicar</button></div></div><div class="report-bars">${Object.entries(r.by_type||{}).map(([k,v])=>`<div class="report-row"><span>${esc(docLabels[k]||k)}</span><strong>${money(v)}</strong></div>`).join('')||'<div class="empty">No hay documentos publicados en el período.</div>'}</div></div><div class="two-col mt"><div class="card"><div class="toolbar"><div><h2>Ranking de productos</h2><div class="muted">Por monto vendido</div></div><select id="reportRankLimit" class="rank-select"><option value="1" ${limit==1?'selected':''}>Top 1</option><option value="10" ${limit==10?'selected':''}>Top 10</option><option value="20" ${limit==20?'selected':''}>Top 20</option><option value="50" ${limit==50?'selected':''}>Top 50</option><option value="ALL" ${limit==='ALL'?'selected':''}>Todos</option></select></div><div class="ranking-list">${products.map((x,i)=>`<div class="ranking-item"><span class="ranking-pos">${i+1}</span><div><strong>${esc(x.name)}</strong><small>${esc(x.sku||'Sin SKU')} · ${fmtQty(x.quantity)} un.</small></div><strong>${money(x.total)}</strong></div>`).join('')||'<div class="empty">Sin ventas publicadas.</div>'}</div></div><div class="card"><div class="toolbar"><div><h2>Ranking de clientes</h2><div class="muted">Por monto comprado</div></div></div><div class="ranking-list">${customers.map((x,i)=>`<div class="ranking-item"><span class="ranking-pos">${i+1}</span><div><strong>${esc(x.name)}</strong><small>${fmtQty(x.count)} documentos</small></div><strong>${money(x.total)}</strong></div>`).join('')||'<div class="empty">Sin clientes con ventas.</div>'}</div></div></div>`;
    $('#applyReport')?.addEventListener('click',async e=>{const b=e.currentTarget;setBusy(b,true,'Aplicando…');try{const rr=await erpCall('reports.summary',{from:$('#reportFrom').value,to:$('#reportTo').value});state.cache.report=rr;renderReportsFromData(rr,true)}catch(e){toast(errorText(e),true)}finally{if(b.isConnected)setBusy(b,false)}});
    $('#reportRankLimit')?.addEventListener('change',e=>{state.cache.reportRankLimit=e.target.value==='ALL'?'ALL':Number(e.target.value);renderReportsFromData(state.cache.report,true)});
  }

  async function renderBilling(){return window.SiasOperations.billing();}

  function billingConfigModal(c){openModal('Configuración de facturación',`<div class="form-stack"><label>Proveedor activo<select name="active_provider"><option value="SII_PROPIO" ${c.active_provider==='SII_PROPIO'?'selected':''}>Facturación propia SII</option><option value="FACTURACION_CL" ${c.active_provider==='FACTURACION_CL'?'selected':''}>Facturacion.cl</option></select></label><label>Ambiente<select name="environment"><option value="CERTIFICACION" ${c.environment!=='PRODUCCION'?'selected':''}>Certificación / Prueba</option><option value="PRODUCCION" ${c.environment==='PRODUCCION'?'selected':''}>Producción</option></select></label><label>IVA general %<input name="general_tax_rate" type="number" min="0" max="100" step="0.01" value="${esc(c.general_tax_rate??19)}"></label><label>API Facturacion.cl<input name="facturacion_cl_api_url" value="${esc(c.facturacion_cl_api_url||'https://rest.facturacion.cl')}"></label><div class="section-note">Los formatos de papel se administran en <strong>Sistema → Formatos de impresión</strong>, donde puedes definir A4, 80 mm o 57/58 mm por cada tipo de DTE y documento interno.</div><label class="toggle-card"><input name="facturacion_cl_include_link" type="checkbox" ${c.facturacion_cl_include_link!==false?'checked':''}><span><strong>Solicitar enlace al proveedor</strong></span></label><div class="section-note">El cambio de ambiente no modifica credenciales: prueba y producción se guardan por separado.</div></div>`,async fd=>erpCall('billing.config.save',{...Object.fromEntries(fd),general_tax_rate:Number(fd.get('general_tax_rate')||19),facturacion_cl_include_link:fd.get('facturacion_cl_include_link')==='on'}));}

  function billingCredentialsModal(c){openModal('Credenciales Facturacion.cl',`<div class="form-stack"><label>Ambiente<select name="environment"><option value="PRUEBA">Prueba / Certificación</option><option value="PRODUCCION">Producción</option></select></label><label>Usuario<input name="usuario" autocomplete="off" required></label><label>RUT emisor<input name="rut" placeholder="76.123.456-7" required></label><label>Clave<input name="clave" type="password" autocomplete="new-password" required></label><div class="section-note">Las credenciales se cifran de forma segura en el backend; la clave no se vuelve a mostrar.</div></div>`,async fd=>erpCall('billing.credentials.save',Object.fromEntries(fd)),"Guardar credenciales");}
  function billingTestModal(c){openModal('Probar Facturacion.cl',`<div class="form-stack"><label>Ambiente<select name="environment"><option value="PRUEBA">Prueba / Certificación</option><option value="PRODUCCION">Producción</option></select></label><div class="section-note">Se validará el login contra Facturacion.cl y se consultará la versión remota.</div></div>`,async fd=>{const r=await erpCall('billing.facturacioncl.test',{environment:fd.get('environment')});toast(`Conexión correcta${r.remote_version?` · ${r.remote_version}`:''}`)},"Probar conexión");}
  function issueDteModal(documentId,number,availableRefs){openModal(`Emitir DTE · ${number}`,`<div class="form-stack"><label>Tipo DTE<select name="document_type" id="issueDteType"><option value="33">33 · Factura electrónica</option><option value="34">34 · Factura exenta</option><option value="39">39 · Boleta electrónica</option><option value="41">41 · Boleta exenta</option><option value="61">61 · Nota de crédito</option><option value="56">56 · Nota de débito</option></select></label><label>Fecha emisión<input name="issue_date" type="date" value="${new Date().toISOString().slice(0,10)}"></label><div id="noteReferenceFields" class="hidden form-stack"><label>Documento referenciado<select name="reference_id"><option value="">Seleccionar…</option>${availableRefs.map(x=>`<option value="${x.id}">DTE ${x.document_type} · folio ${x.folio} · ${esc(x.recipient_name||'')}</option>`).join('')}</select></label><label>Motivo<select name="reference_code"><option value="1">1 · Anula documento</option><option value="2">2 · Corrige texto</option><option value="3">3 · Corrige monto</option></select></label><label>Razón referencia<input name="reference_reason" value="Corrección documento"></label><label>Monto nota (solo código 3)<input name="note_amount" type="number" min="0"></label></div><div class="danger-note section-note">Antes de emitir en PRODUCCIÓN confirma RUT, razón social, giro y dirección del cliente. Para Notas 56/61, SiasCloud toma el RUT del DTE original y no permite cambiarlo manualmente.</div></div>`,async fd=>issueAndOpenPdf({document_id:documentId,document_type:Number(fd.get('document_type')),issue_date:fd.get('issue_date'),reference_id:fd.get('reference_id')||null,reference_code:Number(fd.get('reference_code')||1),reference_reason:fd.get('reference_reason'),note_amount:Number(fd.get('note_amount')||0)}),"Emitir documento");$('#issueDteType').addEventListener('change',e=>$('#noteReferenceFields').classList.toggle('hidden',![56,61].includes(Number(e.target.value))));}
  async function openExternalPdf(id,format){return window.SiasDtePdf.open(id,format);}
  function issueAndOpenPdf(payload,format){return window.SiasDtePdf.emit(payload,format);}
  window.SiasDtePdf.init({erpCall,state,toast,errorText,setBusy});

  window.addEventListener("hashchange",()=>{const r=location.hash.replace('#','');if(r&&r!==state.route)navigate(r)});
  window.SiasOperations.init({erpCall,call,can,state,navigate,render,openModal,closeModal,money,fmtQty,fmtDate,toast,errorText,setBusy,icon,fileToBase64,prepareCompanyLogo,inventoryMovementChart,stockAdjustModal,supplierModal,billingConfigModal,billingCredentialsModal,billingTestModal,openExternalPdf,issueAndOpenPdf,draftKey,saveDraft,loadDraft,clearDraft,attachModalDraft,serializeFormDraft,restoreFormDraft,initContentFormDraft,clearContentFormDraft});
  window.SiasImporters.init({erpCall,can,state,navigate,money,fmtDate,toast,errorText,setBusy});
  window.SiasRetail.init({erpCall,call,can,state,navigate,render,openModal,closeModal,customerModal,money,fmtQty,fmtDate,toast,errorText,setBusy,icon,draftKey,saveDraft,loadDraft,clearDraft,attachModalDraft,serializeFormDraft,restoreFormDraft});
  bindPasswordToggles();
  boot();
})();
