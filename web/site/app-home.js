/* Home page = the Homaclo app home screen (loaded last, so it replaces the older home layout).
   Same order as the app: location + coins strip, hero card, Before & After slider, Why Tank Cleaning Matters,
   Our Services (live list, same Book now buttons as the Services page), Our Cleaning Process, FAQs. */
(function(){
'use strict';
if(typeof homeView!=='function')return;

const FAQ=[
['How often should I clean my water tank?','We recommend cleaning your water tank at least once every 6 months. In Satna’s climate, twice a year ensures safe, clean water for your family.'],
['How long does the cleaning process take?','A standard 1000L tank takes approximately 2–3 hours. Larger tanks (1500L–2000L) may take 3–4 hours. Our technician will confirm the time estimate before starting.'],
['Is the antibacterial spray safe for drinking water?','Yes, absolutely. We use WHO-approved, food-grade antibacterial spray that is completely safe for drinking water after a 30-minute settling period.'],
['Do I need to be present during the cleaning?','We recommend being present or having a trusted adult at home. Our technician will call 30 minutes before arrival to confirm.'],
['What areas in Satna do you service?','We service all areas in Satna, MP including Civil Lines, Gandhi Nagar, Bharhut Nagar, Prem Nagar, Rewa Road, and all surrounding colonies.'],
['Do you provide a cleaning certificate?','Yes! We provide a TDS-tested cleaning certificate after every service. This includes before/after TDS readings for your records.']
];
const STEPS=[
['Complete Draining','Full water drainage using submersible pump to empty the tank completely.'],
['Sludge Extraction','Manual removal of accumulated sludge, sediment, and debris from tank floor.'],
['High-Pressure Washing','Industrial-grade high-pressure jet wash to remove stubborn stains and biofilm.'],
['Vacuum Cleaning','Industrial vacuum extraction of all loosened particles and dirty water.'],
['Antibacterial Spray','WHO-approved food-grade antibacterial spray applied on all inner surfaces.']
];
const RISKS=['Hair Fall & Scalp Damage from minerals & bacteria','Skin Allergies & Rashes from dirty water','Typhoid, Jaundice & stomach illness risk','Bad Odor & white limescale on taps'];
const GOOD=['Healthy Hair & Skin with purified water','100% Safe Drinking Water, bacteria-free','Extended Plumbing Life, no clogging','Fresh taste & zero foul odor'];
const esc=s=>String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');

function place(){
  let a='';
  try{a=(S.profile&&S.profile.location)||''}catch(e){}
  if(!a){try{const l=JSON.parse(sessionStorage.getItem('mx_loc')||'null');a=(l&&l.addr)||''}catch(e){}}
  return a;
}

homeView=function(){
  const a=place(),authed=!!(S&&S.user);
  return `<div class="ah fade">
  <div class="ah-strip">
    <a class="ah-chip ah-loc" href="${authed?'#/profile':'#/login'}" aria-label="Your location"><span class="ah-pin">📍</span><span class="ah-lt">${a?esc(a):'Set your location'}</span><span class="ah-dn">⌄</span></a>
    ${authed?`<a class="ah-chip ah-coin" href="#/profile" aria-label="Wallet coins"><span>🪙</span><b>${Number(S.coins||0)}</b></a>`:''}
  </div>
  <a class="ah-hero" href="#/book">
    <img class="ah-hero-img" src="img/maintix-8.png" alt="Water tank cleaning in Satna" fetchpriority="high">
    <span class="ah-ov"></span>
    <span class="ah-hero-c">
      <span class="ah-badge">🛡️ TDS Tested &amp; Certified</span>
      <h1>Professional Tank<br>Cleaning — Satna</h1>
      <span class="ah-sub">500L Overhead Plastic Tank Cleaning</span>
      <span class="ah-pr"><b>Starting ₹1,000</b><i>• 5-Stage Clean</i></span>
    </span>
  </a>
  <section class="ah-card ah-ba">
    <div class="ah-ba-h"><div><h2>Before &amp; After</h2><p>500L Overhead Plastic Tank Cleaning</p></div>
    <div class="ah-tg" role="group" aria-label="Before or after"><button type="button" data-ah="b">Before</button><button type="button" data-ah="a" class="on">After</button></div></div>
    <div class="ah-cmp" id="ahc" style="--p:46%">
      <img src="img/after.png" alt="Tank after cleaning" loading="lazy" draggable="false">
      <div class="ah-bf"><img src="img/before.png" alt="Tank before cleaning" loading="lazy" draggable="false"></div>
      <span class="ah-lb l">BEFORE</span><span class="ah-lb r">AFTER</span>
      <span class="ah-hd" aria-hidden="true"><span>⇄</span></span>
    </div>
  </section>
  <section class="ah-card ah-why"><h2>Why Tank Cleaning Matters</h2>
    <div class="ah-cols">
      <div><h3 class="bad">❌ Dirty Water Risks</h3><ul>${RISKS.map(x=>`<li class="bad">${esc(x)}</li>`).join('')}</ul></div>
      <div><h3 class="good">✓ Clean Water Benefits</h3><ul>${GOOD.map(x=>`<li class="good">${esc(x)}</li>`).join('')}</ul></div>
    </div>
  </section>
  <section class="ah-sv" id="hsv"><div class="ah-sh"><h2>Our Services</h2><span>Tap a service to get started</span></div>
    <div class="grid g3" id="svc"><div class="sk"></div><div class="sk"></div><div class="sk"></div></div>
  </section>
  <section class="ah-proc"><h2>Our Cleaning Process</h2><p>5-Stage professional tank cleaning</p>
    <ol>${STEPS.map((s,i)=>`<li><span class="n">${i+1}</span><div><small>STEP 0${i+1}</small><b>${esc(s[0])}</b><span>${esc(s[1])}</span></div></li>`).join('')}</ol>
  </section>
  <section class="ah-card ah-faq"><h2>Frequently Asked Questions</h2><p>Everything you need to know</p>
    ${FAQ.map(f=>`<details name="ahfaq"><summary>${esc(f[0])}<i>⌄</i></summary><div>${esc(f[1])}</div></details>`).join('')}
  </section>
  </div>`;
};

homeAfter=async function(){
  try{servicesAfter()}catch(e){}
};

/* Before / After slider: drag anywhere on the picture, or tap the Before / After buttons */
function setP(p){
  const c=document.getElementById('ahc');if(!c)return;
  p=Math.max(0,Math.min(100,p));
  c.style.setProperty('--p',p+'%');
  document.querySelectorAll('.ah-tg button').forEach(b=>b.classList.toggle('on',(b.dataset.ah==='b')===(p>=50)));
}
let drag=false;
function fromX(x){const c=document.getElementById('ahc');if(!c)return;const r=c.getBoundingClientRect();if(r.width)setP((x-r.left)/r.width*100)}
document.addEventListener('pointerdown',e=>{
  const c=e.target.closest&&e.target.closest('#ahc');if(!c)return;
  drag=true;try{c.setPointerCapture(e.pointerId)}catch(_){}
  fromX(e.clientX);
});
document.addEventListener('pointermove',e=>{if(drag)fromX(e.clientX)});
['pointerup','pointercancel'].forEach(t=>document.addEventListener(t,()=>{drag=false}));
document.addEventListener('click',e=>{
  const b=e.target.closest&&e.target.closest('[data-ah]');
  if(b)setP(b.dataset.ah==='b'?100:0);
});

/* styles */
const st=document.createElement('style');
st.id='ah-css';
st.textContent=`
.ah{max-width:980px;margin:0 auto;padding:14px 16px 44px;display:grid;gap:16px}
.ah h1,.ah h2,.ah h3{font-family:'Plus Jakarta Sans',system-ui,sans-serif;letter-spacing:0}
.ah-strip{display:flex;gap:12px;align-items:stretch}
.ah-chip{display:flex;align-items:center;gap:10px;min-height:54px;padding:0 18px;border-radius:18px;background:var(--sf);border:1px solid var(--line);box-shadow:var(--sh);font-weight:700;color:var(--ink)}
.ah-loc{flex:1;min-width:0}.ah-lt{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ah-pin{font-size:1.05rem}.ah-dn{color:var(--mut);font-weight:800}
.ah-coin b{font-size:1.15rem}
.ah-hero{position:relative;display:block;min-height:210px;border-radius:28px;overflow:hidden;color:#fff;border:1px solid rgba(15,185,168,.25);background:linear-gradient(135deg,#072654,#0a5a8a);box-shadow:0 12px 26px rgba(7,38,84,.35),0 0 36px rgba(15,185,168,.1)}
.ah-hero-img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
.ah-ov{position:absolute;inset:0;background:linear-gradient(90deg,rgba(7,38,84,.92) 0%,rgba(7,38,84,.55) 70%,rgba(15,185,168,.12) 100%)}
.ah-hero-c{position:relative;display:flex;flex-direction:column;align-items:flex-start;justify-content:center;gap:0;min-height:210px;padding:22px}
.ah-badge{padding:5px 12px;border-radius:20px;background:linear-gradient(90deg,#14d4c0,var(--cyan));font-size:.72rem;font-weight:800;letter-spacing:.2px;box-shadow:0 0 10px rgba(15,185,168,.4)}
.ah-hero h1{margin:12px 0 6px;font-size:clamp(1.4rem,5vw,2.2rem);font-weight:800;line-height:1.22;color:#fff}
.ah-sub{font-size:.85rem;color:rgba(255,255,255,.8)}
.ah-pr{display:flex;align-items:baseline;gap:8px;margin-top:14px}.ah-pr b{font-size:1.05rem;font-weight:800;color:#14d4c0}.ah-pr i{font-style:normal;font-size:.78rem;color:rgba(255,255,255,.7)}
.ah-card{background:var(--sf);border:1px solid var(--line);border-radius:22px;padding:18px;box-shadow:var(--sh)}
.ah-card h2,.ah-sv h2,.ah-proc h2{font-size:1.05rem;font-weight:800}
.ah-ba-h{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;margin-bottom:14px}
.ah-ba-h h2{font-size:1.3rem}.ah-ba-h p{color:var(--mut);font-size:.88rem;margin-top:2px;line-height:1.35}
.ah-tg{display:flex;flex:none;padding:4px;border-radius:99px;background:var(--bg);border:1px solid var(--line)}
.ah-tg button{border:0;background:transparent;color:var(--mut);font:700 .9rem inherit;font-family:inherit;padding:9px 16px;border-radius:99px;cursor:pointer}
.ah-tg button.on{background:#10b981;color:#fff}
.ah-cmp{position:relative;aspect-ratio:4/3;max-height:480px;margin:0 -18px -18px;overflow:hidden;border-radius:0 0 22px 22px;background:#0b2a52;touch-action:pan-y;user-select:none;-webkit-user-select:none;cursor:ew-resize}
.ah-cmp img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;pointer-events:none}
.ah-bf{position:absolute;inset:0;clip-path:inset(0 calc(100% - var(--p)) 0 0)}
.ah-hd{position:absolute;top:0;bottom:0;left:var(--p);width:2px;margin-left:-1px;background:#fff;display:grid;place-items:center}
.ah-hd span{width:52px;height:52px;border-radius:50%;background:#fff;color:#072654;display:grid;place-items:center;font-size:1.3rem;font-weight:800;box-shadow:0 6px 18px rgba(0,0,0,.3)}
.ah-lb{position:absolute;bottom:12px;padding:6px 12px;border-radius:10px;background:rgba(7,38,84,.7);color:#fff;font-size:.7rem;font-weight:800;letter-spacing:.06em}
.ah-lb.l{left:12px}.ah-lb.r{right:12px;background:rgba(16,185,129,.85)}
.ah-why h2{margin-bottom:14px}
.ah-cols{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.ah-why h3{font-size:.8rem;font-weight:800;margin-bottom:8px}.ah-why h3.bad{color:var(--err)}.ah-why h3.good{color:var(--ok)}
.ah-why ul{list-style:none;padding:0;display:grid;gap:7px}
.ah-why li{position:relative;padding-left:14px;font-size:.78rem;line-height:1.45;color:var(--mut)}
.ah-why li::before{content:"";position:absolute;left:0;top:.5em;width:6px;height:6px;border-radius:50%}
.ah-why li.bad::before{background:var(--err)}.ah-why li.good::before{background:var(--ok)}
.ah-sh{display:flex;justify-content:space-between;align-items:baseline;gap:10px;margin-bottom:12px;flex-wrap:wrap}
.ah-sh h2{font-size:1.1rem}.ah-sh span{font-size:.8rem;color:var(--mut)}
.ah-proc{background:var(--navy);color:#fff;border-radius:22px;padding:18px}
.ah-proc>p{font-size:.8rem;color:rgba(255,255,255,.6);margin:4px 0 16px}
.ah-proc ol{list-style:none;padding:0;display:grid;gap:0}
.ah-proc li{position:relative;display:flex;gap:14px;padding-bottom:16px}
.ah-proc li:not(:last-child)::before{content:"";position:absolute;left:17px;top:36px;bottom:0;width:2px;background:rgba(15,185,168,.3)}
.ah-proc li:last-child{padding-bottom:0}
.ah-proc .n{flex:none;width:36px;height:36px;border-radius:50%;background:var(--teal);display:grid;place-items:center;font-weight:800;box-shadow:0 2px 8px rgba(15,185,168,.3)}
.ah-proc small{display:block;font-size:.65rem;font-weight:800;letter-spacing:.12em;color:#14d4c0}
.ah-proc b{display:block;font-size:.95rem;margin:2px 0 4px}
.ah-proc li span:not(.n){display:block;font-size:.82rem;line-height:1.45;color:rgba(255,255,255,.65)}
.ah-faq>p{font-size:.8rem;color:var(--mut);margin:4px 0 14px}
.ah-faq details{border-bottom:1px solid var(--line);padding:4px 0}.ah-faq details:last-child{border-bottom:0}
.ah-faq summary{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:12px;border-radius:10px;font-weight:700;font-size:.88rem;cursor:pointer;list-style:none;background:var(--bg)}
.ah-faq summary::-webkit-details-marker{display:none}
.ah-faq summary i{font-style:normal;color:var(--mut);font-weight:800;transition:transform .2s}
.ah-faq details[open] summary{background:color-mix(in srgb,var(--teal) 12%,transparent);color:var(--teal)}
.ah-faq details[open] summary i{transform:rotate(180deg);color:var(--teal)}
.ah-faq details>div{padding:10px 12px 6px;font-size:.86rem;line-height:1.55;color:var(--mut)}
@media(min-width:760px){.ah{padding-top:26px;gap:20px}.ah-hero,.ah-hero-c{min-height:280px}.ah-hero-c{padding:36px 40px}.ah-hero h1{font-size:2.3rem}.ah-cmp{aspect-ratio:16/9}.ah-why li,.ah-why h3{font-size:.9rem}.ah-card,.ah-proc{padding:26px}.ah-cmp{margin:0 -26px -26px}}
@media(max-width:380px){.ah-cols{grid-template-columns:1fr}.ah-ba-h{flex-direction:column}}
`;
document.head.appendChild(st);
})();
