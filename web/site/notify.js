(function(){
'use strict';
/* Notifications: same system as the app. Rows go into the `notifications` table (the DB webhook sends the OneSignal push to app devices),
   the web listens in real time, updates the bell and shows a system notification once the user allows it. */
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const LS=(k,v)=>{try{if(v===undefined)return localStorage.getItem(k);localStorage.setItem(k,v)}catch(e){return null}};
async function push(uid,title,body,type){
  try{await sb.from('notifications').insert(Array.isArray(title)?title.map(r=>({...r,user_id:uid})):{user_id:uid,title,body,type})}catch(e){}
}

/* Service worker (image cache + notification clicks) */
if('serviceWorker' in navigator)addEventListener('load',()=>navigator.serviceWorker.register('sw.js').catch(()=>{}));

/* System notification (works on Android Chrome through the service worker) */
async function sys(n){
  if(!('Notification' in window)||Notification.permission!=='granted')return;
  const o={body:n.body||'',tag:String(n.id||Date.now()),data:{url:location.href.split('#')[0]+'#/notifications'}};
  try{
    const reg='serviceWorker' in navigator?await navigator.serviceWorker.getRegistration():null;
    if(reg){await reg.showNotification(n.title||'Homaclo',o);return}
    new Notification(n.title||'Homaclo',o);
  }catch(e){}
}

/* Real-time listener (same as NotificationService.subscribeToUserNotifications) */
let ch=null,chUid=null;
function sub(u){
  if(!u){if(ch){sb.removeChannel(ch);ch=null;chUid=null}return}
  if(chUid===u.id)return;
  if(ch)sb.removeChannel(ch);
  chUid=u.id;
  ch=sb.channel('web_notifications_'+u.id).on('postgres_changes',{event:'INSERT',schema:'public',table:'notifications',filter:'user_id=eq.'+u.id},p=>{
    if(window.mxUnread)window.mxUnread();
    if(/^#\/notifications/.test(location.hash))route();
    sys(p.new||{});
  }).subscribe();
}

/* Login / signup notifications (same texts as AppState) */
const done=new Set();
async function onLogin(u){
  if(done.has(u.id))return;done.add(u.id);
  try{
    const {data:w}=await sb.from('notifications').select('id').eq('user_id',u.id).eq('type','welcome').limit(1);
    if(w&&w.length)return;
    const since=new Date(Date.now()-7*864e5).toISOString();
    const {data:c}=await sb.from('coin_transactions').select('id').eq('user_id',u.id).eq('type','welcome').gte('created_at',since).limit(1);
    const rows=[{title:'Welcome to Homaclo! 🚰',body:'Book your professional water tank cleaning slot today.',type:'welcome'}];
    if(c&&c.length)rows.push({title:'Welcome Bonus! 🪙',body:'You received 50 Coins on signup! (Value ₹50)',type:'welcome'},{title:'Welcome Offer! 🎁',body:'Get ₹100 Flat Discount on your first booking using code WEL100!',type:'coupon'});
    await push(u.id,rows);
    if(window.mxUnread)window.mxUnread();
  }catch(e){done.delete(u.id)}
}

/* 3-tank offer after a booking. "Booking Confirmed" and "Payment Received" notifications are created ONCE by the
   database (server side) when the payment succeeds, so the website no longer adds them again (that caused duplicates). */
async function threeTank(uid){
  try{
    const {data}=await sb.from('bookings').select('service_name,status').eq('user_id',uid);
    const n=(data||[]).filter(b=>/tank/i.test(b.service_name||'')&&/^(completed|confirmed)$/i.test(b.status||'')).length;
    if(n>=3)return;
    const kc='mx_3t_c_'+uid+'_'+new Date().getDate(),kl='mx_3t_l_'+uid,sent=Number(LS(kc)||0);
    if(sent>=3)return;
    const last=LS(kl);if(last&&Date.now()-new Date(last).getTime()<4*36e5)return;
    await push(uid,'Special Offer! 🎉','Get ₹500 Flat Discount on 3 Tank Cleaning Bookings! Book now.','offer');
    LS(kc,sent+1);LS(kl,new Date().toISOString());
  }catch(e){}
}
const _sd=successDialog;
successDialog=function(pid,oid){
  _sd(pid,oid);
  const u=S.user;if(!u)return;
  threeTank(u.id);
};

/* Monthly bonus notification (claim_monthly_bonus returns true only when coins were credited) */
const _rpc=sb.rpc.bind(sb);
sb.rpc=function(name,args,opts){
  const p=_rpc(name,args,opts);
  if(name!=='claim_monthly_bonus')return p;
  return Promise.resolve(p).then(r=>{
    if(r&&r.data===true&&S.user)push(S.user.id,'Monthly Bonus! 🪙','+50 Coins credited to your wallet this month!','bonus');
    return r;
  });
};

/* Permission prompt */
function ask(){
  if(!S.user||!('Notification' in window)||Notification.permission!=='default'||$('#npop'))return;
  if(Date.now()-Number(LS('mx_np_t')||0)<3*864e5)return;
  const d=document.createElement('div');d.id='npop';d.setAttribute('role','dialog');d.setAttribute('aria-label','Enable notifications');
  d.innerHTML='<span class="np-i">🔔</span><div class="np-t"><b>Turn on notifications</b><span>Get booking updates, offers and rewards instantly.</span></div><button class="btn sm" data-np="allow">Allow</button><button class="np-x" data-np="no" aria-label="Not now">✕</button>';
  document.body.appendChild(d);
}
document.addEventListener('click',async e=>{
  const b=e.target.closest('[data-np]');if(!b)return;
  LS('mx_np_t',String(Date.now()));
  const p=$('#npop');if(p)p.remove();
  if(b.dataset.np!=='allow')return;
  try{
    const r=await Notification.requestPermission();
    if(r==='granted')sys({id:'welcome-on',title:'Notifications enabled 🔔',body:'You will now get booking updates, offers and rewards.'});
  }catch(x){}
});

/* Clear all notifications (button appears above the list on the Notifications page) */
function clr(){
  const l=$('#nlist');
  if(!l||!l.querySelector('.card')){const x=$('#nclr');if(x)x.remove();return}
  if($('#nclr'))return;
  const w=document.createElement('div');
  w.id='nclr';w.className='row';w.style.cssText='justify-content:flex-end;margin:4px 0 8px';
  w.innerHTML='<button class="btn ghost sm" data-nclr="1">🗑 Clear all</button>';
  l.parentNode.insertBefore(w,l);
}
new MutationObserver(()=>requestAnimationFrame(clr)).observe($('#app'),{childList:true,subtree:true});
document.addEventListener('click',async e=>{
  const b=e.target.closest('[data-nclr]');if(!b||!S.user)return;
  if(!confirm('Clear all notifications?'))return;
  b.disabled=true;
  const {error}=await sb.from('notifications').delete().eq('user_id',S.user.id);
  if(error){b.disabled=false;toast('Could not clear. Try again.');return}
  const l=$('#nlist');if(l)l.innerHTML='<p class="muted" style="margin:30px 0">No notifications yet.</p>';
  const x=$('#nclr');if(x)x.remove();
  if(window.mxUnread)window.mxUnread();
  toast('All notifications cleared');
});

sb.auth.onAuthStateChange((ev,session)=>{
  const u=session&&session.user||null;
  setTimeout(()=>{
    sub(u);
    if(u){setTimeout(()=>onLogin(u),2500);setTimeout(ask,4500)}
    else{const p=$('#npop');if(p)p.remove()}
  },0);
});

/* Faster images: hero first, rest lazy + async decode; warm the cache when idle on a good connection */
function perf(){
  $$('img').forEach(i=>{
    i.decoding='async';
    if(i.closest('.hero')){i.loading='eager';i.setAttribute('fetchpriority','high')}
    else if(!i.hasAttribute('loading'))i.loading='lazy';
  });
}
let q=0;
new MutationObserver(()=>{cancelAnimationFrame(q);q=requestAnimationFrame(perf)}).observe($('#app'),{childList:true,subtree:true});
perf();
addEventListener('load',()=>{
  const c=navigator.connection;if(c&&(c.saveData||c.effectiveType!=='4g'))return;
  (window.requestIdleCallback||(f=>setTimeout(f,2500)))(()=>{
    ['maintix-8','maintix-7','maintix-9','maintix-1','maintix-2','maintix-3','maintix-4','maintix-5','maintix-6','maintix-10','before','after'].forEach(n=>{new Image().src='img/'+n+'.png'});
  });
});
})();
