(() => {
  "use strict";

  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const esc = (v) => String(v ?? "").replace(/[&<>'"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]));
  const money = (v) => new Intl.NumberFormat("es-CL",{style:"currency",currency:"CLP",maximumFractionDigits:0}).format(Number(v||0));
  const fmtDate = (v) => v ? new Date(v).toLocaleString("es-CL") : "—";
  const cfg = window.SIASCLOUD_CONFIG || {};

  if (cfg.fixedConnection && cfg.functionsBaseUrl) localStorage.removeItem("sias_functions_url");

  function formData(form){
    if(!form || String(form.tagName).toUpperCase() !== "FORM") throw new Error("Formulario inválido. Recarga la página con Ctrl + F5.");
    return new FormData(form);
  }

  const state = {
    token: sessionStorage.getItem("sias_customer_token") || "",
    me: null,
    route: "home",
    cart: JSON.parse(sessionStorage.getItem("sias_portal_cart") || "[]"),
    catalog: [],
    commercial: null,
    paymentMethod: sessionStorage.getItem("sias_portal_payment_method") || "TRANSFERENCIA"
  };

  const STATUS_LABELS = {
    DRAFT:"Borrador",
    POSTED:"Confirmado",
    VOID:"Anulado",
    PENDING:"Pendiente",
    PARTIAL:"Pago parcial",
    PAID:"Pagado",
    EMITIDO:"Emitido",
    ACEPTADO:"Aceptado",
    RECHAZADO:"Rechazado",
    PREPARACION:"En preparación",
    PREPARACIÓN:"En preparación",
    CONFIRMADO:"Confirmado",
    PENDIENTE:"Pendiente",
    ANULADO:"Anulado",
    CANCELLED:"Cancelado",
    CANCELED:"Cancelado",
    PROCESSING:"En preparación",
    SHIPPED:"Despachado",
    DELIVERED:"Entregado",
    READY:"Listo para despacho",
    CONFIRMED:"Confirmado"
  };

  const DOC_LABELS = {
    ORDER:"Pedido",
    WHOLESALE:"Venta mayorista",
    SALE:"Venta",
    QUOTE:"Cotización",
    REQUEST:"Solicitud"
  };

  const DTE_LABELS = {
    33:"Factura electrónica",
    34:"Factura exenta",
    39:"Boleta electrónica",
    41:"Boleta exenta",
    52:"Guía de despacho",
    56:"Nota de débito",
    61:"Nota de crédito"
  };

  function cleanName(v){ return String(v ?? "").trim(); }
  function looksBadDisplayName(v){
    const s = cleanName(v);
    if(!s) return true;
    if(/^\+?\d[\d\s().-]{6,}$/.test(s)) return true;
    if(/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(s)) return true;
    return false;
  }
  function displayCustomerName(c = {}){
    const opts = [c.contact_name,c.name,c.full_name,c.display_name,c.customer_name,c.trade_name,c.legal_name];
    for(const v of opts) if(!looksBadDisplayName(v)) return cleanName(v);
    return cleanName(c.trade_name || c.legal_name || "Cliente");
  }

  function statusLabel(v){
    const k = String(v ?? "").trim().toUpperCase();
    return STATUS_LABELS[k] || String(v ?? "—").replaceAll("_"," ").toLowerCase().replace(/(^|\s)\S/g,m=>m.toUpperCase());
  }

  function statusBadge(v){
    const k = String(v ?? "").trim().toUpperCase();
    const ok = ["POSTED","PAID","EMITIDO","ACEPTADO","CONFIRMADO","CONFIRMED","DELIVERED","READY"].includes(k);
    const warn = ["DRAFT","PENDING","PARTIAL","PREPARACION","PREPARACIÓN","PROCESSING","SHIPPED","PENDIENTE"].includes(k);
    const off = ["VOID","ANULADO","RECHAZADO","CANCELLED","CANCELED"].includes(k);
    return `<span class="badge ${ok?"ok":warn?"warn":off?"off":""}">${esc(statusLabel(v))}</span>`;
  }

  function docTypeLabel(v){ return DOC_LABELS[String(v||"").toUpperCase()] || String(v||"—"); }
  function dteTypeLabel(v){ return DTE_LABELS[Number(v)] || `DTE ${esc(v)}`; }

  function paymentIcon(code){
    const k = String(code||"").toUpperCase();
    const paths = {
      CREDITO:'<path d="M5 7h14v10H5z"/><path d="M8 10h8M8 14h4"/><path d="M3 9V6a2 2 0 0 1 2-2h12"/>',
      TRANSFERENCIA:'<path d="M3 10h18"/><path d="M5 10v8M9 10v8M15 10v8M19 10v8"/><path d="M2 20h20M12 3l9 5H3l9-5Z"/>',
      TARJETA:'<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18M7 15h4"/>',
      EFECTIVO:'<rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M6 9h.01M18 15h.01"/>'
    };
    return `<span class="payment-logo ${esc(k.toLowerCase())}"><svg viewBox="0 0 24 24" aria-hidden="true">${paths[k]||paths.TRANSFERENCIA}</svg></span>`;
  }

  function base(){
    return (cfg.functionsBaseUrl || localStorage.getItem("sias_functions_url") || "").replace(/\/$/,"");
  }

  function endpoint(){
    const b = base();
    if(!b) throw new Error("Configura la conexión antes de ingresar");
    return `${b}/${cfg.portalFunction || "siascloud-erp"}`;
  }

  async function api(action,payload={}){
    const headers = {"Content-Type":"application/json"};
    if(state.token) headers["X-Sias-Customer-Session"] = state.token;
    const res = await fetch(endpoint(),{
      method:"POST",
      headers,
      body:JSON.stringify({scope:"portal",action,payload}),
      cache:"no-store"
    });
    let data = {};
    try{ data = await res.json(); }catch{ throw new Error("Respuesta inválida del servidor"); }
    if(!res.ok || !data.ok){
      if(res.status === 401 && state.token){
        sessionStorage.removeItem("sias_customer_token");
        state.token = "";
        state.me = null;
        showLogin("La sesión terminó. Ingresa nuevamente.");
      }
      throw new Error(data.message || `Error ${res.status}`);
    }
    return data;
  }

  function toast(message){
    const t = $("#portalToast");
    t.textContent = message;
    t.classList.add("show");
    clearTimeout(toast.t);
    toast.t = setTimeout(()=>t.classList.remove("show"),2800);
  }

  function setButtonBusy(btn,on,label="Procesando…"){
    if(!btn) return;
    if(on){
      if(!btn.dataset.originalHtml) btn.dataset.originalHtml = btn.innerHTML;
      btn.disabled = true;
      btn.classList.add("is-loading");
      btn.innerHTML = `<span class="button-spinner" aria-hidden="true"></span><span>${esc(label)}</span>`;
    }else{
      btn.disabled = false;
      btn.classList.remove("is-loading");
      btn.innerHTML = btn.dataset.originalHtml || btn.innerHTML;
      delete btn.dataset.originalHtml;
    }
  }

  async function withButtonBusy(btn,label,fn){
    setButtonBusy(btn,true,label);
    try{ return await fn(); } finally { setButtonBusy(btn,false); }
  }

  function hideSplash(){
    const el = $("#portalSplash");
    if(!el || el.classList.contains("splash-hide")) return;
    el.classList.add("splash-hide");
    setTimeout(()=>el.remove(),420);
  }

  function bindPasswordToggles(root=document){
    $$("[data-password-toggle]",root).forEach(btn=>{
      if(btn.dataset.bound === "1") return;
      btn.dataset.bound = "1";
      btn.addEventListener("click",()=>{
        const input = document.querySelector(btn.dataset.passwordToggle);
        if(!input) return;
        const showing = input.type === "text";
        input.type = showing ? "password" : "text";
        btn.classList.toggle("showing",!showing);
        btn.setAttribute("aria-label",showing ? "Mostrar contraseña" : "Ocultar contraseña");
        btn.innerHTML = showing
          ? '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>'
          : '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 3l18 18"/><path d="M10.6 6.2A11 11 0 0 1 12 6c6.5 0 10 6 10 6a18 18 0 0 1-3 3.8M6.6 6.6C3.6 8.5 2 12 2 12s3.5 6 10 6c1.8 0 3.4-.5 4.8-1.2"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/></svg>';
      });
    });
  }

  function showLogin(msg=""){
    $("#portalApp").classList.add("hidden");
    $("#portalLogin").classList.remove("hidden");
    $("#loginMessage").textContent = msg;
    bindPasswordToggles($("#portalLogin"));
    hideSplash();
  }

  function saveCart(){
    sessionStorage.setItem("sias_portal_cart",JSON.stringify(state.cart));
    const cc = $("#cartCount");
    if(cc) cc.textContent = state.cart.reduce((s,x)=>s+Number(x.quantity||0),0);
  }

  async function detectLoginCompany(){
    const email = $("#portalLoginEmail")?.value?.trim() || "";
    const card = $("#loginCompanyCard"), name = $("#loginCompanyName"), meta = $("#loginCompanyMeta");
    const logo = $("#loginCompanyLogo"), wrap = $("#loginCompanySelectWrap"), sel = $("#loginCompanySelect");

    if(!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)){
      card.className = "login-auto-company waiting";
      name.textContent = "Empresa pendiente de detectar";
      meta.textContent = "Escribe tu correo y reconoceremos la empresa registrada en Mayoristas.";
      logo.src = "siascloud-logo.png";
      wrap.classList.add("hidden");
      sel.innerHTML = "";
      return;
    }

    card.className = "login-auto-company loading";
    name.textContent = "Buscando empresa…";
    meta.textContent = "Validando el acceso creado en el módulo Mayoristas.";

    try{
      const r = await api("company.resolve",{email});
      const rows = r.companies || [];
      if(!rows.length){
        card.className = "login-auto-company error";
        name.textContent = "No se encontró una empresa";
        meta.textContent = "No hay coincidencia para este correo en la cuenta de portal ni en el cliente mayorista.";
        logo.src = "siascloud-logo.png";
        wrap.classList.add("hidden");
        sel.innerHTML = "";
        return;
      }

      const paint = (c)=>{
        const ready = c.portal_account_exists !== false && c.account_active !== false && c.portal_password_ready && c.customer_linked !== false;
        card.className = ready ? "login-auto-company detected" : "login-auto-company error";
        name.textContent = c.trade_name || c.legal_name || "Empresa detectada";
        meta.textContent = ready
          ? `RUT ${c.rut||"—"} · acceso Portal Mayorista reconocido`
          : c.customer_linked === false
            ? `RUT ${c.rut||"—"} · cuenta encontrada, pero el vínculo con el cliente mayorista necesita reparación`
            : c.portal_account_exists === false
              ? `RUT ${c.rut||"—"} · empresa detectada; falta crear el acceso en Mayoristas → Acceso Portal Mayorista`
              : c.account_active === false
                ? `RUT ${c.rut||"—"} · empresa detectada; la cuenta del portal está desactivada`
                : `RUT ${c.rut||"—"} · empresa detectada; falta definir una clave propia del Portal Mayorista`;
        logo.src = c.logo_url || "siascloud-logo.png";
      };

      sel.innerHTML = rows.map(c=>`<option value="${esc(c.id)}">${esc(c.trade_name||c.legal_name)} · ${esc(c.rut||"")}</option>`).join("");
      if(rows.length > 1){
        wrap.classList.remove("hidden");
        sel.onchange = ()=>paint(rows.find(c=>c.id===sel.value) || rows[0]);
      }else{
        wrap.classList.add("hidden");
      }
      paint(rows[0]);
    }catch(err){
      card.className = "login-auto-company error";
      name.textContent = "No fue posible detectar la empresa";
      meta.textContent = err.message || "Revisa la conexión del portal.";
    }
  }

  let detectTimer = null;
  $("#portalLoginEmail")?.addEventListener("input",()=>{
    clearTimeout(detectTimer);
    detectTimer = setTimeout(detectLoginCompany,450);
  });
  $("#portalLoginEmail")?.addEventListener("blur",detectLoginCompany);

  async function boot(){
    bindPasswordToggles();
    if(!base()){
      showLogin("Configura la conexión para comenzar.");
      $("#connectionForm").classList.remove("hidden");
      return;
    }
    try{
      const s = await api("status");
      if(typeof cfg.checkBackendVersion!=='function')throw new Error('Actualiza config.js y recarga el sitio con Ctrl+F5.');
      cfg.checkBackendVersion(s.version);
    }catch(e){
      showLogin(e.message || "No fue posible conectar con el portal.");
      return;
    }
    if(state.token){
      try{
        const r = await api("me");
        state.me = r;
        start();
        return;
      }catch{}
    }
    showLogin($("#loginMessage").textContent || "");
  }

  if(cfg.fixedConnection){
    $("#connectionToggle").classList.add("hidden");
    $("#connectionForm").classList.add("hidden");
  }

  $("#connectionToggle").onclick = ()=>$("#connectionForm").classList.toggle("hidden");
  $("#connectionForm").onsubmit = (e)=>{
    e.preventDefault();
    const v = formData(e.currentTarget).get("functions_url").trim().replace(/\/$/,"");
    if(!/^https:\/\/.+\/functions\/v1$/i.test(v)){
      $("#loginMessage").textContent = "Revisa la URL de conexión.";
      return;
    }
    localStorage.setItem("sias_functions_url",v);
    $("#connectionForm").classList.add("hidden");
    $("#loginMessage").textContent = "Conexión guardada.";
  };

  $("#portalLoginForm").onsubmit = async (e)=>{
    e.preventDefault();
    const form = e.currentTarget;
    const btn = e.submitter || form.querySelector('button[type="submit"]');
    $("#loginMessage").textContent = "";
    await withButtonBusy(btn,"Ingresando…",async()=>{
      try{
        const f = Object.fromEntries(formData(form));
        await detectLoginCompany();
        const r = await api("login",f);
        state.token = r.token;
        sessionStorage.setItem("sias_customer_token",r.token);
        state.me = {company:r.company,customer:r.customer,account:r.account};
        state.commercial = null;
        start();
      }catch(err){
        $("#loginMessage").textContent = err.message || "No fue posible validar el acceso mayorista.";
      }
    });
  };

  function start(){
    $("#portalLogin").classList.add("hidden");
    $("#portalApp").classList.remove("hidden");
    $("#companyName").textContent = state.me.company.trade_name || state.me.company.legal_name;
    setAvatar();
    saveCart();

    $$("[data-route]").forEach(b=>b.onclick=()=>navigate(b.dataset.route));
    $("#menuBtn").onclick = ()=>$("#portalSidebar").classList.toggle("open");
    $("#cartBtn").onclick = async ()=>withButtonBusy($("#cartBtn"),"Cargando…",openCart);
    $("#logoutBtn").onclick = async ()=>{
      const b = $("#logoutBtn");
      await withButtonBusy(b,"Saliendo…",async()=>{
        try{ await api("logout"); }catch{}
        sessionStorage.removeItem("sias_customer_token");
        state.token = "";
        state.me = null;
        state.commercial = null;
        showLogin();
      });
    };
    hideSplash();
    navigate(location.hash.replace("#","") || "home");
  }

  function setAvatar(){
    const img = $("#headerAvatar");
    const profile = state.me?.customer?.profile_photo_url;
    const companyLogo = state.me?.company?.logo_url;
    img.src = profile || companyLogo || "siascloud-logo.png";
    img.classList.toggle("company-mark",!profile);
  }

  function navigate(route){
    state.route = ["home","catalog","orders","dtes","profile"].includes(route) ? route : "home";
    location.hash = state.route;
    $$("[data-route]").forEach(b=>b.classList.toggle("active",b.dataset.route===state.route));
    $("#portalSidebar").classList.remove("open");
    const titles = {home:"Inicio",catalog:"Catálogo",orders:"Mis pedidos",dtes:"Documentos",profile:"Mi perfil"};
    $("#portalTitle").textContent = titles[state.route];
    render();
  }

  window.addEventListener("hashchange",()=>{
    const r = location.hash.slice(1);
    if(r !== state.route) navigate(r);
  });

  async function render(){
    const c = $("#portalContent");
    c.innerHTML = '<div class="portal-loading"><span class="portal-spinner"></span><strong>Cargando información…</strong></div>';
    try{
      await ({home:renderHome,catalog:renderCatalog,orders:renderOrders,dtes:renderDtes,profile:renderProfile}[state.route] || renderHome)();
    }catch(e){
      c.innerHTML = `<div class="card"><strong>No fue posible cargar</strong><p class="muted">${esc(e.message)}</p></div>`;
    }
  }

  async function getCatalog(){
    const r = await api("catalog");
    state.catalog = r.rows || [];
    return state.catalog;
  }

  async function getCommercial(force=false){
    if(state.commercial && !force) return state.commercial;
    state.commercial = await api("commercial.summary");
    return state.commercial;
  }

  function renderPaymentMethods(methods=[],compact=false){
    return `<div class="payment-method-grid ${compact?"compact":""}">${methods.map(m=>`
      <div class="payment-method-card ${m.enabled===false?"disabled":""}">
        ${paymentIcon(m.code)}
        <div>
          <strong>${esc(m.name)}</strong>
          <span>${esc(m.detail || (m.enabled===false ? "No disponible" : "Disponible"))}</span>
        </div>
      </div>`).join("")}</div>`;
  }

  async function renderHome(){
    const [orders,products,commercial] = await Promise.all([api("orders.list"),getCatalog(),getCommercial(true)]);
    const rows = orders.rows || [];
    const pending = rows.filter(x=>["DRAFT","PENDING","PREPARACION","PREPARACIÓN"].includes(String(x.status||"").toUpperCase())).length;
    const total = rows.filter(x=>String(x.status||"").toUpperCase()==="POSTED").reduce((s,x)=>s+Number(x.total||0),0);
    const c = state.me.customer;
    const helloName = displayCustomerName(c);
    const heroLogo = c.profile_photo_url || state.me?.company?.logo_url || "siascloud-logo.png";

    const creditBlock = commercial.credit_enabled
      ? `<div class="credit-panel">
          <div class="credit-panel-head">
            <div><span>Línea de crédito</span><strong>${money(commercial.credit_limit)}</strong></div>
            <span class="badge ${commercial.available_credit>0?"ok":"off"}">${commercial.available_credit>0?"Disponible":"Sin disponible"}</span>
          </div>
          <div class="credit-progress"><i style="width:${Math.min(100,Math.max(0,Number(commercial.credit_used_percent||0)))}%"></i></div>
          <div class="credit-stats">
            <div><span>Utilizado</span><strong>${money(commercial.credit_used)}</strong></div>
            <div><span>Disponible</span><strong>${money(commercial.available_credit)}</strong></div>
          </div>
        </div>`
      : `<div class="credit-panel no-credit">
          <div><span>Línea de crédito</span><strong>Sin crédito asignado</strong></div>
          <p>La empresa no tiene una línea de crédito configurada para esta cuenta mayorista.</p>
        </div>`;

    $("#portalContent").innerHTML = `
      <div class="hero">
        <div>
          <h2>Hola, ${esc(helloName)}</h2>
          <p>Tu operación mayorista en un solo lugar.</p>
        </div>
        <img class="hero-logo" src="${esc(heroLogo)}" alt="Identidad del portal">
      </div>

      <div class="grid kpis">
        <div class="card kpi"><span>Pedidos</span><strong>${rows.length}</strong></div>
        <div class="card kpi"><span>Pendientes</span><strong>${pending}</strong></div>
        <div class="card kpi"><span>Productos disponibles</span><strong>${products.length}</strong></div>
        <div class="card kpi"><span>Compras registradas</span><strong>${money(total)}</strong></div>
      </div>

      <div class="commercial-grid">
        ${creditBlock}
        <div class="card payment-panel">
          <div class="toolbar">
            <div><h2>Medios de pago</h2><div class="muted">Opciones disponibles para tus pedidos mayoristas.</div></div>
          </div>
          ${renderPaymentMethods(commercial.payment_methods||[])}
        </div>
      </div>

      <div class="card" style="margin-top:15px">
        <div class="toolbar"><h2>Acceso rápido</h2></div>
        <button class="primary" id="homeCatalog">Ver catálogo y crear pedido</button>
      </div>`;

    $("#homeCatalog").onclick = ()=>navigate("catalog");
  }

  async function renderCatalog(){
    const rows = await getCatalog();
    $("#portalContent").innerHTML = `
      <div class="toolbar">
        <div><h2>Catálogo mayorista</h2><div class="muted">Precios asignados a tu canal comercial.</div></div>
        <input id="catalogSearch" class="search" placeholder="Buscar producto o SKU">
      </div>
      <div id="productsGrid" class="grid products"></div>`;

    const draw = (q)=>{
      const filtered = rows.filter(x=>!q || `${x.name} ${x.sku||""} ${x.category||""}`.toLowerCase().includes(q.toLowerCase()));
      $("#productsGrid").innerHTML = filtered.map(x=>`
        <article class="card product">
          ${x.featured?'<span class="featured">★ Destacado</span>':""}
          <div class="product-img"><img src="${esc(x.image_url||"siascloud-logo.png")}" alt="${esc(x.name)}"></div>
          <div class="product-body">
            <small>${esc(x.sku||x.category||"Producto")}</small>
            <h3>${esc(x.name)}</h3>
            <span class="product-price">${money(x.portal_price)}</span>
            <small>Stock referencial: ${Number(x.stock_total||0).toLocaleString("es-CL")}</small>
            <button type="button" class="product-view-button" data-product-image="${x.id}">Ver</button>
            <button data-add="${x.id}" ${Number(x.stock_total||0)<=0?"disabled":""}>${Number(x.stock_total||0)>0?"Agregar al carrito":"Sin stock"}</button>
          </div>
        </article>`).join("") || '<div class="card empty">No se encontraron productos.</div>';

      $$("[data-add]").forEach(b=>b.onclick=()=>{
        setButtonBusy(b,true,"Agregando…");
        addCart(b.dataset.add);
        setTimeout(()=>setButtonBusy(b,false),320);
      });
      const openImage=(el)=>{const p=rows.find(x=>x.id===el.dataset.productImage);if(!p)return;const images=[...new Set((Array.isArray(p.images)&&p.images.length?p.images:[p.image_url||'siascloud-logo.png']).filter(Boolean))];modal(`Imágenes · ${p.name}`,`<div class="portal-product-album"><div class="portal-album-stage"><button type="button" class="portal-album-arrow prev" id="portalAlbumPrev" aria-label="Imagen anterior">‹</button><img id="portalAlbumMain" src="${esc(images[0])}" alt="${esc(p.name)}"><button type="button" class="portal-album-arrow next" id="portalAlbumNext" aria-label="Siguiente imagen">›</button><span id="portalAlbumCount" class="portal-album-count">1 / ${images.length}</span></div><div class="portal-album-thumbs">${images.map((url,i)=>`<button type="button" class="portal-album-thumb ${i===0?'active':''}" data-portal-album-index="${i}"><img src="${esc(url)}" alt="Vista ${i+1} de ${esc(p.name)}"></button>`).join('')}</div><div class="portal-product-image-meta"><strong>${esc(p.name)}</strong><span>${esc(p.sku||p.category||`${images.length} imágenes`)}</span></div></div>`);let index=0;const main=$('#portalAlbumMain'),count=$('#portalAlbumCount'),thumbs=$$('[data-portal-album-index]');const show=i=>{index=(i+images.length)%images.length;main.src=images[index];count.textContent=`${index+1} / ${images.length}`;thumbs.forEach((b,n)=>b.classList.toggle('active',n===index));};thumbs.forEach(b=>b.onclick=()=>show(Number(b.dataset.portalAlbumIndex)));$('#portalAlbumPrev')?.addEventListener('click',()=>show(index-1));$('#portalAlbumNext')?.addEventListener('click',()=>show(index+1));};
      $$("[data-product-image]").forEach(el=>{el.onclick=e=>{e.preventDefault();e.stopPropagation();openImage(el);};el.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();openImage(el);}};});
    };

    draw("");
    $("#catalogSearch").oninput = e=>draw(e.target.value);
  }

  function addCart(id){
    const p = state.catalog.find(x=>x.id===id);
    if(!p) return;
    const x = state.cart.find(x=>x.product_id===id);
    if(x) x.quantity = Math.min(Number(p.stock_total||999999),Number(x.quantity)+1);
    else state.cart.push({product_id:id,name:p.name,sku:p.sku,price:p.portal_price,quantity:1,stock:Number(p.stock_total||0)});
    saveCart();
    toast("Producto agregado");
  }

  function modal(title,body,actions='<button value="cancel">Cerrar</button>'){
    $("#modalTitle").textContent = title;
    $("#modalBody").innerHTML = body;
    $("#modalActions").innerHTML = actions;
    $("#portalModal").showModal();
  }

  async function openCart(){
    const commercial = await getCommercial();
    const cartTotal = state.cart.reduce((s,x)=>s+Number(x.price)*Number(x.quantity),0);
    const methods = commercial.payment_methods || [];
    const methodCards = methods.map(m=>{
      const creditInsufficient = m.code==="CREDITO" && Number(commercial.available_credit||0) < cartTotal;
      const disabled = m.enabled===false || creditInsufficient;
      const checked = state.paymentMethod===m.code && !disabled;
      const detail = m.code==="CREDITO"
        ? `Disponible: ${money(commercial.available_credit)}`
        : (m.detail || "Disponible");
      return `<label class="payment-choice ${disabled?"disabled":""}">
        <input type="radio" name="cart_payment_method" value="${esc(m.code)}" ${checked?"checked":""} ${disabled?"disabled":""}>
        ${paymentIcon(m.code)}
        <span><strong>${esc(m.name)}</strong><small>${esc(detail)}${creditInsufficient?" · crédito insuficiente para este pedido":""}</small></span>
      </label>`;
    }).join("");

    const body = state.cart.length
      ? `<div class="cart-sheet">
          <div class="cart-list">${state.cart.map(x=>`
            <div class="cart-line">
              <div class="cart-info">
                <strong>${esc(x.name)}</strong>
                <small class="muted">SKU: ${esc(x.sku||"—")}</small>
                <small class="muted">Precio unitario: ${money(x.price)}</small>
              </div>
              <div class="cart-qty"><input type="number" min="1" max="${x.stock||999999}" value="${x.quantity}" data-cartqty="${x.product_id}" aria-label="Cantidad de ${esc(x.name)}"></div>
              <button class="cart-remove" data-cartdel="${x.product_id}" aria-label="Quitar ${esc(x.name)}">×</button>
            </div>`).join("")}</div>
          <div class="cart-payment">
            <div class="cart-payment-head"><strong>Medio de pago</strong><span>Selecciona cómo deseas gestionar el pedido.</span></div>
            <div class="payment-choice-grid">${methodCards}</div>
          </div>
          <label class="cart-notes">Observaciones<textarea id="cartNotes" placeholder="Indicaciones para el pedido"></textarea></label>
          <div class="cart-total"><span>Total estimado</span><span id="cartTotal"></span></div>
        </div>`
      : '<div class="empty">Tu carrito está vacío.</div>';

    modal(
      "Carrito",
      body,
      state.cart.length
        ? '<button value="cancel" class="cart-secondary-btn">Seguir comprando</button><button type="button" id="sendOrder" class="primary cart-primary-btn">Enviar pedido</button>'
        : '<button value="cancel">Cerrar</button>'
    );

    const ensurePaymentSelection = ()=>{
      let selected = $('input[name="cart_payment_method"]:checked');
      if(!selected){
        selected = $('input[name="cart_payment_method"]:not(:disabled)');
        if(selected) selected.checked = true;
      }
      if(selected){
        state.paymentMethod = selected.value;
        sessionStorage.setItem("sias_portal_payment_method",selected.value);
      }
    };

    const calc = ()=>{
      const total = state.cart.reduce((s,x)=>s+Number(x.price)*Number(x.quantity),0);
      $("#cartTotal").textContent = money(total);
      const credit = $('input[name="cart_payment_method"][value="CREDITO"]');
      if(credit){
        const disabled = Number(commercial.available_credit||0) < total || !commercial.credit_enabled;
        credit.disabled = disabled;
        credit.closest(".payment-choice")?.classList.toggle("disabled",disabled);
        if(disabled && credit.checked) credit.checked = false;
      }
      ensurePaymentSelection();
    };

    $$("[data-cartqty]").forEach(i=>i.onchange=()=>{
      const x = state.cart.find(x=>x.product_id===i.dataset.cartqty);
      if(x) x.quantity = Math.max(1,Math.min(x.stock||999999,Number(i.value||1)));
      saveCart();
      calc();
    });

    $$("[data-cartdel]").forEach(b=>b.onclick=()=>{
      state.cart = state.cart.filter(x=>x.product_id!==b.dataset.cartdel);
      saveCart();
      openCart();
    });

    $$('input[name="cart_payment_method"]').forEach(r=>r.onchange=()=>{
      if(r.checked){
        state.paymentMethod = r.value;
        sessionStorage.setItem("sias_portal_payment_method",r.value);
      }
    });

    calc();
    $("#sendOrder")?.addEventListener("click",sendOrder);
  }

  async function sendOrder(){
    const b = $("#sendOrder");
    await withButtonBusy(b,"Enviando…",async()=>{
      try{
        const selected = $('input[name="cart_payment_method"]:checked')?.value;
        if(!selected) throw new Error("Selecciona un medio de pago.");
        const r = await api("orders.create",{
          items:state.cart.map(x=>({product_id:x.product_id,quantity:x.quantity})),
          notes:$("#cartNotes")?.value || "",
          payment_method:selected
        });
        state.cart = [];
        state.commercial = null;
        saveCart();
        $("#portalModal").close();
        toast(`Pedido ${r.document.number} enviado`);
        navigate("orders");
      }catch(e){
        toast(e.message);
      }
    });
  }

  async function renderOrders(){
    const r = await api("orders.list"), rows = r.rows || [];
    $("#portalContent").innerHTML = `
      <div class="card">
        <div class="toolbar">
          <div><h2>Mis pedidos y ventas</h2><div class="muted">Seguimiento de tu historial comercial.</div></div>
          <button id="newOrder" class="primary" style="width:auto">Nuevo pedido</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Fecha</th><th>Número</th><th>Tipo</th><th>Estado</th><th>Pago</th><th class="right">Total</th><th></th></tr></thead>
            <tbody>${rows.map(x=>`
              <tr>
                <td>${esc(x.issue_date)}</td>
                <td><strong>${esc(x.number)}</strong></td>
                <td>${esc(docTypeLabel(x.document_type))}</td>
                <td>${statusBadge(x.status)}</td>
                <td>${statusBadge(x.payment_status)}</td>
                <td class="right">${money(x.total)}</td>
                <td><button data-order="${x.id}">Ver</button></td>
              </tr>`).join("") || '<tr><td colspan="7" class="empty">Aún no tienes pedidos.</td></tr>'}</tbody>
          </table>
        </div>
      </div>`;

    $("#newOrder").onclick = ()=>navigate("catalog");
    $$("[data-order]").forEach(b=>b.onclick=()=>withButtonBusy(b,"Cargando…",()=>showOrder(b.dataset.order)));
  }

  async function showOrder(id){
    const r = await api("orders.get",{id}), d = r.document, items = r.items || [];
    modal(`Pedido ${d.number}`,`
      <div class="order-summary-strip">
        <div><span>Estado</span>${statusBadge(d.status)}</div>
        <div><span>Pago</span>${statusBadge(d.payment_status)}</div>
        <div><span>Medio de pago</span><strong>${esc(paymentMethodName(d.payment_method))}</strong></div>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Producto</th><th class="right">Cant.</th><th class="right">Precio</th><th class="right">Total</th></tr></thead>
          <tbody>${items.map(x=>`<tr><td>${esc(x.description)}</td><td class="right">${Number(x.quantity).toLocaleString("es-CL")}</td><td class="right">${money(x.unit_price)}</td><td class="right">${money(x.line_total)}</td></tr>`).join("")}</tbody>
        </table>
      </div>
      <div class="cart-total"><span>Total</span><span>${money(d.total)}</span></div>`);
  }

  function paymentMethodName(v){
    return ({
      CREDITO:"Crédito empresa",
      TRANSFERENCIA:"Transferencia bancaria",
      TARJETA:"Tarjeta",
      EFECTIVO:"Efectivo",
      POR_DEFINIR:"Por definir",
      OTHER:"Otro",
      OTRO:"Otro"
    })[String(v||"").toUpperCase()] || String(v||"Por definir").replaceAll("_"," ");
  }

  async function renderDtes(){
    const r = await api("dtes.list"), rows = r.rows || [];
    $("#portalContent").innerHTML = `
      <div class="card">
        <div class="toolbar">
          <div><h2>Documentos tributarios</h2><div class="muted">Facturas, boletas y notas asociadas a tu cuenta.</div></div>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Fecha</th><th>DTE</th><th>Folio</th><th>Estado</th><th class="right">Total</th><th>PDF</th></tr></thead>
            <tbody>${rows.map(x=>`
              <tr>
                <td>${esc(x.issue_date)}</td>
                <td>${esc(dteTypeLabel(x.document_type))}</td>
                <td>${esc(x.folio||"—")}</td>
                <td>${statusBadge(x.status)}</td>
                <td class="right">${money(x.total)}</td>
                <td>${String(x.status||"").toUpperCase()==="EMITIDO"?`<button data-pdf="${x.id}">Ver PDF</button>`:"—"}</td>
              </tr>`).join("") || '<tr><td colspan="6" class="empty">No hay documentos disponibles.</td></tr>'}</tbody>
          </table>
        </div>
      </div>`;

    $$("[data-pdf]").forEach(b=>b.onclick=()=>withButtonBusy(b,"Abriendo…",()=>openPdf(b.dataset.pdf)));
  }

  async function openPdf(id){
    try{
      const r = await api("dtes.pdf",{id});
      const raw = atob(String(r.pdf_base64||"").replace(/\s/g,""));
      const bytes = new Uint8Array(raw.length);
      for(let i=0;i<raw.length;i++) bytes[i]=raw.charCodeAt(i);
      const url = URL.createObjectURL(new Blob([bytes],{type:"application/pdf"}));
      window.open(url,"_blank","noopener");
      setTimeout(()=>URL.revokeObjectURL(url),60000);
    }catch(e){
      toast(e.message);
    }
  }

  async function file64(file){
    return await new Promise((resolve,reject)=>{
      const r = new FileReader();
      r.onload = ()=>resolve(String(r.result).split(",")[1]);
      r.onerror = reject;
      r.readAsDataURL(file);
    });
  }

  async function renderProfile(){
    const [r,commercial] = await Promise.all([api("me"),getCommercial()]);
    state.me = r;
    setAvatar();
    const c = r.customer;
    $("#portalContent").innerHTML = `
      <div class="card">
        <div class="profile-grid">
          <div>
            <img class="profile-photo" src="${esc(c.profile_photo_url||r.company?.logo_url||"siascloud-logo.png")}" alt="Perfil">
            <label style="margin-top:10px">Cambiar foto<input id="profileImage" type="file" accept="image/jpeg,image/png,image/webp"></label>
            <div class="profile-credit">
              <span>Límite de crédito</span>
              <strong>${money(commercial.credit_limit||0)}</strong>
              <small>Disponible: ${money(commercial.available_credit||0)}</small>
            </div>
          </div>
          <form id="profileForm" class="form-grid">
            <label>Razón social<input value="${esc(c.legal_name)}" disabled></label>
            <label>RUT<input value="${esc(c.rut||"")}" disabled></label>
            <label>Contacto<input name="contact_name" value="${esc(c.contact_name||"")}"></label>
            <label>Teléfono<input name="phone" value="${esc(c.phone||"")}"></label>
            <label class="full">Dirección<input name="address" value="${esc(c.address||"")}"></label>
            <label>Comuna<input name="commune" value="${esc(c.commune||"")}"></label>
            <label>Ciudad<input name="city" value="${esc(c.city||"")}"></label>
            <label>Región<input name="region" value="${esc(c.region||"")}"></label>
            <div class="full"><button class="primary" type="submit">Guardar cambios</button></div>
          </form>
        </div>
      </div>`;

    $("#profileForm").onsubmit = async (e)=>{
      e.preventDefault();
      const btn = e.submitter;
      await withButtonBusy(btn,"Guardando…",async()=>{
        try{
          const rr = await api("profile.save",Object.fromEntries(formData(e.currentTarget)));
          state.me.customer = rr.customer;
          toast("Perfil actualizado");
        }catch(err){
          toast(err.message);
        }
      });
    };

    $("#profileImage").onchange = async (e)=>{
      const f = e.target.files[0];
      if(!f) return;
      if(f.size > 5*1024*1024){ toast("La imagen supera 5 MB"); return; }
      const label = e.target.closest("label");
      label?.classList.add("uploading");
      try{
        const rr = await api("profile.image",{file_base64:await file64(f),content_type:f.type});
        state.me.customer.profile_photo_url = rr.url;
        setAvatar();
        await renderProfile();
        toast("Foto actualizada");
      }catch(err){
        toast(err.message);
      }finally{
        label?.classList.remove("uploading");
      }
    };
  }

  bindPasswordToggles();
  boot();
})();
