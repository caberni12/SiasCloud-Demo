/* Importadores de maestros XLSX. Cada pantalla conserva su propio estado. */
(()=>{
  'use strict';
  let A,activeView;
  const $=s=>document.querySelector(s);
  const E=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const C=window.SiasImportCore;
  const modes={Productos:'Maestro de productos',Clientes:'Maestro de clientes',Precios:'Listas de precios',General:'Carga inicial general'};
  let selectedMode='General';
  const current=v=>activeView===v&&v.root.isConnected&&A.state.route==='importer'&&A.state.me?.companyId===v.company;
  const find=(v,s)=>v.root.querySelector(s),all=(v,s)=>[...v.root.querySelectorAll(s)];
  function refreshButtons(v){
    if(!current(v))return;
    const validate=find(v,'#importValidate'),commit=find(v,'#importCommit');
    if(validate)validate.disabled=v.bulkRunning||validate.dataset.busy==='1'||!v.normalized||v.normalized.errors.length>0||v.completed||!A.can('IMPORT_MANAGE');
    if(commit)commit.disabled=v.bulkRunning||commit.dataset.busy==='1'||!v.validated;
    all(v,'#importFile,#importStrategy,#importList,[data-import-mode],[data-import-sheet],[data-import-field],[data-import-resume],[data-import-cancel]').forEach(el=>{el.disabled=!!v.bulkRunning||el.id==='importFile'&&!A.can('IMPORT_MANAGE');});
  }
  const guarded=(v,fn)=>async e=>{
    if(!current(v))return;
    const b=e?.currentTarget;
    try{if(b?.tagName==='BUTTON')A.setBusy(b,true);await fn(e);}
    catch(err){if(current(v))A.toast(A.errorText(err),true);}
    finally{if(b?.tagName==='BUTTON'&&b.isConnected)A.setBusy(b,false);refreshButtons(v);}
  };
  function invalidate(v){v.revision++;v.validated=null;v.completed=false;const result=find(v,'#importResult');if(result)result.innerHTML='';refreshButtons(v);}
  function settings(v){
    const sheets={},columns={};
    all(v,'[data-import-sheet]').forEach(s=>sheets[s.dataset.importSheet]=s.value);
    all(v,'[data-import-field]').forEach(s=>(columns[s.dataset.sheet]||=Object.create(null))[s.dataset.index]=s.value);
    return {mode:v.mode,sheets,columns,defaultList:find(v,'#importList')?.value};
  }
  function errors(rows){return `<div class="import-alert error"><strong>${rows.length} errores de validación</strong><p>Corrige el archivo o la asignación de columnas y vuelve a revisar.</p><div class="table-wrap"><table><thead><tr><th>Hoja</th><th>Fila</th><th>Campo</th><th>Detalle</th></tr></thead><tbody>${rows.slice(0,100).map(r=>`<tr><td>${E(r.sheet)}</td><td>${E(r.row)}</td><td>${E(r.column)}</td><td>${E(r.message)}</td></tr>`).join('')}</tbody></table></div><button type="button" class="btn secondary small" id="importErrors">Descargar errores CSV</button></div>`;}
  function exportErrors(rows){
    const q=v=>'"'+(/^[=+@\-\t\r]/.test(String(v??''))?"'":'')+String(v??'').replaceAll('"','""')+'"';
    const blob=new Blob(['\uFEFF'+[['Hoja','Fila','Campo','Error'],...rows.map(r=>[r.sheet,r.row,r.column,r.message])].map(r=>r.map(q).join(';')).join('\r\n')],{type:'text/csv;charset=utf-8'}),url=URL.createObjectURL(blob),a=document.createElement('a');
    a.href=url;a.download='Errores_importacion.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
  }
  function showErrors(v,rows){find(v,'#importPreview').innerHTML=errors(rows);find(v,'#importErrors').onclick=()=>exportErrors(rows);}
  function summary(s){return `<div class="table-wrap"><table><thead><tr><th>Maestro</th><th>Crear</th><th>Actualizar</th><th>Omitir</th></tr></thead><tbody>${Object.entries(s||{}).map(([name,c])=>`<tr><td>${E(name)}</td><td>${c.created||0}</td><td>${c.updated||0}</td><td>${c.skipped||0}</td></tr>`).join('')}</tbody></table></div>`;}
  async function localPreview(v){
    if(!current(v)||!v.book)return;
    invalidate(v);const revision=v.revision;v.normalized=null;refreshButtons(v);
    const normalized=await window.SiasBulkImport.normalize(v.book,v.meta.schema,settings(v));
    if(!current(v)||revision!==v.revision)return;v.normalized=normalized;refreshButtons(v);
    if(v.normalized.errors.length){showErrors(v,v.normalized.errors);return;}
    const counts={};v.normalized.rows.forEach(r=>counts[r.sheet]=(counts[r.sheet]||0)+1);
    find(v,'#importPreview').innerHTML=`<div class="import-alert"><strong>${v.normalized.rows.length} filas listas para validar en el servidor</strong><p>${Object.entries(counts).map(([k,n])=>E(k)+' · '+n).join(' &nbsp; / &nbsp; ')}</p></div><details open><summary>Vista previa · primeras 30 filas</summary><div class="table-wrap"><table><thead><tr><th>Hoja</th><th>Fila</th><th>Datos</th></tr></thead><tbody>${v.normalized.rows.slice(0,30).map(r=>`<tr><td>${E(r.source)}</td><td>${r.row}</td><td>${Object.entries(r.values).slice(0,6).map(([k,value])=>`<span class="import-value"><b>${E(v.meta.schema.tables.find(t=>t.key===r.sheet).fields[k].label)}:</b> ${E(Array.isArray(value)?value.join(', '):value)}</span>`).join('')}</td></tr>`).join('')}</tbody></table></div></details>`;
  }
  async function mappings(v){
    const old=settings(v),schema=v.meta.schema;
    const allowed=v.mode==='General'?schema.tables:v.mode==='Precios'?schema.tables.filter(t=>['ListasPrecios','Precios'].includes(t.key)):schema.tables.filter(t=>t.key===v.mode||v.mode==='Productos'&&t.key==='Atributos');
    const usable=v.book.sheets.filter(s=>!['instrucciones','ayuda','leeme'].includes(C.norm(s.name))&&(s.rows.length>1||!C.sheetKey(s.name,schema)));
    find(v,'#importMapping').innerHTML=usable.map(sh=>{
      const key=Object.hasOwn(old.sheets,sh.name)?old.sheets[sh.name]:C.sheetKey(sh.name,schema)||(usable.length===1&&['Productos','Clientes'].includes(v.mode)?v.mode:'');
      const t=allowed.find(t=>t.key===key),cols=t?C.columns(sh.rows[0]?.cells||[],t):{};
      return `<details class="import-sheet" ${!t||Object.keys(cols).length<(sh.rows[0]?.cells||[]).filter(value=>value!==null&&value!==undefined&&value!=='').length?'open':''}><summary>${E(sh.name)} <small>${Math.max(0,sh.rows.length-1)} filas</small></summary><label>Destino<select data-import-sheet="${E(sh.name)}"><option value="">Asignar tabla…</option>${allowed.map(t=>`<option value="${t.key}" ${t.key===key?'selected':''}>${E(t.key)}</option>`).join('')}<option value="IGNORE" ${key==='IGNORE'?'selected':''}>Ignorar hoja</option></select></label>${t?`<div class="import-column-grid">${(sh.rows[0]?.cells||[]).map((h,i)=>`<label><span>${E(h||'Columna '+(i+1))}</span><select data-import-field data-sheet="${E(sh.name)}" data-index="${i}"><option value="">Ignorar columna</option>${Object.entries(t.fields).map(([k,f])=>`<option value="${k}" ${k===(old.columns[sh.name]&&Object.hasOwn(old.columns[sh.name],i)?old.columns[sh.name][i]:cols[i])?'selected':''}>${E(f.label)}${f.required?' *':''}</option>`).join('')}</select></label>`).join('')}</div>`:''}</details>`;
    }).join('');
    all(v,'[data-import-sheet]').forEach(s=>s.addEventListener('change',()=>{mappings(v);localPreview(v);}));
    all(v,'[data-import-field]').forEach(s=>s.addEventListener('change',()=>localPreview(v)));await localPreview(v);
  }
  async function history(v){
    const sequence=++v.historySequence;
    let r;
    try{r=await A.erpCall('imports.history');}catch(err){if(!current(v)||sequence!==v.historySequence)return;throw err;}
    if(!current(v)||sequence!==v.historySequence)return;
    const rows=r.rows||[];
    find(v,'#importHistory').innerHTML=rows.length?`<div class="table-wrap"><table><thead><tr><th>Archivo</th><th>Tipo</th><th>Estado</th><th>Fecha</th><th>Filas</th></tr></thead><tbody>${rows.map(b=>`<tr><td>${E(b.filename)}</td><td>${E(modes[b.mode]||b.mode)}</td><td><span class="badge ${b.status==='COMPLETED'?'ok':''}">${b.status==='COMPLETED'?'Completada':'Vista previa'}</span></td><td>${E(A.fmtDate(b.completed_at||b.created_at))}</td><td>${E(b.result?.rows||0)}</td></tr>`).join('')}</tbody></table></div>`:'<div class="empty">Todavía no hay cargas en esta empresa.</div>';
    if(v.meta.schema.maxRows>5000&&A.can('IMPORT_MANAGE')){
      const bulk=await A.erpCall('imports.bulk.list',{company_id:v.company});if(!current(v)||sequence!==v.historySequence)return;
      const labels={UPLOADING:'Recibiendo archivo',READY:'Lista para confirmar',RUNNING:'Parcial · continuar',FAILED:'Parcial · revisar error',COMPLETED:'Completada',CANCELLED:'Cancelada'};
      find(v,'#importHistory').insertAdjacentHTML('beforeend',`<h4>Cargas por lotes</h4><div class="table-wrap"><table><thead><tr><th>Archivo</th><th>Estado</th><th>Recibidas</th><th>Aplicadas</th><th>Acciones</th></tr></thead><tbody>${(bulk.jobs||[]).map(j=>`<tr><td>${E(j.filename)}</td><td>${E(labels[j.status]||j.status)}</td><td>${j.uploaded_rows} / ${j.total_rows}</td><td>${j.processed_rows} / ${j.total_rows}</td><td>${!['COMPLETED','CANCELLED'].includes(j.status)?`<button type="button" class="btn secondary small" data-import-resume="${E(j.id)}">Continuar</button> <button type="button" class="btn secondary small" data-import-cancel="${E(j.id)}">Cancelar carga</button>`:''}</td></tr>`).join('')||'<tr><td colspan="5">Todavía no hay cargas por lotes.</td></tr>'}</tbody></table></div>`);
      all(v,'[data-import-resume]').forEach(b=>b.onclick=guarded(v,async()=>{const j=(bulk.jobs||[]).find(j=>j.id===b.dataset.importResume);if(j.status==='UPLOADING'){v.uploadJob=j;find(v,'#importFilename').textContent='Para continuar '+j.filename+', selecciona de nuevo el mismo archivo.';find(v,'#importFile').focus();}else{v.validated={bulk:true,job:j};v.completed=false;bulkProgress(v,j,'ready');refreshButtons(v);find(v,'#importCommit').scrollIntoView({block:'center'});}}));
      all(v,'[data-import-cancel]').forEach(b=>b.onclick=guarded(v,async()=>{const r=await A.erpCall('imports.bulk.cancel',{company_id:v.company,job_id:b.dataset.importCancel});if(r.validation?.ok===false)throw new Error(r.validation.errors?.[0]?.message);if(v.validated?.job?.id===b.dataset.importCancel)v.validated=null;if(v.uploadJob?.id===b.dataset.importCancel)v.uploadJob=null;A.toast('Carga cancelada. Las filas ya aplicadas se conservan.');await history(v);}));
    }
  }
  function bulkProgress(v,job,phase){
    if(!current(v)||!job)return;const done=phase==='upload'?job.uploaded_rows:job.processed_rows;
    const label=phase==='upload'?'Recibiendo archivo':phase==='validate'?'Validando referencias':phase==='ready'?'Archivo listo para confirmar':phase==='paused'?'Carga pausada':'Aplicando datos';
    const canPause=v.bulkRunning&&['upload','validate','apply'].includes(phase);
    find(v,'#importResult').innerHTML=`<div class="import-alert ${job.status==='COMPLETED'?'success':''}"><strong>${job.status==='COMPLETED'?'Importación completada':E(label)}</strong><p>${job.uploaded_rows.toLocaleString('es-CL')} filas recibidas · ${job.processed_rows.toLocaleString('es-CL')} de ${job.total_rows.toLocaleString('es-CL')} aplicadas.</p><progress value="${done}" max="${job.total_rows}" aria-label="Progreso de importación"></progress><p>La carga se aplica por lotes. Si se interrumpe, continúa desde el historial. Las filas aplicadas se conservan.</p>${canPause?'<button type="button" class="btn secondary small" id="importPause">Pausar carga</button>':''}${job.processed_rows?summary(job.summary):''}</div>`;
    const pause=find(v,'#importPause');if(pause)pause.onclick=()=>{A.setBusy(pause,true,'Pausando…');v.bulkClient?.pause();};
  }
  function bulkClient(v){return window.SiasBulkImport.create({company:v.company,call:A.erpCall,current:()=>current(v),onProgress:(j,p)=>bulkProgress(v,j,p)});}
  function bind(v){
    all(v,'[data-import-mode]').forEach(b=>b.onclick=()=>{selectedMode=b.dataset.importMode;render();});
    find(v,'#importStrategy').onchange=()=>invalidate(v);find(v,'#importList').onchange=()=>localPreview(v);
    find(v,'#importFile').onchange=guarded(v,async e=>{
      const f=e.target.files[0];if(!f)return;
      if(v.bulkRunning)return;
      const seq=++v.fileSequence;v.book=null;v.normalized=null;v.filename='';invalidate(v);
      find(v,'#importPreview').innerHTML='';find(v,'#importMapping').innerHTML='';find(v,'#importFilename').textContent='Leyendo '+f.name+'…';
      let parsed;
      try{const pair=await window.SiasSplash.run('Leyendo '+f.name+'…',async update=>Promise.all([window.SiasXlsxReader.read(f,{onProgress:p=>update('Leyendo '+p.sheet+' · '+p.rows.toLocaleString('es-CL')+' filas…')}),crypto.subtle.digest('SHA-256',await f.arrayBuffer())]),{priority:10});parsed=pair[0];v.fileHash=Array.from(new Uint8Array(pair[1]),x=>x.toString(16).padStart(2,'0')).join('');}catch(err){if(current(v)&&seq===v.fileSequence){find(v,'#importFilename').textContent=f.name+' · No se pudo leer el archivo';throw err;}return;}
      if(!current(v)||seq!==v.fileSequence)return;
      v.book=parsed;v.filename=f.name;find(v,'#importFilename').textContent=f.name+' · '+Math.ceil(f.size/1024)+' KB · '+parsed.cellCount.toLocaleString('es-CL')+' celdas con contenido';await window.SiasSplash.run('Revisando filas y columnas…',()=>mappings(v),{priority:10});
    });
    find(v,'#importValidate').onclick=guarded(v,async()=>{
      await localPreview(v);if(!v.normalized||v.normalized.errors.length)return;
      const revision=v.revision;
      if(v.normalized.rows.length>5000){
        const client=bulkClient(v);v.bulkClient=client;v.bulkRunning=true;refreshButtons(v);
        try{await window.SiasSplash.run('Preparando carga por lotes…',async update=>{v.splashUpdate=update;const job=await client.prepare(v.normalized.rows,{filename:v.filename,file_hash:v.fileHash,mode:v.mode,strategy:find(v,'#importStrategy').value},v.uploadJob);if(!current(v)||revision!==v.revision)return;v.validated={bulk:true,job};v.uploadJob=null;bulkProgress(v,job,'ready');},{priority:10,onPause:()=>client.pause()});}
        catch(err){if(current(v)){if(err.rows?.length)showErrors(v,err.rows);const job=err.job||client.job;if(job){v.uploadJob=job;bulkProgress(v,job,'paused');}A.toast(A.errorText(err),!err.paused);}}
        finally{v.bulkRunning=false;v.bulkClient=null;v.splashUpdate=null;if(current(v))await history(v);}return;
      }
      const r=await A.erpCall('imports.preview',{company_id:v.company,filename:v.filename,mode:v.mode,strategy:find(v,'#importStrategy').value,rows:v.normalized.rows});
      if(!current(v)||revision!==v.revision)return;
      const valid=r.validation||r;if(!valid.ok){showErrors(v,valid.errors||[]);return;}
      v.validated=valid;find(v,'#importResult').innerHTML=`<div class="import-alert success"><strong>Archivo validado · revisa los cambios antes de confirmar</strong><p>Esta revisión vence en 30 minutos. Si los datos cambian, será necesario revisar otra vez.</p>${summary(valid.summary)}</div>`;
    });
    find(v,'#importCommit').onclick=guarded(v,async()=>{
      if(!v.validated)return;
      if(v.validated.bulk){
        const client=bulkClient(v);v.bulkClient=client;v.bulkRunning=true;refreshButtons(v);
        try{await window.SiasSplash.run('Importando datos…',async update=>{v.splashUpdate=update;const result=await client.resume(v.validated.job);if(!current(v))return;v.validated=result.job.status==='COMPLETED'?null:{bulk:true,job:result.job};v.completed=result.job.status==='COMPLETED';bulkProgress(v,result.job,result.paused?'paused':'apply');A.toast(v.completed?'Importación completada':'Carga pausada; puedes continuar desde el historial.');},{priority:10,onPause:()=>client.pause()});}
        catch(err){if(current(v)){const job=err.job||client.job;if(job){v.validated={bulk:true,job};bulkProgress(v,job,'paused');}if(err.rows?.length)showErrors(v,err.rows);A.toast(A.errorText(err),true);}}
        finally{v.bulkRunning=false;v.bulkClient=null;v.splashUpdate=null;if(current(v))await history(v);}return;
      }
      const revision=v.revision,id=v.validated.batch_id;
      const r=await A.erpCall('imports.commit',{company_id:v.company,batch_id:id});
      if(!current(v)||revision!==v.revision)return;
      const result=r.validation||r;if(!result.ok){invalidate(v);showErrors(v,result.errors||[]);return;}
      v.validated=null;v.completed=true;
      find(v,'#importResult').innerHTML=`<div class="import-alert success"><strong>Importación completada · ${result.rows} filas procesadas</strong>${summary(result.summary)}</div>`;
      find(v,'#importFile').value='';refreshButtons(v);A.toast('Importación completada');await history(v);
    });
  }
  async function render(){
    const root=document.createElement('div');root.className='importer-view';
    const v={root,company:A.state.me.companyId,mode:selectedMode,meta:null,book:null,filename:'',normalized:null,validated:null,revision:0,fileSequence:0,historySequence:0,completed:false};
    activeView=v;$('#content').replaceChildren(root);root.innerHTML='<div class="center"><span class="spinner"></span><p>Cargando importadores…</p></div>';
    try{
      const meta=await A.erpCall('imports.meta');if(!current(v))return;v.meta=meta;
      root.innerHTML=`<div class="retail-head"><div><h2>Importadores XLSX</h2><p>Carga tus maestros y la información inicial de la empresa activa.</p></div><span class="badge">Excel · 50 MB · 100.000 filas</span></div><div class="import-modes">${Object.entries(modes).map(([k,label])=>`<button type="button" class="import-mode ${k===v.mode?'active':''}" data-import-mode="${k}" aria-pressed="${k===v.mode}"><span>${k==='General'?'▦':'▤'}</span><strong>${E(label)}</strong></button>`).join('')}</div><div class="card import-card"><div class="import-steps"><span class="active">1. Elegir archivo</span><span>2. Revisar y validar</span><span>3. Confirmar carga</span></div><div class="import-config"><label>Operación<select id="importStrategy"><option value="UPSERT">Crear y actualizar por clave</option><option value="CREATE">Solo crear · omitir existentes</option></select></label><label id="importListLabel" ${v.mode!=='Precios'?'hidden':''}>Lista de destino (si no viene en el archivo)<select id="importList"><option value="">La indicada en la hoja</option>${(meta.lists||[]).map(l=>`<option value="${E(l.import_code||l.name)}">${E(l.name)}</option>`).join('')}</select></label><a class="btn secondary" id="importTemplate" href="plantillas/Plantilla_${v.mode==='Precios'?'ListasPrecios':v.mode}.xlsx" download>Descargar plantilla</a></div><label class="import-upload"><span class="import-upload-icon">↑</span><strong>Selecciona tu archivo Excel</strong><span>Encabezados en la primera fila · archivo .xlsx</span><input type="file" id="importFile" accept=".xlsx" ${!A.can('IMPORT_MANAGE')?'disabled':''}></label><p class="master-help" id="importFilename"></p><p class="master-help">Hasta 100.000 filas y 2.000.000 de celdas con contenido por archivo. Más de 5.000 filas se procesan por lotes con progreso y reanudación. Las celdas opcionales vacías conservan los datos existentes. Las listas conservan los precios no incluidos. Los documentos se cargan como borradores.</p><div id="importMapping"></div><div id="importPreview"></div><div id="importResult" aria-live="polite"></div><div class="import-actions"><button type="button" class="btn secondary" id="importValidate" disabled>Validar en el servidor</button><button type="button" class="btn primary" id="importCommit" disabled>Confirmar importación</button></div></div><details class="card import-help"><summary>Tablas de la carga general</summary><p>${meta.schema.tables.map(t=>E(t.key)).join(' · ')}</p><p>Se aplica a la empresa activa y requiere los permisos de cada maestro. Los accesos, certificados, pagos y comprobantes fiscales se gestionan desde sus módulos.</p></details><div class="card mt"><div class="toolbar"><h3>Historial de cargas</h3></div><div id="importHistory"></div></div>`;
      bind(v);await history(v);
    }catch(err){
      if(!current(v))return;
      activeView=null;
      const detail=A.errorText(err),message=/(?:column|relation|function).*does not exist|schema cache/i.test(detail)?'Aplica ACTUALIZACION_IMPORTADORES_V3_1.sql en Supabase para habilitar los importadores.':detail;
      root.innerHTML=`<div class="card"><h3>No fue posible cargar los importadores</h3><p class="danger-text">${E(message)}</p><button type="button" class="btn primary" id="importRetry">Reintentar</button></div>`;find(v,'#importRetry').onclick=()=>render();
    }
  }
  function attach(route){
    if(!A.can('IMPORT_VIEW')||!A.can('IMPORT_MANAGE'))return;
    const mode={products:'Productos',customers:'Clientes',prices:'Precios'}[route];if(!mode)return;
    const toolbar=$('#content .toolbar-actions')||$('#content .toolbar')||$('#content .retail-actions');if(!toolbar||$('#openImporter'))return;
    const b=document.createElement('button');b.type='button';b.className='btn secondary';b.id='openImporter';b.textContent='Importar XLSX';b.onclick=()=>{selectedMode=mode;A.navigate('importer');};toolbar.appendChild(b);
  }
  window.SiasImporters={init:value=>{A=value;},render,attach};
})();
