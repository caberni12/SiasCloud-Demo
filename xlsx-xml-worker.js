/* SAX streaming; las hojas no se convierten en millones de nodos DOM. */
(()=>{
 'use strict';
 function defineXlsxParser(){
  'use strict';
  const local=name=>name.split(':').at(-1),fail=message=>{throw new Error(message);};
  function scan(buffer,handlers){
   const parser=self.sax.parser(true,{position:false}),decoder=new TextDecoder();
   parser.ondoctype=()=>fail('XML del XLSX no compatible: no se permiten entidades ni DTD.');
   parser.onerror=error=>fail('XML del XLSX inválido: '+error.message.slice(0,120));
   parser.onopentag=node=>handlers.open?.(local(node.name),node.attributes);
   parser.onclosetag=name=>handlers.close?.(local(name));parser.ontext=value=>handlers.text?.(value);parser.oncdata=value=>handlers.text?.(value);
   const bytes=new Uint8Array(buffer);for(let at=0;at<bytes.length;at+=65536)parser.write(decoder.decode(bytes.subarray(at,at+65536),{stream:true}));parser.write(decoder.decode()).close();
  }
  self.SiasParseXlsx=files=>{
   let date1904=false;const sheets=[],rels=new Map(),shared=[],zeroFormats=new Map(),formats=[];
   scan(files['xl/workbook.xml'],{open:(n,a)=>{if(n==='workbookPr')date1904=['1','true'].includes(a.date1904);if(n==='sheet')sheets.push({name:a.name,id:a['r:id']||Object.entries(a).find(([k])=>k.endsWith(':id'))?.[1]});}});
   if(sheets.length>32)fail('Máximo 32 hojas por archivo.');
   scan(files['xl/_rels/workbook.xml.rels'],{open:(n,a)=>{if(n==='Relationship'&&a.TargetMode!=='External')rels.set(a.Id,a.Target);}});
   if(files['xl/sharedStrings.xml']){
    let value='',inSi=false,inT=false,phonetic=0;
    scan(files['xl/sharedStrings.xml'],{open:n=>{if(n==='si'){value='';inSi=true;}if(n==='rPh')phonetic++;if(n==='t')inT=true;},text:v=>{if(inSi&&inT&&!phonetic)value+=v;},close:n=>{if(n==='t')inT=false;if(n==='rPh')phonetic--;if(n==='si'){shared.push(value);inSi=false;}}});delete files['xl/sharedStrings.xml'];
   }
   if(files['xl/styles.xml']){let cellXfs=false;scan(files['xl/styles.xml'],{open:(n,a)=>{if(n==='numFmt'&&/^0+$/.test(a.formatCode||''))zeroFormats.set(a.numFmtId,a.formatCode.length);if(n==='cellXfs')cellXfs=true;else if(n==='xf'&&cellXfs)formats.push(a.numFmtId);},close:n=>{if(n==='cellXfs')cellXfs=false;}});}
   let count=0,blankCells=0,rowCount=0;const result=[];
   for(const sheet of sheets){
    const target=rels.get(sheet.id);if(!target)fail('No se encontró la hoja '+sheet.name);
    const parts=[];for(const p of (target.startsWith('/')?target.slice(1):'xl/'+target).split('/')){if(p==='..')parts.pop();else if(p!=='.')parts.push(p);}const name=parts.join('/');if(!files[name])fail('La hoja no está disponible o no es compatible.');
    const rows=[];let rowNumber=0,cells=[],cell=null,node='',phonetic=0,occupied=new Set();
    function finishCell(){
     if(!cell)return;
     if(cell.formula&&!cell.hasValue)fail(`${sheet.name} ${cell.ref}: guarda el resultado de la fórmula en Excel antes de importar.`);
     if(cell.type==='e')fail(`${sheet.name} ${cell.ref}: contiene un error de Excel.`);
     if(!cell.hasValue&&!cell.inline){blankCells++;return;}
     let v='';
     if(cell.type==='s'){const index=Number(cell.value);if(!Number.isInteger(index)||index<0||index>=shared.length)fail('Texto XLSX inválido.');v=shared[index];}
     else if(cell.type==='inlineStr')v=cell.inline;
     else if(cell.type==='b')v=cell.value==='1';
     else if(cell.type==='str'||cell.type==='d')v=cell.value;
     else if(cell.hasValue&&cell.value!==''){v=Number(cell.value);if(!Number.isFinite(v))fail('Número XLSX inválido.');const zeros=zeroFormats.get(formats[Number(cell.style||0)]);if(zeros&&Number.isInteger(v))v=String(v).padStart(zeros,'0');}
     if(v===''||v===null){blankCells++;return;}
     if(++count>2000000)fail('El libro supera 2.000.000 de celdas con contenido. Las vacías con formato no cuentan.');
     const ref=cell.ref?.match(/^([A-Z]+)(\d+)$/);if(!ref||Number(ref[2])!==rowNumber)fail('Referencia de celda inválida.');let col=0;for(const c of ref[1])col=col*26+c.charCodeAt(0)-64;if(col>160)fail('Máximo 160 columnas con datos por hoja.');if(occupied.has(col))fail('Referencia de celda repetida.');occupied.add(col);cells[col-1]=v;
    }
    scan(files[name],{open:(n,a)=>{node=n;if(n==='row'){rowNumber=Number(a.r);if(!Number.isInteger(rowNumber)||rowNumber<1||rowNumber>1048576)fail('Número de fila inválido.');cells=[];occupied=new Set();}if(n==='c')cell={ref:a.r,type:a.t,style:a.s,value:'',inline:'',hasValue:false,formula:false};if(n==='f'&&cell)cell.formula=true;if(n==='v'&&cell)cell.hasValue=true;if(n==='rPh')phonetic++;},text:v=>{if(!cell)return;if(node==='v')cell.value+=v;if(node==='t'&&!phonetic)cell.inline+=v;},close:n=>{if(n==='rPh')phonetic--;if(n==='c'){finishCell();cell=null;}if(n==='row'&&cells.length){rows.push({row:rowNumber,cells:Array.from(cells,v=>v??'')});if(++rowCount>101024)fail('Máximo 100.000 filas de datos por archivo, además de encabezados e instrucciones.');if(rowCount%500===0)self.postMessage({progress:{phase:'xml',sheet:sheet.name,rows:rowCount,cells:count}});}node='';}});
    delete files[name];result.push({name:sheet.name,rows});
   }
   return {sheets:result,date1904,cellCount:count,blankCells};
  };
 }
 if(typeof document!=='undefined')window.SiasXlsxXmlWorkerSource='('+defineXlsxParser.toString()+')();';else defineXlsxParser();
})();
