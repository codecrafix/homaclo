(function(){
const $$=(s,e=document)=>[...e.querySelectorAll(s)];
function fix(){$$('#svc .card').forEach(c=>{const i=c.querySelector('.ph img');if(!i||i.dataset.s)return;const t=c.textContent;if(/solar/i.test(t)&&/cleaning/i.test(t)&&!/maintenance|repair/i.test(t)){i.dataset.s=1;i.onerror=()=>{i.onerror=null;i.src='img/maintix-7.png'};i.src='img/maintix-9.png'}})}
new MutationObserver(()=>requestAnimationFrame(fix)).observe(document.getElementById('app'),{childList:true,subtree:true});fix();
})();

/* Signup bonus (parity with the app): the Supabase trigger credits 50 welcome coins at account
   creation. claim_signup_bonus() is an idempotent server-side fallback for accounts the trigger
   missed (e.g. created before it existed). Safe to call on every login: it can only ever pay once. */
(function(){
const tried=new Set();
const seenKey=id=>'mx_welcome_'+id;
const seen=id=>{try{return !!localStorage.getItem(seenKey(id))}catch(e){return false}};
const mark=id=>{try{localStorage.setItem(seenKey(id),'1')}catch(e){}};
sb.auth.onAuthStateChange((ev,session)=>{
  const u=session&&session.user;
  if(!u||tried.has(u.id))return;
  tried.add(u.id);
  // Never await Supabase calls inside this callback (known deadlock); defer instead.
  setTimeout(async()=>{
    try{
      const {data,error}=await sb.rpc('claim_signup_bonus');
      if(error){tried.delete(u.id);return}
      let show=data===true;
      if(!show&&!seen(u.id)){
        const since=new Date(Date.now()-7*864e5).toISOString();
        const {data:w}=await sb.from('coin_transactions').select('id').eq('user_id',u.id).eq('type','welcome').gte('created_at',since).limit(1);
        show=!!(w&&w.length);
      }
      if(show){
        mark(u.id);
        await refreshCoins();
        toast('Welcome to Homaclo! 50 bonus coins added 🪙');
        route();
      }
      // Monthly +50 coins (same 30-day rule as the app, enforced server-side so it can't double-credit).
      const {data:mb}=await sb.rpc('claim_monthly_bonus');
      if(mb===true){await refreshCoins();toast('Monthly bonus! +50 coins added 🪙');route()}
      if(window.mxUnread)window.mxUnread();
    }catch(e){tried.delete(u.id)}
  },600);
});
})();

