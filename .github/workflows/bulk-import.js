/* Un archivo, solicitudes acotadas y cursor persistente en el servidor. */
(()=>{
 'use strict';
 const encoder=new TextEncoder();
 const check=result=>{if(result.validation?.ok===false){const error=new Error(result.validation.errors?.[0]?.message||'No se pudo procesar la carga');error.rows=result.validation.errors||[];error.job=result.job;throw error;}return result.job;};
 async function normalize(book,schema,settings){
  const source='const C='+window.SiasImportCoreSource+';self.onmessage=e=>{try{self.postMessage({ok:true,value:C.normalize(e.data.book,e.data.schema,e.data.settings)});}catch(e){self.postMessage({ok:false,message:e.message});}};';
  const local=location.protocol==='file:',url=local?URL.createObjectURL(new Blob([source],{type:'text/javascript'})):new URL('import-normalize-worker.js?v=3.1.7',document.baseURI);let worker;
  try{return await new Promise((resolve,reject)=>{worker=new Worker(url);worker.onmessage=e=>e.data.ok?resolve(e.data.value):reject(new Error(e.data.message));worker.onerror=()=>reject(new Error('No se pudo revisar el archivo.'));worker.postMessage({book,schema,settings});});}finally{worker?.terminate();if(local)URL.revokeObjectURL(url);}
 }
 function create({call,company,current,onProgress}){
  let job=null,paused=false;
  const api=async(action,p={})=>{const result=await call('imports.bulk.'+action,{...p,company_id:company});const next=check(result);if(next)job=next;return result;};
  const progress=phase=>onProgress?.(job,phase);
  const active=()=>{if(paused||!current())throw Object.assign(new Error('Carga pausada. Puedes continuar desde el historial.'),{paused:true,job});};
  return {
   get job(){return job;},pause:()=>{paused=true;},
   async prepare(rows,options,existing){
    paused=false;job=existing||null;const id=job?.id||crypto.randomUUID();
    await api('start',{job_id:id,total_rows:rows.length,...options});
    while(job.uploaded_rows<rows.length){active();const offset=job.uploaded_rows,chunk=[];let bytes=2;
     for(let i=offset;i<rows.length&&chunk.length<500;i++){const size=encoder.encode(JSON.stringify(rows[i])).length+1;if(bytes+size>1500000&&chunk.length)break;if(size>1500000)throw new Error('Una fila supera el tamaño permitido. Revisa los textos del archivo.');chunk.push(rows[i]);bytes+=size;}
     progress('upload');await api('upload',{job_id:id,offset,rows:chunk});progress('upload');
    }
    active();progress('validate');await api('validate',{job_id:id});progress('ready');return job;
   },
   async resume(existing){paused=false;job=existing;await api('status',{job_id:job.id});if(job.processed_rows===0)await api('validate',{job_id:job.id});progress('apply');
    while(job.status!=='COMPLETED'){if(paused||!current()){progress('paused');return {job,paused:true};}await api('step',{job_id:job.id,offset:job.processed_rows});progress('apply');}
    return {job,paused:false};
   }
  };
 }
 window.SiasBulkImport={create,normalize};
})();
