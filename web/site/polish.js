(function(){
'use strict';
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const A=(href,t)=>`<a href="${href}">${t}</a>`;
const plain=x=>x.replace(/<[^>]+>/g,'');

/* ---------- FAQ content (mirrors the website + app Terms, Privacy & Refund policy) ---------- */
function faqData(){return [
{c:'Booking & Services',i:[
 ['svc','What services does Homaclo offer?','Homaclo provides professional water tank cleaning for homes and businesses in Satna, including disinfection and sanitization with food-grade, eco-friendly cleaning agents. You can book 500L, 750L, 1000L, 1500L and 2000L tanks online.'],
 ['price','How much does tank cleaning cost?','Pricing is fixed by tank size: '+Object.entries(PRICES).map(([k,p])=>k+' '+inr(p)).join(', ')+'. Prices include applicable GST and there are no hidden charges.'],
 ['book','How do I book a cleaning?','Choose your tank size and quantity, pick a date and a 2-hour time slot, enter your address and phone number, then review and pay securely online. You sign in with your email using a one-time code, so no password is needed. '+A('#/book','Book now')],
 ['prep','What should I arrange before the visit?','Please make sure the technician can reach the tank and has access to water, and that you or a responsible adult is present. Our team contacts you 1–2 hours before the scheduled service.']
]},
{c:'Payments & Offers',i:[
 ['pay','Which payment methods are accepted?','Payments are processed securely by Razorpay. You can pay with UPI, debit or credit card, or netbanking. Homaclo does not store your card details.'],
 ['wel','How do I use the WEL100 coupon?','WEL100 gives ₹100 off your first booking. Copy it from the Offers section, then enter it in the Coupon code box on the Review & pay step. If you copied it on this device, it is applied for you automatically.'],
 ['bulk','Is there a discount for multiple tanks?','Yes. Book 3 or more tanks and ₹500 is taken off automatically at checkout. No code is needed.'],
 ['coins','How do reward coins work?','You receive 50 bonus coins when you sign up, 10 coins for every review you submit, and a monthly bonus of 50 coins. Each coin is worth ₹1, and you can redeem up to 50 coins per booking at checkout.'],
 ['nobook','Money was deducted but I cannot see my booking. What should I do?','Payment confirmation can take a short while. Please check '+A('#/bookings','My Bookings')+' after a few minutes before paying again. If the booking still does not appear, contact us with your payment reference. An accidental double payment, or money debited without a booking, is fully refundable.']
]},
{c:'Cancellation & Refunds',i:[
 ['cancel','Can I cancel a booking?','All confirmed bookings are final and non-cancellable, and refunds for a change of mind are not offered. For any special situation, please contact our support team. '+A('#/refund','Read the full policy')],
 ['refund','When will I get a refund?','Refunds are issued when Homaclo is unable to deliver the scheduled service (for example due to operational issues, technician unavailability, severe weather or unforeseen technical failures), and for accidental double or failed payments. Approved refunds are credited to your original payment source within 5–7 business days.'],
 ['quality','What if I am not satisfied with the cleaning?','Report it within 24 hours through the app or by email. We will re-inspect and re-service at no additional cost. The guarantee does not cover pre-existing tank damage or structural issues.']
]},
{c:'Account & Privacy',i:[
 ['login','How do I sign in?','Enter your email and we send you a one-time code. Enter the code and you are signed in. No password is required, and your account is created automatically on first sign-in.'],
 ['rev','Who can write a review?','Customers with a completed booking can write one review per booking and earn 10 coins. Reviews appear publicly after approval.'],
 ['data','Is my personal data safe?','We never sell or rent your personal information. Data is encrypted in transit and at rest, and shared only as needed for your service, such as technician details for an active booking. You can request access or deletion by emailing maintix.help@gmail.com. '+A('#/privacy','Privacy Policy')],
 ['contact','How can I contact Homaclo?','Email maintix.help@gmail.com or call +91 62622 62913. You can also reach us on WhatsApp from the footer. We are based in Satna, Madhya Pradesh.']
]}
]}
const item=x=>`<details class="fq"><summary>${x[1]}</summary><div class="fa">${x[2]}</div></details>`;
const HOME=['svc','price','book','pay','cancel','refund'];

function faqPage(){
  setTimeout(()=>{document.title='FAQs · Homaclo'},0);
  return `<div class="page"><div class="wrap fade" style="max-width:900px"><div class="head c"><span class="fq-k">HELP CENTRE</span><h1>Frequently asked questions</h1><p>Everything about booking, payments, offers and our policies.</p></div>
  <div class="fq-s"><input id="fq-q" type="search" placeholder="Search questions…" aria-label="Search FAQs"></div>
  ${faqData().map(g=>`<section class="fq-g"><h2>${h(g.c)}</h2>${g.i.map(item).join('')}</section>`).join('')}
  <p class="fq-none" id="fq-none">No matching questions. Try different words or contact us below.</p>
  <div class="fq-help"><h3>Still need help?</h3><p>Our team in Satna is happy to assist you.</p><div class="fq-btns"><a class="btn" href="https://wa.me/916262262913" target="_blank" rel="noopener">WhatsApp</a><a class="btn ghost" href="tel:+916262262913">Call</a><a class="btn ghost" href="mailto:maintix.help@gmail.com">Email</a></div></div></div></div>`;
}
Object.assign(ROUTES,{faq:'faq'});
const _lv=legalView;
legalView=function(k){return k==='faq'?faqPage():_lv(k)};
document.addEventListener('input',e=>{
  if(e.target.id!=='fq-q')return;
  const t=e.target.value.trim().toLowerCase();let any=false;
  $$('#app .fq').forEach(d=>{const m=!t||d.textContent.toLowerCase().includes(t);d.style.display=m?'':'none';if(m)any=true});
  $$('#app .fq-g').forEach(g=>{g.style.display=$$('.fq',g).some(d=>d.style.display!=='none')?'':'none'});
  const n=$('#fq-none');if(n)n.style.display=any?'none':'block';
});

/* Home: FAQ preview just above the closing call-to-action */
function homeFaq(){
  const band=$('#app .band');if(!band||$('#faqSec'))return;
  const all=faqData().flatMap(g=>g.i),l=HOME.map(id=>all.find(x=>x[0]===id)).filter(Boolean);
  const s=document.createElement('section');s.className='sec alt';s.id='faqSec';
  s.innerHTML=`<div class="wrap"><div class="head c"><h2>Frequently asked questions</h2><p>Quick answers before you book.</p></div><div class="fq-list">${l.map(item).join('')}</div><div class="fq-more"><a class="btn ghost" href="#/faq">View all FAQs →</a></div></div>`;
  band.closest('section').before(s);
}

/* Footer link + FAQPage structured data (once) */
function footLink(){
  const c=$$('.foot h5').find(x=>x.textContent.trim()==='Company');
  if(c&&!c.parentElement.querySelector('[href="#/faq"]')){const a=document.createElement('a');a.href='#/faq';a.textContent='FAQs';c.parentElement.append(a)}
  if(!$('#faq-ld')){
    const s=document.createElement('script');s.type='application/ld+json';s.id='faq-ld';
    s.textContent=JSON.stringify({'@context':'https://schema.org','@type':'FAQPage',mainEntity:faqData().flatMap(g=>g.i).map(x=>({'@type':'Question',name:x[1],acceptedAnswer:{'@type':'Answer',text:plain(x[2])}}))});
    document.head.appendChild(s);
  }
}

/* ---------- Home rating: never show a dash (same fallback as the Reviews page: database average, else 5.0) ---------- */
const _ha=homeAfter;
homeAfter=async function(){
  await _ha();
  const e=$('#st-r');if(e&&e.textContent.trim()==='—')e.textContent='5.0 ★';
};

/* ---------- Reviews page: compact layout, reviews grouped by service category (tabs) ----------
   reviews.js still renders the feed (#rfeed); here each card is sorted into a category from its service tag icon
   (💧 water tank, ☀️ solar cleaning, 🔧 solar repair) and only the chosen category is shown. Full review text is always visible. */
window.reviewsView=function(){
  return `<div class="page"><div class="wrap fade rvp">
  <div class="rv-hero"><div><span class="fq-k">CUSTOMER REVIEWS</span><h1>Trusted by families across Satna</h1><p>Real feedback from customers who booked Homaclo services.</p></div>
  <div class="rv-score"><div class="rv-n"><b id="rv-avg">5.0</b><span>★</span></div><div class="rv-st">★★★★★</div><small>Average rating</small></div></div>
  <div class="rv-stats"><div><b>500+</b><span>Happy customers</span></div><div><b>5.0</b><span>Average rating</span></div><div><b>100%</b><span>Satisfaction rate</span></div></div>
  <div class="rv-bar"><h2>What customers say</h2><button class="btn" data-rv="write">✍️ Write a review</button></div>
  <div id="rtabs" class="rv-tabs" role="tablist" aria-label="Review categories"></div>
  <div id="rfeed" class="rv-grid"><div class="sk"></div><div class="sk"></div><div class="sk"></div></div></div></div>`;
};
let RC='water';
const RCATS=[['water','💧','Water Tank'],['clean','☀️','Solar Cleaning'],['repair','🔧','Solar Repair']];
function cardCat(c){
  const tag=[...c.children].find(x=>x.tagName==='SPAN');
  const t=tag?tag.textContent:'';
  return t.indexOf('🔧')>-1?'repair':(t.indexOf('☀')>-1?'clean':'water');
}
function applyCat(){
  const feed=$('#rfeed'),tabs=$('#rtabs');if(!feed||!tabs)return;
  const cards=[...feed.children].filter(x=>!x.classList.contains('sk'));
  if(!cards.length)return;
  const n={water:0,clean:0,repair:0};
  cards.forEach(c=>{const k=cardCat(c);n[k]++;c.style.display=k===RC?'':'none'});
  const html=RCATS.map(x=>`<button type="button" role="tab" aria-selected="${x[0]===RC}" class="rv-tab${x[0]===RC?' on':''}" data-rc="${x[0]}">${x[1]} ${x[2]} <b>${n[x[0]]}</b></button>`).join('');
  if(tabs.innerHTML!==html)tabs.innerHTML=html;
}
document.addEventListener('click',e=>{
  const t=e.target.closest&&e.target.closest('[data-rc]');
  if(!t)return;
  RC=t.dataset.rc;applyCat();
});

/* ---------- Count-up numbers (real values only; animation just counts up to them) ---------- */
const RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
const io='IntersectionObserver' in window?new IntersectionObserver(es=>es.forEach(e=>{if(e.isIntersecting){io.unobserve(e.target);go(e.target)}}),{threshold:.35}):null;
function arm(el){
  if(RM||el.dataset.run||el._fin===el.textContent)return;
  const m=el.textContent.trim().match(/^(\D*?)(\d[\d,]*(?:\.\d+)?)(.*)$/);if(!m)return;
  const dec=(m[2].split('.')[1]||'').length,comma=m[2].includes(',');
  el._o=el.textContent;el._n=parseFloat(m[2].replace(/,/g,''));
  el._f=v=>m[1]+(comma?v.toLocaleString('en-IN',{minimumFractionDigits:dec,maximumFractionDigits:dec}):v.toFixed(dec))+m[3];
  el.dataset.run='1';el.textContent=el._f(0);
  if(io)io.observe(el);else go(el);
}
function go(el){
  const t0=performance.now(),D=1200;
  const step=t=>{
    const p=Math.min(1,(t-t0)/D),v=el._n*(1-Math.pow(1-p,3));
    if(p<1){el.textContent=el._f(v);requestAnimationFrame(step)}
    else{el.textContent=el._o;el._fin=el._o;delete el.dataset.run}
  };
  requestAnimationFrame(step);
}

let q=0;
function run(){homeFaq();footLink();applyCat();$$('#app .stat b,#app .rv-stats b,#app .rv-n b').forEach(arm)}
new MutationObserver(()=>{cancelAnimationFrame(q);q=requestAnimationFrame(run)}).observe($('#app'),{childList:true,subtree:true,characterData:true});
window.addEventListener('hashchange',()=>setTimeout(run,0));run();
})();