/* Parity with the app: Notifications screen + unread bell, review-reward notification. */
(function(){
Object.assign(ROUTES,{notifications:'notifications'});
const ICON={welcome:'🎉',coupon:'🏷️',reward:'🪙',bonus:'🪙',offer:'🎁',broadcast:'📢',booking:'📅'};
const when=t=>{try{return new Date(t).toLocaleString('en-IN',{day:'numeric',month:'short',hour:'numeric',minute:'2-digit'})}catch(e){return ''}};
let unread=0;
function bell(){
  let b=document.getElementById('nbBell');
  if(!b){
    const r=document.querySelector('.nav-r');if(!r)return null;
    b=document.createElement('a');b.id='nbBell';b.href='#/notifications';b.className='icon';
    b.setAttribute('aria-label','Notifications');b.style.cssText='position:relative;text-decoration:none;display:none';
    b.innerHTML='🔔<i style="position:absolute;top:-4px;right:-4px;min-width:16px;height:16px;padding:0 4px;border-radius:8px;background:#e5484d;color:#fff;font:700 10px/16px system-ui;text-align:center;font-style:normal;display:none"></i>';
    r.insertBefore(b,document.getElementById('authBtn'));
  }
  return b;
}
function paint(){
  const b=bell();if(!b)return;
  const c=b.querySelector('i');c.textContent=unread>99?'99+':unread;c.style.display=unread?'':'none';
  b.style.display=S.user?'':'none';
}
async function refreshUnread(){
  if(!S.user){unread=0;paint();return}
  const {count}=await sb.from('notifications').select('id',{count:'exact',head:true}).eq('user_id',S.user.id).eq('is_read',false);
  unread=count||0;paint();
}
window.mxUnread=refreshUnread;
async function loadNotes(){
  const el=document.getElementById('nlist');if(!el||!S.user)return;
  const {data}=await sb.from('notifications').select('*').eq('user_id',S.user.id).order('created_at',{ascending:false}).limit(50);
  el.innerHTML=(data&&data.length)?data.map(n=>`<div class="card" style="margin:10px 0;display:flex;gap:12px;align-items:flex-start;${n.is_read?'':'border-left:3px solid #0a84ff'}"><span style="font-size:22px">${ICON[n.type]||'🔔'}</span><div style="flex:1;min-width:0"><b>${h(n.title)}</b><div class="muted small" style="margin-top:4px">${h(n.body)}</div><div class="muted small" style="margin-top:6px;opacity:.7">${h(when(n.created_at))}</div></div><button class="btn ghost sm" data-nx="${h(n.id)}" aria-label="Delete notification">✕</button></div>`).join(''):'<p class="muted" style="margin:30px 0">No notifications yet.</p>';
  await sb.from('notifications').update({is_read:true}).eq('user_id',S.user.id).eq('is_read',false);
  unread=0;paint();
}
document.addEventListener('click',async e=>{
  const b=e.target.closest('[data-nx]');if(!b||!S.user)return;
  b.disabled=true;
  const {error}=await sb.from('notifications').delete().eq('id',b.dataset.nx).eq('user_id',S.user.id);
  if(error){b.disabled=false;toast('Could not delete. Try again.');return}
  const c=b.closest('.card');if(c)c.remove();
});
document.addEventListener('DOMContentLoaded',()=>{
  const _lv=legalView;
  legalView=function(k){
    if(k==='notifications'){
      if(!S.user)return gate('Sign in to see your notifications');
      setTimeout(loadNotes,0);
      return '<div class="page"><div class="wrap fade"><h1>Notifications</h1><div id="nlist"><div class="boot"><span></span></div></div></div></div>';
    }
    return _lv(k);
  };
  bell();paint();
  if(/^#\/notifications/.test(location.hash))route();
});
sb.auth.onAuthStateChange((ev,session)=>{
  setTimeout(()=>{if(!session||!session.user){unread=0;paint();return}refreshUnread()},0);
});
// Review reward notification (the app sends one after +10 coins).
const _ac=addCoins;
addCoins=async function(n,type,desc){
  const ok=await _ac(n,type,desc);
  if(ok&&type==='reward'&&/^Review submitted/.test(desc||'')&&S.user){
    await sb.from('notifications').insert({user_id:S.user.id,title:'Review Reward! 🪙',body:'+10 Coins added for submitting your review!',type:'reward'});
    refreshUnread();
  }
  return ok;
};
})();

/* Profile photo upload (same mechanism as the app): resized + compressed JPEG goes to the public
   'avatars' bucket at {user_id}/avatar_<timestamp>.jpg, and the public URL is saved in profiles.avatar_url. */
(function(){
const MAX=800,QUALITY=.85,LIMIT=15*1024*1024,MARK='/storage/v1/object/public/avatars/';
function compress(file){
  return new Promise((ok,no)=>{
    const url=URL.createObjectURL(file),img=new Image();
    img.onload=()=>{
      try{
        const k=Math.min(1,MAX/Math.max(img.naturalWidth,img.naturalHeight));
        const w=Math.max(1,Math.round(img.naturalWidth*k)),hh=Math.max(1,Math.round(img.naturalHeight*k));
        const c=document.createElement('canvas');c.width=w;c.height=hh;
        const x=c.getContext('2d');x.fillStyle='#fff';x.fillRect(0,0,w,hh);x.drawImage(img,0,0,w,hh);
        c.toBlob(b=>b?ok(b):no(new Error('compress failed')),'image/jpeg',QUALITY);
      }catch(e){no(e)}finally{URL.revokeObjectURL(url)}
    };
    img.onerror=()=>{URL.revokeObjectURL(url);no(new Error('bad image'))};
    img.src=url;
  });
}
const BADGE='<span aria-hidden="true" style="position:absolute;right:-4px;bottom:-4px;width:22px;height:22px;border-radius:50%;background:#0a84ff;color:#fff;display:grid;place-items:center;font-size:12px;border:2px solid #fff">📷</span>';
document.addEventListener('DOMContentLoaded',()=>{
  const _pv=profileView;
  profileView=function(){
    const html=_pv();
    if(!S.user||!S.profile)return html;
    const re=/<div class="av" style="([^"]*)">([^<]*)<\/div>/;
    if(!re.test(html))return html;
    const u=S.profile.avatar_url;
    return html.replace(re,(m,st,ini)=>{
      const inner=u?`<img class="av" id="avimg" alt="Profile photo" src="${h(u)}" style="width:56px;height:56px;object-fit:cover">`:m;
      return `<label for="avf" id="avlab" title="Change profile photo" style="position:relative;cursor:pointer;display:block;flex:none;width:56px;height:56px"><span id="avbox">${inner}</span>${BADGE}</label><input id="avf" type="file" accept="image/jpeg,image/png,image/webp" hidden>`;
    });
  };
  if(/^#\/profile/.test(location.hash)&&S.user)route();
});
document.addEventListener('change',async e=>{
  const f=e.target;if(!f||f.id!=='avf'||!f.files||!f.files[0]||!S.user)return;
  const file=f.files[0];f.value='';
  if(!/^image\/(jpeg|png|webp)$/.test(file.type)){toast('Please choose a JPG, PNG or WebP image');return}
  if(file.size>LIMIT){toast('Image is too large (max 15 MB)');return}
  const box=document.getElementById('avbox');if(!box)return;
  const before=box.innerHTML,prev=URL.createObjectURL(file);
  box.innerHTML=`<img class="av" id="avimg" alt="Profile photo" src="${prev}" style="width:56px;height:56px;object-fit:cover;opacity:.55">`;
  try{
    const blob=await compress(file);
    const uid=S.user.id,path=`${uid}/avatar_${Date.now()}.jpg`;
    const up=await sb.storage.from('avatars').upload(path,blob,{contentType:'image/jpeg',upsert:true});
    if(up.error)throw up.error;
    const url=sb.storage.from('avatars').getPublicUrl(path).data.publicUrl;
    const {error}=await sb.from('profiles').update({avatar_url:url,updated_at:new Date().toISOString()}).eq('id',uid);
    if(error){sb.storage.from('avatars').remove([path]);throw error}
    const old=S.profile&&S.profile.avatar_url;
    if(S.profile)S.profile.avatar_url=url;
    const im=document.getElementById('avimg');if(im){im.src=url;im.style.opacity=''}
    toast('Profile photo updated ✅');
    const i=old?old.indexOf(MARK):-1;
    if(i>-1){const key=decodeURIComponent(old.slice(i+MARK.length).split('?')[0]);if(key&&key!==path)sb.storage.from('avatars').remove([key])}
  }catch(err){
    const b=document.getElementById('avbox');if(b)b.innerHTML=before;
    toast('Could not upload photo. Please try again.');
  }finally{URL.revokeObjectURL(prev)}
});
})();
