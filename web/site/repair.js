/* Solar Maintenance & Repair booking (loaded after final.js).
   Flow: services card "Book now" -> booking page, step 1 = pick the solar problems (or type your own), then the same
   schedule / address / pay steps as the other services. Flat service charge: Rs 1,000.
   The problems are stored in the booking's service_name (the bookings table has no notes column) and the booking is
   saved with service_category 'solar' (the only other value the database allows besides 'water_tank'). */
(function(){
const REP={on:false,sel:new Set(),note:''},PRICE=1000;
window.REP=REP;
const PROBS=[
'Inverter not working','Inverter error / fault','ACDB problem','DCDB problem','Solar not working properly',
'Low voltage','Low output / less generation','No output at all','Wiring / loose connection','Sparking / burning smell',
'Panel damaged / hot-spot','Earthing / lightning arrestor','Monitoring / WiFi issue','General checkup & maintenance'];

const st=document.createElement('style');
st.textContent=`
.svt button{padding:10px 4px;font-size:.86rem}
.rchips{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0 6px}
.rchip{padding:10px 14px;min-height:44px;border-radius:12px;border:1.5px solid rgba(128,128,128,.35);background:transparent;color:inherit;font:inherit;font-size:.88rem;text-align:left;cursor:pointer}
.rchip.on{border-color:#06b6d4;background:color-mix(in srgb,#06b6d4 14%,transparent);font-weight:700}
.rchip.on::before{content:'\\2713  ';color:#06b6d4}
`;
document.head.appendChild(st);

const ready=()=>REP.sel.size>0||REP.note.trim().length>=5;
const tabs=()=>`<div class="svt"><button type="button" data-act="smode" data-m="water">💧 Water Tank</button><button type="button" data-act="smode" data-m="solar">☀️ Solar Panel</button><button type="button" data-act="rmode" class="on">🔧 Solar Repair</button></div>`;
function detailName(){
  const l=[...REP.sel].sort((a,b)=>a-b).map(i=>PROBS[i]);
  const note=REP.note.trim().replace(/\s+/g,' ');
  return ('Solar Maintenance & Repair — '+l.join(', ')+(note?(l.length?' | ':'')+'Other: '+note:'')).slice(0,300);
}

/* ---- price / summary ---- */
const _calc=calc;
calc=function(){
  if(!REP.on)return _calc();
  const c=S.cart,sub=PRICE,cp=c.coupon?c.coupon.discount:0,coins=c.useCoins?Math.min(S.coins,50):0;
  return {tanks:0,sub,bulk:0,cp,coins,total:Math.max(0,sub-cp-coins)};
};
const _sb=summaryBox;
summaryBox=function(){
  if(!REP.on)return _sb();
  const c=S.cart,t=calc(),n=REP.sel.size;
  const info=n||REP.note.trim()?`<p class="muted small" style="margin:6px 0">${n?n+' problem'+(n===1?'':'s')+' selected':''}${n&&REP.note.trim()?' + ':''}${REP.note.trim()?'your description':''}</p>`:'<p class="muted small" style="margin:6px 0">Select or describe your problem.</p>';
  return `<div class="card sum"><h4 style="margin-bottom:10px">Order summary</h4><div class="line"><span>Solar maintenance &amp; repair</span><span>${inr(t.sub)}</span></div>${info}${t.cp?`<div class="line ok"><span>Coupon ${h(c.coupon.code)}</span><span>−${inr(t.cp)}</span></div>`:''}${t.coins?`<div class="line ok"><span>Wallet coins</span><span>−${inr(t.coins)}</span></div>`:''}<div class="line t"><span>Total</span><span>${inr(t.total)}</span></div>${S.step>1?`<p class="muted small" style="margin-top:10px">📅 ${h(c.date)}${c.slot?'<br>🕒 '+h(c.slot):''}</p>`:''}</div>`;
};

/* ---- booking page ---- */
function stepOne(){
  const ok=ready();
  const body=`${tabs()}<h3>Solar maintenance &amp; repair</h3><p class="muted small" style="margin-bottom:6px">Select every problem you are facing, or type it yourself below. Service charge: ${inr(PRICE)}.</p>
  <div class="rchips">${PROBS.map((p,i)=>`<button type="button" class="rchip${REP.sel.has(i)?' on':''}" data-act="rpick" data-i="${i}" aria-pressed="${REP.sel.has(i)}">${h(p)}</button>`).join('')}</div>
  <label>Other problem (type it yourself)</label><textarea id="rep-note" rows="3" maxlength="300" placeholder="Describe your solar problem in your own words…">${h(REP.note)}</textarea>
  <button class="btn block" style="margin-top:20px" data-act="rnext" ${ok?'':'disabled'}>Next — choose date &amp; time →</button>`;
  return `<div class="page"><div class="wrap fade"><h1>Book a service</h1><div class="steps"><span class="on">1. Service</span><span>2. Schedule</span><span>3. Address</span><span>4. Pay</span></div><div class="bk"><div class="card">${body}</div>${summaryBox()}</div></div></div>`;
}
const _bv=bookView;
bookView=function(){
  if(!REP.on){
    const html=_bv();
    return S.step===1?html.replace(/(data-m="solar"[^>]*>[^<]*<\/button>)/,'$1<button type="button" data-act="rmode">🔧 Solar Repair</button>'):html;
  }
  if(S.step!==1)return _bv().replace('1. Tanks','1. Service');
  return stepOne();
};
/* update the step in place while picking (no re-render, so no blink and typing is never interrupted) */
function rUpd(summary){
  const nb=document.querySelector('[data-act="rnext"]');if(nb)nb.disabled=!ready();
  if(summary){const sm=document.querySelector('.bk .sum');if(sm)sm.outerHTML=summaryBox()}
}
const _ff=finishFlow;
finishFlow=function(){_ff();REP.on=false;REP.sel=new Set();REP.note=''};
const _pay=pay;
pay=function(){return REP.on?repPay():_pay()};

/* ---- payment (same flow as the other services) ---- */
async function findHook(oid){
  for(const ms of [0,700,1200,2000]){
    if(ms)await sleep(ms);
    const {data}=await sb.from('payments').select('status,booking_id').eq('razorpay_order_id',oid).maybeSingle();
    if(!data)return null;
    if(data.booking_id)return data.booking_id;
    if(data.status!=='SUCCESS')return null;
  }
  return null;
}
async function repPay(){
  if(S.paying)return;
  const c=S.cart,t=calc();
  const M={service_category:'solar'};
  const serviceName=detailName();
  if(!S.user)return openLogin();
  if(t.total<1)return toast('Total payable must be at least ₹1');
  if(typeof Razorpay==='undefined')return toast('Payment SDK failed to load. Please refresh and try again.');
  S.paying=true;const btn=document.getElementById('payBtn');if(btn){btn.disabled=true;btn.textContent='Preparing secure payment…'}
  const address=fullAddr();let order;
  try{
    const {data,error}=await sb.functions.invoke('create-razorpay-order',{body:{amount:t.total*100,currency:'INR',receipt:'rcpt_'+Date.now(),cartSnapshot:{serviceName,date:c.date,timeSlot:c.slot,address}}});
    if(error||!data?.id)throw error||new Error('no order');order=data;
  }catch(e){S.paying=false;toast('Could not create payment order. Please try again.');route();return}
  const oid=order.id;let settled=false;
  const onFail=async()=>{
    if(settled)return;settled=true;toast('Confirming your payment status…');
    const ok=await pollOrder(oid);S.paying=false;
    if(ok){
      if(ok.booking_id)await sb.from('bookings').update(M).eq('id',ok.booking_id);
      successDialog(ok.razorpay_payment_id||'',oid);finishFlow();await refreshCoins();route();return;
    }
    toast("We couldn’t confirm this payment yet. If money was deducted, it will appear in My Bookings shortly — please check before retrying.");
    await sb.from('payments').update({status:'FAILED',updated_at:new Date().toISOString()}).eq('razorpay_order_id',oid).eq('status','PENDING');
    route();
  };
  const onPaid=async r=>{
    if(settled)return;settled=true;
    const rid=r.razorpay_order_id||oid;
    try{
      const {data:v,error}=await sb.functions.invoke('verify-razorpay-payment',{body:{orderId:rid,paymentId:r.razorpay_payment_id,signature:r.razorpay_signature}});
      if(error||v?.verified!==true){toast('Payment verification failed. No booking was created.');S.paying=false;route();return}
    }catch(e){toast('Payment verification failed. No booking was created.');S.paying=false;route();return}
    if(c.useCoins&&t.coins>0)await deductCoins(t.coins,'Coins redeemed for booking');
    let bid=await findHook(rid);
    if(bid){await sb.from('bookings').update(M).eq('id',bid)}
    else{
      const row={user_id:S.user.id,service_name:serviceName,date:c.date,booking_date:c.date,booking_time:c.slot,address,status:'CONFIRMED',price:t.total,...M};
      const q=window.__bookOnce?window.__bookOnce(rid,row):sb.from('bookings').insert(row);
      const {data:bk}=await q.select().maybeSingle();
      bid=bk?.id||null;
    }
    await sb.from('payments').update({razorpay_payment_id:r.razorpay_payment_id,booking_id:bid,status:'SUCCESS',updated_at:new Date().toISOString()}).eq('razorpay_order_id',rid);
    if(c.coupon?.id)await markCouponUsed(c.coupon.id);
    if(c.phone&&!S.profile?.phone_number){await sb.from('profiles').update({phone_number:c.phone}).eq('id',S.user.id)}
    S.paying=false;successDialog(r.razorpay_payment_id,rid);finishFlow();route();
  };
  try{
    const rz=new Razorpay({key:order.key||RZP_FALLBACK,amount:t.total*100,currency:'INR',order_id:oid,name:'Homaclo',description:'Solar Maintenance & Repair Service',prefill:{email:S.user.email||'',contact:c.phone},theme:{color:'#072654'},retry:{enabled:true,max_count:1},timeout:300,handler:onPaid,modal:{ondismiss:onFail}});
    rz.on('payment.failed',onFail);rz.open();
  }catch(e){S.paying=false;toast('Could not open payment window.');route()}
}

/* ---- clicks ---- */
/* capture phase: leaving repair mode when another mode tab or a plain Book link is used (runs before the other handlers) */
document.addEventListener('click',e=>{
  if(!e.target.closest)return;
  const el=e.target.closest('[data-act]');
  if(el&&el.dataset.act==='smode')REP.on=false;
  const a=e.target.closest('a[href="#/book"],a[href="book"]');
  if(a&&REP.on&&!/^#\/book/.test(location.hash))REP.on=false;
},true);
document.addEventListener('click',e=>{
  const el=e.target.closest('[data-act]');if(!el)return;
  const act=el.dataset.act;
  if(act==='rbook'||act==='rmode'){
    REP.on=true;SOL.on=false;S.step=1;S.cart.coupon=null;S.cart.useCoins=false;
    if(act==='rmode')route();
  }else if(act==='rpick'){
    const i=Number(el.dataset.i);
    if(REP.sel.has(i))REP.sel.delete(i);else REP.sel.add(i);
    el.classList.toggle('on',REP.sel.has(i));el.setAttribute('aria-pressed',String(REP.sel.has(i)));
    rUpd(true);
  }else if(act==='rnext'){
    const n=document.getElementById('rep-note');if(n)REP.note=n.value;
    if(ready()){S.step=2;route()}
  }
});
document.addEventListener('input',e=>{
  if(e.target.id!=='rep-note')return;
  REP.note=e.target.value;rUpd(true);
});

/* ---- services page: Solar Maintenance & Repair card gets a Book now button (instead of Coming soon) and the Rs 1,000 price ---- */
function fixRep(){
  document.querySelectorAll('#svc .card').forEach(c=>{
    const t=c.textContent;
    if(!(/solar/i.test(t)&&/maintenance|repair/i.test(t)))return;
    if(c.querySelector('[data-act="rbook"]'))return;
    c.querySelectorAll('*').forEach(x=>{
      if(x.children.length||!/^\s*coming\s*soon\s*$/i.test(x.textContent))return;
      let n=x;while(n.parentElement&&n.parentElement!==c)n=n.parentElement;
      n.remove();
    });
    const p=c.querySelector('.price');
    if(p)[...p.childNodes].forEach(n=>{if(n.nodeType===3&&/₹/.test(n.nodeValue))n.nodeValue=n.nodeValue.replace(/₹\s*[\d,]+/,inr(PRICE))});
    const a=document.createElement('a');a.className='btn sm';a.href='#/book';a.dataset.act='rbook';a.textContent='Book now';
    c.appendChild(a);
  });
}
new MutationObserver(()=>requestAnimationFrame(fixRep)).observe(document.getElementById('app'),{childList:true,subtree:true});
fixRep();
})();
