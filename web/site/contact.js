(function(){
'use strict';
/* Contact Us page: professional contact form saved to Supabase (public.contact_messages, insert-only for visitors). */
const $=(s,e=document)=>e.querySelector(s);
const EMAIL='homaclo.official@gmail.com';
const IG='https://www.instagram.com/homaclo/',YT='https://www.youtube.com/@homaclo';
const ICON={
 mail:'<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/></svg>',
 phone:'<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 1.9.7 2.8a2 2 0 0 1-.5 2.1L8 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.8.7a2 2 0 0 1 1.7 2z"/></svg>',
 pin:'<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/></svg>',
 ig:'<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r="1" fill="currentColor" stroke="none"/></svg>',
 yt:'<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" aria-hidden="true"><path d="M23.5 6.2a3 3 0 0 0-2.1-2.1C19.5 3.6 12 3.6 12 3.6s-7.5 0-9.4.5A3 3 0 0 0 .5 6.2C0 8.1 0 12 0 12s0 3.9.5 5.8a3 3 0 0 0 2.1 2.1c1.9.5 9.4.5 9.4.5s7.5 0 9.4-.5a3 3 0 0 0 2.1-2.1c.5-1.9.5-5.8.5-5.8s0-3.9-.5-5.8zM9.6 15.6V8.4l6.2 3.6-6.2 3.6z"/></svg>',
 ok:'<svg viewBox="0 0 24 24" width="34" height="34" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>'
};
const st=document.createElement('style');
st.textContent=
'.ct-head{text-align:center;max-width:640px;margin:0 auto 38px}.ct-head h1{font-size:clamp(2rem,4.5vw,3rem);margin:10px 0 12px}.ct-head p{color:var(--mut)}'+
'.ct-g{display:grid;grid-template-columns:minmax(0,.8fr) minmax(0,1.2fr);gap:24px;align-items:start;max-width:1040px;margin:0 auto}'+
'.ct-info{background:linear-gradient(160deg,#04132e,#072654 60%,#0a3b66);color:#fff;border:0;padding:34px 30px}.ct-info h3{color:#fff;margin-bottom:6px}.ct-info>p{color:#a9c0e2;font-size:.92rem;margin-bottom:14px}'+
'.ct-row{display:flex;gap:14px;align-items:center;padding:12px 0;color:#fff}a.ct-row:hover .ct-ic{background:rgba(34,211,238,.25)}'+
'.ct-ic{width:46px;height:46px;border-radius:14px;background:rgba(255,255,255,.12);display:grid;place-items:center;flex:none;color:#22d3ee;transition:.2s}'+
'.ct-row small{display:block;color:#a9c0e2;font-size:.74rem;letter-spacing:.04em;text-transform:uppercase;font-weight:700}.ct-row b{font-size:.96rem;word-break:break-word}'+
'.ct-sep{height:1px;background:rgba(255,255,255,.14);margin:18px 0}.ct-info h4{color:#fff;margin-bottom:12px}'+
'.ct-info .soc-r{display:flex;gap:10px}.ct-info .soc-r a.sb{display:inline-flex;align-items:center;justify-content:center;width:44px;height:44px;border-radius:12px;border:1px solid rgba(255,255,255,.25);background:rgba(255,255,255,.08);color:#fff;margin:0;transition:.2s}'+
'.ct-form{padding:34px 30px}.ct-form h3{margin-bottom:4px}.ct-2{display:grid;grid-template-columns:1fr 1fr;gap:14px}.ct-form select{appearance:auto}'+
'.ct-hp{position:absolute;left:-9999px;width:1px;height:1px;overflow:hidden}.ct-err{color:var(--err);font-size:.88rem;min-height:1.3em;margin:10px 0 4px}.ct-form .btn{margin-top:6px;min-height:52px}'+
'.ct-done{text-align:center;padding:30px 10px}.ct-done .ok-ic{width:72px;height:72px;border-radius:50%;margin:0 auto 18px;display:grid;place-items:center;background:color-mix(in srgb,var(--ok) 16%,transparent);color:var(--ok)}.ct-done p{color:var(--mut);margin:8px 0 22px}'+
'@media(max-width:900px){.ct-g{grid-template-columns:1fr}}@media(max-width:520px){.ct-2{grid-template-columns:1fr}.ct-info,.ct-form{padding:26px 20px}}';
document.head.appendChild(st);

const TOPICS=['Booking enquiry','Pricing & services','Payment or refund','Feedback','Partnership','Other'];
function contactView(){
  const u=(typeof S!=='undefined'&&S.user)?S.user:null,p=(typeof S!=='undefined'&&S.profile)||{};
  const nm=h(p.full_name||''),em=h((u&&u.email)||''),ph=h(p.phone_number||'');
  return `<div class="page"><div class="wrap fade">
  <div class="ct-head"><span class="fq-k">CONTACT US</span><h1>We’d love to hear from you</h1><p>Questions about a booking, pricing or our services? Send us a message and we’ll reply by email.</p></div>
  <div class="ct-g">
  <aside class="ct-info card"><h3>Get in touch</h3><p>Reach us any way that suits you.</p>
    <a class="ct-row" href="mailto:${EMAIL}"><span class="ct-ic">${ICON.mail}</span><span><small>Email</small><b>${EMAIL}</b></span></a>
    <a class="ct-row" href="tel:+916262262913"><span class="ct-ic">${ICON.phone}</span><span><small>Phone</small><b>+91 62622 62913</b></span></a>
    <div class="ct-row"><span class="ct-ic">${ICON.pin}</span><span><small>Location</small><b>Satna, Madhya Pradesh, India</b></span></div>
    <div class="ct-sep"></div><h4>Follow us</h4>
    <div class="soc-r"><a class="sb ig" href="${IG}" target="_blank" rel="noopener" aria-label="Homaclo on Instagram">${ICON.ig}</a><a class="sb yt" href="${YT}" target="_blank" rel="noopener" aria-label="Homaclo on YouTube">${ICON.yt}</a></div>
  </aside>
  <form class="ct-form card" id="ct-form" novalidate>
    <h3>Send us a message</h3><p class="muted small">Fill in the form and our team will get back to you.</p>
    <div class="ct-2"><div><label for="ct-n">Full name</label><input id="ct-n" autocomplete="name" maxlength="100" placeholder="Your name" value="${nm}"></div>
    <div><label for="ct-p">Phone <span class="muted" style="font-weight:500">(optional)</span></label><input id="ct-p" inputmode="tel" autocomplete="tel" maxlength="20" placeholder="Mobile number" value="${ph}"></div></div>
    <label for="ct-e">Email address</label><input id="ct-e" type="email" inputmode="email" autocomplete="email" maxlength="200" placeholder="you@example.com" value="${em}">
    <label for="ct-s">Topic</label><select id="ct-s">${TOPICS.map(t=>`<option>${h(t)}</option>`).join('')}</select>
    <label for="ct-m">Message</label><textarea id="ct-m" rows="5" maxlength="3000" placeholder="How can we help you?"></textarea>
    <div class="ct-hp" aria-hidden="true"><label for="ct-hp">Leave empty</label><input id="ct-hp" tabindex="-1" autocomplete="off"></div>
    <p class="ct-err" role="alert"></p>
    <button class="btn block" id="ct-go" type="submit">Send message →</button>
  </form></div></div></div>`;
}
const _lv=legalView;
legalView=function(k){return k==='contact'?contactView():_lv(k)};

const LS=(k,v)=>{try{if(v===undefined)return localStorage.getItem(k);localStorage.setItem(k,v)}catch(e){return null}};
document.addEventListener('submit',async e=>{
  const f=e.target;if(!f||f.id!=='ct-form')return;
  e.preventDefault();
  const v=id=>((f.querySelector('#'+id)||{}).value||'').trim();
  if(v('ct-hp'))return;
  const err=f.querySelector('.ct-err'),go=f.querySelector('#ct-go');
  const name=v('ct-n'),email=v('ct-e').toLowerCase(),phone=v('ct-p').replace(/[^\d+ ]/g,'').trim(),subject=v('ct-s'),message=v('ct-m');
  const bad=name.length<2?'Please enter your name.':!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)?'Please enter a valid email address.':(phone&&phone.replace(/\D/g,'').length<7)?'Please enter a valid phone number or leave it empty.':message.length<10?'Please write at least 10 characters in your message.':'';
  if(bad){err.textContent=bad;return}
  if(Date.now()-Number(LS('mx_ct_t')||0)<30000){err.textContent='Please wait a few seconds before sending another message.';return}
  err.textContent='';go.disabled=true;go.textContent='Sending…';
  let error=null;
  try{({error}=await sb.from('contact_messages').insert({name,email,phone:phone||null,subject,message}))}catch(x){error=x}
  if(error){err.textContent='Could not send your message. Please try again, or email us at '+EMAIL+'.';go.disabled=false;go.textContent='Send message →';return}
  LS('mx_ct_t',String(Date.now()));
  f.innerHTML=`<div class="ct-done"><div class="ok-ic">${ICON.ok}</div><h3>Message sent</h3><p>Thank you, ${h(name.split(' ')[0])}. We have received your message and will reply to ${h(email)}.</p><button class="btn ghost" type="button" data-ct="again">Send another message</button></div>`;
});
document.addEventListener('click',e=>{
  if(e.target.closest&&e.target.closest('[data-ct="again"]'))route();
});
})();
