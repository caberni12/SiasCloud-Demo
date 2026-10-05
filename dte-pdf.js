/* Impresión DTE. A4 usa el PDF oficial; térmico usa /wsds/getticket del mismo DTE de Facturacion.cl. */
(()=>{
 'use strict';
 let A;const activeUrls=new Set();
 const safe=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 function view(){
  let popup=null;try{popup=window.open('','_blank');if(popup)popup.opener=null;}catch{}
  let host;
  if(popup){popup.document.write('<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>DTE · SiasCloud</title><body style="margin:0;background:#f3f7fd;font:16px system-ui;color:#14233c"><main style="max-width:640px;margin:12vh auto;padding:28px;background:white;border-radius:20px"><h1 style="font-size:28px">Documento tributario</h1><p data-pdf-status>Preparando documento…</p><button data-pdf-retry hidden style="font:inherit;padding:12px 20px;border:0;border-radius:10px;background:#2563eb;color:white">Consultar nuevamente</button></main></body></html>');popup.document.close();host=popup.document;}
  else{
   let dialog=document.querySelector('#dtePdfViewer');if(!dialog){dialog=document.createElement('dialog');dialog.id='dtePdfViewer';dialog.className='dte-pdf-viewer';dialog.innerHTML='<div class="dte-pdf-head"><strong>Documento tributario</strong><button type="button" class="btn secondary" data-pdf-close>Cerrar</button></div><p data-pdf-status></p><button type="button" class="btn primary" data-pdf-retry hidden>Consultar nuevamente</button><iframe title="Documento tributario" hidden></iframe><a class="btn secondary" data-pdf-download hidden download="Documento_tributario.pdf">Descargar PDF</a>';document.body.appendChild(dialog);dialog.querySelector('[data-pdf-close]').onclick=()=>dialog.close();}
   host=dialog;dialog.querySelector('iframe').hidden=true;dialog.querySelector('[data-pdf-download]').hidden=true;dialog.querySelector('[data-pdf-retry]').hidden=true;const refresh=dialog.querySelector('[data-pdf-refresh]');if(refresh)refresh.hidden=true;dialog.querySelector('[data-pdf-status]').textContent='Preparando documento…';if(!dialog.open)dialog.showModal();
  }
  return {popup,host,company:A.state.me?.companyId,token:A.state.token};
 }
 function message(v,text){if(v.popup?.closed)return;v.host.querySelector('[data-pdf-status]')&&(v.host.querySelector('[data-pdf-status]').textContent=text);}
 function release(url){if(activeUrls.delete(url))URL.revokeObjectURL(url);}
 function assertContext(v){if(v.company!==A.state.me?.companyId||v.token!==A.state.token)throw new Error('La sesión o la empresa activa cambió. Abre el documento nuevamente.');}
 async function preferred(dte={}){try{const r=await A.erpCall('printing.config.get'),f=r.formats||{},type=String(dte.document_type||'');return f.tributary?.[type]||(A.state.route==='pos'?(f.defaults?.pos||'80MM'):(f.defaults?.tributary||'A4'));}catch{try{const r=await A.erpCall('billing.config.get'),c=r.config||{};return A.state.route==='pos'?(c.pos_dte_print_format||'80MM'):(c.dte_print_format||'A4');}catch{return 'A4';}}}
 function pdfCaption(dte){return `DTE A4 oficial · folio ${dte.folio||'confirmado'} · Teléfono de emisión: ${dte.recipient_phone||'Sin registro'}`;}
 async function refreshA4(dte,v,button){
  if(button.disabled)return;button.disabled=true;message(v,'Actualizando el PDF oficial del mismo folio…');
  try{await showA4(dte,v,true);}catch(error){message(v,A.errorText(error));}finally{button.disabled=false;}
 }
 async function showA4(dte,v,refresh=false){
  for(let attempt=0;attempt<5;attempt++){
   if(v.popup?.closed)return false;
   try{assertContext(v);message(v,`DTE emitido · folio ${dte.folio||'confirmado'}. Preparando A4 oficial…`);const r=await A.erpCall('billing.pdf',{id:dte.id,...(refresh?{refresh:true}:{})});assertContext(v);Object.assign(dte,r.document||{});
    const base64=String(r.pdf_base64||'').replace(/^data:application\/pdf;base64,/i,'').replace(/\s/g,'');if(base64.length>41943040)throw new Error('El PDF supera el tamaño admitido.');const raw=atob(base64);if(!raw.startsWith('%PDF-'))throw new Error('El proveedor devolvió un PDF inválido.');
    const bytes=Uint8Array.from(raw,c=>c.charCodeAt(0)),url=URL.createObjectURL(new Blob([bytes],{type:'application/pdf'}));activeUrls.add(url);
    if(v.popup&&!v.popup.closed){
     const doc=v.popup.document;doc.title='DTE · folio '+(dte.folio||'confirmado');doc.body.style.cssText='margin:0;font:15px system-ui;display:flex;flex-direction:column;height:100vh;background:#fff;color:#14233c';
     const header=doc.createElement('header'),title=doc.createElement('strong'),download=doc.createElement('a'),reload=doc.createElement('button'),frame=doc.createElement('iframe');
     header.style.cssText='display:flex;flex-wrap:wrap;align-items:center;gap:12px;padding:16px 22px;border-bottom:1px solid #dde5f0';title.style.cssText='flex:1;min-width:200px';title.setAttribute('data-pdf-status','');title.textContent=pdfCaption(dte);
     download.textContent='Descargar PDF';download.href=url;download.download='DTE_'+(dte.folio||'emitido')+'.pdf';
     reload.type='button';reload.textContent='Actualizar PDF';reload.style.cssText='padding:9px 12px;border:1px solid #cbd5e1;border-radius:8px;background:white;color:#14233c;font:inherit;cursor:pointer';reload.onclick=()=>refreshA4(dte,v,reload);
     frame.title='PDF del documento tributario';frame.style.cssText='width:100%;flex:1;border:0';frame.src=url;header.append(title,reload,download);doc.body.replaceChildren(header,frame);
    }else if(!v.popup){
     const frame=v.host.querySelector('iframe'),link=v.host.querySelector('[data-pdf-download]');frame.src=url;frame.removeAttribute('srcdoc');frame.hidden=false;link.href=url;link.hidden=false;message(v,pdfCaption(dte));
     let reload=v.host.querySelector('[data-pdf-refresh]');if(!reload){reload=document.createElement('button');reload.type='button';reload.className='btn secondary';reload.setAttribute('data-pdf-refresh','');reload.textContent='Actualizar PDF';v.host.appendChild(reload);}reload.hidden=false;reload.onclick=()=>refreshA4(dte,v,reload);
     v.host.addEventListener('close',()=>release(url),{once:true});
    }else{release(url);return false;}
    if(v.pdfUrl)release(v.pdfUrl);v.pdfUrl=url;setTimeout(()=>release(url),900000);return true;
   }catch(error){if(attempt<4&&/PDF_NO_DISPONIBLE|PDF.*(?:pendiente|no.*disponible)/i.test(error.message)){message(v,'El documento ya fue emitido. Esperando el PDF oficial de Facturacion.cl…');await new Promise(r=>setTimeout(r,500*(attempt+1)));continue;}throw error;}
  }
 }
 function thermalHtml(ticket,format){
  const phone=String(ticket.recipient_phone||'').trim(),digits=phone.replace(/\D/g,''),printed=String(ticket.head_text||'')+' '+String(ticket.foot_text||'');
  const extraPhone=phone&&(!digits||!printed.replace(/\D/g,'').includes(digits))?`<p class="provider recipient-phone">Teléfono: ${safe(phone)}</p>`:'';
  const is58=format==='58MM',paper=is58?'58mm':'80mm',content=is58?'52mm':'72mm',font=is58?'8.4px':'10.5px',company=(A.state.me?.companies||[]).find(c=>c.id===A.state.me?.companyId)||{},logo=(company.show_logo_documents!==false&&company.logo_url)?company.logo_url:'';return `<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>DTE ${safe(ticket.folio||'')} · ${paper}</title><style>@page{size:${paper} auto;margin:0}*{box-sizing:border-box}html,body{margin:0;padding:0;background:#fff;color:#000}body{font-family:"Courier New",monospace}.toolbar{position:sticky;top:0;display:flex;gap:8px;justify-content:center;padding:10px;background:#eef3f9;border-bottom:1px solid #ccd6e2;font:13px system-ui;z-index:2}.toolbar button{border:0;border-radius:8px;padding:9px 14px;background:#1769d2;color:#fff;font-weight:700;cursor:pointer}.ticket{width:${content};margin:0 auto;padding:${is58?'2.5mm 1.5mm 5mm':'3mm 2mm 6mm'};overflow:hidden}.company-logo{display:block;max-width:${is58?'34mm':'48mm'};max-height:${is58?'15mm':'20mm'};object-fit:contain;margin:0 auto 3mm}.provider{margin:0;white-space:pre-wrap;overflow-wrap:anywhere;word-break:break-word;font-size:${font};line-height:1.25}.ted{display:flex;justify-content:center;width:100%;margin:${is58?'3mm':'4mm'} 0}.ted svg{display:block;width:100%;max-width:100%;height:auto}.meta{text-align:center;font:700 ${is58?'7.5px':'9px'} Arial,sans-serif;margin:2mm 0}.warning{font:8px Arial,sans-serif;text-align:center;margin-top:2mm}@media print{.toolbar{display:none}.ticket{margin:0 auto}}</style></head><body><div class="toolbar"><button onclick="window.print()">Imprimir ${paper}</button></div><main class="ticket">${logo?`<img class="company-logo" src="${safe(logo)}" alt="Logotipo de ${safe(company.trade_name||company.legal_name||'empresa')}">`:''}<pre class="provider">${safe(ticket.head_text||'')}</pre>${extraPhone}<div class="ted">${ticket.ted_svg||''}</div><pre class="provider">${safe(ticket.foot_text||'')}</pre><div class="meta">DTE ${safe(ticket.document_type)} · Folio ${safe(ticket.folio)} · ${safe(ticket.environment||'')}</div><div class="warning">Representación térmica del mismo DTE emitido por Facturacion.cl. No genera un nuevo folio.</div></main></body></html>`;}
 async function showThermal(dte,v,format){assertContext(v);message(v,`DTE emitido · folio ${dte.folio||'confirmado'}. Consultando ticket térmico oficial…`);const ticket=await A.erpCall('billing.ticket',{id:dte.id,format});assertContext(v);const html=thermalHtml(ticket,format);
  if(v.popup&&!v.popup.closed){v.popup.document.open();v.popup.document.write(html);v.popup.document.close();}
  else if(!v.popup){const frame=v.host.querySelector('iframe');frame.removeAttribute('src');frame.srcdoc=html;frame.hidden=false;v.host.querySelector('[data-pdf-download]').hidden=true;message(v,`Ticket ${format==='58MM'?'57/58 mm':'80 mm'} · mismo DTE folio ${ticket.folio}`);}return true;}
 async function show(dte,v=view(),format){if(dte?.status&&dte.status!=='EMITIDO'){message(v,'La emisión todavía no está confirmada. Revisa su estado antes de imprimir.');return false;}if(!dte?.id){message(v,'No se encontró el DTE emitido.');return false;}const selected=(format||await preferred(dte)).toUpperCase();try{return selected==='A4'?await showA4(dte,v):await showThermal(dte,v,selected==='58MM'?'58MM':'80MM');}catch(error){message(v,'El documento ya fue emitido. No se pudo preparar esta impresión: '+A.errorText(error)+'. No se volverá a emitir.');const retry=v.host.querySelector('[data-pdf-retry]');if(retry){retry.hidden=false;retry.onclick=async()=>{A.setBusy?.(retry,true,'Consultando…');try{await show(dte,v,selected);}finally{A.setBusy?.(retry,false);}};}return false;}}
 async function recipient(payload){
  try{const r=await A.erpCall('billing.recipient.get',payload);if(r.phone_field_ready!==true)throw new Error('Actualización de documentos tributarios pendiente. Actualiza el backend de SiasCloud.');return r;}
  catch(error){if(/Acción ERP no reconocida|ACCION_NO_EXISTE/.test(error.message||''))throw new Error('Actualización de documentos tributarios pendiente. Actualiza el backend de SiasCloud.');throw error;}
 }
 async function emit(payload,format){const v=view();try{
  const preview=await recipient({document_id:payload.document_id,...(Object.prototype.hasOwnProperty.call(payload,'recipient_phone')?{recipient_phone:payload.recipient_phone}:{})});assertContext(v);
  const result=await A.erpCall('billing.facturacioncl.issue',{...payload,recipient_phone:preview.phone});const fmt=(format||await preferred(result.document)).toUpperCase();result.pdf_opened=await show(result.document,v,fmt);return result;}catch(error){message(v,'La emisión no está confirmada: '+A.errorText(error)+'. Revisa el historial antes de volver a emitir.');throw error;}}
 window.SiasDtePdf={init:api=>{A=api;},emit,recipient,open:(id,format)=>show({id,status:'EMITIDO'},view(),format)};
})();
