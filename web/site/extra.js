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
  <div class="bn"><h4>✓ Clean water benefits</h4><ul>${L(['Healthier hair and skin','Safe, bacteria-free drinking water','Longer plumbing life, less clogging','Fresh taste, zero foul odour'])}</ul></div></div>
  <div class="promo"><div class="pc"><div><b>WEL100</b><small>₹100 off your first booking</small></div><button data-copy="WEL100">Copy</button></div><div class="pc"><div><b>TANK500</b><small>₹500 off on 3+ tanks</small></div><button data-copy="TANK500">Copy</button></div></div></div>`;
  hr.closest('section').before(s);
  const ba=$('.ba',s),r=$('input',ba);r.oninput=()=>ba.style.setProperty('--p',r.value+'%');
}
function enhance(){
  proof();
  $$('#svc .card').forEach(c=>{if(!$('a[href="#/book"]',c)&&!$('.soon',c)){const b=$('.btn',c);if(b)b.outerHTML='<span class="soon">Coming soon</span>'}});
  const rl=$('#ravg');if(rl&&!$('.trust')){const t=document.createElement('div');t.className='trust';t.innerHTML='<span class="bdg">⭐ Verified reviews</span><span class="bdg g">💯 100% Satisfaction Rate</span>';rl.closest('.head').after(t)}
  $$('#rl .card,#hrev .card').forEach(c=>{if(!$('.vb',c)&&$('p',c))c.insertAdjacentHTML('beforeend','<span class="vb">✔ Verified Satna customer</span>')});
  const s=$('.sum');if(s&&!s.classList.contains('dr')){s.classList.add('dr');const t=$('.line.t',s);const d=document.createElement('div');d.className='dh';d.innerHTML='<span>Order summary ▴</span><span>'+(t?t.lastElementChild.textContent:'')+'</span>';s.prepend(d);d.onclick=()=>s.classList.toggle('open')}
  const a=(location.hash.replace(/^#\/?/,'').split('?')[0])||'';
  $$('.bnav a').forEach(x=>x.classList.toggle('on',x.dataset.r===(a||'home')));
}
let q=0;new MutationObserver(()=>{cancelAnimationFrame(q);q=requestAnimationFrame(enhance)}).observe($('#app'),{childList:true,subtree:true});
window.addEventListener('hashchange',()=>setTimeout(enhance,0));enhance();
document.addEventListener('click',e=>{const b=e.target.closest('[data-copy]');if(!b)return;const v=b.dataset.copy;(navigator.clipboard?navigator.clipboard.writeText(v):Promise.reject()).then(()=>{b.textContent='Copied ✓';if(typeof toast==='function')toast(v+' copied');setTimeout(()=>b.textContent='Copy',1800)}).catch(()=>{if(typeof toast==='function')toast('Code: '+v)})});
})();
