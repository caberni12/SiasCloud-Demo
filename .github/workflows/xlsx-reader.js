/* Lectura XLSX completa fuera del hilo de interfaz. */
(() => {
 'use strict';
 const limits=Object.freeze({maxFileBytes:52428800,maxExpandedBytes:209715200,maxCells:2000000,maxRows:100000,maxColumns:160,maxSheets:32});
 async function read(file,options={}){
  if(!/\.xlsx$/i.test(file.name))throw new Error('Selecciona un archivo .xlsx.');
  if(file.size>limits.maxFileBytes)throw new Error('El archivo supera 50 MB.');
  const buffer=await file.arrayBuffer();
  return new Promise((resolve,reject)=>{
   let worker,timer,blobUrl,finished=false;
   const finish=(error,data)=>{if(finished)return;finished=true;clearTimeout(timer);worker?.terminate();if(blobUrl)URL.revokeObjectURL(blobUrl);error?reject(error):resolve(data);};
   try{
    const local=location.protocol==='file:';
    if(local&&(!window.SiasXlsxZipWorkerSource||!window.SiasXmlSaxSource||!window.SiasXlsxXmlWorkerSource))throw new Error('Actualiza todos los archivos web de la versión 3.1.7, incluidos los lectores XML y XLSX, y vuelve a abrir index.html.');
    const source=local?window.SiasXmlSaxSource+window.SiasXlsxXmlWorkerSource+window.SiasXlsxZipWorkerSource:'';
    const url=local?(blobUrl=URL.createObjectURL(new Blob([source],{type:'text/javascript'}))):new URL('xlsx-zip-worker.js?v=3.1.7',document.baseURI);
    worker=new Worker(url);timer=setTimeout(()=>finish(new Error('La lectura superó dos minutos. Revisa el tamaño y el formato del archivo.')),120000);
    worker.onerror=()=>finish(new Error('No se pudo iniciar el lector XLSX. Actualiza los archivos web y comprueba que tu navegador admite Workers.'));
    worker.onmessage=event=>{const data=event.data;if(data.progress){try{options.onProgress?.(data.progress);}catch{}return;}data.ok?finish(null,data.book):finish(new Error(data.message));};
    worker.postMessage(buffer,[buffer]);
   }catch(error){finish(error);}
  });
 }
 window.SiasXlsxReader={read,limits};
})();
