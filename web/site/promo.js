(function(){
'use strict';
const $=(s,e=document)=>e.querySelector(s);
const PK='mx_pending_coupon';
let cache=null,busy=false;
/* Active coupons straight from the database (public read policy: is_active = true). */
function coupons(){
  return cache||(cache=(async()=>{
    try{
      const {data,error}=await sb.from('coupons').select('*').eq('is_active',true).order('created_at',{ascending:false});
      if(error)throw error;
      const l=(data||[]).filter(x=>(!x.expires_at||new Date(x.expires_at)>new Date())&&(x.max_uses==null||(x.used_count||0)<x.max_uses));
      if(!l.length)cache=null;
      return l;
    }catch(e){cache=null;return[]}
  })());
}
function card(c){
  const first=c.code==='WEL100',amt=c.discount_amount||0;
  return `<article class="pm"><span class="pm-t">${first?'Welcome offer':'Limited-time offer'}</span><div class="pm-a">${amt>0?`<b>${inr(amt)}</b> OFF`:`<b>${h(c.description||'Special discount')}</b>`}</div><p>${first?'on your first booking':h(amt>0&&c.description?c.description:'on your booking')}</p><div class="pm-r"><span class="pm-c">${h(c.code)}</span><button type="button" class="pm-b" data-pcopy="${h(c.code)}"><span class="lb">Copy code</span></button></div><small>${first?'Valid on your first booking only. Apply it at checkout.':'Apply it at checkout.'}</small></article>`;
}
const BULK='<article class="pm alt"><span class="pm-t">Bulk saving</span><div class="pm-a"><b>₹500</b> OFF</div><p>when you book 3 or more tanks</p><div class="pm-r"><span class="pm-c auto">Applied automatically</span><a class="pm-b" href="#/book">Book now →</a></div><small>No code needed. The discount appears at checkout.</small></article>';

/* Home: offers section right below the stats row */
async function home(){
  const st=$('#app .stats');if(!st||$('#offerSec')||busy)return;
  busy=true;
  try{
    const l=await coupons();
    const s=$('#app .stats');if(!s||$('#offerSec'))return;
    const sec=document.createElement('section');sec.className='sec';sec.id='offerSec';
    sec.innerHTML=`<div class="wrap"><div class="head c"><h2>Offers made for you</h2><p>Save on your tank cleaning. Copy a code and use it at checkout.</p></div><div class="pm-g">${l.map(card).join('')}${BULK}</div></div>`;
    s.closest('.wrap').after(sec);
  }finally{busy=false}
}

/* Footer: one slim promo strip above the link columns (footer lives outside #app, so injected once) */
async function foot(){
  const f=$('.foot');if(!f||$('#footPromo'))return;
  const l=await coupons();if($('#footPromo'))return;
  const c=l.find(x=>x.code==='WEL100')||l[0];
  const head=c?`New here? Get ${inr(c.discount_amount||0)} off your first booking`:'Save ₹500 when you book 3 or more tanks';
  const sub=c?`Use code ${h(c.code)} at checkout. Book 3+ tanks and save ₹500 more, applied automatically.`:'Applied automatically at checkout. No code needed.';
  f.insertAdjacentHTML('afterbegin',`<div class="wrap"><div class="fp" id="footPromo"><div class="fp-t"><span class="fp-k">LIMITED OFFER</span><b>${head}</b><span>${sub}</span></div><div class="cbar">${c?`<button type="button" class="cbtn" data-pcopy="${h(c.code)}"><span class="lb">Copy code</span></button>`:''}<a class="cbtn wa" href="#/book">Book now</a></div></div></div>`);
}

let q=0;
function run(){home();foot()}
new MutationObserver(()=>{cancelAnimationFrame(q);q=requestAnimationFrame(run)}).observe($('#app'),{childList:true,subtree:true});
window.addEventListener('hashchange',()=>setTimeout(run,0));run();

/* Copy: silent, the button itself confirms. The code is remembered and auto-applied on the checkout step. */
document.addEventListener('click',e=>{
  const b=e.target.closest('[data-pcopy]');if(!b)return;
  const v=b.dataset.pcopy,lb=b.querySelector('.lb');
  const done=()=>{
    try{localStorage.setItem(PK,v)}catch(x){}
    if(!lb)return;const o=lb.dataset.o||(lb.dataset.o=lb.textContent);
    lb.textContent='Copied ✓';clearTimeout(b._t);b._t=setTimeout(()=>{lb.textContent=o},1800);
  };
  const fb=()=>{try{const t=document.createElement('textarea');t.value=v;t.style.cssText='position:fixed;opacity:0';document.body.appendChild(t);t.select();const ok=document.execCommand('copy');t.remove();if(ok)done()}catch(x){}};
  navigator.clipboard?navigator.clipboard.writeText(v).then(done,fb):fb();
});
})();
