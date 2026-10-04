/* POS visual y cobros: módulo independiente. */
(()=>{
  'use strict';
  let A,viewSequence=0;
  const $=(s,r=document)=>r.querySelector(s),$$=(s,r=document)=>[...r.querySelectorAll(s)];
  const E=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const C=window.SiasRetailCore,api=(action,p={})=>A.erpCall(action,p),money=v=>A.money(v),qty=v=>A.fmtQty(v);
  const uid=()=>crypto.randomUUID();
  const status={DRAFT:'Borrador',POSTED:'Confirmado',VOID:'Anulado',OPEN:'Abierta',CLOSED:'Cerrado'};
  const methods={CASH:'Efectivo',CARD:'Tarjeta',TRANSFER:'Transferencia',CLIENT_CREDIT:'Crédito cliente',OTHER:'Otro'};
  const badge=(s,ok=true)=>`<span class="badge ${ok?'ok':'warn'}">${E(status[s]||s)}</span>`;
  const button=(label,id,primary=false)=>`<button type="button" id="${id}" class="btn ${primary?'primary':'secondary'}">${E(label)}</button>`;
  const options=(rows,value='',empty='Seleccionar…')=>`<option value="">${E(empty)}</option>`+rows.map(x=>`<option value="${E(x.id)}" ${x.id===value?'selected':''}>${E(x.name||x.legal_name)}${x.rut?' · '+E(x.rut):''}</option>`).join('');
  const guarded=fn=>async e=>{const b=e?.currentTarget;try{if(b?.tagName==='BUTTON')A.setBusy(b,true);await fn(e);}catch(err){A.toast(A.errorText(err),true);}finally{if(b?.tagName==='BUTTON'&&b.isConnected)A.setBusy(b,false);}};
  const on=(id,fn)=>$(id)?.addEventListener('click',guarded(fn));
  function readModal(title,html){A.openModal(title,html,async()=>{},'Cerrar');const b=$('#modalActions .primary');b.type='button';b.onclick=()=>A.closeModal(true);$('#modalCancel').classList.add('hidden');}
  const cartState={company:null,lines:[],customer:'',warehouse:'',priceList:'',seller:'',category:'',customerRow:null,data:null};
  const pendingKey=()=>`sias_pos_pending:${A.state.me.companyId}:${A.state.me.user.id}`;
  function pending(){try{return JSON.parse(sessionStorage.getItem(pendingKey())||'null');}catch{return null;}}
  function clearPending(){sessionStorage.removeItem(pendingKey());cartState.lines=[];}
  async function completeCheckout(r,after={}){clearPending();A.closeModal(true);await pos();A.toast(`Venta ${r.document.number} registrada · vuelto ${money(r.change||0)}`);try{if(after.dteType)await window.SiasOperations.issueConfigured(r.document.id,after.dteType,after.printFormat,after.recipientPhone);else if(after.printReceipt)await A.print(r.document.id,'AUTO');}catch(e){A.toast('La venta quedó registrada. '+A.errorText(e),true);}}
  async function retryCheckout(){const p=pending();if(!p)return;try{const r=await api('pos.checkout',p);await completeCheckout(r);}catch(e){A.toast(A.errorText(e),true);}}
  async function cancelPending(){const p=pending();if(!p)return;const r=await api('pos.cancel',{request_key:p.request_key});if(r.document){await completeCheckout(r);return;}clearPending();await pos();A.toast('Cobro pendiente descartado');}
  async function pos(){
    const view=++viewSequence;
    const company=A.state.me.companyId;if(cartState.company!==company){Object.assign(cartState,{company,lines:[],customer:'',warehouse:'',priceList:'',seller:'',category:'',customerRow:null});}
    const data=await api('pos.catalog',{warehouse_id:cartState.warehouse,price_list_id:cartState.priceList});
    if(view!==viewSequence||A.state.route!=='pos'||A.state.me?.companyId!==company)return;
    cartState.data=data;
    if(cartState.customerRow?.id===cartState.customer&&!data.customers.some(c=>c.id===cartState.customer))data.customers.unshift(cartState.customerRow);
    cartState.warehouse=data.warehouse_id||cartState.warehouse||data.warehouses[0]?.id||'';
    const waiting=pending(),session=data.session,activeCashier=session?data.staff.find(s=>s.id===session.cashier_id):null,cashierName=activeCashier?.name||(session?A.state.me.user.full_name:'');
    $('#content').innerHTML=`<div class="pos-workspace"><div class="pos-topbar"><div><span class="pos-mark">▦</span><strong>Punto de venta</strong><small>Venta rápida</small></div><div class="pos-search-wrap"><span aria-hidden="true">⌕</span><input class="pos-search" id="posSearch" aria-label="Buscar producto o escanear código" placeholder="Buscar producto, SKU o código de barras…" autocomplete="off" ${waiting?'disabled':''}></div>${button('Caja y cierre','posCash')}</div>`+
      (waiting?`<div class="retail-note warn"><strong>Hay un cobro pendiente de verificar.</strong><p>Reintenta para recuperar la misma venta o descarta la solicitud de forma segura.</p><div class="retail-actions">${button('Reintentar cobro','posRetry',true)}${button('Descartar cobro pendiente','posCancelPending')}</div></div>`:'')+
      (data.stock_policy?.allow_negative_stock?`<div class="retail-note warn pos-stock-policy"><strong>Venta sin stock habilitada</strong><span>El sistema permitirá cerrar ventas aunque el stock quede negativo.</span></div>`:'')+
      `<div class="pos-layout pos-reference"><section class="card pos-sale"><div class="pos-ticket-head"><div><small>TICKET ACTUAL</small><h3>Venta rápida</h3></div><span class="badge" id="posLineCount">0 artículos</span></div><div class="pos-controls"><div class="pos-customer-field"><div class="pos-control-heading"><label for="posCustomer">Cliente</label>${A.can('CUSTOMER_MANAGE')?`<button type="button" id="posNewCustomer" class="btn secondary small" aria-label="Crear cliente sin salir del punto de venta" ${waiting?'disabled':''}>+ Nuevo cliente</button>`:''}</div><div class="pos-customer-search"><input id="posCustomerSearch" type="search" placeholder="Buscar por nombre, RUT o teléfono…" aria-label="Buscar cliente" role="combobox" aria-autocomplete="list" aria-controls="posCustomerResults" aria-expanded="false" autocomplete="off" ${waiting?'disabled':''}><div id="posCustomerResults" class="pos-customer-results" role="listbox" aria-label="Clientes encontrados" hidden></div></div><select id="posCustomer" ${waiting?'disabled':''}>${options(data.customers,cartState.customer)}</select></div><label><span class="pos-control-heading">Vendedor</span><select id="posSeller" ${waiting?'disabled':''}>${options(data.staff.filter(s=>s.roles.includes('SELLER')),cartState.seller,'Sin asignar')}</select></label></div><div class="pos-lines" id="posLines"></div><div class="pos-ticket-footer"><div class="pos-summary"><div><span>Neto + exento</span><b id="posNet"></b></div><div><span>IVA incluido</span><b id="posTax"></b></div></div><div class="pos-total"><span>Total a pagar</span><strong id="posTotal"></strong></div><button type="button" class="btn primary pos-charge" id="posCharge" aria-label="Cobrar" ${waiting||!session||!A.can('POS_MANAGE')?'disabled':''}><span>Cobrar</span><strong id="posChargeAmount" aria-hidden="true"></strong></button><div class="pos-ticket-actions">${button('Vaciar ticket','posClear')}<span>F2 buscar · F4 cobrar</span></div></div></section><section class="card pos-catalog"><div class="pos-catalog-head"><div><h3>Catálogo</h3><small class="master-help" id="posCatalogCount"></small></div><div class="pos-controls"><label>Bodega<select id="posWarehouse" ${waiting?'disabled':''}>${options(data.warehouses,cartState.warehouse)}</select></label><label>Lista de precios<select id="posPriceList" ${waiting||cartState.lines.length?'disabled':''}>${options(data.lists,cartState.priceList,'Precio de venta')}</select></label></div></div><div class="pos-categories" id="posCategories" role="group" aria-label="Categorías"></div><div class="pos-products" id="posProducts"></div></section></div><div class="pos-session">${session?badge('OPEN')+'<strong>'+E(session.register_code)+'</strong> · '+E(A.fmtDate(session.opened_at))+`<span class="pos-cashier-pill">Cajero: <strong>${E(cashierName||'Sin asignar')}</strong></span>`:badge('Caja cerrada',false)+'<span>Abre una caja para cobrar.</span>'}${!session&&A.can('POS_MANAGE')?button('Abrir caja','posOpenCash',true):''}<span class="pos-session-end">SiasCloud · ${E((A.state.me.companies||[]).find(c=>c.id===company)?.trade_name||'Venta por unidad, peso y empaque')}</span></div></div>`;
    const root=$('.pos-workspace'),isCurrent=()=>root.isConnected&&view===viewSequence&&A.state.route==='pos'&&A.state.me?.companyId===company;
    let products=data.products,searchSequence=0,timer;
    const catalogProducts=[...data.products];
    const normalizeSearch=v=>String(v??'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();
    const compactSearch=v=>normalizeSearch(v).replace(/\s+/g,'');
    const editDistance=(a,b,max=2)=>{
      if(Math.abs(a.length-b.length)>max)return max+1;
      let prev=Array.from({length:b.length+1},(_,i)=>i);
      for(let i=1;i<=a.length;i++){
        const cur=[i];let rowMin=i;
        for(let j=1;j<=b.length;j++){const cost=a[i-1]===b[j-1]?0:1;cur[j]=Math.min(cur[j-1]+1,prev[j]+1,prev[j-1]+cost);rowMin=Math.min(rowMin,cur[j]);}
        if(rowMin>max)return max+1;prev=cur;
      }
      return prev[b.length];
    };
    const fuzzyScore=(p,raw)=>{
      const q=normalizeSearch(raw);if(!q)return 1;
      const qCompact=compactSearch(raw),tokens=q.split(/\s+/).filter(Boolean);
      const name=normalizeSearch(p.name),sku=normalizeSearch(p.sku),barcode=normalizeSearch(p.barcode),category=normalizeSearch(p.category),description=normalizeSearch(p.description);
      const compactName=name.replace(/\s+/g,''),all=[name,sku,barcode,category,description].filter(Boolean).join(' '),words=all.split(/\s+/).filter(Boolean);
      if(q===barcode||q===sku)return 2000;
      if(qCompact&&(qCompact===compactSearch(p.barcode)||qCompact===compactSearch(p.sku)))return 1950;
      let score=0;
      if(name===q)score=Math.max(score,1500);
      if(name.startsWith(q))score=Math.max(score,1250);
      if(compactName.includes(qCompact))score=Math.max(score,1100);
      if(sku.startsWith(q)||barcode.startsWith(q))score=Math.max(score,1050);
      if(all.includes(q))score=Math.max(score,900);
      let matched=0;
      for(const t of tokens){
        let best=0;
        if(all.includes(t))best=160;
        else if(words.some(w=>w.startsWith(t)))best=135;
        else if(t.length>=4&&words.some(w=>Math.abs(w.length-t.length)<=2&&editDistance(w,t,2)<=Math.min(2,Math.floor(t.length/4))))best=95;
        if(best){matched++;score+=best;}
      }
      if(tokens.length&&matched===tokens.length)score+=400;
      else if(tokens.length>1&&matched<Math.ceil(tokens.length*.67))return 0;
      return score;
    };
    const localSearch=(text,source=catalogProducts)=>{
      const q=normalizeSearch(text);
      const pool=(cartState.category&&q?source.filter(p=>p.category===cartState.category):source);
      if(!q)return cartState.category?pool.filter(p=>p.category===cartState.category):pool;
      return pool.map((p,i)=>({p,score:fuzzyScore(p,text),i})).filter(x=>x.score>0).sort((a,b)=>b.score-a.score||a.i-b.i).map(x=>x.p);
    };
    const categories=data.categories||[...new Set(data.products.map(p=>p.category).filter(Boolean))].sort();
    $('#posCategories').innerHTML=['',...categories].map((c,i)=>`<button type="button" class="pos-category ${c===(cartState.category||'')?'active':''}" data-pos-category="${E(c)}" aria-pressed="${c===(cartState.category||'')}" style="--category-accent:${['#389bdf','#a98adb','#e5a850','#48b7a7','#e47e94'][i%5]}" ${waiting?'disabled':''}>${E(c||'Todos')}</button>`).join('');
    const drawProducts=()=>{if(!isCurrent())return;$('#posProducts',root).innerHTML=products.map(p=>`<button type="button" class="pos-product" data-pos-product="${E(p.id)}" ${waiting?'disabled':''}><b class="pos-product-price">${money(p.price)}</b><div class="pos-product-image">${p.image_url?`<img alt="" src="${E(p.image_url)}" loading="lazy">`:`<span class="pos-product-placeholder" aria-hidden="true">${E((p.name||'P').slice(0,2).toUpperCase())}</span>`}</div><strong>${E(p.name)}</strong><small>${E(p.sku||p.barcode||'')} · ${E(C.normalizeUnit(p.unit))}</small><span class="pos-product-category">${E(p.category||'Sin categoría')}</span><span class="pos-stock ${p.stock_total>0?'':'empty-stock'}">Stock ${qty(p.stock_total)}</span><span class="pos-product-corner" aria-hidden="true">+</span></button>`).join('')||'<div class="empty">No se encontraron productos.</div>';$('#posCatalogCount').textContent=`${products.length} productos · precios por unidad base`;$$('[data-pos-product]').forEach(b=>b.addEventListener('click',guarded(()=>capture(products.find(p=>p.id===b.dataset.posProduct)))));};
    const drawLines=()=>{
      if(!isCurrent())return;
      $('#posLines').innerHTML=cartState.lines.map(x=>`<div class="pos-line"><div><strong>${E(x.name)}</strong><small>${E(x.sku||'')} · ${money(x.unit_price)} / ${E(x.unit)}</small></div><div class="pos-line-quantity"><input type="number" data-pos-qty="${E(x.product_id)}" aria-label="Cantidad de ${E(x.name)}" min="0.0001" max="1000000" step="0.0001" value="${x.quantity}" ${waiting?'disabled':''}><small>${E(x.unit)}</small></div><div class="line-total">${money(Math.round(x.quantity*x.unit_price))}</div><button type="button" class="icon-btn" data-pos-remove="${E(x.product_id)}" aria-label="Quitar ${E(x.name)}" ${waiting?'disabled':''}>×</button></div>`).join('')||'<div class="retail-line-empty"><span class="pos-empty-icon" aria-hidden="true">▤</span><strong>Tu ticket está vacío</strong><p>Selecciona un producto o escanea su código para comenzar.</p></div>';
      const total=C.totals(cartState.lines);let tax=0;for(const x of cartState.lines){const pr=[...products,...data.products].find(p=>p.id===x.product_id)||x,lineTotal=Math.round(x.quantity*x.unit_price),rate=Number(pr.tax_rate??19);if(!pr.exempt)tax+=lineTotal-Math.round(lineTotal/(1+rate/100));}
      $('#posTotal').textContent=money(total);$('#posChargeAmount').textContent=money(total);$('#posNet').textContent=money(total-tax);$('#posTax').textContent=money(tax);$('#posLineCount').textContent=`${cartState.lines.length} artículos`;
      $('#posPriceList').disabled=Boolean(waiting||cartState.lines.length);
      $$('[data-pos-remove]').forEach(b=>b.addEventListener('click',()=>{cartState.lines=cartState.lines.filter(x=>x.product_id!==b.dataset.posRemove);drawLines();}));
      $$('[data-pos-qty]').forEach(input=>input.addEventListener('change',()=>{try{const line=cartState.lines.find(x=>x.product_id===input.dataset.posQty),pr=[...products,...data.products].find(p=>p.id===line.product_id);line.quantity=C.toBase(pr||line,input.value,line.unit);drawLines();}catch(e){A.toast(A.errorText(e),true);drawLines();}}));
    };
    $$('[data-pos-category]').forEach(b=>b.addEventListener('click',guarded(async()=>{cartState.category=b.dataset.posCategory;$$('[data-pos-category]').forEach(x=>{x.classList.toggle('active',x===b);x.setAttribute('aria-pressed',String(x===b));});await query($('#posSearch').value);}))); 
    async function capture(p){if(!p)return;const available=[C.normalizeUnit(p.unit)];if(available[0]==='KG')available.push('GR');if(available[0]==='GR')available.push('KG');if(p.pack_quantity&&available[0]!=='CAJA')available.push('CAJA');if(p.pack_quantity&&p.pallet_boxes&&available[0]!=='PALLET')available.push('PALLET');
      if(available.length===1&&available[0]==='UN'&&!p.fractional){cartState.lines=C.addCapture(cartState.lines,p,1,'UN',p.price);drawLines();return;}
      A.openModal(`Agregar ${p.name}`,`<div class="retail-form"><div class="document-hero"><div><h3>${E(p.name)}</h3><span>${money(p.price)} / ${E(p.unit)}</span></div></div><div class="form-grid"><label>Cantidad / peso<input name="quantity" id="captureQuantity" type="number" min="0.0001" step="0.0001" value="1" required autofocus></label><label>Unidad<select name="input_unit" id="captureUnit">${available.map(u=>`<option>${E(u)}</option>`).join('')}</select></label></div><div class="pos-total"><span id="captureBase"></span><strong id="captureAmount"></strong></div></div>`,async fd=>{cartState.lines=C.addCapture(cartState.lines,p,fd.get('quantity'),fd.get('input_unit'),p.price);return {toast:'Producto agregado'};},'Agregar');
      const recalc=()=>{try{const amount=C.toBase(p,$('#captureQuantity').value,$('#captureUnit').value);$('#captureBase').textContent=`${qty(amount)} ${C.normalizeUnit(p.unit)}`;$('#captureAmount').textContent=money(Math.round(amount*p.price));}catch{$('#captureAmount').textContent='Revisa la cantidad';}};$('#captureQuantity').addEventListener('input',recalc);$('#captureUnit').addEventListener('change',recalc);recalc();$('#captureQuantity').select();}
    const applyLocalSearch=text=>{products=localSearch(text);drawProducts();return products;};
    const query=async (text,all=false)=>{
      const seq=++searchSequence,q=String(text||'').trim();
      if(!isCurrent())return [];
      if(all&&cartState.category){cartState.category='';$$('[data-pos-category]',root).forEach(b=>{const active=b.dataset.posCategory==='';b.classList.toggle('active',active);b.setAttribute('aria-pressed',String(active));});}
      const local=applyLocalSearch(q);
      const r=await api('pos.catalog',{search:q,warehouse_id:cartState.warehouse,price_list_id:cartState.priceList,category:all?'':cartState.category});
      if(seq!==searchSequence||!isCurrent()||$('#posSearch',root).value.trim()!==q)return products;
      for(const p of r.products||[]){const i=catalogProducts.findIndex(x=>x.id===p.id);if(i<0)catalogProducts.push(p);else catalogProducts[i]=p;}
      const merged=new Map([...local,...(r.products||[])].map(p=>[p.id,p]));
      products=localSearch(q,[...merged.values()]);drawProducts();return products;
    };
    $('#posSearch').addEventListener('input',e=>{
      clearTimeout(timer);searchSequence++;
      const value=e.target.value;applyLocalSearch(value);
      if(value.trim().length>=2)timer=setTimeout(()=>query(value).catch(err=>{if(isCurrent())A.toast(A.errorText(err),true);}),160);
    });
    $('#posSearch').addEventListener('keydown',guarded(async e=>{
      if(e.key==='Escape'){e.preventDefault();searchSequence++;e.target.value='';clearTimeout(timer);applyLocalSearch('');return;}
      if(e.key!=='Enter')return;
      e.preventDefault();clearTimeout(timer);
      const q=e.target.value.trim();if(!q)return;
      const exact=products.filter(p=>[p.sku,p.barcode].some(v=>v&&compactSearch(v)===compactSearch(q)));
      if(exact.length===1){await capture(exact[0]);e.target.value='';applyLocalSearch('');return;}
      await query(q,true);
      if(!isCurrent()||e.target.value.trim()!==q)return;
      if(products.length===1){await capture(products[0]);e.target.value='';applyLocalSearch('');return;}
      A.toast(products.length?`${products.length} coincidencias. Selecciona el producto.`:'No encontré coincidencias. Prueba con parte del nombre, SKU o código.',!products.length);
    }));
    $('#posWarehouse').addEventListener('change',guarded(async e=>{cartState.warehouse=e.target.value;await pos();}));$('#posPriceList').addEventListener('change',guarded(async e=>{cartState.priceList=e.target.value;await pos();}));$('#posCustomer').addEventListener('change',e=>{cartState.customer=e.target.value;cartState.customerRow=data.customers.find(c=>c.id===cartState.customer)||null;});$('#posSeller').addEventListener('change',e=>cartState.seller=e.target.value);
    on('#posNewCustomer',()=>{if(waiting||!A.can('CUSTOMER_MANAGE'))return;A.customerModal({}, {title:'Nuevo cliente para esta venta',saveLabel:'Crear y seleccionar',toast:'Cliente creado y seleccionado',onSaved:row=>{if(A.state.me.companyId===company){cartState.customer=row.id;cartState.customerRow=row;}}});});on('#posClear',()=>{if(waiting)return;cartState.lines=[];drawLines();});on('#posCash',()=>A.navigate('cash'));on('#posOpenCash',A.openCash);on('#posRetry',retryCheckout);on('#posCancelPending',cancelPending);on('#posCharge',()=>charge(session));window.SiasPosCustomers.bind({root,A,customers:data.customers,isCurrent,onSelect:c=>{cartState.customer=c.id;cartState.customerRow=c;}});products=localSearch('');drawProducts();drawLines();
  }
  async function charge(session){
    if(!cartState.lines.length)throw new Error('Agrega productos');if(!cartState.customer)throw new Error('Selecciona el cliente');if(!cartState.warehouse)throw new Error('Selecciona la bodega');
    const total=C.totals(cartState.lines);let credits=[];if(A.can('CREDIT_VIEW')&&A.can('CREDIT_MANAGE'))credits=(await api('credits.list',{customer_id:cartState.customer,available:true})).rows.filter(x=>x.environment===cartState.data.environment);let printCfg={};try{printCfg=(await api('printing.config.get')).formats||{};}catch{}const defaultDte=Number(printCfg.issuance?.POS||39),paperFor=t=>printCfg.tributary?.[String(t)]||printCfg.defaults?.pos||'80MM';
    const chargeCustomer=cartState.customer;
    const recipientPhone=A.can('BILLING_MANAGE')?(await window.SiasDtePdf.recipient({customer_id:chargeCustomer})).phone:'';
    if(chargeCustomer!==cartState.customer)throw new Error('El cliente cambió. Abre el cobro nuevamente.');
    A.openModal('Cobrar venta',`<div class="retail-form"><div class="pos-total"><span>Total de la venta</span><strong>${money(total)}</strong></div>${credits.length?`<div class="form-section"><h4>Crédito disponible del cliente</h4>${credits.map(c=>`<label class="credit-pay-row"><span>Nota ${E(c.dte?.folio||'')}<small>Saldo ${money(c.balance)} · ${E(c.environment)}</small></span><input type="number" data-credit-payment="${E(c.id)}" min="0" max="${Math.min(c.balance,total)}" step="1" value="0" aria-label="Usar saldo de nota ${E(c.dte?.folio||'')}"></label>`).join('')}</div>`:''}<div class="form-section"><div class="toolbar"><h4>Medios de pago</h4>${button('Agregar medio','chargeAdd')}</div><div id="chargePayments"></div></div><label>Efectivo recibido<input id="chargeReceived" type="number" min="0" step="1" value="${total}"></label><div class="settlement-check" id="chargeCheck"></div><div class="settlement-check"><span>Vuelto</span><strong id="chargeChange"></strong></div>${A.can('BILLING_MANAGE')?`<div class="form-section"><h4>Documento tributario</h4><div class="form-grid"><label>Emitir como<select id="chargeDteType"><option value="0">No emitir DTE</option>${[[39,'39 · Boleta electrónica'],[41,'41 · Boleta exenta'],[33,'33 · Factura electrónica'],[34,'34 · Factura exenta']].map(([v,l])=>`<option value="${v}" ${defaultDte===v?'selected':''}>${l}</option>`).join('')}</select></label><label>Imprimir en<select id="chargeDteFormat"><option value="A4">A4</option><option value="80MM">80 mm</option><option value="58MM">57/58 mm</option></select></label><label>Teléfono<input id="chargeRecipientPhone" type="tel" maxlength="80" autocomplete="tel" value="${E(recipientPhone)}" placeholder="+56 9 1234 5678"><small>Se enviará con el documento tributario.</small></label></div><div class="source-strip"><span>Cliente: <strong>${E(cartState.customerRow?.legal_name||'')}</strong></span></div><div class="section-note">Ya viene parametrizado. Al confirmar el cobro, SiasCloud emitirá e imprimirá directamente sin abrir modales intermedios.</div></div>`:''}</div>`,async()=>{
      const payments=$$('.payment-row').map(row=>({method:$('select',row).value,amount:Number($('input',row).value),request_key:uid()})).filter(x=>x.amount>0);
      const used=$$('[data-credit-payment]').map(input=>({credit_id:input.dataset.creditPayment,amount:Number(input.value),request_key:uid()})).filter(x=>x.amount>0);C.settlement(total,payments,used);
      const received=Number($('#chargeReceived').value),cash=payments.filter(x=>x.method==='CASH').reduce((s,x)=>s+x.amount,0);if(cash&&(!Number.isSafeInteger(received)||received<cash))throw new Error('El efectivo recibido no cubre el pago');
      const p={request_key:uid(),cash_session_id:session.id,customer_id:cartState.customer,warehouse_id:cartState.warehouse,price_list_id:cartState.priceList||null,seller_id:cartState.seller||null,items:cartState.lines.map(x=>({product_id:x.product_id,quantity:x.quantity,input_unit:x.unit,unit_price:x.unit_price})),payments,credits:used,cash_received:received};
      const dteType=A.can('BILLING_MANAGE')?Number($('#chargeDteType')?.value||0):0,printFormat=A.can('BILLING_MANAGE')?($('#chargeDteFormat')?.value||paperFor(dteType)):null;const dtePhone=$('#chargeRecipientPhone')?.value.trim();sessionStorage.setItem(pendingKey(),JSON.stringify(p));try{const r=await api('pos.checkout',p);clearPending();return {toast:'Venta y pagos registrados',afterSave:()=>completeCheckout(r,{dteType,printFormat,recipientPhone:dtePhone,printReceipt:!dteType})};}catch(e){return {toast:'Cobro pendiente de verificar',afterSave:()=>{A.toast(A.errorText(e),true);pos();}};}
    },'Confirmar cobro');
    if(A.can('BILLING_MANAGE')){const syncDtePaper=()=>{const t=Number($('#chargeDteType')?.value||0),sel=$('#chargeDteFormat');if(sel){sel.disabled=!t;if(t)sel.value=paperFor(t);}};$('#chargeDteType')?.addEventListener('change',syncDtePaper);syncDtePaper();}
    const recalc=()=>{const paid=$$('.payment-row').reduce((s,row)=>s+Number($('input',row).value||0),0)+$$('[data-credit-payment]').reduce((s,input)=>s+Number(input.value||0),0),cash=$$('.payment-row').filter(row=>$('select',row).value==='CASH').reduce((s,row)=>s+Number($('input',row).value||0),0);$('#chargeCheck').classList.toggle('invalid',paid!==total);$('#chargeCheck').innerHTML=`<span>${paid===total?'Pago completo':'Pendiente '+money(total-paid)}</span><strong>${money(paid)}</strong>`;$('#chargeChange').textContent=money(Math.max(0,Number($('#chargeReceived').value||0)-cash));};
    const add=(method='CASH',amount=0)=>{const row=document.createElement('div');row.className='payment-row';row.innerHTML=`<select aria-label="Medio de pago">${['CASH','CARD','TRANSFER'].map(m=>`<option value="${m}" ${m===method?'selected':''}>${methods[m]}</option>`).join('')}</select><input type="number" min="0" step="1" value="${amount}" aria-label="Monto del pago"><button type="button" class="icon-btn" aria-label="Quitar medio de pago">×</button>`;$('#chargePayments').appendChild(row);row.addEventListener('input',recalc);row.addEventListener('change',recalc);$('button',row).addEventListener('click',()=>{row.remove();recalc();});};on('#chargeAdd',()=>{add();recalc();});$$('[data-credit-payment]').forEach(input=>input.addEventListener('input',recalc));$('#chargeReceived').addEventListener('input',recalc);add('CASH',total);recalc();
  }
  window.SiasPos={init:value=>{A=value;document.addEventListener('keydown',e=>{if(A.state.route!=='pos'||$('#modal')?.open)return;if(e.key==='F2'){e.preventDefault();$('#posSearch')?.focus();}if(e.key==='F4'){e.preventDefault();$('#posCharge')?.click();}});},render:pos};
})();
