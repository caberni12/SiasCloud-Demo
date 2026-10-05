(() => {
  'use strict';
  const $ = s => document.querySelector(s);
  const $$ = s => [...document.querySelectorAll(s)];
  const E = v => String(v ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const cash = v => new Intl.NumberFormat('es-CL',{style:'currency',currency:'CLP',maximumFractionDigits:0}).format(Number(v||0));
  const cfg = window.SIASCLOUD_CONFIG || {};
  const requestedSlug = new URLSearchParams(location.search).get('tienda') || cfg.storeSlug || '';
  const state = {store:null,products:[],cart:[],category:'',sending:false,requestSending:false,heroIndex:0,heroTimer:null};

  function toast(s){ const el=$('#storeToast'); el.textContent=s; el.classList.add('show'); clearTimeout(toast.timer); toast.timer=setTimeout(()=>el.classList.remove('show'),3000); }
  async function api(action,p={}){
    const base=String(cfg.functionsBaseUrl||'').replace(/\/$/,'');
    if(!base) throw new Error('La conexión de la tienda no está configurada');
    const r = await fetch(`${base}/${cfg.storeFunction||'siascloud-erp'}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({scope:'store',action,payload:{slug:state.store?.slug||requestedSlug,...p}}),cache:'no-store'});
    let data;
    try { data = await r.json(); } catch { throw new Error('No fue posible conectar con la tienda'); }
    if(!r.ok || !data.ok) throw new Error(data.code==='TIENDA_NO_DISPONIBLE'?'La tienda no está publicada. Su administrador puede activarla desde SiasCloud.':data.code==='ENLACE_TIENDA_REQUERIDO'?'Abre el enlace de la tienda que te entregó la empresa.':data.message||'No fue posible completar la solicitud');
    return data;
  }

  const product = id => state.products.find(p=>String(p.id)===String(id));
  const cartKey = () => `sias_cart:${state.store?.slug || requestedSlug || 'default'}`;
  const scrollToCatalog = () => $('#catalogo')?.scrollIntoView({behavior:'smooth',block:'start'});
  function saveCart(){ localStorage.setItem(cartKey(), JSON.stringify(state.cart)); updateCount(); }
  function updateCount(){ $('#cartCount').textContent = state.cart.reduce((s,x)=>s + Number(x.quantity||0),0); }
  function cartTotal(){ return state.cart.reduce((s,x)=>s + (Number(product(x.product_id)?.price||0) * Number(x.quantity||0)),0); }
  function add(id,quantity=1){
    if(!state.store?.allow_orders){ toast('Consulta con la tienda para realizar tu pedido'); return; }
    const p = product(id);
    if(!p || !Number.isFinite(quantity) || quantity<=0 || quantity>10000) return;
    const row = state.cart.find(x=>String(x.product_id)===String(id));
    if(row) row.quantity = Math.min(10000, Number(row.quantity||0) + quantity);
    else state.cart.push({product_id:id, quantity});
    saveCart();
    toast(`${p.name} agregado al carrito`);
  }
  function excerpt(value,size=120){ const text=String(value||'').replace(/\s+/g,' ').trim(); return text.length>size?`${text.slice(0,size-1).trim()}…`:text; }
  function waLink(phone,message='Hola, vengo desde la tienda y quiero hacer una consulta.'){
    const clean = String(phone||'').replace(/\D/g,'');
    return clean ? `https://wa.me/${clean}?text=${encodeURIComponent(message)}` : '';
  }
  function heroProducts(){
    const featured = state.products.filter(p=>p.image_url && p.featured);
    const pool = (featured.length ? featured : state.products.filter(p=>p.image_url)).slice(0,6);
    if(pool.length) return pool;
    return state.products.slice(0,6);
  }
  function zoomProductImage(id){
    const p = product(id);
    const images=[...new Set((Array.isArray(p?.images)&&p.images.length?p.images:[p?.image_url]).filter(Boolean))];
    if(!p || !images.length) return;
    $('#imageZoomBody').innerHTML = `<div class="store-product-album"><div class="store-album-stage"><button type="button" class="store-album-arrow prev" id="storeAlbumPrev" aria-label="Imagen anterior">‹</button><img id="storeAlbumMain" src="${E(images[0])}" alt="${E(p.name)}"><button type="button" class="store-album-arrow next" id="storeAlbumNext" aria-label="Siguiente imagen">›</button><span class="store-album-count" id="storeAlbumCount">1 / ${images.length}</span></div><div class="store-album-thumbs">${images.map((url,i)=>`<button type="button" class="store-album-thumb ${i===0?'active':''}" data-store-album-index="${i}"><img src="${E(url)}" alt="Vista ${i+1} de ${E(p.name)}"></button>`).join('')}</div><div class="store-product-image-zoom-meta"><strong>${E(p.name)}</strong><span>${E(p.sku||p.category||`${images.length} imagen${images.length===1?'':'es'}`)}</span></div></div>`;
    const d=$('#imageZoomDialog'); if(!d.open) d.showModal();
    let index=0;const main=$('#storeAlbumMain'),count=$('#storeAlbumCount'),thumbs=$$('[data-store-album-index]');
    const show=i=>{index=(i+images.length)%images.length;main.src=images[index];count.textContent=`${index+1} / ${images.length}`;thumbs.forEach((b,n)=>b.classList.toggle('active',n===index));};
    thumbs.forEach(b=>b.addEventListener('click',()=>show(Number(b.dataset.storeAlbumIndex))));
    $('#storeAlbumPrev')?.addEventListener('click',()=>show(index-1));$('#storeAlbumNext')?.addEventListener('click',()=>show(index+1));
  }
  function bindImageZoom(root=document){
    root.querySelectorAll('[data-product-image]').forEach(el=>{
      if(el.dataset.zoomBound) return;
      el.dataset.zoomBound='1';
      el.addEventListener('click',e=>{ e.preventDefault(); e.stopPropagation(); zoomProductImage(el.dataset.productImage); });
    });
  }
  function showTerms(){ if(state.store) $('#termsDialog').showModal(); }
  function socialLink({href,label,icon}){ if(!href) return ''; return `<a href="${E(href)}" target="_blank" rel="noopener" aria-label="${E(label)}" title="${E(label)}">${icon}</a>`; }
  function icon(name){
    const icons={
      whatsapp:'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20.52 3.48A11.85 11.85 0 0 0 12.09 0C5.56 0 .25 5.3.25 11.84c0 2.08.54 4.1 1.57 5.88L0 24l6.46-1.7a11.8 11.8 0 0 0 5.63 1.43h.01c6.53 0 11.84-5.31 11.84-11.84 0-3.16-1.23-6.12-3.42-8.41ZM12.1 21.73h-.01a9.8 9.8 0 0 1-5-1.37l-.36-.21-3.84 1 1.03-3.74-.24-.39a9.8 9.8 0 0 1-1.5-5.18C2.18 6.42 6.6 2 12.09 2a9.8 9.8 0 0 1 6.99 2.9 9.78 9.78 0 0 1 2.87 6.95c0 5.5-4.42 9.88-9.85 9.88Zm5.42-7.36c-.3-.15-1.77-.88-2.04-.98-.27-.1-.46-.15-.65.15-.2.29-.75.97-.92 1.16-.17.2-.34.22-.64.08-.29-.15-1.24-.46-2.36-1.47-.87-.77-1.46-1.73-1.63-2.02-.17-.29-.02-.45.13-.6.14-.14.29-.34.44-.51.14-.17.19-.29.29-.49.1-.19.05-.37-.02-.51-.08-.14-.66-1.59-.9-2.17-.24-.58-.48-.49-.65-.5h-.56c-.2 0-.51.08-.78.37-.27.3-1.03 1-1.03 2.44s1.05 2.82 1.2 3.02c.15.2 2.05 3.13 4.96 4.39.69.3 1.24.48 1.66.61.7.22 1.33.19 1.83.12.56-.08 1.77-.72 2.02-1.41.24-.7.24-1.3.17-1.42-.07-.12-.27-.19-.56-.34Z"/></svg>',
      instagram:'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 2h10a5 5 0 0 1 5 5v10a5 5 0 0 1-5 5H7a5 5 0 0 1-5-5V7a5 5 0 0 1 5-5Zm0 2a3 3 0 0 0-3 3v10a3 3 0 0 0 3 3h10a3 3 0 0 0 3-3V7a3 3 0 0 0-3-3H7Zm10.5 1.5a1 1 0 1 1-.001 1.999A1 1 0 0 1 17.5 5.5ZM12 7a5 5 0 1 1 0 10 5 5 0 0 1 0-10Zm0 2a3 3 0 1 0 0 6 3 3 0 0 0 0-6Z"/></svg>',
      facebook:'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M13.5 22v-8h2.7l.4-3h-3.1V9.1c0-.9.3-1.5 1.6-1.5h1.7V4.9c-.3 0-1.3-.1-2.4-.1-2.4 0-4 1.5-4 4.2V11H8v3h2.4v8h3.1Z"/></svg>',
      tiktok:'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M14.5 2h2.7c.3 2.2 1.6 3.5 3.8 3.7v2.8c-1.7-.1-3.2-.6-4.5-1.5v7.1a6.1 6.1 0 1 1-6.1-6.1c.4 0 .9 0 1.3.1V11a3.3 3.3 0 1 0 2.8 3.2V2Z"/></svg>',
      youtube:'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M23.5 6.2a3 3 0 0 0-2.1-2.1C19.5 3.6 12 3.6 12 3.6s-7.5 0-9.4.5A3 3 0 0 0 .5 6.2C0 8.1 0 12 0 12s0 3.9.5 5.8a3 3 0 0 0 2.1 2.1c1.9.5 9.4.5 9.4.5s7.5 0 9.4-.5a3 3 0 0 0 2.1-2.1C24 15.9 24 12 24 12s0-3.9-.5-5.8ZM9.6 15.6V8.4l6.3 3.6-6.3 3.6Z"/></svg>',
      email:'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 5h18a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1Zm0 2v.2l9 6.3 9-6.3V7H3Zm18 10V9.6l-8.4 5.9a1 1 0 0 1-1.2 0L3 9.6V17h18Z"/></svg>'
    };
    return icons[name] || '';
  }

  function renderHero(){
    const items = heroProducts();
    const container = $('#storeHeroCarousel');
    const fallbackImage = state.store?.hero_image || '';
    if(!items.length && fallbackImage){
      container.innerHTML = `<div class="hero-slide"><div class="hero-slide-copy"><small>${E(state.store?.title||'TIENDA')}</small><h3>${E(state.store?.hero_title || 'Descubre nuestro catálogo')}</h3><p>${E(state.store?.hero_text || 'Explora nuestros productos, destacados y campañas disponibles.')}</p><div class="hero-slide-actions"><a class="button primary" href="#catalogo">Ver catálogo</a></div></div><div class="hero-slide-visual"><button type="button" data-hero-image="standalone"><img src="${E(fallbackImage)}" alt="${E(state.store?.title||'Tienda')}"></button></div></div>`;
      return;
    }
    if(!items.length){
      container.innerHTML = `<div class="hero-slide"><div class="hero-slide-copy"><small>${E(state.store?.title||'TIENDA')}</small><h3>${E(state.store?.hero_title || 'Descubre nuestro catálogo')}</h3><p>${E(state.store?.hero_text || 'Pronto verás aquí productos destacados, ofertas y campañas comerciales.')}</p><div class="hero-slide-actions"><a class="button primary" href="#catalogo">Ver catálogo</a></div></div><div class="hero-slide-visual"></div></div>`;
      return;
    }
    container.innerHTML = `
      <div class="hero-carousel-track">
        ${items.map((p,i)=>`
          <article class="hero-slide" aria-hidden="${i===0?'false':'true'}">
            <div class="hero-slide-copy">
              <small>${E(p.category || 'DESTACADO')}</small>
              <h3>${E(p.name || 'Producto destacado')}</h3>
              <p>${E(excerpt(p.description || state.store?.hero_text || 'Explora nuestros destacados, productos y promociones.', 180))}</p>
              <div class="hero-slide-actions">
                <span class="pill">${p.featured ? 'Destacado' : 'Catálogo'}</span>
                <span class="pill">${cash(p.price || 0)}</span>
                <button class="button primary" type="button" data-hero-product="${E(p.id)}">Ver producto</button>
              </div>
            </div>
            <div class="hero-slide-visual">
              ${p.featured ? '<span class="hero-slide-badge">Destacado</span>' : ''}
              ${p.image_url ? `<button type="button" data-product-image="${E(p.id)}" aria-label="Ampliar imagen de ${E(p.name)}"><img src="${E(p.image_url)}" alt="${E(p.name)}"></button>` : ''}
            </div>
          </article>`).join('')}
      </div>
      <div class="hero-carousel-dots">${items.map((_,i)=>`<button type="button" data-hero-dot="${i}" class="${i===0?'active':''}" aria-label="Ir al slide ${i+1}"></button>`).join('')}</div>
      ${items.length>1?`<div class="hero-carousel-nav"><button type="button" data-hero-prev aria-label="Slide anterior">‹</button><button type="button" data-hero-next aria-label="Siguiente slide">›</button></div>`:''}
    `;
    const track = container.querySelector('.hero-carousel-track');
    const dots = [...container.querySelectorAll('[data-hero-dot]')];
    const count = items.length;
    state.heroIndex = Math.min(state.heroIndex, count - 1);
    const paint = () => {
      track.style.transform = `translateX(-${state.heroIndex * 100}%)`;
      dots.forEach((dot,index)=>dot.classList.toggle('active', index===state.heroIndex));
      container.querySelectorAll('.hero-slide').forEach((slide,index)=>slide.setAttribute('aria-hidden', index===state.heroIndex ? 'false' : 'true'));
    };
    const go = index => { state.heroIndex = (index + count) % count; paint(); restartHeroTimer(); };
    const restartHeroTimer = () => {
      clearInterval(state.heroTimer);
      if(count>1){ state.heroTimer = setInterval(()=>{ state.heroIndex=(state.heroIndex+1)%count; paint(); }, 5500); }
    };
    container.querySelector('[data-hero-prev]')?.addEventListener('click',()=>go(state.heroIndex-1));
    container.querySelector('[data-hero-next]')?.addEventListener('click',()=>go(state.heroIndex+1));
    dots.forEach(dot=>dot.addEventListener('click',()=>go(Number(dot.dataset.heroDot))));
    container.querySelectorAll('[data-hero-product]').forEach(btn=>btn.addEventListener('click',()=>details(btn.dataset.heroProduct)));
    bindImageZoom(container);
    paint();
    restartHeroTimer();
  }

  function renderCatalog(){
    const q = $('#catalogSearch').value.trim().toLowerCase();
    const sort = $('#catalogSort').value;
    const rows = state.products.filter(p => (!state.category || p.category===state.category) && (!q || [p.name,p.sku,p.category,p.description].some(v=>String(v||'').toLowerCase().includes(q))));
    rows.sort(sort==='price-asc'?(a,b)=>Number(a.price)-Number(b.price):sort==='price-desc'?(a,b)=>Number(b.price)-Number(a.price):sort==='name'?(a,b)=>String(a.name||'').localeCompare(String(b.name||''),'es'):(a,b)=>Number(b.featured)-Number(a.featured)||String(a.name||'').localeCompare(String(b.name||''),'es'));
    $('#catalogCount').textContent = `${rows.length} ${rows.length===1?'producto':'productos'}`;
    $('#productGrid').innerHTML = rows.map(p => `
      <article class="product-card">
        <div class="product-photo">
          ${p.featured?'<span class="featured-tag">Destacado</span>':''}
          ${p.image_url ? `<button type="button" data-product-image="${E(p.id)}" aria-label="Ver imagen ampliada de ${E(p.name)}"><img src="${E(p.image_url)}" alt="${E(p.name)}" loading="lazy"></button>` : '<span class="product-placeholder" aria-hidden="true">◇</span>'}
        </div>
        <div class="product-body">
          <span class="product-category">${E(p.category || 'CATÁLOGO')}</span>
          <h3 class="product-title"><button type="button" data-product="${E(p.id)}">${E(p.name)}</button></h3>
          <p class="product-desc">${E(excerpt(p.description || 'Consulta con nuestro equipo si necesitas más información sobre este producto.', 135))}</p>
          <div class="product-meta">${E(p.unit ? `Por ${p.unit}` : 'Pedido personalizado disponible')}${p.exempt ? ' · Exento' : ''}</div>
          <div class="product-footer">
            <div class="product-price-block">
              <div class="product-price">${cash(p.price)}</div>
              <span class="product-unit">${p.available ? (state.store?.show_stock ? `${Number(p.stock||0).toLocaleString('es-CL')} disponibles` : 'Disponible') : 'Consultar disponibilidad'}</span>
            </div>
            <div class="product-actions">
              <div class="product-actions-row">
                ${p.image_url ? `<button class="view-product-image" type="button" data-product-image="${E(p.id)}">Ver</button>` : ''}
                <button class="view-product-detail" type="button" data-product="${E(p.id)}">Detalle</button>
              </div>
              ${state.store?.allow_orders ? `<button class="add-product" type="button" data-add="${E(p.id)}">+ Agregar</button>` : `<button class="add-product" type="button" data-product="${E(p.id)}">Consultar</button>`}
            </div>
          </div>
        </div>
      </article>`).join('') || '<div class="catalog-empty">No hay productos para esta búsqueda.</div>';

    $$('[data-product]').forEach(b=>b.addEventListener('click',()=>details(b.dataset.product)));
    $$('[data-add]').forEach(b=>b.addEventListener('click',()=>add(b.dataset.add)));
    bindImageZoom($('#productGrid'));
    $$('#productGrid img').forEach(img=>img.addEventListener('error',()=>{ img.replaceWith(Object.assign(document.createElement('span'),{className:'product-placeholder',textContent:'◇'})); }));
  }

  function details(id){
    const p = product(id);
    if(!p) return;
    $('#productDetail').innerHTML = `<div class="product-detail-grid">${p.image_url?`<button class="product-detail-photo product-image-zoom-trigger" type="button" data-product-image="${p.id}" aria-label="Ampliar imagen de ${E(p.name)}" title="Ver imagen ampliada"><img src="${E(p.image_url)}" alt="${E(p.name)}"></button>`:'<div class="product-detail-photo"><span class="product-placeholder">◇</span></div>'}<div class="product-detail-copy"><span class="eyebrow">${E(p.category||'PRODUCTO')}</span><h2>${E(p.name)}</h2><p>${E(p.description||'Consulta con nuestro equipo si necesitas más información sobre este producto.')}</p><div class="detail-price">${cash(p.price)}</div><small class="muted">por ${E(p.unit||'unidad')} · ${p.exempt?'Exento de IVA':'IVA incluido'}</small>${state.store?.allow_orders?'<label class="detail-quantity">Cantidad<input id="detailQuantity" type="number" min="1" max="10000" step="1" value="1"></label><button id="detailAdd" class="button primary full-button" type="button">Agregar al carrito</button>':''}</div></div>`;
    bindImageZoom($('#productDetail'));
    $('#productDialog').showModal();
    $('#detailAdd')?.addEventListener('click',()=>{
      const qty = Number($('#detailQuantity').value);
      if(!Number.isInteger(qty) || qty<1 || qty>10000){ toast('Ingresa una cantidad válida'); return; }
      add(id,qty); $('#productDialog').close();
    });
  }

  function renderCart(){
    state.cart = state.cart.filter(x=>product(x.product_id));
    saveCart();
    $('#cartItems').innerHTML = state.cart.map(x=>{
      const p = product(x.product_id);
      return `<div class="cart-row">${p.image_url?`<button type="button" class="cart-product-image product-image-zoom-trigger" data-product-image="${p.id}" aria-label="Ampliar imagen de ${E(p.name)}" title="Ver imagen ampliada"><img src="${E(p.image_url)}" alt="${E(p.name)}"></button>`:'<div class="cart-mini-placeholder"></div>'}<div><strong>${E(p.name)}</strong><small>${cash(p.price)} por ${E(p.unit || 'unidad')}</small></div><input type="number" min="1" max="10000" step="1" value="${x.quantity}" data-cart-qty="${p.id}" aria-label="Cantidad de ${E(p.name)}"><strong class="cart-line-total">${cash(Number(p.price||0) * Number(x.quantity||0))}</strong><button class="remove-cart" type="button" data-cart-remove="${p.id}" aria-label="Quitar ${E(p.name)}">×</button></div>`;
    }).join('') || '<div class="cart-empty">Tu carrito está vacío. Explora el catálogo y agrega tus favoritos.</div>';
    $('#cartSummary').innerHTML = state.cart.length ? `<div class="cart-total"><span>Total de productos</span><strong>${cash(cartTotal())}</strong></div><button class="button primary full-button" id="goCheckout" type="button">Continuar con la solicitud</button><p class="order-explanation">El pedido y el despacho serán confirmados por nuestro equipo.</p>` : '';
    $$('[data-cart-remove]').forEach(b=>b.addEventListener('click',()=>{ state.cart = state.cart.filter(x=>String(x.product_id)!==String(b.dataset.cartRemove)); renderCart(); }));
    $$('[data-cart-qty]').forEach(input=>input.addEventListener('change',()=>{ const qty=Number(input.value); if(!Number.isInteger(qty)||qty<1||qty>10000){ renderCart(); return; } state.cart.find(x=>String(x.product_id)===String(input.dataset.cartQty)).quantity=qty; renderCart(); }));
    bindImageZoom($('#cartItems'));
    $('#goCheckout')?.addEventListener('click',()=>{ $('#cartDialog').close(); $('#checkoutTotal').textContent = cash(cartTotal()); $('#checkoutError').textContent=''; $('#checkoutDialog').showModal(); });
  }

  function renderStoreChrome(){
    const s = state.store || {};
    document.title = `${s.title || 'Tienda'} · Tienda`;
    if(/^#[a-f0-9]{6}$/i.test(s.primary_color)) document.documentElement.style.setProperty('--store-primary', s.primary_color);
    const assignments = [
      ['#storeName', s.title || 'Nuestra tienda'],
      ['#storeFooterName', s.title || 'Nuestra tienda'],
      ['#storeTagline', s.tagline || 'Bienvenido a nuestra tienda'],
      ['#storeHeroTitle', s.hero_title || 'Productos para cada día'],
      ['#storeHeroText', s.hero_text || 'Explora nuestro catálogo, productos destacados y campañas comerciales.'],
      ['#storeAboutTitle', s.about_title || 'Estamos para ayudarte'],
      ['#storeAboutText', s.about_text || 'Encuentra tus productos favoritos y coordina tu pedido con nuestro equipo.'],
      ['#storeDeliveryText', s.delivery_text || 'Coordina la entrega o retiro con nuestro equipo al confirmar tu pedido.'],
      ['#storeTerms', s.terms || 'Las solicitudes están sujetas a confirmación de disponibilidad, entrega y pago. Los datos ingresados se utilizan para atender y gestionar tu solicitud.'],
      ['#storeFooterDescription', s.about_text ? excerpt(s.about_text, 120) : 'Catálogo conectado a SiasCloud para gestionar productos, pedidos y consultas.'],
      ['#storeFooterAddress', s.contact_address || ''],
      ['#storeFooterEmail', s.contact_email || '']
    ];
    assignments.forEach(([id,val])=>{ const el=$(id); if(el) el.textContent = val; });
    if(s.logo_url){ $('#storeLogo').src = s.logo_url; $('#storeFooterLogo').src = s.logo_url; }
    $('#storeFooterPhone').textContent = s.whatsapp ? `+${String(s.whatsapp).replace(/(\d{2})(\d+)/,'$1 $2')}` : 'Sin teléfono configurado';


    const networkButtons = [
      {href: s.whatsapp ? waLink(s.whatsapp) : '', label:'WhatsApp', icon: icon('whatsapp')},
      {href: s.instagram_url || '', label:'Instagram', icon: icon('instagram')},
      {href: s.facebook_url || '', label:'Facebook', icon: icon('facebook')},
      {href: s.tiktok_url || '', label:'TikTok', icon: icon('tiktok')},
      {href: s.youtube_url || '', label:'YouTube', icon: icon('youtube')}
    ];
    $('#storeSocialLinks').innerHTML = networkButtons.map(x=>x.href
      ? socialLink(x)
      : `<span class="social-disabled" title="Configura ${E(x.label)} desde Administración" aria-label="${E(x.label)} sin configurar">${x.icon}</span>`
    ).join('') + `<button id="openRequestSocial" type="button" aria-label="Enviar solicitud" title="Enviar solicitud">${icon('email')}</button>`;
    $('#openRequestSocial')?.addEventListener('click',()=>$('#requestDialog').showModal());

    const wa = $('#floatingWhatsapp');
    if(s.whatsapp){ wa.href = waLink(s.whatsapp); wa.classList.remove('hidden'); } else { wa.classList.add('hidden'); }
  }

  async function load(){
    $('#storeLoading').classList.remove('hidden'); $('#storeError').classList.add('hidden'); $('#storeContent').classList.add('hidden');
    try{
      const r = await api('catalog');
      state.store = r.store;
      state.products = r.rows || [];
      renderStoreChrome();
      try{
        const data = JSON.parse(localStorage.getItem(cartKey()) || '[]');
        state.cart = Array.isArray(data) ? data.filter(x=>product(x.product_id) && Number.isInteger(x.quantity) && x.quantity>0 && x.quantity<=10000).slice(0,60) : [];
      }catch{ state.cart=[]; }
      const categories = [...new Set(state.products.map(p=>p.category).filter(Boolean))].sort((a,b)=>a.localeCompare(b,'es'));
      $('#catalogCategories').innerHTML = `<button type="button" class="active" data-category="">Todos</button>${categories.map(c=>`<button type="button" data-category="${E(c)}">${E(c)}</button>`).join('')}`;
      $$('[data-category]').forEach(b=>b.addEventListener('click',()=>{ state.category=b.dataset.category; $$('[data-category]').forEach(x=>x.classList.toggle('active',x===b)); renderCatalog(); }));
      $('#openCart').disabled = !state.store.allow_orders;
      saveCart();
      renderHero();
      renderCatalog();
      $('#storeContent').classList.remove('hidden');
    }catch(err){
      $('#storeErrorText').textContent = err.message;
      $('#storeError').classList.remove('hidden');
    }finally{
      $('#storeLoading').classList.add('hidden');
    }
  }

  $('#catalogSearch').addEventListener('input', renderCatalog);
  $('#catalogSort').addEventListener('change', renderCatalog);
  $('#storeRetry').addEventListener('click', load);
  $('#openCart').addEventListener('click', ()=>{ if(!state.store) return; renderCart(); $('#cartDialog').showModal(); });
  $('#headerSearch').addEventListener('click', scrollToCatalog);
  $('#heroSecondaryBtn').addEventListener('click', scrollToCatalog);
  $$('[data-close]').forEach(b=>b.addEventListener('click',()=>{ if(b.dataset.close==='checkoutDialog' && state.sending) return; $('#'+b.dataset.close).close(); }));
  $$('dialog').forEach(d=>d.addEventListener('click',e=>{ if(e.target!==d) return; const r=d.getBoundingClientRect(); if(e.clientX<r.left || e.clientX>r.right || e.clientY<r.top || e.clientY>r.bottom){ if(d.id==='checkoutDialog' && state.sending) return; d.close(); } }));
  $('#openTerms').addEventListener('click', showTerms);
  $('#openTermsBottom').addEventListener('click', showTerms);
  $('#openTermsBottom2').addEventListener('click', showTerms);
  $('#openRequestFooter').addEventListener('click',()=>$('#requestDialog').showModal());
  $('#requestDialog').addEventListener('cancel',e=>{ if(state.requestSending)e.preventDefault(); });
  $('#requestForm').addEventListener('submit', async e=>{
    e.preventDefault();
    const form=e.currentTarget;
    if(state.requestSending)return;
    const fd=new FormData(form);
    const payload={
      request_key:crypto.randomUUID(),
      website:fd.get('website'),
      contact:{
        name:String(fd.get('name')||'').trim(),
        phone:String(fd.get('phone')||'').trim(),
        email:String(fd.get('email')||'').trim(),
        subject:String(fd.get('subject')||'').trim(),
        message:String(fd.get('message')||'').trim()
      }
    };
    state.requestSending=true;
    $('#submitRequest').disabled=true;
    $('#submitRequest').textContent='Enviando…';
    $('#requestError').textContent='';
    try{
      const r=await api('contact.create',payload);
      $('#requestDialog').close();
      form.reset();
      $('#successNumber').textContent=r.number||'Solicitud enviada';
      $('#successTotal').textContent='Tu mensaje quedó registrado en SiasCloud.';
      $('#successDialog').showModal();
    }catch(err){
      $('#requestError').textContent=err.message||'No fue posible enviar la solicitud';
    }finally{
      state.requestSending=false;
      $('#submitRequest').disabled=false;
      $('#submitRequest').textContent='Enviar solicitud';
    }
  });
  $('#checkoutDelivery').addEventListener('change',()=>{ const required=$('#checkoutDelivery').value==='DESPACHO'; $$('.delivery-address').forEach(label=>{ label.classList.toggle('hidden',!required); label.querySelector('input').required=required; }); });
  $('#checkoutDialog').addEventListener('cancel',e=>{ if(state.sending) e.preventDefault(); });
  $('#checkoutForm').addEventListener('submit', async e=>{
    e.preventDefault(); const form = e.currentTarget; if(state.sending || !state.cart.length) return; state.sending=true; $('#submitOrder').disabled=true; $('#submitOrder').textContent='Enviando solicitud…'; $('#checkoutError').textContent='';
    try{
      const fd = new FormData(form);
      const contact = Object.fromEntries([...fd].filter(([k])=>!['accept_terms','website'].includes(k)));
      const payload = {contact, items:state.cart.map(x=>({...x})), website:fd.get('website'), accept_terms:fd.get('accept_terms')==='on'};
      const bytes = new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(JSON.stringify(payload))));
      const fingerprint = [...bytes].map(x=>x.toString(16).padStart(2,'0')).join('');
      const pendingKey = `sias_pending:${state.store.slug}`;
      let pending; try{ pending = JSON.parse(sessionStorage.getItem(pendingKey) || 'null'); }catch{}
      if(!pending || pending.fingerprint!==fingerprint){ pending={request_key:crypto.randomUUID(),fingerprint}; sessionStorage.setItem(pendingKey, JSON.stringify(pending)); }
      const r = await api('orders.create',{...payload,request_key:pending.request_key});
      state.cart=[]; saveCart(); sessionStorage.removeItem(pendingKey); $('#checkoutDialog').close(); $('#successNumber').textContent=r.number; $('#successTotal').textContent=r.total!==undefined?`Total registrado: ${cash(r.total)}`:''; $('#successDialog').showModal(); form.reset(); $$('.delivery-address').forEach(label=>{ label.classList.add('hidden'); label.querySelector('input').required=false; });
    }catch(err){ $('#checkoutError').textContent = err.message; }
    finally{ state.sending=false; $('#submitOrder').disabled=false; $('#submitOrder').textContent='Enviar solicitud'; }
  });

  $('#storeYear').textContent = new Date().getFullYear();
  load();
})();
