/* Splash global: solo arranque y apertura de módulos. Las acciones internas usan loaders en botones. */
(() => {
  'use strict';
  const el=document.querySelector('#erpSplash');
  if(!el)return;
  const message=el.querySelector('[data-splash-message]'),progress=el.querySelector('[data-splash-progress]'),pause=el.querySelector('[data-splash-pause]');
  const tasks=new Map();let next=0,boot=true;
  const topLayer=()=>{if(typeof el.showPopover!=='function')return;try{el.popover='manual';if(!el.matches(':popover-open'))el.showPopover();}catch{}};
  function refresh(){
    const task=[...tasks.values()].at(-1);
    if(!boot&&!task){
      el.classList.add('splash-hide');
      el.setAttribute('aria-hidden','true');
      document.body.removeAttribute('aria-busy');
      try{if(el.matches(':popover-open'))el.hidePopover();}catch{}
      return;
    }
    el.classList.remove('splash-hide','splash-compact');
    el.setAttribute('aria-hidden','false');
    document.body.setAttribute('aria-busy','true');
    message.textContent=task?.message||'Conectando con SiasCloud ERP…';
    progress.hidden=!task?.total;
    progress.max=task?.total||1;
    progress.value=task?.done||0;
    pause.hidden=true;
    topLayer();
  }
  function beginModule(label='Abriendo módulo…',options={}){
    const id=++next,t={message:label,total:options.total||0,done:0,start:performance.now()};
    tasks.set(id,t);refresh();let ended=false;
    const end=()=>{if(ended)return;ended=true;const delay=Math.max(0,(options.minimum??180)-(performance.now()-t.start));setTimeout(()=>{tasks.delete(id);refresh();},delay);};
    end.update=(label,done,total)=>{if(ended)return;if(label)t.message=label;if(total!==undefined)t.total=total;if(done!==undefined)t.done=done;refresh();};
    return end;
  }
  async function runModule(label,fn,options={}){const end=beginModule(label,options);try{return await fn(end.update);}finally{end();}}

  /* Compatibilidad: ya no abre splash para operaciones internas. */
  function begin(){const end=()=>{};end.update=()=>{};return end;}
  async function run(_label,fn){return await fn(()=>{});}
  function setBusy(){/* El loader de botones lo administra app.js. */}

  window.SiasSplash={begin,run,setBusy,beginModule,runModule,finishBoot:()=>{boot=false;refresh();}};
  refresh();
})();
