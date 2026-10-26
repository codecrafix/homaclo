'use strict';
/* Reviews system — mirrors app: reviews_screen.dart, reviews_card_widget.dart, profile_menu_widget.dart (My Reviews), AppState review logic.
   - Public feed = approved reviews only (newest first) + 6 Satna sample reviews; header avg = DB avg or 5.0
   - Write a Review always visible: signed out -> sign-in prompt; no booking -> locked; latest review newer than latest booking -> locked
   - Submit: insert (is_approved=false) + 10 coins, then locked until next booking
   - Profile -> My Reviews: all of the user's reviews, ✅ Live / ⏳ Approval pending */
(function(){
  const COLORS=['#3b82f6','#10b981','#ec4899','#f59e0b','#8b5cf6','#06b6d4','#0d9488'];
  const TEAL='#06a9cc';
  const MOCK=[
    ['Rajesh Sharma','Civil Lines, Satna','2 weeks ago',5,'Excellent service! The team was professional and thorough. My 1000L tank was cleaned spotlessly. Water quality has improved significantly. Highly recommend to everyone in Satna!','1000L Cleaned','#3B82F6','RS'],
    ['Ramesh Tiwari','Dawari, Satna','2 weeks ago',5,'Bahut achha service hai! Team time par aayi aur tank bilkul saaf kar diya. Paani ab zyada saaf aata hai. Homaclo ki team bahut professional hai. Definitely recommend karunga.','1000L Tank Cleaned','#10B981','RT'],
    ['Priya Sharma','Pateri, Satna','3 weeks ago',4,'Good service, reasonable price. The technician was very professional and explained everything clearly. My family was worried about water quality but now we are fully satisfied.','750L Cleaned','#EC4899','PS'],
    ['Suresh Gupta','Birla Road, Satna','1 month ago',5,'Superb experience! Booked online and the team arrived exactly on time. Tank cleaning was done in under 2 hours. Very affordable pricing. Will definitely book again.','1500L Cleaned','#F59E0B','SG'],
    ['Anita Verma','Maihar Bypass, Satna','3 weeks ago',5,'Excellent work by the Homaclo team. They cleaned our 2000L overhead tank thoroughly. The water now tastes much better. Highly professional and courteous staff.','2000L Cleaned','#8B5CF6','AV'],
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
    return `<div style="position:relative;padding:16px;border-radius:16px;background:var(--sf);box-shadow:var(--sh);border-left:3px solid ${o.color}80">
      <div style="display:flex;gap:12px;align-items:center"><div class="av" style="width:44px;height:44px;background:${o.color}">${h(o.initials)}</div>
        <div style="flex:1;min-width:0"><div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap"><b style="font-size:.92rem">${h(o.name)}</b><span style="padding:2px 6px;border-radius:6px;background:color-mix(in srgb,var(--ok) 12%,transparent);color:var(--ok);font-size:.62rem;font-weight:700">✓ Verified</span></div>
        <div class="muted" style="font-size:.72rem">📍 ${h(o.location)}</div></div>
        <div style="text-align:right;flex:none"><div class="stars" style="font-size:.85rem;letter-spacing:1px">${stars5(o.rating)}</div><div class="muted" style="font-size:.66rem">${h(o.timeAgo)}</div></div></div>
      <p class="muted" style="margin:12px 0 10px;font-size:.88rem">${h(o.review)}</p>
      <span style="display:inline-block;padding:4px 10px;border-radius:20px;background:color-mix(in srgb,${TEAL} 14%,transparent);color:${TEAL};font-size:.74rem;font-weight:600">💧 ${h(o.tag)}</span>
      ${o.del?`<button data-rv="del" data-id="${h(o.del)}" aria-label="Delete review" style="position:absolute;bottom:10px;right:10px;border:0;border-radius:50%;width:30px;height:30px;cursor:pointer;background:color-mix(in srgb,var(--err) 12%,transparent);color:var(--err)">🗑</button>`:''}</div>`;
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

  /* ---- eligibility (same logic as AppState.checkReviewEligibility) ---- */
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
      <button class="btn block" id="rv-go" style="margin-top:16px;background:${TEAL};color:#fff;box-shadow:none" data-rv="submit">Submit Review (+10 🪙)</button>
      <button class="btn ghost block" style="margin-top:10px" data-act="close">Cancel</button>`;
    if(!d.open)d.showModal();
  }
  async function onWrite(btn){
    if(!S.user){info('🔐','Sign in required','Please login or signup first to write a review.',['Sign in / Sign up','login']);return}
    const o=btn.innerHTML;btn.disabled=true;btn.textContent='Checking…';
    let e;try{e=await eligibility()}catch(x){e={s:'err'}}
    btn.disabled=false;btn.innerHTML=o;
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

  /* ---- Profile -> My Reviews (all own reviews incl. pending) ---- */
  async function openMy(){
    const d=dlg();
    d.innerHTML='<h3>My Reviews</h3><div class="sk" style="margin-top:14px"></div>';
    if(!d.open)d.showModal();
    let list=[];
    try{const {data}=await sb.from('reviews').select('*').eq('user_id',S.user.id).order('created_at',{ascending:false});list=data||[]}catch(e){}
    const body=list.length?list.map(r=>`<div style="padding:14px;border-radius:12px;background:var(--bg);margin-bottom:12px">
      <div style="display:flex;align-items:center"><span class="stars" style="letter-spacing:1px">${stars5(Math.round(r.rating))}</span><span style="flex:1"></span><button data-rv="my-del" data-id="${h(r.id)}" aria-label="Delete review" style="border:0;background:none;color:var(--err);cursor:pointer;font-size:1rem">🗑</button></div>
      <p class="muted small" style="margin:6px 0 4px">${h(r.review_text)}</p>
      <div class="muted" style="font-size:.72rem">${h(ago(r.created_at))}  •  ${r.is_approved?'✅ Live':'⏳ Approval pending'}</div></div>`).join('')
      :`<div class="c" style="padding:34px 0"><div style="font-size:2.6rem;color:var(--mut)">☆</div><b class="muted" style="display:block;margin:8px 0 4px">No reviews yet</b><span class="muted small">Complete a booking to write your first review</span></div>`;
    d.innerHTML=`<div style="display:flex;align-items:center;margin-bottom:12px"><h3 style="font-size:1.15rem">My Reviews</h3><span style="flex:1"></span><span style="padding:4px 10px;border-radius:12px;background:color-mix(in srgb,${TEAL} 14%,transparent);color:${TEAL};font-size:.76rem;font-weight:600">${list.length} review${list.length!==1?'s':''}</span></div>
      <div style="max-height:55vh;overflow-y:auto">${body}</div><button class="btn ghost block" style="margin-top:12px" data-act="close">Close</button>`;
  }
  function injectMy(){
    const ctx=document.getElementById('ctx');if(!ctx||document.getElementById('rv-my'))return;
    const stack=ctx.closest('.stack');if(!stack)return;
    const b=document.createElement('button');b.id='rv-my';b.dataset.rv='my';b.className='card';
    b.style.cssText='display:flex;gap:12px;align-items:center;width:100%;text-align:left;cursor:pointer;font:inherit;color:inherit';
    b.innerHTML='<span style="width:40px;height:40px;border-radius:10px;background:rgba(245,158,11,.14);display:grid;place-items:center;font-size:1.2rem">⭐</span><span style="flex:1"><b style="display:block">My Reviews</b><span class="muted small">Reviews you have submitted</span></span><span class="muted">›</span>';
    stack.insertBefore(b,stack.children[1]||null);
  }
  const appEl=document.getElementById('app');
  if(appEl){new MutationObserver(injectMy).observe(appEl,{childList:true,subtree:true});injectMy()}

  /* ---- Reviews page (replaces old reviewsView/reviewsAfter from app.js) ---- */
  window.reviewsView=function(){
    return `<div class="page"><div class="wrap fade" style="max-width:820px">
      <div style="background:linear-gradient(135deg,#0f2a47,#1a3f5c);color:#fff;border-radius:22px;padding:34px 26px 20px">
        <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap"><span style="color:#f59e0b;font-size:1.7rem">★</span><b id="rv-avg" style="font:800 2rem 'Plus Jakarta Sans'">5.0</b>
        <span style="padding:4px 10px;border-radius:8px;background:rgba(22,163,74,.25);color:#4ade80;font-weight:700;font-size:.78rem">✓ Verified</span></div>
        <p style="color:rgba(255,255,255,.7);margin-top:8px">What our customers say</p></div>
      <div style="display:grid;grid-template-columns:repeat(3,1fr);margin-top:16px;background:linear-gradient(135deg,#0f2a47,#0a5a8a);color:#fff;border-radius:18px;padding:18px 6px;text-align:center">
        ${[['👥','500+','Happy<br>Customers'],['★','5.0','Avg<br>Rating'],['✅','100%','Satisfaction<br>Rate']].map((x,i)=>`<div style="${i?'border-left:1px solid rgba(255,255,255,.15)':''}"><div style="font-size:1.2rem">${x[0]}</div><b style="font:800 1.5rem 'Plus Jakarta Sans'">${x[1]}</b><div style="font-size:.72rem;color:rgba(255,255,255,.65);line-height:1.3">${x[2]}</div></div>`).join('')}</div>
      <button class="btn block" style="margin-top:16px;height:50px;border-radius:14px;background:${TEAL};color:#fff;box-shadow:none" data-rv="write">✍️ Write a Review</button>
      <h3 style="margin:22px 0 12px;font-size:1.1rem;font-family:'Plus Jakarta Sans',sans-serif">Customer Reviews</h3>
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
      case 'my':if(S.user)openMy();break;
      case 'del':confirmDel(el.dataset.id);break;
      case 'del-ok':{
        el.disabled=true;
        try{await sb.from('reviews').delete().eq('id',el.dataset.id).eq('user_id',S.user.id)}catch(x){}
        dlg().close();await loadFeed();break}
      case 'my-del':{
        try{await sb.from('reviews').delete().eq('id',el.dataset.id).eq('user_id',S.user.id)}catch(x){}
        dlg().close();await loadFeed();say('Review deleted');break}
    }
  });
  // keep the public feed live: refresh every 30s while the reviews page is open
  setInterval(()=>{if(document.getElementById('rfeed')&&!document.hidden)loadFeed()},30000);
})();
