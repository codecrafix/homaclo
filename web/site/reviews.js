'use strict';
/* Reviews system — mirrors app: lib/presentation/reviews_screen + AppState.checkReviewEligibility/submitDbReview
   Rules (same as app):
   - Feed = approved DB reviews (newest first) + 6 Satna sample reviews; header avg = DB avg or 5.0
   - "Write a Review" always visible. Signed out -> sign-in prompt. No booking -> locked (Booking Required).
   - Latest review newer than latest booking -> locked (Review Already Submitted).
   - Submit: insert review (is_approved=false) + 10 coins ('reward'), then locks until next booking. */
(function(){
  const COLORS=['#3b82f6','#10b981','#ec4899','#f59e0b','#8b5cf6','#06b6d4','#0d9488'];
  const MOCK=[
    ['Rajesh Sharma','Civil Lines, Satna','2 weeks ago',5,'Excellent service! The team was professional and thorough. My 1000L tank was cleaned spotlessly. Water quality has improved significantly. Highly recommend to everyone in Satna!','1000L Cleaned','#3B82F6','RS'],
    ['Ramesh Tiwari','Dawari, Satna','2 weeks ago',5,'Bahut achha service hai! Team time par aayi aur tank bilkul saaf kar diya. Paani ab zyada saaf aata hai. Maintix ki team bahut professional hai. Definitely recommend karunga.','1000L Tank Cleaned','#10B981','RT'],
    ['Priya Sharma','Pateri, Satna','3 weeks ago',4,'Good service, reasonable price. The technician was very professional and explained everything clearly. My family was worried about water quality but now we are fully satisfied.','750L Cleaned','#EC4899','PS'],
    ['Suresh Gupta','Birla Road, Satna','1 month ago',5,'Superb experience! Booked online and the team arrived exactly on time. Tank cleaning was done in under 2 hours. Very affordable pricing. Will definitely book again.','1500L Cleaned','#F59E0B','SG'],
    ['Anita Verma','Maihar Bypass, Satna','3 weeks ago',5,'Excellent work by the Maintix team. They cleaned our 2000L overhead tank thoroughly. The water now tastes much better. Highly professional and courteous staff.','2000L Cleaned','#8B5CF6','AV'],
    ['Mohan Patel','Jawahar Nagar, Satna','1 month ago',4,'Very good service at a fair price. The team was punctual and cleaned the tank properly. I noticed a clear improvement in water quality after the cleaning. Recommended!','500L Cleaned','#06B6D4','MP']
  ];
  let DB=[],loading=true,rate=5,busy=false;
  const dlg=()=>document.getElementById('dlg');
  const say=m=>{if(typeof toast==='function')toast(m)};
  const stars5=n=>'★'.repeat(n)+'☆'.repeat(5-n);
  const ini=n=>n.split(' ').filter(Boolean).map(w=>w[0]).slice(0,2).join('').toUpperCase()||'C';
  function ago(iso){
    const d=(Date.now()-new Date(iso).getTime())/864e5;
    if(d>30)return Math.floor(d/30)+' month(s) ago';
    if(d>=1)return Math.floor(d)+' day(s) ago';
    const hr=Math.floor(d*24);return hr>0?hr+' hour(s) ago':'Just now';
  }
  function cardHtml(o){
    return `<div class="card" style="position:relative;padding:18px"><div class="row" style="align-items:flex-start"><div class="av" style="background:${o.color}">${h(o.initials)}</div>
      <div class="grow"><b>${h(o.name)}</b><div class="muted small">📍 ${h(o.location)} · ${h(o.timeAgo)}</div><div class="stars small">${stars5(o.rating)}</div></div></div>
      <p class="muted" style="margin:12px 0">${h(o.review)}</p><span class="pill g">${h(o.tag)}</span>${o.del?`<button data-rv="del" data-id="${h(o.del)}" aria-label="Delete review" style="position:absolute;top:10px;right:10px;border:0;border-radius:50%;width:30px;height:30px;cursor:pointer;background:color-mix(in srgb,var(--err) 14%,transparent);color:var(--err)">🗑</button>`:''}</div>`;
  }
  function dbCard(r){
    const own=S.user&&r.user_id===S.user.id;
    let name=(r.user_name||'').trim();
    if(!name)name=own&&S.profile&&S.profile.full_name?S.profile.full_name:'Customer';
    return cardHtml({name,initials:ini(name),color:COLORS[name.charCodeAt(0)%COLORS.length],rating:Math.round(r.rating),review:r.review_text||'',
      location:'Satna, MP',timeAgo:ago(r.created_at),tag:r.service_name||'Tank Cleaning',del:own?r.id:null});
  }
  function renderFeed(){
    const el=document.getElementById('rfeed');if(!el)return;
    const avg=document.getElementById('rv-avg');
    if(avg)avg.textContent=DB.length?(DB.reduce((s,r)=>s+Number(r.rating||0),0)/DB.length).toFixed(1):'5.0';
    el.innerHTML=loading?'<div class="sk"></div><div class="sk"></div><div class="sk"></div>'
      :DB.map(dbCard).join('')+MOCK.map(m=>cardHtml({name:m[0],location:m[1],timeAgo:m[2],rating:m[3],review:m[4],tag:m[5],color:m[6],initials:m[7]})).join('');
  }
  async function loadFeed(){
    try{const {data}=await sb.from('reviews').select('*').eq('is_approved',true).order('created_at',{ascending:false});DB=data||[]}catch(e){}
    loading=false;renderFeed();
  }

  /* ---- eligibility (same logic as checkReviewEligibility) ---- */
  async function eligibility(){
    if(!S.user)return {s:'anon'};
    const {data:b}=await sb.from('bookings').select('created_at,service_name').eq('user_id',S.user.id).order('created_at',{ascending:false}).limit(1);
    if(!b||!b.length)return {s:'nobooking'};
    const service=b[0].service_name||'Water Tank Cleaning';
    const {data:r}=await sb.from('reviews').select('created_at').eq('user_id',S.user.id).order('created_at',{ascending:false}).limit(1);
    if(!r||!r.length)return {s:'ok',service};
    return new Date(r[0].created_at)>new Date(b[0].created_at)?{s:'done'}:{s:'ok',service};
  }

  function info(icon,title,msg,primary){
    const d=dlg();
    d.innerHTML=`<div class="c"><div style="font-size:3rem">${icon}</div><h3 style="margin:8px 0">${title}</h3><p class="muted small" style="margin-bottom:18px">${msg}</p></div>
      ${primary?`<button class="btn block" data-rv="${primary[1]}">${primary[0]}</button><button class="btn ghost block" style="margin-top:10px" data-act="close">Cancel</button>`:'<button class="btn navy block" data-act="close">Got it</button>'}`;
    if(!d.open)d.showModal();
  }
  function form(service){
    const d=dlg();
    d.innerHTML=`<h3>Write a Review</h3><p class="muted small" style="margin:4px 0 6px">Share your experience to earn +10 coins</p>
      <label>Service</label><input id="rv-svc" readonly value="${h(service)}">
      <label>Your Rating</label><div id="rv-st">${[1,2,3,4,5].map(i=>`<button data-rv="star" data-n="${i}" aria-label="${i} star" style="font-size:2rem;padding:0 3px;border:0;background:none;color:#f59e0b;cursor:pointer">${i<=rate?'★':'☆'}</button>`).join('')}</div>
      <label>Your Review</label><textarea id="rv-txt" rows="4" maxlength="300" placeholder="Tell others about your experience..."></textarea>
      <button class="btn block" id="rv-go" style="margin-top:16px" data-rv="submit">Submit Review (+10 🪙)</button>
      <button class="btn ghost block" style="margin-top:10px" data-act="close">Cancel</button>`;
    if(!d.open)d.showModal();
  }
  async function onWrite(btn){
    if(!S.user){info('🔐','Sign in required','Please login or signup first to write a review.',['Sign in / Sign up','login']);return}
    const o=btn.textContent;btn.disabled=true;btn.textContent='Checking…';
    let e;try{e=await eligibility()}catch(x){e={s:'err'}}
    btn.disabled=false;btn.textContent=o;
    if(e.s==='nobooking')return info('🔒','Booking Required','Please complete a service booking first to unlock verified customer reviews!');
    if(e.s==='done')return info('🔒','Review Already Submitted','You have already submitted a review for your last booking. Complete another booking to write a new review!');
    if(e.s!=='ok')return say('Could not check review eligibility. Try again.');
    rate=5;form(e.service);
  }
  async function onSubmit(btn){
    if(busy)return;
    const txt=document.getElementById('rv-txt').value.trim();
    if(!txt)return say('Please write your review before submitting.');
    busy=true;btn.disabled=true;btn.textContent='Submitting...';
    const service=document.getElementById('rv-svc').value.trim()||'Water Tank Cleaning';
    try{
      // re-check so double-submit / stale form cannot bypass the lock
      const e=await eligibility();
      if(e.s!=='ok'){dlg().close();busy=false;return info('🔒','Review Already Submitted','You have already submitted a review for your last booking. Complete another booking to write a new review!')}
      const {error}=await sb.from('reviews').insert({user_id:S.user.id,user_name:(S.profile&&S.profile.full_name)||'',service_name:service,rating:rate,review_text:txt,is_approved:false});
      if(error)throw error;
      const ok=await addCoins(10,'reward','Review submitted for '+service);
      dlg().close();say(ok?'🪙 Review submitted! +10 coins added.':'Review submitted!');
      await loadFeed();
    }catch(x){btn.disabled=false;btn.textContent='Submit Review (+10 🪙)';say('Could not submit review. Please try again.')}
    busy=false;
  }
  function confirmDel(id){
    const d=dlg();
    d.innerHTML=`<h3>Delete Review?</h3><p class="muted small" style="margin:8px 0 18px">This review will be permanently deleted.</p>
      <div class="row"><button class="btn ghost grow" data-act="close">Cancel</button><button class="btn grow" style="background:var(--err);color:#fff;box-shadow:none" data-rv="del-ok" data-id="${h(id)}">Delete</button></div>`;
    if(!d.open)d.showModal();
  }

  /* ---- page (replaces old reviewsView/reviewsAfter from app.js) ---- */
  window.reviewsView=function(){
    return `<div class="page"><div class="wrap fade" style="max-width:820px">
      <div style="background:linear-gradient(135deg,#072654,#1a3f5c);color:#fff;border-radius:22px;padding:24px 26px">
        <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap"><span style="color:#f59e0b;font-size:1.6rem">★</span><b id="rv-avg" style="font:800 1.9rem 'Plus Jakarta Sans'">5.0</b>
        <span style="padding:3px 10px;border-radius:8px;background:rgba(22,163,74,.22);color:#4ade80;font-weight:700;font-size:.75rem">✓ Verified</span></div>
        <p style="color:rgba(255,255,255,.72);margin-top:6px">What our customers say</p></div>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:16px;background:linear-gradient(135deg,#072654,#0a5a8a);color:#fff;border-radius:18px;padding:18px 10px;text-align:center">
        ${[['👥','500+','Happy Customers'],['★','5.0','Avg Rating'],['✅','100%','Satisfaction Rate']].map(x=>`<div><div>${x[0]}</div><b style="font:800 1.4rem 'Plus Jakarta Sans'">${x[1]}</b><div style="font-size:.72rem;color:rgba(255,255,255,.65)">${x[2]}</div></div>`).join('')}</div>
      <button class="btn block" style="margin-top:16px;height:50px" data-rv="write">✍️ Write a Review</button>
      <h3 style="margin:22px 0 12px;font-size:1.1rem">Customer Reviews</h3>
      <div class="stack" id="rfeed"><div class="sk"></div><div class="sk"></div><div class="sk"></div></div></div></div>`;
  };
  window.reviewsAfter=function(){loading=!DB.length;renderFeed();loadFeed()};

  document.addEventListener('click',async e=>{
    const el=e.target.closest('[data-rv]');if(!el)return;
    switch(el.dataset.rv){
      case 'write':onWrite(el);break;
      case 'login':if(typeof openLogin==='function')openLogin();break;
      case 'star':rate=Number(el.dataset.n);document.querySelectorAll('#rv-st button').forEach((b,i)=>b.textContent=i<rate?'★':'☆');break;
      case 'submit':onSubmit(el);break;
      case 'del':confirmDel(el.dataset.id);break;
      case 'del-ok':{
        el.disabled=true;
        try{await sb.from('reviews').delete().eq('id',el.dataset.id).eq('user_id',S.user.id)}catch(x){}
        dlg().close();await loadFeed();break}
    }
  });
  // keep feed live: refresh every 30s while reviews page is open
  setInterval(()=>{if(document.getElementById('rfeed')&&!document.hidden)loadFeed()},30000);
})();
