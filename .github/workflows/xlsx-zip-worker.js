// Reusable ZIP reader: a classic Worker on HTTP(S), a Blob Worker for file://.
(()=>{
 'use strict';
 function startZipWorker(){
  'use strict';
// Read only XLSX ZIP entries. Stream limits apply to actual inflated bytes.
self.onmessage=async event=>{
 try{
  if(!self.sax)importScripts('xml-sax.js?v=3.1.7','xlsx-xml-worker.js?v=3.1.7');
  const crcTable=new Uint32Array(256);for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=c&1?0xedb88320^(c>>>1):c>>>1;crcTable[n]=c>>>0;}
  const crc32=data=>{let c=0xffffffff;for(const b of data)c=crcTable[(c^b)&255]^(c>>>8);return (c^0xffffffff)>>>0;};
  const bytes=new Uint8Array(event.data),view=new DataView(bytes.buffer);
  const fail=message=>{throw new Error(message);};
  if(bytes.length>52428800)fail('El archivo supera 50 MB.');
  let end=-1;
  for(let p=bytes.length-22;p>=Math.max(0,bytes.length-65557);p--)if(view.getUint32(p,true)===0x06054b50){end=p;break;}
  if(end<0)fail('El archivo no es un XLSX válido.');
  const count=view.getUint16(end+10,true),offset=view.getUint32(end+16,true);
  if(count>1500||count===65535||view.getUint16(end+4,true)||view.getUint16(end+6,true)||view.getUint16(end+8,true)!==count||end+22+view.getUint16(end+20,true)!==bytes.length)fail('Formato ZIP no compatible.');
  let cursor=offset,total=0;const files={},seen=new Set(),decoder=new TextDecoder();
  for(let i=0;i<count;i++){
   if(cursor+46>bytes.length||view.getUint32(cursor,true)!==0x02014b50)fail('Directorio XLSX dañado.');
   const flags=view.getUint16(cursor+8,true),method=view.getUint16(cursor+10,true),compressed=view.getUint32(cursor+20,true),expanded=view.getUint32(cursor+24,true),nl=view.getUint16(cursor+28,true),extra=view.getUint16(cursor+30,true),comment=view.getUint16(cursor+32,true),local=view.getUint32(cursor+42,true);
   const expectedCrc=view.getUint32(cursor+16,true);
   if(cursor+46+nl+extra+comment>end)fail('Directorio XLSX incompleto.');
   const name=decoder.decode(bytes.subarray(cursor+46,cursor+46+nl));cursor+=46+nl+extra+comment;
   if(flags&1||name.includes('..')||name.startsWith('/')||seen.has(name))fail('Estructura XLSX no compatible.');seen.add(name);
   if(/vbaProject|encryption/i.test(name))fail('Selecciona un XLSX sin macros ni contraseña.');
   if(!/^(?:\[Content_Types\]\.xml|xl\/(?:workbook\.xml|_rels\/workbook\.xml\.rels|sharedStrings\.xml|styles\.xml|worksheets\/[a-zA-Z0-9_-]+\.xml))$/.test(name))continue;
   if(expanded>209715200||total+expanded>209715200)fail('El contenido del archivo supera 200 MB al descomprimir.');
   if(local+30>bytes.length||view.getUint32(local,true)!==0x04034b50)fail('Archivo XLSX dañado.');
   const start=local+30+view.getUint16(local+26,true)+view.getUint16(local+28,true);
   if(start+compressed>offset)fail('Contenido XLSX incompleto.');
   const packed=bytes.subarray(start,start+compressed);let data;
   if(method===0){data=packed.slice();total+=data.length;}
   else if(method===8){
    let inflater;try{inflater=new DecompressionStream('deflate-raw');}catch{fail('Actualiza tu navegador para leer archivos XLSX.');}
    const reader=new Blob([packed]).stream().pipeThrough(inflater).getReader(),chunks=[];let length=0;
    while(true){const part=await reader.read();if(part.done)break;length+=part.value.length;total+=part.value.length;if(total>209715200){await reader.cancel();fail('El contenido XLSX supera 200 MB al descomprimir.');}chunks.push(part.value);}
    data=new Uint8Array(length);let at=0;for(const chunk of chunks){data.set(chunk,at);at+=chunk.length;}
   }else fail('Compresión XLSX no compatible.');
   if(data.length!==expanded||total>209715200||crc32(data)!==expectedCrc)fail('El archivo XLSX está dañado o excede el límite.');
   files[name]=data.buffer;
  }
  if(!files['xl/workbook.xml']||!files['xl/_rels/workbook.xml.rels'])fail('No se encontró el libro XLSX.');
  self.postMessage({ok:true,book:self.SiasParseXlsx(files)});
 }catch(error){self.postMessage({ok:false,message:error.message||'No se pudo leer el XLSX.'});}
};

 }
 if(typeof document!=='undefined'){
  window.SiasXlsxZipWorkerSource='('+startZipWorker.toString()+')();';
 }else startZipWorker();
})();
