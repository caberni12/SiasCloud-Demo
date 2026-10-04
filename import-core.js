/* Normalización compartida y comprobable. Nunca modifica la base de datos. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else {root.SiasImportCore=api;root.SiasImportCoreSource='('+factory.toString()+')()';}})(globalThis,function(){
  'use strict';
  const norm=v=>String(v??'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]/g,'');
  const empty=v=>v===null||v===undefined||typeof v==='string'&&!v.trim();
  function numeric(v){if(typeof v==='number')return v;let s=String(v).trim().replace(/\s|\$/g,'');if(s.includes(','))s=s.replace(/\./g,'').replace(',','.');else if(/^-?\d{1,3}(\.\d{3})+$/.test(s))s=s.replace(/\./g,'');if(!/^-?\d+(\.\d+)?$/.test(s))throw Error('Número inválido');return Number(s);}
  function date(v,date1904){if(typeof v==='number'){if(!Number.isFinite(v)||v<(date1904?0:1)||v>150000)throw Error('Fecha Excel fuera de rango');if(!date1904&&Math.floor(v)===60)throw Error('Fecha Excel inexistente (29/02/1900)');if(!date1904&&v<60)v+=1;v=new Date(Date.UTC(date1904?1904:1899,date1904?0:11,date1904?1:30)+Math.floor(v)*86400000).toISOString().slice(0,10);}let s=String(v).trim();if(/^\d{2}[/.-]\d{2}[/.-]\d{4}$/.test(s)){const [d,m,y]=s.split(/[/.-]/);s=`${y}-${m}-${d}`;}if(!/^\d{4}-\d{2}-\d{2}$/.test(s)||isNaN(Date.parse(s))||new Date(s+'T12:00:00Z').toISOString().slice(0,10)!==s)throw Error('Usa fecha Excel, AAAA-MM-DD o DD/MM/AAAA');return s;}
  function convert(v,f,date1904){
    if(empty(v))return undefined;
    if(f.type==='number'||f.type==='integer'){const n=numeric(v);if(!Number.isFinite(n)||n<(f.min??-Infinity)||n>(f.max??Infinity)||f.type==='integer'&&!Number.isInteger(n))throw Error(`Número fuera de rango${f.min!==undefined?' ('+f.min+' a '+f.max+')':''}`);return n;}
    if(f.type==='bool'){const n=norm(v);if(['si','s','true','1','activo','activa'].includes(n))return true;if(['no','n','false','0','inactivo','inactiva'].includes(n))return false;throw Error('Usa Sí o No');}
    if(f.type==='date')return date(v,date1904);
    let s=String(v).trim();if(s.length>(f.maxLength??6000))throw Error('Texto demasiado largo');
    if(f.type==='rut'){s=s.replace(/[.\s]/g,'').toUpperCase();if(!/^[0-9]{1,12}-[0-9K]$/.test(s))throw Error('RUT inválido: usa número-dígito verificador');}
    if(f.type==='email'&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s))throw Error('Correo inválido');
    if(f.type==='url'){let u;try{u=new URL(s);}catch{throw Error('URL inválida');}if(!['https:','http:'].includes(u.protocol))throw Error('Usa una URL https:// o http://');}
    if(f.type==='color'&&!/^#[0-9a-f]{6}$/i.test(s))throw Error('Usa color #RRGGBB');
    if(f.type==='unit'){s=({unidad:'UN',unidades:'UN',und:'UN',unid:'UN',g:'GR',gramos:'GR',kilogramos:'KG',cajas:'CAJA',litros:'LT',l:'LT'}[norm(s)]||s.toUpperCase());if(!['UN','KG','GR','LT','ML','MT','CM','CAJA','PALLET'].includes(s))throw Error('Unidad no válida');}
    if(f.type==='kind'){s=({producto:'PRODUCT',insumo:'SUPPLY'}[norm(s)]||s.toUpperCase());if(!['PRODUCT','SUPPLY'].includes(s))throw Error('Usa PRODUCT o SUPPLY');}
    if(f.type==='roles'){const roles=s.split(/[,;|]/).map(v=>({vendedor:'SELLER',preparador:'PREPARER',embalador:'PACKER',cajero:'CASHIER'}[norm(v)]||v.trim().toUpperCase()));if(!roles.length||roles.some(r=>!['SELLER','PREPARER','PACKER','CASHIER'].includes(r)))throw Error('Funciones: SELLER, PREPARER, PACKER, CASHIER');return [...new Set(roles)];}
    if(f.type==='book'){s=({ventas:'SALES',compras:'PURCHASES'}[norm(s)]||s.toUpperCase());if(!['SALES','PURCHASES'].includes(s))throw Error('Usa SALES (ventas) o PURCHASES (compras)');}
    if(f.type==='document'){s=({cotizacion:'QUOTE',pedido:'ORDER',solicitud:'REQUEST',venta:'SALE',mayorista:'WHOLESALE',ventamayorista:'WHOLESALE',compra:'PURCHASE',ingreso:'RECEIPT',salida:'ISSUE',guia:'DELIVERY'}[norm(s)]||s.toUpperCase());if(!['QUOTE','ORDER','REQUEST','SALE','WHOLESALE','PURCHASE','RECEIPT','ISSUE','DELIVERY'].includes(s))throw Error('Tipo de documento no válido');}
    return s;
  }
  function sheetKey(name,schema){const n=norm(name);const aliases={maestroproductos:'Productos',maestroclientes:'Clientes',listadeprecios:'Precios',listaprecios:'Precios',listaprecio:'Precios',stock:'StockInicial',inventario:'StockInicial',detalle:'DetalleDocumentos'};return aliases[n]||schema.tables.find(t=>[norm(t.key),norm(t.key).replace(/s$/,''),norm(t.db)].includes(n))?.key||'';}
  function columns(headers,table){const out={};headers.forEach((h,i)=>{const n=norm(h);const k=Object.keys(table.fields).find(k=>norm(k)===n||norm(table.fields[k].label)===n);if(k)out[i]=k;});return out;}
  function normalize(book,schema,settings={}){
    const rows=[],errors=[],warnings=[],seen=new Map(),tables=new Map(schema.tables.map(t=>[t.key,t]));
    const fail=(sheet,row,column,message)=>{if(errors.length<301)errors.push({sheet,row,column,message});};
    for(const sh of book.sheets){
      if(['instrucciones','ayuda','leeme'].includes(norm(sh.name)))continue;
      let key=settings.sheets?.[sh.name];if(key===undefined)key=sheetKey(sh.name,schema)||(['Productos','Clientes'].includes(settings.mode)&&book.sheets.filter(s=>!['instrucciones','ayuda','leeme'].includes(norm(s.name))).length===1?settings.mode:'');
      if(key==='IGNORE'||!sh.rows.length)continue;
      if(!tables.has(key)){fail(sh.name,1,'Hoja','Asigna esta hoja a una tabla o elige Ignorar');continue;}
      const allowed=settings.mode==='General'?schema.tables.map(t=>t.key):settings.mode==='Precios'?['ListasPrecios','Precios']:settings.mode==='Productos'?['Productos','Atributos']:[settings.mode];if(settings.mode&&!allowed.includes(key)){fail(sh.name,1,'Hoja','Esta hoja no corresponde al tipo de carga elegido');continue;}
      const t=tables.get(key),header=sh.rows[0],map=settings.columns?.[sh.name]||columns(header.cells,t),used=new Set(),mapped=Object.entries(map).filter(([i,k])=>k&&t.fields[k]),required=Object.entries(t.fields).filter(([k,f])=>f.required);
      for(const [i,k]of Object.entries(map)){if(!k)continue;if(!t.fields[k]){fail(sh.name,header.row,header.cells[i],'Columna no válida');continue;}if(used.has(k))fail(sh.name,header.row,header.cells[i],'Dos columnas apuntan al mismo campo');used.add(k);}
      for(const rr of sh.rows.slice(1)){
        if(rr.cells.every(empty))continue;const values={};
        for(const [i,k]of mapped){try{const val=convert(rr.cells[i],t.fields[k],book.date1904);if(val!==undefined)values[k]=val;}catch(e){fail(sh.name,rr.row,t.fields[k].label,e.message);}}
        if(key==='Precios'&&!values.list&&settings.defaultList)values.list=settings.defaultList;
        for(const [k,f]of required)if(empty(values[k]))fail(sh.name,rr.row,f.label,'Campo obligatorio');
        if(['Clientes','Proveedores'].includes(key)&&!values.rut&&!values.import_code)fail(sh.name,rr.row,'RUT / Código','Indica RUT o código único');
        let identity=t.singleton?'única':key==='Precios'?values.list+'|'+values.sku:key==='StockInicial'?values.warehouse+'|'+values.sku:key==='Atributos'?values.sku+'|'+values.attribute:key==='Recetas'?values.sku+'|'+values.supply_sku:key==='DetalleDocumentos'?values.document+'|'+values.line_no:key==='RCV'?[values.book,values.document_type,values.rut,values.folio].join('|'):key==='Documentos'?values.import_code:key==='Folios'?values.code:t.identity?.map(k=>values[k]).find(v=>!empty(v));
        identity=key+'|'+String(identity??'').trim().toLowerCase();if(seen.has(identity))fail(sh.name,rr.row,'Clave','Registro repetido; primera fila '+seen.get(identity));else seen.set(identity,rr.row);
        rows.push({sheet:key,source:sh.name,row:rr.row,values});
      }
    }
    if(rows.length>schema.maxRows)fail('Archivo',0,'Filas',`Máximo ${schema.maxRows} filas por archivo`);
    if(!rows.length)fail('Archivo',0,'Filas','El archivo no contiene registros');
    const prods=rows.filter(r=>r.sheet==='Productos'),bySku=new Map(prods.map(r=>[String(r.values.sku||'').trim().toLowerCase(),r])),visited=new Set(),stack=new Set(),sorted=[];
    for(const r of prods){
      const chain=[];let next=r;
      while(next){const k=String(next.values.sku||'').trim().toLowerCase();if(visited.has(k))break;if(stack.has(k)){fail(next.source,next.row,'SKU padre','Relación circular entre productos');break;}stack.add(k);chain.push([k,next]);next=bySku.get(String(next.values.parent_sku||'').trim().toLowerCase());}
      for(let i=chain.length-1;i>=0;i--){const [k,item]=chain[i];stack.delete(k);if(!visited.has(k)){visited.add(k);sorted.push(item);}}
    }
    const ordered=[];for(const t of schema.tables)for(const row of (t.key==='Productos'?sorted:rows.filter(r=>r.sheet===t.key)))ordered.push(row);
    if(errors.length>300)errors.splice(300,errors.length-300,{sheet:'Archivo',row:0,column:'Errores',message:'Hay más errores; corrige los primeros y vuelve a revisar'});
    return {rows:ordered,errors,warnings};
  }
  return {norm,numeric,convert,columns,sheetKey,normalize};
});
