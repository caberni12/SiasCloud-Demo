/* Búsqueda de clientes del POS; independiente del catálogo y del ticket. */
(()=>{
  'use strict';
  const normalize=v=>String(v??'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,' ').trim();
  const compact=v=>normalize(v).replace(/ /g,'');
  function bind({root,A,customers,onSelect,isCurrent}){
    const input=root.querySelector('#posCustomerSearch'),list=root.querySelector('#posCustomerResults'),select=root.querySelector('#posCustomer');
    if(!input||!list||!select)return;
    let sequence=0,timer,results=[],active=-1;
    const current=()=>root.isConnected&&isCurrent();
    const setStatus=text=>{list.replaceChildren();const p=document.createElement('p');p.className='pos-customer-status';p.textContent=text;list.append(p);list.hidden=false;input.setAttribute('aria-expanded','true');};
    const close=()=>{sequence++;clearTimeout(timer);list.hidden=true;active=-1;input.setAttribute('aria-expanded','false');input.removeAttribute('aria-activedescendant');};
    const local=q=>{const words=normalize(q).split(' ').filter(Boolean),code=compact(q);return customers.filter(c=>{
      const text=normalize([c.legal_name,c.trade_name,c.rut,c.email,c.phone].join(' '));
      return words.length&&(words.every(w=>text.includes(w))||compact(c.rut).includes(code)||compact(c.phone).includes(code));
    }).slice(0,50);};
    const choose=c=>{
      if(!current())return;
      if(![...select.options].some(o=>o.value===c.id))select.add(new Option(`${c.legal_name}${c.rut?' · '+c.rut:''}`,c.id));
      select.value=c.id;onSelect(c);input.value='';close();select.focus();
    };
    const highlight=()=>{[...list.querySelectorAll('[data-customer-result]')].forEach((b,i)=>{b.classList.toggle('active',i===active);b.setAttribute('aria-selected',String(i===active));});const b=list.querySelectorAll('[data-customer-result]')[active];if(b){input.setAttribute('aria-activedescendant',b.id);b.scrollIntoView({block:'nearest'});}else input.removeAttribute('aria-activedescendant');};
    const draw=(rows,truncated=false)=>{
      results=rows;active=-1;input.removeAttribute('aria-activedescendant');list.replaceChildren();
      if(!rows.length){setStatus('No se encontraron clientes. Puedes crear uno con + Nuevo cliente.');return;}
      rows.forEach((c,i)=>{const b=document.createElement('button');b.type='button';b.className='pos-customer-result';b.id='pos-customer-result-'+i;b.dataset.customerResult=c.id;b.setAttribute('role','option');b.setAttribute('aria-selected','false');
        const name=document.createElement('strong'),detail=document.createElement('small');name.textContent=c.legal_name||c.trade_name||'Cliente';detail.textContent=[c.rut,c.trade_name,c.phone,c.email].filter(Boolean).join(' · ');b.append(name,detail);b.addEventListener('mousedown',e=>e.preventDefault());b.addEventListener('click',()=>choose(c));list.append(b);});
      if(truncated){const p=document.createElement('p');p.className='pos-customer-status';p.textContent='Hay más coincidencias. Escribe más datos para acotar la búsqueda.';list.append(p);}
      list.hidden=false;input.setAttribute('aria-expanded','true');
    };
    input.addEventListener('input',()=>{
      clearTimeout(timer);const seq=++sequence,q=input.value.trim();
      if(!q){close();return;}
      draw(local(q));
      timer=setTimeout(async()=>{if(!current()||seq!==sequence)return;try{
        const r=await A.erpCall('pos.customers.search',{search:q});
        if(!current()||seq!==sequence||input.value.trim()!==q)return;
        draw(r.rows||[],Boolean(r.truncated));
      }catch(e){if(current()&&seq===sequence&&e?.code!=='OBSOLETE_VIEW'){if(!results.length)setStatus('No se pudo consultar el servidor. Vuelve a escribir para reintentar.');A.toast(A.errorText(e),true);}}},180);
    });
    input.addEventListener('keydown',e=>{
      if(e.key==='Escape'){e.preventDefault();input.value='';close();return;}
      if(list.hidden)return;
      if(e.key==='ArrowDown'||e.key==='ArrowUp'){e.preventDefault();if(!results.length)return;active=(active+(e.key==='ArrowDown'?1:-1)+results.length)%results.length;highlight();}
      if(e.key==='Enter'){e.preventDefault();const c=results[active]||(results.length===1?results[0]:null);if(c)choose(c);}
    });
    input.addEventListener('blur',()=>setTimeout(()=>{if(document.activeElement!==input&&!list.contains(document.activeElement))close();},150));
    select.addEventListener('change',()=>{input.value='';close();});
  }
  window.SiasPosCustomers={bind};
})();
