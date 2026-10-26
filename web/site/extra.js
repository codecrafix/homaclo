(function(){
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const L=a=>a.map(x=>`<li>${x}</li>`).join('');
function proof(){
  const hr=$('#hrev');if(!hr||$('#proof'))return;
  const s=document.createElement('section');s.id='proof';s.className='sec alt';
  s.innerHTML=`<div class="wrap"><div class="head c"><h2>Real work proof</h2><p>Drag the slider: muddy tank before, hygienic tank after.</p></div>
  <div class="ba"><img class="after" src="img/after.png" alt="Tank after Homaclo cleaning" loading="lazy"><img class="before" src="img/before.png" alt="Tank before cleaning" loading="lazy"><span class="tg b">BEFORE</span><span class="tg a">AFTER ✨</span><input type="range" min="0" max="100" value="50" aria-label="Before and after slider"></div>
  <div class="head" style="margin:56px 0 24px"><h2>Why tank cleaning matters</h2></div>
  <div class="rb"><div class="rk"><h4>✕ Dirty water risks</h4><ul>${L(['Hair fall and scalp damage from minerals and bacteria','Skin allergies and rashes','Typhoid, jaundice and stomach illness risk','Bad odour and limescale on taps'])}</ul></div>
  <div class="bn"><h4>✓ Clean water benefits</h4><ul>${L(['Healthier hair and skin','Safe, bacteria-free drinking water','Longer plumbing life, less clogging','Fresh taste, zero foul odour'])}</ul></div></div></div>`;
  hr.closest('section').before(s);
  const ba=$('.ba',s),r=$('input',ba);r.oninput=()=>ba.style.setProperty('--p',r.value+'%');
}

/* ---------- Offers (same as the app): Profile "Active Offer" + "Special Offer" cards, checkout coupon hint chip ---------- */
(function(){const st=document.createElement('style');st.textContent=
'#offers{display:grid;gap:12px;margin:18px 0 6px}#offers .oh{margin:-2px 4px 0;font-size:.82rem;color:var(--mut)}'+
'.of{display:flex;align-items:center;gap:14px;padding:16px;border-radius:18px;color:#fff;text-decoration:none}'+
'.of.act{background:linear-gradient(135deg,#0d9488,#0f766e);box-shadow:0 8px 22px rgba(13,148,136,.3)}'+
'.of.sp{background:linear-gradient(135deg,#0d9488,#0a2540 65%,#0a2540);box-shadow:0 8px 22px rgba(13,148,136,.25)}'+
'.of .gi{width:46px;height:46px;border-radius:14px;background:rgba(255,255,255,.18);display:grid;place-items:center;font-size:22px;flex:none}'+
'.of .ob{flex:1;min-width:0;display:flex;flex-direction:column;gap:2px;font-size:.85rem;line-height:1.4}'+
'.of small{font-size:.68rem;font-weight:700;letter-spacing:.08em;opacity:.75;text-transform:uppercase}'+
'.of .ob>b{font-size:1.25rem;font-weight:800}.of em{font-style:normal;font-size:.72rem;opacity:.8}'+
'.of .cc{flex:none;min-height:48px;padding:6px 12px;border:0;border-radius:12px;background:#fff;color:#0d9488;cursor:pointer;display:flex;flex-direction:column;align-items:center;gap:2px;box-shadow:0 2px 6px rgba(0,0,0,.15)}'+
'.of .cc b{font-size:.82rem;letter-spacing:.1em;font-weight:800}.of .cc .lb{font-size:.62rem;font-weight:700;opacity:.8}'+
'.of .ar{width:34px;height:34px;border-radius:50%;background:#fff;color:#0d9488;display:grid;place-items:center;font-weight:800;flex:none}'+
'.hintc{display:inline-flex;align-items:center;gap:6px;margin-top:10px;min-height:40px;padding:4px 12px;border-radius:10px;border:1px solid color-mix(in srgb,var(--teal) 45%,transparent);background:color-mix(in srgb,var(--teal) 10%,transparent);color:var(--teal);font:700 .78rem inherit;cursor:pointer}';
document.head.appendChild(st)})();
const PK='mx_pending_coupon';
function pend(v){try{if(v===undefined)return localStorage.getItem(PK);if(v===null)localStorage.removeItem(PK);else localStorage.setItem(PK,v)}catch(e){return null}}
async function offers(){
  const ctx=$('#ctx'),h1=$('#app .page h1');if(!ctx||!h1||$('#offers')||!S.user)return;
  const box=document.createElement('div');box.id='offers';
  box.innerHTML='<a class="of sp" href="#/book"><span class="gi">🏷️</span><div class="ob"><small>Special Offer 🎉</small><span>₹500 Flat Discount on 3 Tank Cleaning Bookings!</span></div><span class="ar">→</span></a>';
  h1.after(box);
  let c=null;
  try{const r=await sb.from('coupons').select('*').eq('is_active',true).order('created_at',{ascending:false}).limit(1).maybeSingle();c=r.data}catch(e){}
  if(!c||!$('#offers')||$('#offers .act'))return;
  const d=c.discount_amount||0,desc=c.description||'',ex=c.expires_at?new Date(c.expires_at):null;
  const exp=ex&&!isNaN(ex)?`Valid till ${ex.getDate()} ${MN[ex.getMonth()]} ${ex.getFullYear()}`:'';
  box.insertAdjacentHTML('afterbegin',`<div class="of act"><span class="gi">🎁</span><div class="ob"><small>Active Offer</small><b>${d>0?inr(d)+' OFF':h(desc||'Special Discount')}</b>${desc&&d>0?`<em>${h(desc)}</em>`:''}${exp?`<em>${exp}</em>`:''}</div><button type="button" class="cc" data-copy="${h(c.code)}" aria-label="Copy coupon ${h(c.code)}"><b>${h(c.code)}</b><span class="lb">COPY</span></button></div><p class="oh">Tap the code to copy. It is applied automatically on the Review &amp; pay step, or paste it in Coupon code.</p>`);
}
let autoBusy=false;
async function autoApply(){
  if(autoBusy||!$('#f-cp')||!S.user||S.cart.coupon)return;
  const code=pend();if(!code)return;
  autoBusy=true;
  try{
    const r=await validateCoupon(code);
    if(!$('#f-cp'))return;
    pend(null);couponMsg=r.message;S.cart.coupon=r.valid?r:null;route();
  }finally{autoBusy=false}
}
function hint(){
  const i=$('#f-cp');if(!i||$('.hintc'))return;
  const row=i.closest('.row');if(!row)return;
  const p=row.nextElementSibling;
  (p&&p.tagName==='P'?p:row).insertAdjacentHTML('afterend','<div><button type="button" class="hintc" data-fill="WEL100">🏷️ WEL100 — ₹100 off first booking</button></div>');
}

function enhance(){
  proof();offers();autoApply();hint();
  $$('#svc .card').forEach(c=>{if(!$('a[href="#/book"]',c)&&!$('.soon',c)){const b=$('.btn',c);if(b)b.outerHTML='<span class="soon">Coming soon</span>'}});
  const rl=$('#ravg');if(rl&&!$('.trust')){const t=document.createElement('div');t.className='trust';t.innerHTML='<span class="bdg">⭐ Verified reviews</span><span class="bdg g">💯 100% Satisfaction Rate</span>';rl.closest('.head').after(t)}
  $$('#rl .card,#hrev .card').forEach(c=>{if(!$('.vb',c)&&$('p',c))c.insertAdjacentHTML('beforeend','<span class="vb">✔ Verified Satna customer</span>')});
  const s=$('.sum');if(s&&!s.classList.contains('dr')){s.classList.add('dr');const t=$('.line.t',s);const d=document.createElement('div');d.className='dh';d.innerHTML='<span>Order summary ▴</span><span>'+(t?t.lastElementChild.textContent:'')+'</span>';s.prepend(d);d.onclick=()=>s.classList.toggle('open')}
  const a=(location.hash.replace(/^#\/?/,'').split('?')[0])||'';
  $$('.bnav a').forEach(x=>x.classList.toggle('on',x.dataset.r===(a||'home')));
}
let q=0;new MutationObserver(()=>{cancelAnimationFrame(q);q=requestAnimationFrame(enhance)}).observe($('#app'),{childList:true,subtree:true});
window.addEventListener('hashchange',()=>setTimeout(enhance,0));enhance();
/* Tap a coupon hint chip at checkout: fills the coupon field (same as the app). */
document.addEventListener('click',e=>{
  const f=e.target.closest('[data-fill]');if(!f)return;
  const i=$('#f-cp');if(i&&!i.disabled){i.value=f.dataset.fill;i.focus()}
});
/* Copy: no toast, the chip itself confirms. The copied code is remembered and auto-applied on the checkout step. */
document.addEventListener('click',e=>{
  const b=e.target.closest('[data-copy]');if(!b)return;const v=b.dataset.copy,lb=$('.lb',b);
  const done=()=>{pend(v);if(!lb)return;lb.textContent='COPIED ✓';clearTimeout(b._t);b._t=setTimeout(()=>{lb.textContent='COPY'},1800)};
  const fb=()=>{try{const t=document.createElement('textarea');t.value=v;t.style.cssText='position:fixed;opacity:0';document.body.appendChild(t);t.select();const ok=document.execCommand('copy');t.remove();if(ok)done()}catch(x){}};
  navigator.clipboard?navigator.clipboard.writeText(v).then(done,fb):fb();
});
})();
