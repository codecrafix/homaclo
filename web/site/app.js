'use strict';
const SB_URL='https://hudlucmsjyjilkjpviva.supabase.co';
const SB_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1ZGx1Y21zanlqaWxranB2aXZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwMDQwMzksImV4cCI6MjEwMzU4MDAzOX0.nEoVQzbJYD8EF5fQ168KPheIeJRpZMRm02D2zynn86M';
const RZP_FALLBACK='rzp_test_TVv2X2c32eqwCg';
const sb=supabase.createClient(SB_URL,SB_KEY,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:false}});
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const h=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const inr=n=>'₹'+Number(n).toLocaleString('en-IN');
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const PRICES={'500L':1000,'750L':1500,'1000L':1800,'1500L':2000,'2000L':2500};
const SLOTS=['8:00 AM – 10:00 AM','10:00 AM – 12:00 PM','12:00 PM – 2:00 PM','2:00 PM – 4:00 PM','4:00 PM – 6:00 PM'];
const DN=['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],MN=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const fmtDate=d=>`${DN[d.getDay()]}, ${d.getDate()} ${MN[d.getMonth()]} ${d.getFullYear()}`;
const newCart=()=>({q:{'500L':0,'750L':0,'1000L':0,'1500L':0,'2000L':0},di:0,date:fmtDate(new Date()),slot:'',addr:'',land:'',phone:'',useCoins:false,coupon:null,agree:false});
const S={user:null,profile:null,coins:0,cart:newCart(),step:1,busy:false,paying:false};
let couponMsg='',rating=5;

function toast(m){const t=$('#toast');t.textContent=m;t.classList.add('show');clearTimeout(toast.t);toast.t=setTimeout(()=>t.classList.remove('show'),3800)}
function store(k,v){try{if(v===undefined)return localStorage.getItem(k);localStorage.setItem(k,v)}catch(e){return null}}
(function(){const t=store('mx_theme');if(t)document.documentElement.dataset.theme=t})();

/* ---------- data helpers ---------- */
async function addCoins(n,type,desc){
  const u=S.user;if(!u)return false;
  try{
    const {data}=await sb.from('user_coins').select('balance').eq('user_id',u.id).maybeSingle();
    const nb=(data?.balance||0)+n;
    await sb.from('user_coins').update({balance:nb,updated_at:new Date().toISOString()}).eq('user_id',u.id);
    await sb.from('coin_transactions').insert({user_id:u.id,amount:n,type,description:desc});
    S.coins=nb;return true;
  }catch(e){return false}
}
async function deductCoins(n,desc){
  const u=S.user;if(!u)return false;
  try{
    const {data}=await sb.from('user_coins').select('balance').eq('user_id',u.id).maybeSingle();
    const nb=Math.max(0,(data?.balance||0)-n);
    await sb.from('user_coins').update({balance:nb,updated_at:new Date().toISOString()}).eq('user_id',u.id);
    await sb.from('coin_transactions').insert({user_id:u.id,amount:-n,type:'deduction',description:desc});
    S.coins=nb;return true;
  }catch(e){return false}
}
async function refreshCoins(){if(!S.user)return;const {data}=await sb.from('user_coins').select('balance').eq('user_id',S.user.id).maybeSingle();S.coins=data?.balance||0}
async function setup(){
  if(S.busy||!S.user)return;S.busy=true;
  try{
    const u=S.user;
    let {data:p}=await sb.from('profiles').select('*').eq('id',u.id).maybeSingle();
    let isNew=false;
    if(!p){
      isNew=true;
      await sb.from('profiles').insert({id:u.id,email:u.email||'',full_name:(u.email||'').split('@')[0],phone_number:'',location:'',signup_bonus_awarded:false});
      ({data:p}=await sb.from('profiles').select('*').eq('id',u.id).maybeSingle());
    }
    S.profile=p;
    const {data:uc}=await sb.from('user_coins').select('balance').eq('user_id',u.id).maybeSingle();
    if(!uc)await sb.from('user_coins').insert({user_id:u.id,balance:0});
    S.coins=uc?.balance||0;
    if(isNew){
      const {data:w}=await sb.from('coin_transactions').select('id').eq('user_id',u.id).eq('type','welcome').limit(1);
      if(!w?.length){
        await sb.from('profiles').update({signup_bonus_awarded:true}).eq('id',u.id);
        if(await addCoins(50,'welcome','Welcome signup bonus'))toast('Welcome to Maintix! 50 bonus coins added 🪙');
      }
    }
  }catch(e){console.warn('setup',e)}
  finally{S.busy=false}
}

/* ---------- auth ---------- */
function navAuth(){
  document.body.classList.toggle('authed',!!S.user);
  $('#authBtn').textContent=S.user?'Sign out':'Sign in';
}
// Do not await Supabase calls inside this callback (known deadlock); defer instead.
sb.auth.onAuthStateChange((ev,session)=>{
  S.user=session?.user||null;
  setTimeout(async()=>{
    if(S.user)await setup();else{S.profile=null;S.coins=0}
    navAuth();route();
  },0);
});
function openLogin(email){
  const d=$('#dlg');
  d.innerHTML=`<h3>Sign in to Maintix</h3><p class="muted small" style="margin:6px 0 4px">We’ll email you a one-time code. No password needed.</p>
  <form id="lf"><label>Email address</label><input id="em" type="email" required autocomplete="email" placeholder="you@example.com" value="${h(email||'')}">
  <button class="btn block" style="margin-top:18px">Send code</button></form>
  <button class="btn ghost block" style="margin-top:10px" data-act="close">Cancel</button>`;
  if(!d.open)d.showModal();
  $('#lf').onsubmit=async e=>{
    e.preventDefault();const em=$('#em').value.trim().toLowerCase(),btn=$('#lf .btn');btn.disabled=true;btn.textContent='Sending…';
    const {error}=await sb.auth.signInWithOtp({email:em,options:{shouldCreateUser:true}});
    if(error){toast(error.message);btn.disabled=false;btn.textContent='Send code';return}
    openVerify(em);
  };
}
function openVerify(em){
  const d=$('#dlg');
  d.innerHTML=`<h3>Enter your code</h3><p class="muted small" style="margin:6px 0 4px">Sent to <b>${h(em)}</b>. Check spam if you don’t see it.</p>
  <form id="vf"><label>One-time code</label><input id="cd" inputmode="numeric" autocomplete="one-time-code" required minlength="4" maxlength="10" placeholder="123456" style="letter-spacing:.3em;font-size:1.3rem;text-align:center">
  <button class="btn block" style="margin-top:18px">Verify &amp; continue</button></form>
  <button class="btn ghost block" style="margin-top:10px" id="back">Use a different email</button>`;
  $('#back').onclick=()=>openLogin(em);
  $('#vf').onsubmit=async e=>{
    e.preventDefault();const btn=$('#vf .btn');btn.disabled=true;btn.textContent='Verifying…';
    const {error}=await sb.auth.verifyOtp({email:em,token:$('#cd').value.trim(),type:'email'});
    if(error){toast('Invalid or expired code');btn.disabled=false;btn.textContent='Verify & continue';return}
    d.close();toast('Signed in successfully ✅');
  };
}

/* ---------- pricing / cart ---------- */
function calc(){
  const c=S.cart;let tanks=0,sub=0;
  for(const k in PRICES){tanks+=c.q[k];sub+=c.q[k]*PRICES[k]}
  const bulk=tanks>=3?500:0,cp=c.coupon?c.coupon.discount:0,coins=c.useCoins?Math.min(S.coins,50):0;
  return {tanks,sub,bulk,cp,coins,total:Math.max(0,sub-bulk-cp-coins)};
}
async function validateCoupon(code){
  const up=code.trim().toUpperCase(),t=calc();
  if(!up)return {valid:false,message:'Enter a coupon code'};
  if(!S.user)return {valid:false,message:'Please sign in to apply a coupon'};
  if(up==='TANK500'&&t.tanks<3)return {valid:false,message:'TANK500 requires 3 or more tanks'};
  try{
    const {data}=await sb.from('coupons').select('*').eq('code',up).eq('is_active',true).maybeSingle();
    if(!data)return {valid:false,message:'Invalid or expired coupon code'};
    if(data.expires_at&&new Date(data.expires_at)<new Date())return {valid:false,message:'This coupon has expired'};
    if(data.max_uses!=null&&(data.used_count||0)>=data.max_uses)return {valid:false,message:'Coupon usage limit reached'};
    if(up==='WEL100'){
      const {data:b}=await sb.from('bookings').select('id').eq('user_id',S.user.id);
      if(b?.length)return {valid:false,message:'WEL100 is only valid on your first booking'};
    }
    return {valid:true,code:up,id:data.id,discount:data.discount_amount||0,message:`🎉 Coupon applied! ${inr(data.discount_amount||0)} off`};
  }catch(e){return {valid:false,message:'Could not validate coupon. Try again.'}}
}
async function markCouponUsed(id){
  try{const {error}=await sb.rpc('increment_coupon_usage',{coupon_id:id});if(!error)return;
    const {data}=await sb.from('coupons').select('used_count').eq('id',id).maybeSingle();
    await sb.from('coupons').update({used_count:(data?.used_count||0)+1}).eq('id',id)}catch(e){}
}
const fullAddr=()=>S.cart.addr.trim()+(S.cart.land.trim()?', Near '+S.cart.land.trim():'');

/* ---------- payment ---------- */
async function pollOrder(orderId){
  for(const ms of [800,1500,2000,3000,3000,4000,4000,5000,5000,5000]){
    await sleep(ms);
    const {data}=await sb.from('payments').select('status,booking_id,razorpay_payment_id').eq('razorpay_order_id',orderId).maybeSingle();
    if(data?.status==='SUCCESS')return data;
  }
  return null;
}
function successDialog(pid,oid){
  const d=$('#dlg');
  d.innerHTML=`<div class="c"><div style="font-size:3rem">🎉</div><h3>Payment successful</h3><p class="muted" style="margin:8px 0 16px">Your booking is confirmed.</p>
  <div class="card small" style="box-shadow:none;padding:12px;text-align:left"><div class="line"><span class="muted">Payment ID</span><b>${h(pid)}</b></div><div class="line"><span class="muted">Order ID</span><b>${h(oid)}</b></div></div>
  <a class="btn block" style="margin-top:16px" href="#/bookings" data-act="close">View my bookings</a></div>`;
  if(!d.open)d.showModal();
}
function finishFlow(){S.cart=newCart();S.step=1;couponMsg=''}
async function pay(){
  if(S.paying)return;
  const c=S.cart,t=calc();
  if(!S.user)return openLogin();
  if(t.total<1)return toast('Total payable must be at least ₹1');
  if(typeof Razorpay==='undefined')return toast('Payment SDK failed to load. Please refresh and try again.');
  S.paying=true;const btn=$('#payBtn');if(btn){btn.disabled=true;btn.textContent='Preparing secure payment…'}
  const label=Object.entries(c.q).filter(([,v])=>v>0).map(([k,v])=>`${k} × ${v}`).join(', ');
  const serviceName=`${label} Tank Cleaning`,address=fullAddr();
  let order;
  try{
    const {data,error}=await sb.functions.invoke('create-razorpay-order',{body:{amount:t.total*100,currency:'INR',receipt:'rcpt_'+Date.now(),cartSnapshot:{serviceName,date:c.date,timeSlot:c.slot,address}}});
    if(error||!data?.id)throw error||new Error('no order');order=data;
  }catch(e){S.paying=false;toast('Could not create payment order. Please try again.');route();return}
  const oid=order.id;let settled=false;
  const onFail=async()=>{
    if(settled)return;settled=true;toast('Confirming your payment status…');
    const ok=await pollOrder(oid);S.paying=false;
    if(ok){successDialog(ok.razorpay_payment_id||'',oid);finishFlow();await refreshCoins();route();return}
    toast("We couldn't confirm this payment yet. If money was deducted, it will appear in My Bookings shortly — please check before retrying.");
    await sb.from('payments').update({status:'FAILED',updated_at:new Date().toISOString()}).eq('razorpay_order_id',oid).eq('status','PENDING');
    route();
  };
  const onPaid=async r=>{
    if(settled)return;settled=true;
    try{
      const {data:v,error}=await sb.functions.invoke('verify-razorpay-payment',{body:{orderId:r.razorpay_order_id||oid,paymentId:r.razorpay_payment_id,signature:r.razorpay_signature}});
      if(error||v?.verified!==true){toast('Payment verification failed. No booking was created.');S.paying=false;route();return}
    }catch(e){toast('Payment verification failed. No booking was created.');S.paying=false;route();return}
    if(c.useCoins&&t.coins>0)await deductCoins(t.coins,'Coins redeemed for booking');
    const {data:bk}=await sb.from('bookings').insert({user_id:S.user.id,service_name:serviceName,date:c.date,booking_date:c.date,booking_time:c.slot,address,status:'CONFIRMED',price:t.total}).select().maybeSingle();
    await sb.from('payments').update({razorpay_payment_id:r.razorpay_payment_id,booking_id:bk?.id||null,status:'SUCCESS',updated_at:new Date().toISOString()}).eq('razorpay_order_id',r.razorpay_order_id||oid);
    if(c.coupon?.id)await markCouponUsed(c.coupon.id);
    if(c.phone&&!S.profile?.phone_number){await sb.from('profiles').update({phone_number:c.phone}).eq('id',S.user.id)}
    S.paying=false;successDialog(r.razorpay_payment_id,r.razorpay_order_id||oid);finishFlow();route();
  };
  try{
    const rz=new Razorpay({key:order.key||RZP_FALLBACK,amount:t.total*100,currency:'INR',order_id:oid,name:'Maintix',description:'Water Tank Cleaning Service',prefill:{email:S.user.email||'',contact:c.phone},theme:{color:'#072654'},retry:{enabled:true,max_count:1},timeout:300,handler:onPaid,modal:{ondismiss:onFail}});
    rz.on('payment.failed',onFail);rz.open();
  }catch(e){S.paying=false;toast('Could not open payment window.');route()}
}

/* ---------- views ---------- */
const stars=n=>'★'.repeat(Math.round(n))+'☆'.repeat(5-Math.round(n));
const COL=['#3b82f6','#10b981','#ec4899','#f59e0b','#8b5cf6','#06b6d4','#0d9488'];
const ini=n=>(n||'C').split(' ').filter(Boolean).map(w=>w[0]).slice(0,2).join('').toUpperCase()||'C';
const col=n=>COL[(n||'C').charCodeAt(0)%COL.length];
function reviewCard(r){const n=r.user_name||'Customer';return `<div class="card hov"><div class="row"><div class="av" style="background:${col(n)}">${h(ini(n))}</div><div><b>${h(n)}</b><div class="stars small">${stars(r.rating)}</div></div></div><p class="muted" style="margin-top:14px">“${h(r.review_text)}”</p></div>`}
const gate=msg=>`<div class="page"><div class="wrap c fade"><h2>${msg}</h2><p class="muted" style="margin:10px 0 22px">Sign in with your email to continue.</p><button class="btn" data-act="auth">Sign in</button></div></div>`;
const AF='grid-template-columns:repeat(auto-fit,minmax(210px,1fr))';
const tankSvg=`<svg viewBox="0 0 400 400" class="tankart" aria-hidden="true"><defs><radialGradient id="w" cx="50%" cy="45%"><stop offset="0" stop-color="#67e8f9"/><stop offset="1" stop-color="#0e9aa8"/></radialGradient><linearGradient id="s" x1="0" x2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#fff" stop-opacity=".55"/></linearGradient><clipPath id="cp"><circle cx="200" cy="200" r="128"/></clipPath></defs><circle cx="200" cy="200" r="190" fill="none" stroke="#22d3ee" stroke-opacity=".18"/><circle cx="200" cy="200" r="165" fill="#0b2a52" stroke="#1d4f86" stroke-width="10"/><circle cx="200" cy="200" r="128" fill="url(#w)"/><g clip-path="url(#cp)"><circle class="rip" cx="200" cy="200" r="128" fill="none" stroke="#fff" stroke-width="3"/><circle class="rip" cx="200" cy="200" r="128" fill="none" stroke="#fff" stroke-width="3"/><path class="sweep" d="M200 200 L200 72 A128 128 0 0 1 328 200Z" fill="url(#s)"/></g><circle cx="200" cy="200" r="128" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="3"/><circle cx="200" cy="34" r="10" fill="#22d3ee"/><circle cx="366" cy="200" r="10" fill="#22d3ee"/><circle cx="200" cy="366" r="10" fill="#22d3ee"/><circle cx="34" cy="200" r="10" fill="#22d3ee"/></svg>`;

function homeView(){
  return `<section class="hero"><div class="wrap"><div class="fade"><span class="kick">💧 SATNA’S TRUSTED TANK CLEANING</span><h1>Clean tank. <em>Clean water.</em> Healthy home.</h1>
  <p class="lead">Professional, hygienic water tank cleaning with transparent pricing and doorstep service. Book in under two minutes.</p>
  <div class="cta"><a class="btn" href="#/book">Book a cleaning →</a><a class="btn ghost" href="#/services">See pricing</a></div>
  <div class="chips"><span>✔ Food-grade cleaning agents</span><span>✔ No hidden charges</span><span>✔ Secure Razorpay payment</span></div></div>${tankSvg}</div></section>
  <div class="wrap"><div class="stats"><div class="stat"><b>₹1,000</b><span class="muted">Starting price</span></div><div class="stat"><b>5</b><span class="muted">Tank sizes</span></div><div class="stat"><b id="st-r">—</b><span class="muted">Customer rating</span></div><div class="stat"><b>₹500</b><span class="muted">Off on 3+ tanks</span></div></div></div>
  <section class="sec"><div class="wrap"><div class="head c"><h2>How it works</h2><p>Four simple steps from tap to sparkling tank.</p></div><div class="grid" style="${AF}">
  ${[['Choose','Pick your tank size and quantity.'],['Schedule','Select a date and 2-hour time slot.'],['Pay securely','Pay online with UPI, card or netbanking.'],['We clean','Our trained team arrives and cleans.']].map((x,i)=>`<div class="card hov"><div class="num">${i+1}</div><h4>${x[0]}</h4><p class="muted small">${x[1]}</p></div>`).join('')}</div></div></section>
  <section class="sec alt"><div class="wrap"><div class="head"><h2>Why families choose Maintix</h2></div><div class="grid g3">
  ${[['🧪','Eco-friendly, food-grade agents','Safe for drinking water storage and your family.'],['💰','Transparent pricing','Fixed price per tank size. What you see is what you pay.'],['📅','Same-day & scheduled slots','Pick the date and time that suits you.'],['🛡️','Trained professionals','Careful, hygienic cleaning at your doorstep.'],['🪙','Rewards wallet','Earn coins on signup and reviews, redeem on bookings.'],['📍','Local to Satna','A neighbourhood team, quick to reach you.']].map(x=>`<div class="card hov"><div style="font-size:1.8rem">${x[0]}</div><h4 style="margin:10px 0 6px">${x[1]}</h4><p class="muted small">${x[2]}</p></div>`).join('')}</div></div></section>
  <section class="sec"><div class="wrap"><div class="head"><h2>What customers say</h2></div><div class="grid g3" id="hrev"><div class="sk"></div><div class="sk"></div><div class="sk"></div></div></div></section>
  <section class="sec" style="padding-top:0"><div class="wrap"><div class="band"><h2>Ready for cleaner water?</h2><p>New here? Sign up and get 50 bonus coins plus ₹100 off with code WEL100 on your first booking.</p><a class="btn" href="#/book">Book now</a></div></div></section>`;
}
async function homeAfter(){
  const {data}=await sb.from('reviews').select('*').eq('is_approved',true).order('created_at',{ascending:false});
  const el=$('#hrev');if(!el)return;
  el.innerHTML=data?.length?data.slice(0,3).map(reviewCard).join(''):'<p class="muted">Be the first to review after your cleaning.</p>';
  if(data?.length&&$('#st-r'))$('#st-r').textContent=(data.reduce((s,r)=>s+r.rating,0)/data.length).toFixed(1)+' ★';
}
function servicesView(){
  return `<div class="page"><div class="wrap fade"><div class="head"><h1>Services &amp; pricing</h1><p>Simple fixed pricing by tank capacity. Book 3 or more tanks and save ₹500.</p></div>
  <div class="grid" style="${AF}">${Object.entries(PRICES).map(([k,p])=>`<div class="card hov c"><div class="tk" style="margin:0 auto 12px">💧</div><h3>${k}</h3><div class="price" style="margin:8px 0">${inr(p)}</div><a class="btn sm block" href="#/book">Book</a></div>`).join('')}</div>
  <div class="head" style="margin-top:60px"><h2>All services</h2></div><div class="grid g3" id="svc"><div class="sk"></div><div class="sk"></div><div class="sk"></div></div></div></div>`;
}
async function servicesAfter(){
  const {data}=await sb.from('services').select('*').order('price',{ascending:true});const el=$('#svc');if(!el)return;
  el.innerHTML=(data||[]).map(s=>{const tank=/tank/i.test(s.title);return `<div class="card hov"><span class="pill g">${h(s.category)}</span><h3 style="margin:12px 0 6px">${h(s.title)}</h3><p class="muted small">${h(s.description||'')}</p><div class="price" style="margin:14px 0"><small>from </small>${inr(s.price)}</div>${tank?'<a class="btn sm" href="#/book">Book now</a>':'<a class="btn sm ghost" href="tel:+916262262913">Call to enquire</a>'}</div>`}).join('')||'<p class="muted">Services will appear here.</p>';
}
function summaryBox(){
  const c=S.cart,t=calc();
  const items=Object.entries(c.q).filter(([,v])=>v>0);
  return `<div class="card sum"><h4 style="margin-bottom:10px">Order summary</h4>${items.length?items.map(([k,v])=>`<div class="line"><span>${k} × ${v}</span><span>${inr(PRICES[k]*v)}</span></div>`).join(''):'<p class="muted small">No tanks selected yet.</p>'}
  ${t.bulk?`<div class="line ok"><span>🎉 Bulk discount</span><span>−${inr(t.bulk)}</span></div>`:''}${t.cp?`<div class="line ok"><span>Coupon ${h(c.coupon.code)}</span><span>−${inr(t.cp)}</span></div>`:''}${t.coins?`<div class="line ok"><span>Wallet coins</span><span>−${inr(t.coins)}</span></div>`:''}
  <div class="line t"><span>Total</span><span>${inr(t.total)}</span></div>${S.step>1?`<p class="muted small" style="margin-top:10px">📅 ${h(c.date)}${c.slot?'<br>🕒 '+h(c.slot):''}</p>`:''}</div>`;
}
function bookView(){
  const c=S.cart,t=calc(),st=S.step;let body='';
  if(st===1){
    body=`<h3>Select tank size &amp; quantity</h3><p class="muted small" style="margin-bottom:14px">You can mix multiple sizes.</p><div class="stack">${Object.entries(PRICES).map(([k,p])=>`<div class="card tank row ${c.q[k]?'on':''}"><div class="tk">💧<br><b>${k}</b></div><div class="grow"><h4>${k} Tank Cleaning</h4><span class="price" style="font-size:1.1rem">${inr(p)}</span></div><div class="qty"><button data-act="q" data-k="${k}" data-d="-1" aria-label="Less">−</button><b>${c.q[k]}</b><button data-act="q" data-k="${k}" data-d="1" aria-label="More">+</button></div></div>`).join('')}</div>
    <button class="btn block" style="margin-top:20px" data-act="next" ${t.tanks?'':'disabled'}>Next — choose date &amp; time →</button>`;
  }else if(st===2){
    const days=Array.from({length:7},(_,i)=>new Date(Date.now()+i*864e5));
    body=`<h3>Select date</h3><div class="days" style="margin:14px 0 24px">${days.map((d,i)=>`<button class="day ${c.di===i?'on':''}" data-act="day" data-i="${i}"><small>${DN[d.getDay()]}</small><b>${d.getDate()}</b><small>${i?MN[d.getMonth()]:'Today'}</small></button>`).join('')}</div>
    <h3 style="margin-bottom:12px">Select time slot</h3>${SLOTS.map(s=>`<button class="slot ${c.slot===s?'on':''}" data-act="slot" data-s="${s}">🕒 ${s}</button>`).join('')}
    <div class="row" style="margin-top:14px"><button class="btn ghost" data-act="back">← Back</button><button class="btn grow" data-act="next" ${c.slot?'':'disabled'}>Continue to address →</button></div>`;
  }else if(st===3){
    body=`<h3>Service address</h3><label>Full address</label><textarea id="f-addr" rows="3" placeholder="House no., street, area, city">${h(c.addr)}</textarea><label>Landmark (optional)</label><input id="f-land" value="${h(c.land)}" placeholder="Near …"><label>Phone number</label><input id="f-ph" inputmode="tel" maxlength="10" value="${h(c.phone)}" placeholder="10-digit mobile number">
    <div class="row" style="margin-top:20px"><button class="btn ghost" data-act="back">← Back</button><button class="btn grow" data-act="next">Review &amp; pay →</button></div>`;
  }else{
    body=`<h3>Review &amp; pay</h3><div class="card" style="box-shadow:none;margin:14px 0"><div class="line"><span class="muted">Date</span><b>${h(c.date)}</b></div><div class="line"><span class="muted">Time</span><b>${h(c.slot)}</b></div><div class="line"><span class="muted">Address</span><b style="text-align:right">${h(fullAddr())}</b></div><div class="line"><span class="muted">Phone</span><b>${h(c.phone)}</b></div></div>
    <label>Coupon code</label><div class="row"><input id="f-cp" value="${h(c.coupon?.code||'')}" ${c.coupon?'disabled':''} placeholder="e.g. WEL100" style="text-transform:uppercase"><button class="btn sm ${c.coupon?'ghost':'navy'}" data-act="${c.coupon?'rmcp':'cp'}">${c.coupon?'Remove':'Apply'}</button></div><p class="small ${c.coupon?'ok':'err'}" style="margin-top:6px">${h(couponMsg)}</p>
    ${S.user&&S.coins>0?`<label class="ck"><input type="checkbox" data-act="coins" ${c.useCoins?'checked':''}><span>🪙 Use wallet coins — ${S.coins} available (max 50 per booking)</span></label>`:''}
    <label class="ck"><input type="checkbox" data-act="agree" ${c.agree?'checked':''}><span>I agree to the <a href="#/terms" target="_blank" style="text-decoration:underline">Terms &amp; Conditions</a> and cancellation policy.</span></label>
    <div class="row"><button class="btn ghost" data-act="back">← Back</button><button class="btn navy grow" id="payBtn" data-act="pay" ${c.agree&&!S.paying?'':'disabled'}>💳 ${S.user?'Pay '+inr(t.total)+' with Razorpay':'Sign in to pay'}</button></div><p class="muted small c" style="margin-top:10px">🔒 Secured by Razorpay</p>`;
  }
  return `<div class="page"><div class="wrap fade"><h1>Book a cleaning</h1><div class="steps">${['Tanks','Schedule','Address','Pay'].map((s,i)=>`<span class="${st===i+1?'on':st>i+1?'done':''}">${i+1}. ${s}</span>`).join('')}</div><div class="bk"><div class="card">${body}</div>${summaryBox()}</div></div></div>`;
}
function readStep3(){const c=S.cart;c.addr=($('#f-addr')?.value??c.addr);c.land=($('#f-land')?.value??c.land);c.phone=($('#f-ph')?.value??c.phone).replace(/\D/g,'')}
function bookingsView(){
  if(!S.user)return gate('Sign in to see your bookings');
  return `<div class="page"><div class="wrap fade"><h1>My bookings</h1><div class="stack" id="bl" style="margin-top:24px"><div class="sk"></div><div class="sk"></div></div></div></div>`;
}
async function bookingsAfter(){
  if(!S.user)return;const {data}=await sb.from('bookings').select('*').eq('user_id',S.user.id).order('created_at',{ascending:false});const el=$('#bl');if(!el)return;
  el.innerHTML=data?.length?data.map(b=>`<div class="card hov"><div class="row"><div class="grow"><h4>${h(b.service_name)}</h4><p class="muted small">📅 ${h(b.booking_date||b.date)} · 🕒 ${h(b.booking_time)}</p><p class="muted small">📍 ${h(b.address)}</p></div><div style="text-align:right"><div class="price" style="font-size:1.4rem">${inr(b.price)}</div><span class="pill ${/confirm|complete/i.test(b.status)?'g':''}">${h(b.status)}</span></div></div></div>`).join(''):`<div class="card c"><p class="muted">No bookings yet.</p><a class="btn sm" style="margin-top:14px" href="#/book">Book your first cleaning</a></div>`;
}
function reviewsView(){
  return `<div class="page"><div class="wrap fade"><div class="head"><h1>Customer reviews</h1><p id="ravg" class="muted"></p></div><div id="rform"></div><div class="grid g3" id="rl"><div class="sk"></div><div class="sk"></div><div class="sk"></div></div></div></div>`;
}
async function reviewsAfter(){
  const {data}=await sb.from('reviews').select('*').eq('is_approved',true).order('created_at',{ascending:false});
  const el=$('#rl');if(!el)return;
  el.innerHTML=data?.length?data.map(reviewCard).join(''):'<p class="muted">No reviews yet.</p>';
  if(data?.length){const avg=data.reduce((s,r)=>s+r.rating,0)/data.length;$('#ravg').innerHTML=`<span class="stars">${stars(avg)}</span> ${avg.toFixed(1)} from ${data.length} review${data.length>1?'s':''}`}
  const f=$('#rform');if(!f)return;
  if(!S.user){f.innerHTML='<div class="card" style="margin-bottom:24px"><p class="muted">Sign in after your booking to share your experience and earn 10 coins.</p></div>';return}
  const {data:b}=await sb.from('bookings').select('created_at').eq('user_id',S.user.id).order('created_at',{ascending:false}).limit(1);
  const {data:r}=await sb.from('reviews').select('created_at').eq('user_id',S.user.id).order('created_at',{ascending:false}).limit(1);
  const can=b?.length&&(!r?.length||new Date(b[0].created_at)>new Date(r[0].created_at));
  if(!$('#rform'))return;
  f.innerHTML=can?`<div class="card" style="margin-bottom:24px"><h4>Write a review · earn 10 🪙</h4><div id="stp" style="margin:8px 0">${[1,2,3,4,5].map(i=>`<button style="font-size:1.7rem;padding:0 4px;border:0;background:none;color:#f59e0b;cursor:pointer" data-act="star" data-n="${i}">${i<=rating?'★':'☆'}</button>`).join('')}</div><textarea id="rt" rows="3" placeholder="How was your experience?"></textarea><button class="btn" style="margin-top:12px" data-act="rsub">Submit review</button><p class="muted small" style="margin-top:8px">Reviews appear publicly after approval.</p></div>`:'<div class="card" style="margin-bottom:24px"><p class="muted">You can write one review after each booking.</p></div>';
}
function profileView(){
  if(!S.user)return gate('Sign in to view your profile');
  const p=S.profile||{};
  return `<div class="page"><div class="wrap fade"><h1>My profile</h1><div class="grid g2" style="margin-top:24px"><div class="card"><div class="row"><div class="av" style="background:${col(p.full_name)};width:56px;height:56px">${h(ini(p.full_name))}</div><div><b>${h(p.full_name)}</b><div class="muted small">${h(S.user.email)}</div></div></div>
  <label>Full name</label><input id="p-n" value="${h(p.full_name)}"><label>Phone</label><input id="p-p" inputmode="tel" value="${h(p.phone_number)}"><label>City / address</label><input id="p-l" value="${h(p.location)}"><button class="btn" style="margin-top:18px" data-act="psave">Save changes</button></div>
  <div class="stack"><div class="card"><div class="line"><span class="muted">Wallet balance</span><b class="price" style="font-size:1.6rem">🪙 <span id="cb">${S.coins}</span></b></div><div id="ctx" class="small muted"></div></div>
  <div class="card"><h4>Need help?</h4><label>Subject</label><input id="t-s"><label>Message</label><textarea id="t-m" rows="3"></textarea><button class="btn navy" style="margin-top:14px" data-act="tsend">Send to support</button></div></div></div></div></div>`;
}
async function profileAfter(){
  if(!S.user)return;await refreshCoins();if($('#cb'))$('#cb').textContent=S.coins;
  const {data}=await sb.from('coin_transactions').select('*').eq('user_id',S.user.id).order('created_at',{ascending:false}).limit(8);const el=$('#ctx');if(!el)return;
  el.innerHTML=data?.length?data.map(x=>`<div class="line"><span>${h(x.description)}</span><b class="${x.amount>0?'ok':'err'}">${x.amount>0?'+':''}${x.amount}</b></div>`).join(''):'No coin activity yet.';
}
function aboutView(){
  return `<div class="page"><div class="wrap fade legal"><div class="head"><h1>About Maintix</h1><p>Trusted water tank cleaning services.</p></div><div class="grid g2"><div class="card"><h3>Our mission</h3><p>To deliver safe, hygienic and affordable water tank cleaning to every household and business. Clean water storage should be accessible to all.</p></div><div class="card"><h3>Our vision</h3><p>A future where every family in India has professionally maintained water storage, starting in Madhya Pradesh.</p></div></div>
  <div class="card" style="margin-top:20px"><h3>Company details</h3><div class="line"><span class="muted">Headquarters</span><b>Satna, Madhya Pradesh, India</b></div><div class="line"><span class="muted">Email</span><b>maintix.help@gmail.com</b></div><div class="line"><span class="muted">Phone</span><b>+91 62622 62913</b></div><div class="line"><span class="muted">Founded</span><b>2024</b></div></div></div></div>`;
}
function legalView(kind){
  if(kind==='privacy')return `<div class="page"><div class="wrap fade legal"><h1>Privacy Policy</h1><p>Maintix collects only the information needed to provide tank cleaning services: your email, name, phone number, address, booking details and, if you allow it, location. Payments are processed by Razorpay; we never see or store your card or UPI details.</p><h3>How we use data</h3><ul><li>To create and manage your account and bookings.</li><li>To contact you about your service.</li><li>To operate rewards, coupons and reviews.</li></ul><h3>Your choices</h3><p>You can edit your profile any time. To request deletion of your data, email maintix.help@gmail.com.</p></div></div>`;
  return `<div class="page"><div class="wrap fade legal"><h1>Terms &amp; Conditions</h1><p>By booking with Maintix you agree to provide accurate address and contact details and to be available in the selected time slot.</p><h3>Pricing &amp; payment</h3><p>Prices are shown per tank size and are payable online through Razorpay. Discounts and coupons are applied as shown at checkout.</p><h3>Cancellations</h3><p>For changes or cancellations, contact us at maintix.help@gmail.com or +91 62622 62913 as early as possible.</p></div></div>`;
}

/* ---------- router ---------- */
const ROUTES={'':'home',services:'services',book:'book',bookings:'bookings',reviews:'reviews',profile:'profile',about:'about',privacy:'privacy',terms:'terms'};
let lastR='';
function route(){
  const key=location.hash.replace(/^#\/?/,'').split('?')[0];const r=ROUTES[key]??'home';
  $$('#links a').forEach(a=>a.classList.toggle('on',a.dataset.r===r));
  $('#nav').classList.remove('open');
  let after=null,html;
  switch(r){
    case 'home':html=homeView();after=homeAfter;break;
    case 'services':html=servicesView();after=servicesAfter;break;
    case 'book':html=bookView();break;
    case 'bookings':html=bookingsView();after=bookingsAfter;break;
    case 'reviews':html=reviewsView();after=reviewsAfter;break;
    case 'profile':html=profileView();after=profileAfter;break;
    case 'about':html=aboutView();break;
    default:html=legalView(r);
  }
  const y=scrollY;$('#app').innerHTML=html;scrollTo(0,(r===lastR&&r==='book')?y:0);lastR=r;
  if(after)after();
  document.title=r==='home'?'Maintix — Professional Water Tank Cleaning in Satna':`${r[0].toUpperCase()+r.slice(1)} · Maintix`;
}
window.addEventListener('hashchange',route);

/* ---------- events ---------- */
document.addEventListener('input',e=>{
  const id=e.target.id,c=S.cart;
  if(id==='f-addr')c.addr=e.target.value;else if(id==='f-land')c.land=e.target.value;else if(id==='f-ph'){c.phone=e.target.value.replace(/\D/g,'');e.target.value=c.phone}
});
document.addEventListener('click',async e=>{
  const el=e.target.closest('[data-act]');if(!el)return;const a=el.dataset.act,c=S.cart;
  switch(a){
    case 'theme':{const cur=document.documentElement.dataset.theme||(matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light');const n=cur==='dark'?'light':'dark';document.documentElement.dataset.theme=n;store('mx_theme',n);break}
    case 'menu':$('#nav').classList.toggle('open');break;
    case 'auth':if(S.user){await sb.auth.signOut();location.hash='#/';toast('Signed out')}else openLogin();break;
    case 'close':$('#dlg').close();break;
    case 'q':c.q[el.dataset.k]=Math.max(0,Math.min(10,c.q[el.dataset.k]+Number(el.dataset.d)));if(c.coupon&&c.coupon.code==='TANK500'&&calc().tanks<3){c.coupon=null;couponMsg=''}route();break;
    case 'day':c.di=Number(el.dataset.i);c.date=fmtDate(new Date(Date.now()+c.di*864e5));route();break;
    case 'slot':c.slot=el.dataset.s;route();break;
    case 'back':readStep3();S.step=Math.max(1,S.step-1);route();break;
    case 'next':
      if(S.step===1&&!calc().tanks)return;
      if(S.step===2&&!c.slot)return;
      if(S.step===3){readStep3();if(c.addr.trim().length<10)return toast('Please enter your complete address');if(c.phone.length!==10)return toast('Enter a valid 10-digit phone number')}
      S.step=Math.min(4,S.step+1);
      if(S.step===3){if(!c.phone&&S.profile?.phone_number)c.phone=S.profile.phone_number;if(!c.addr&&S.profile?.location)c.addr=S.profile.location}
      route();break;
    case 'cp':{const r=await validateCoupon($('#f-cp').value);couponMsg=r.message;c.coupon=r.valid?r:null;route();break}
    case 'rmcp':c.coupon=null;couponMsg='';route();break;
    case 'coins':c.useCoins=el.checked;route();break;
    case 'agree':c.agree=el.checked;route();break;
    case 'pay':pay();break;
    case 'star':rating=Number(el.dataset.n);$$('#stp button').forEach((b,i)=>b.textContent=i<rating?'★':'☆');break;
    case 'rsub':{
      const txt=$('#rt').value.trim();if(txt.length<10)return toast('Please write at least 10 characters');
      el.disabled=true;
      const {error}=await sb.from('reviews').insert({user_id:S.user.id,user_name:S.profile?.full_name||'',service_name:'Water Tank Cleaning',rating,review_text:txt,is_approved:false});
      if(error){toast('Could not submit review');el.disabled=false;return}
      await addCoins(10,'reward','Review submitted for Water Tank Cleaning');toast('Thanks! +10 coins added. Your review appears after approval.');route();break}
    case 'psave':{
      const upd={full_name:$('#p-n').value.trim(),phone_number:$('#p-p').value.trim(),location:$('#p-l').value.trim(),updated_at:new Date().toISOString()};
      const {data,error}=await sb.from('profiles').update(upd).eq('id',S.user.id).select().maybeSingle();
      if(error)return toast('Could not save changes');S.profile=data||{...S.profile,...upd};toast('Profile updated ✅');break}
    case 'tsend':{
      const s=$('#t-s').value.trim(),m=$('#t-m').value.trim();if(!s||!m)return toast('Please fill subject and message');
      const {error}=await sb.from('support_tickets').insert({user_id:S.user.id,subject:s,message:m,status:'open'});
      if(error)return toast('Could not send. Try again.');$('#t-s').value='';$('#t-m').value='';toast('Message sent. We’ll get back to you soon.');break}
  }
});

(async()=>{
  const {data}=await sb.auth.getSession();
  S.user=data.session?.user||null;
  if(S.user)await setup();
  navAuth();route();
})();
