(function(){
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const L=a=>a.map(x=>`<li>${x}</li>`).join('');
function proof(){
  const hr=$('#hrev');if(!hr||$('#proof'))return;
  const s=document.createElement('section');s.id='proof';s.className='sec alt';
  s.innerHTML=`<div class="wrap"><div class="head c"><h2>Real work proof</h2><p>Drag the slider: muddy tank before, hygienic tank after.</p></div>
  <div class="ba"><img class="after" src="img/after.png" alt="Tank after Maintix cleaning" loading="lazy"><img class="before" src="img/before.png" alt="Tank before cleaning" loading="lazy"><span class="tg b">BEFORE</span><span class="tg a">AFTER ✨</span><input type="range" min="0" max="100" value="50" aria-label="Before and after slider"></div>
  <div class="head" style="margin:56px 0 24px"><h2>Why tank cleaning matters</h2></div>
  <div class="rb"><div class="rk"><h4>✕ Dirty water risks</h4><ul>${L(['Hair fall and scalp damage from minerals and bacteria','Skin allergies and rashes','Typhoid, jaundice and stomach illness risk','Bad odour and limescale on taps'])}</ul></div>
  <div class="bn"><h4>✓ Clean water benefits</h4><ul>${L(['Healthier hair and skin','Safe, bacteria-free drinking water','Longer plumbing life, less clogging','Fresh taste, zero foul odour'])}</ul></div></div></div>`;
  hr.closest('section').before(s);
  const ba=$('.ba',s),r=$('input',ba);r.oninput=()=>ba.style.setProperty('--p',r.value+'%');
}

/* ---------- Offers & coupons (Profile) + auto-apply at checkout ---------- */
(function(){const st=document.createElement('style');st.textContent=
'#offers .pc{margin-top:12px}#offers .pc.off{opacity:.55;border-style:solid}#offers .pc button.ok{background:var(--ok);border-color:var(--ok);color:#fff}'+
'#offers .tag{display:inline-block;margin-top:6px;padding:2px 10px;border-radius:99px;font-size:.72rem;font-weight:700;background:color-mix(in srgb,var(--teal) 16%,transparent);color:var(--teal)}'+
'#offers .oh{margin:16px 0 0;padding-left:20px;font-size:.88rem;color:var(--mut)}#offers .oh li{padding:3px 0}';
document.head.appendChild(st)})();
const PK='mx_pending_coupon';
function pend(v){try{if(v===undefined)return localStorage.getItem(PK);if(v===null)localStorage.removeItem(PK);else localStorage.setItem(PK,v)}catch(e){return null}}
const OFFER_TXT={WEL100:'₹100 off your first booking'};
async function offers(){
  const ctx=$('#ctx');if(!ctx||$('#offers')||!S.user)return;
  const card=document.createElement('div');card.id='offers';card.className='card';
  card.innerHTML='<h4>🏷️ Offers &amp; coupons</h4><p class="muted small" style="margin-top:8px">Loading offers…</p>';
  ctx.closest('.card').after(card);
  let list=[],used=false;
  try{
    const [c,b]=await Promise.all([sb.from('coupons').select('code,discount_amount,expires_at,max_uses,used_count').eq('is_active',true),sb.from('bookings').select('id').eq('user_id',S.user.id).limit(1)]);
    list=(c.data||[]).filter(x=>(!x.expires_at||new Date(x.expires_at)>new Date())&&(x.max_uses==null||(x.used_count||0)<x.max_uses));
    used=!!(b.data&&b.data.length);
  }catch(e){}
  if(!$('#offers'))return;
  const cp=list.map(x=>{
    const first=x.code==='WEL100',gone=first&&used;
    return `<div class="pc${gone?' off':''}"><div><b>${h(x.code)}</b><small>${h(OFFER_TXT[x.code]||inr(x.discount_amount||0)+' off')}</small>${gone?'<span class="tag">Already used</span>':''}</div>${gone?'':`<button data-copy="${h(x.code)}">Copy</button>`}</div>`;
  }).join('');
  card.innerHTML=`<h4>🏷️ Offers &amp; coupons</h4>${cp||'<p class="muted small" style="margin-top:8px">No coupon codes are active right now.</p>'}
  <div class="pc"><div><b>3+ tanks</b><small>₹500 off on 3 or more tanks</small><span class="tag">Applied automatically</span></div></div>
  <ol class="oh"><li>Tap <b>Copy</b> on a coupon.</li><li>Book a cleaning and go to <b>Review &amp; pay</b>.</li><li>Your code is applied automatically (or paste it in <i>Coupon code</i>).</li></ol>`;
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

function enhance(){
  proof();offers();autoApply();
  $$('#svc .card').forEach(c=>{if(!$('a[href="#/book"]',c)&&!$('.soon',c)){const b=$('.btn',c);if(b)b.outerHTML='<span class="soon">Coming soon</span>'}});
  const rl=$('#ravg');if(rl&&!$('.trust')){const t=document.createElement('div');t.className='trust';t.innerHTML='<span class="bdg">⭐ Verified reviews</span><span class="bdg g">💯 100% Satisfaction Rate</span>';rl.closest('.head').after(t)}
  $$('#rl .card,#hrev .card').forEach(c=>{if(!$('.vb',c)&&$('p',c))c.insertAdjacentHTML('beforeend','<span class="vb">✔ Verified Satna customer</span>')});
  const s=$('.sum');if(s&&!s.classList.contains('dr')){s.classList.add('dr');const t=$('.line.t',s);const d=document.createElement('div');d.className='dh';d.innerHTML='<span>Order summary ▴</span><span>'+(t?t.lastElementChild.textContent:'')+'</span>';s.prepend(d);d.onclick=()=>s.classList.toggle('open')}
  const a=(location.hash.replace(/^#\/?/,'').split('?')[0])||'';
  $$('.bnav a').forEach(x=>x.classList.toggle('on',x.dataset.r===(a||'home')));
}
let q=0;new MutationObserver(()=>{cancelAnimationFrame(q);q=requestAnimationFrame(enhance)}).observe($('#app'),{childList:true,subtree:true});
window.addEventListener('hashchange',()=>setTimeout(enhance,0));enhance();
/* Copy: no toast, the button itself confirms. The copied code is remembered and auto-applied on the checkout step. */
document.addEventListener('click',e=>{
  const b=e.target.closest('[data-copy]');if(!b)return;const v=b.dataset.copy;
  const done=()=>{pend(v);b.textContent='Copied ✓';b.classList.add('ok');clearTimeout(b._t);b._t=setTimeout(()=>{b.textContent='Copy';b.classList.remove('ok')},1800)};
  const fb=()=>{try{const t=document.createElement('textarea');t.value=v;t.style.cssText='position:fixed;opacity:0';document.body.appendChild(t);t.select();const ok=document.execCommand('copy');t.remove();ok?done():b.textContent=v}catch(x){b.textContent=v}};
  navigator.clipboard?navigator.clipboard.writeText(v).then(done,fb):fb();
});
})();
