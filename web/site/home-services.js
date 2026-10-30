/* Home page: "Our services" section (loaded after the other site scripts).
   - Adds a professional services showcase (Water Tank Cleaning, Solar Panel Cleaning, Solar Maintenance & Repair)
     between the stats strip and "How it works". The main hero heading is NOT changed.
   - Prices and booking links match the Services page and booking flows (final.js / repair.js).
   - Any other service found in the Supabase `services` table is listed below as "coming soon", so the home page stays in sync. */
(function(){
'use strict';
if(typeof homeView!=='function')return;

const SVC=[
 {img:'img/maintix-10.png',icon:'💧',title:'Water Tank Cleaning',alt:'Homaclo technician cleaning a water tank',
  desc:'Complete cleaning and sanitisation of overhead and underground tanks, using food-grade, eco-friendly agents.',
  pts:['Tank sizes from 500L to 2000L','High-pressure wash and sludge removal','TDS meter check after cleaning'],
  price:'₹1,000',unit:'starting price',cta:'Book tank cleaning',href:'#/book',act:''},
 {img:'img/maintix-9.png',icon:'☀️',title:'Solar Panel Cleaning',alt:'Homaclo technician cleaning rooftop solar panels',
  desc:'Professional cleaning for home and commercial solar systems, so your panels keep generating at their best.',
  pts:['Systems from 3 kW to 30 kW','Simple pricing, ₹100 per panel','Pick your own date and time slot'],
  price:'₹100',unit:'per panel',cta:'Book panel cleaning',href:'#/book?s=solar',act:'solbook'},
 {img:'img/maintix-7.png',icon:'🔧',title:'Solar Maintenance & Repair',alt:'Homaclo technician inspecting a rooftop solar installation',
  desc:'Fault finding and repair for your solar system, handled by a trained technician at your doorstep.',
  pts:['Inverter, ACDB and DCDB faults','Low voltage and low output checks','Wiring, earthing and monitoring issues'],
  price:'₹1,000',unit:'flat service charge',cta:'Book a repair visit',href:'#/book',act:'rbook'}
];

const li=a=>a.map(x=>`<li>${x}</li>`).join('');
const card=s=>`<article class="card hov hsv-c"><div class="hsv-im"><img src="${s.img}" alt="${s.alt}" loading="lazy" decoding="async" width="640" height="400" onerror="this.parentNode.classList.add('noimg')"><span class="hsv-ic" aria-hidden="true">${s.icon}</span></div>`+
 `<div class="hsv-b"><h3>${s.title}</h3><p class="muted small">${s.desc}</p><ul>${li(s.pts)}</ul>`+
 `<div class="hsv-f"><div class="hsv-p"><b>${s.price}</b><span>${s.unit}</span></div><a class="btn sm" href="${s.href}"${s.act?` data-act="${s.act}"`:''}>${s.cta}</a></div></div></article>`;

const SECTION=`<section class="sec alt hsv" id="hsv"><div class="wrap"><div class="head c"><span class="hsv-k">OUR SERVICES</span><h2>Complete care for your water and solar systems</h2><p>Book trusted, professionally handled services online, with clear pricing and secure payment.</p></div>`+
 `<div class="grid hsv-g">${SVC.map(card).join('')}</div>`+
 `<div class="hsv-x" id="hsx"></div>`+
 `<div class="hsv-tr"><span>✔ Fixed, upfront pricing</span><span>✔ Trained technicians</span><span>✔ Secure Razorpay payments</span><span>✔ Doorstep service in Satna</span></div>`+
 `<div class="hsv-more"><a class="btn ghost" href="#/services">View all services →</a></div></div></section>\n  `;

const ANCHOR='<section class="sec"><div class="wrap"><div class="head c"><h2>How it works</h2>';

const _hv=homeView;
homeView=function(){
  let html=_hv();
  /* hero: keep the main heading, but make the small label and intro mention the other services too */
  html=html
    .replace(/SATNA.S TRUSTED TANK CLEANING/,'SATNA’S TRUSTED HOME SERVICES')
    .replace('Professional, hygienic water tank cleaning with transparent pricing and doorstep service. Book in under two minutes.',
             'Professional, hygienic water tank cleaning, plus solar panel cleaning and repair, with transparent pricing and doorstep service. Book in under two minutes.');
  const i=html.indexOf(ANCHOR);
  return i<0?html:html.slice(0,i)+SECTION+html.slice(i);
};

/* other services from the database (anything that is not tank / solar) are shown as "coming soon" */
async function extras(){
  if(!document.getElementById('hsx'))return;
  try{
    const {data}=await sb.from('services').select('*').order('price',{ascending:true});
    const box=document.getElementById('hsx');if(!box)return;
    const more=(data||[]).filter(s=>s&&s.title&&!/tank|solar/i.test(s.title));
    if(!more.length)return;
    box.innerHTML=`<h4 class="hsv-xh">More services on the way</h4><div class="hsv-xg">${more.map(s=>`<div class="card hov"><span class="pill">Coming soon</span><h4 style="margin:10px 0 4px">${h(s.title)}</h4><p class="muted small">${h(s.description||'')}</p></div>`).join('')}</div>`;
  }catch(e){}
}
const _ha=homeAfter;
homeAfter=async function(){
  extras();
  return _ha();
};

/* styles */
const st=document.createElement('style');
st.textContent=`
.hsv-k{display:inline-block;padding:5px 13px;border-radius:99px;background:color-mix(in srgb,var(--teal) 14%,transparent);color:var(--teal);font-size:.74rem;font-weight:800;letter-spacing:.09em;margin-bottom:14px}
.hsv-g{grid-template-columns:repeat(3,1fr);align-items:stretch}
.hsv-c{padding:0;overflow:hidden;display:flex;flex-direction:column}
.hsv-im{position:relative;aspect-ratio:16/10;background:linear-gradient(135deg,var(--navy),#0a3b66);overflow:hidden}
.hsv-im img{width:100%;height:100%;object-fit:cover;display:block;transition:transform .5s ease}
.hsv-c:hover .hsv-im img{transform:scale(1.05)}
.hsv-im.noimg img{display:none}
.hsv-ic{position:absolute;top:14px;left:14px;width:44px;height:44px;border-radius:13px;display:grid;place-items:center;font-size:1.35rem;background:rgba(255,255,255,.94);box-shadow:0 6px 16px rgba(4,19,46,.25)}
.hsv-b{padding:22px 22px 24px;display:flex;flex-direction:column;flex:1}
.hsv-b h3{font-size:1.2rem;margin-bottom:8px}
.hsv-b ul{list-style:none;padding:0;margin:14px 0 20px;display:grid;gap:8px}
.hsv-b li{position:relative;padding-left:24px;font-size:.88rem;line-height:1.45}
.hsv-b li::before{content:"✓";position:absolute;left:0;top:0;color:var(--teal);font-weight:800}
.hsv-f{margin-top:auto;display:flex;align-items:center;justify-content:space-between;gap:12px;padding-top:16px;border-top:1px dashed var(--line)}
.hsv-p b{display:block;font:700 1.5rem Fraunces,Georgia,serif;color:var(--teal);line-height:1.1}
.hsv-p span{font-size:.75rem;color:var(--mut)}
.hsv-f .btn{white-space:nowrap}
.hsv-tr{display:flex;flex-wrap:wrap;justify-content:center;gap:10px 26px;margin-top:34px;font-size:.88rem;font-weight:600;color:var(--mut)}
.hsv-more{text-align:center;margin-top:28px}
.hsv-x:empty{display:none}
.hsv-x{margin-top:28px}
.hsv-xh{margin-bottom:12px}
.hsv-xg{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px}
.hsv-xg .card{padding:18px 20px}
@media(max-width:900px){.hsv-g{grid-template-columns:1fr;max-width:560px;margin-inline:auto}}
@media(max-width:520px){.hsv-im{aspect-ratio:16/9}.hsv-b{padding:18px 18px 20px}.hsv-tr{flex-direction:column;align-items:center;gap:8px}}
`;
document.head.appendChild(st);
})();
