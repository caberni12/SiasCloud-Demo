importScripts('import-core.js?v=3.1.7');
self.onmessage=event=>{try{self.postMessage({ok:true,value:self.SiasImportCore.normalize(event.data.book,event.data.schema,event.data.settings)});}catch(error){self.postMessage({ok:false,message:error.message});}};
