/* Home page: "Our services" section (loaded after the other site scripts).
   - Shows the complete "All services" list on the home page, between the stats strip and "How it works".
     It is the same live list and the same cards as the Services page (servicesAfter() fills #svc), so prices, images
     and Book now buttons always match. The main hero heading is NOT changed. */
(function(){
'use strict';
if(typeof homeView!=='function')return;

const SECTION=`<section class="sec alt hsv" id="hsv"><div class="wrap"><div class="head c"><span class="hsv-k">OUR SERVICES</span><h2>Complete care for your water and solar systems</h2><p>Book trusted, professionally handled services online, with clear pricing and secure payment.</p></div>`+
 `<div class="grid g3" id="svc"><div class="sk"></div><div class="sk"></div><div class="sk"></div></div>`+
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

/* fill the services list with the same data and cards as the Services page */
const _ha=homeAfter;
homeAfter=async function(){
  servicesAfter();
  return _ha();
};

/* Home page only: no "Call to enquire" buttons on the service cards (Book now stays).
   The Services page is not touched, because it lives outside #hsv. */
function dropCall(){
  document.querySelectorAll('#hsv #svc a,#hsv #svc button').forEach(x=>{
    if(/^tel:/i.test(x.getAttribute('href')||'')||/call\s*to\s*enquire/i.test(x.textContent))x.remove();
  });
}
const appEl=document.getElementById('app');
if(appEl)new MutationObserver(()=>requestAnimationFrame(dropCall)).observe(appEl,{childList:true,subtree:true});
dropCall();

/* styles */
const st=document.createElement('style');
st.textContent=`
#hsv #svc a[href^="tel:"]{display:none!important}
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
