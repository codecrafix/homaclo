(function(){
'use strict';
/* Contact Us page: professional contact form saved to Supabase (public.contact_messages, insert-only for visitors). */
const $=(s,e=document)=>e.querySelector(s);
const EMAIL='homaclo.official@gmail.com';
const OK_ICON='<svg viewBox="0 0 24 24" width="34" height="34" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>';
const st=document.createElement('style');
st.textContent=
'.ct-head{text-align:center;max-width:640px;margin:0 auto 38px}.ct-head h1{font-size:clamp(2rem,4.5vw,3rem);margin:10px 0 12px}.ct-head p{color:var(--mut)}'+
'.ct-g{max-width:640px;margin:0 auto}'+
'.ct-form{padding:34px 30px}.ct-form h3{margin-bottom:4px}.ct-2{display:grid;grid-template-columns:1fr 1fr;gap:14px}.ct-form select{appearance:auto}'+
'.ct-hp{position:absolute;left:-9999px;width:1px;height:1px;overflow:hidden}.ct-err{color:var(--err);font-size:.88rem;min-height:1.3em;margin:10px 0 4px}.ct-form .btn{margin-top:6px;min-height:52px}'+
'.ct-done{text-align:center;padding:30px 10px}.ct-done .ok-ic{width:72px;height:72px;border-radius:50%;margin:0 auto 18px;display:grid;place-items:center;background:color-mix(in srgb,var(--ok) 16%,transparent);color:var(--ok)}.ct-done p{color:var(--mut);margin:8px 0 22px}'+
'.ct-info{margin-top:20px;padding:24px 26px}.ct-info h3{margin-bottom:10px}.ct-info .line{align-items:flex-start}.ct-info .line b{text-align:right}.ct-info a{color:var(--teal);text-decoration:underline}'+
'@media(max-width:520px){.ct-2{grid-template-columns:1fr}.ct-form{padding:26px 20px}.ct-info{padding:20px}}';
document.head.appendChild(st);

const TOPICS=['Booking enquiry','Pricing & services','Payment or refund','Feedback','Partnership','Other'];
function contactView(){
  const u=(typeof S!=='undefined'&&S.user)?S.user:null,p=(typeof S!=='undefined'&&S.profile)||{};
  const nm=h(p.full_name||''),em=h((u&&u.email)||''),ph=h(p.phone_number||'');
  return `<div class="page"><div class="wrap fade">
  <div class="ct-head"><span class="fq-k">CONTACT US</span><h1>We’d love to hear from you</h1><p>Questions about a booking, pricing or our services? Send us a message and we’ll reply by email.</p></div>
  <div class="ct-g">
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
  </form>
  <div class="ct-info card"><h3>Business details</h3>
    <div class="line"><span class="muted">📧 Email</span><b><a href="mailto:${EMAIL}">${EMAIL}</a></b></div>
    <div class="line"><span class="muted">📞 Phone</span><b><a href="tel:+916262262913">+91 62622 62913</a></b></div>
    <div class="line"><span class="muted">📍 Address</span><b>Jawahar Nagar, Satna, Madhya Pradesh, India</b></div>
  </div></div></div></div>`;
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
  f.innerHTML=`<div class="ct-done"><div class="ok-ic">${OK_ICON}</div><h3>Message sent</h3><p>Thank you, ${h(name.split(' ')[0])}. We have received your message and will reply to ${h(email)}.</p><button class="btn ghost" type="button" data-ct="again">Send another message</button></div>`;
});
document.addEventListener('click',e=>{
  if(e.target.closest&&e.target.closest('[data-ct="again"]'))route();
});
})();
