(function(){
'use strict';
/* My Bookings: same layout as the app (booking_history_screen.dart): Active / Completed sections, status badge,
   Service Date, Time Slot (12-hour), Booked On (IST), address, Total Paid, payment chip, Remove from History, Refresh. */
const $=(s,e=document)=>e.querySelector(s);
const done=s=>/^(completed|done)$/i.test(s||'');
const prog=s=>/^in[ _-]?progress$/i.test(s||'');
const ok=v=>v&&v!=='null'?v:'';
function t12(v){
  const s=String(v||'').trim();if(!s||s==='null')return '';
  if(/am|pm/i.test(s))return s;
  const m=s.match(/^(\d{1,2}):(\d{2})/);if(!m||+m[1]>23)return s;
  const H=+m[1];return ((H%12)||12)+':'+m[2]+' '+(H>=12?'PM':'AM');
}
function booked(iso){
  try{
    const d=new Date(iso);if(isNaN(d))return '';
    const z={timeZone:'Asia/Kolkata'};
    return d.toLocaleDateString('en-IN',{...z,day:'numeric',month:'short',year:'numeric'})+' at '+d.toLocaleTimeString('en-IN',{...z,hour:'numeric',minute:'2-digit',hour12:true}).toUpperCase();
  }catch(e){return ''}
}
const row=(i,l,v)=>`<div class="line"><span class="muted">${i} ${l}</span><b style="text-align:right">${h(v)}</b></div>`;
function card(b){
  const d=done(b.status),sd=ok(b.date)||ok(b.booking_date)||'—',ts=t12(b.booking_time),bo=booked(b.created_at);
  const pill=d?['Completed','g']:prog(b.status)?['In Progress','']:['Confirmed','g'];
  return `<div class="card hov" style="border-left:3px solid ${d?'var(--ok,#16a34a)':'var(--teal,#0d9488)'}">
  <div class="row"><b class="grow" style="color:var(--teal,#0d9488)">${h(b.service_name)}</b><span class="pill ${pill[1]}">${pill[0]}</span></div>
  <div style="margin-top:10px">${row('📅','Service Date',sd)}${ts?row('🕒','Time Slot',ts):''}${bo?row('✅','Booked On',bo):''}${b.address?row('📍','Address',b.address):''}</div>
  <div class="line" style="margin-top:6px"><span class="muted">Total Paid</span><b class="price" style="font-size:1.3rem">${inr(b.price)}</b></div>
  <span class="pill g" style="margin-top:8px">${b.status==='CONFIRMED'?'💳 Paid via Razorpay':'💵 Cash on Service'}</span>
  <button class="btn ghost sm block" style="margin-top:12px" data-bk="del" data-id="${h(b.id)}">🗑 Remove from History</button></div>`;
}
const sec=(t,l)=>l.length?`<h3 style="margin:18px 0 10px;font-size:1.05rem">${t} <span class="pill g">${l.length}</span></h3><div class="stack">${l.map(card).join('')}</div>`:'';
async function load(){
  if(!S.user||!$('#bl'))return;
  let data=null,err=null;
  /* hidden_by_user=false: removed bookings stay out of the list even for admin accounts (who can see every row) */
  try{const r=await sb.from('bookings').select('*').eq('user_id',S.user.id).eq('hidden_by_user',false).order('created_at',{ascending:false});data=r.data;err=r.error}catch(e){err=e}
  const box=$('#bl');if(!box)return;
  if(err){box.innerHTML='<div class="card c"><p class="muted">Could not load your bookings.</p><button class="btn sm" style="margin-top:14px" data-bk="refresh">Try again</button></div>';return}
  if(!data||!data.length){box.innerHTML='<div class="card c"><p class="muted">No bookings yet.</p><a class="btn sm" style="margin-top:14px" href="#/book">Book your first cleaning</a></div>';return}
  box.innerHTML=`<div class="row"><span class="muted small grow">${data.length} booking${data.length!==1?'s':''}</span><button class="btn ghost sm" data-bk="refresh">↻ Refresh</button></div>`+sec('Active Bookings',data.filter(b=>!done(b.status)))+sec('Completed',data.filter(b=>done(b.status)));
}
bookingsAfter=load;

/* WEL100 is for the first booking only: also count bookings the user removed from My Bookings (server-side check) */
const _vc=validateCoupon;
validateCoupon=async function(code){
  const r=await _vc(code);
  if(r&&r.valid&&r.code==='WEL100'&&S.user){
    try{
      const {data}=await sb.rpc('current_user_has_booking');
      if(data===true)return {valid:false,message:'WEL100 is only valid on your first booking'};
    }catch(e){}
  }
  return r;
};

document.addEventListener('click',async e=>{
  const el=e.target.closest('[data-bk]');if(!el)return;
  const a=el.dataset.bk;
  if(a==='refresh'){const b=$('#bl');if(b)b.innerHTML='<div class="sk"></div><div class="sk"></div>';load()}
  else if(a==='del'){
    const d=$('#dlg');
    d.innerHTML=`<h3>Remove Booking?</h3><p class="muted small" style="margin:8px 0 18px">This booking will be removed from your My Bookings list. Old bookings are also removed automatically after 7 days.</p><div class="row"><button class="btn ghost grow" data-act="close">Cancel</button><button class="btn grow" style="background:var(--err);color:#fff;box-shadow:none" data-bk="del-ok" data-id="${h(el.dataset.id)}">Delete</button></div>`;
    if(!d.open)d.showModal();
  }else if(a==='del-ok'&&S.user){
    el.disabled=true;
    let good=false;
    try{const r=await sb.rpc('hide_my_booking',{p_booking_id:el.dataset.id});good=!r.error&&r.data===true}catch(x){}
    const d=$('#dlg');if(d&&d.open)d.close();
    if(!good)toast('Failed to delete booking. Try again.');
    load();
  }
});
})();
