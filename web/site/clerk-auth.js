(function(){
'use strict';
/* Google sign-in through Clerk, side by side with the existing email-code login.
   - Old users and old app builds keep working (Supabase Auth is untouched).
   - A Clerk user is mapped to the same app user id that bookings/wallet use (public.ensure_clerk_profile in Supabase,
     which links an existing profile by the Clerk-verified e-mail or creates a new one).
   - The site code still talks to "sb" exactly as before; this file lends it the Clerk session.
   Clerk itself is only downloaded for people who use Google sign-in (keeps the site fast for everyone else).
   It is warmed up as soon as the sign-in screen opens, so the Google button reacts instantly.
   "Continue with Google" goes straight to Google's account chooser (no Clerk pop-up in between). Google then returns to
   this site's /login page, where the sign-in is finished and the visitor is sent back to the page they came from.
   Auth events match the email login: a fresh Google sign-in emits SIGNED_IN (location + notification prompts, welcome
   messages), a restored session emits INITIAL_SESSION (no repeated prompts on every page load). */
const PK='pk_test_Z2xhZC1nYW5uZXQtODI3OC5jbGVyay5hY2NvdW50cy5kZXYk';
const FAPI='https://glad-gannet-8278.clerk.accounts.dev';
const FLAG='mx_clerk';
const FRESH='mx_gsi';
const PREV='mx_gprev';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const HOME=()=>location.origin+(window.__BASE||'/');
/* the page the visitor was on before the login screen survives the trip to Google */
const prevLoad=()=>{try{const v=sessionStorage.getItem(PREV)||'';sessionStorage.removeItem(PREV);return v}catch(e){return ''}};
let CU=null,real=null,started=false,busy=false,again=false,rt=0,prev=prevLoad();
const subs=[];
let resolveReady;const ready=new Promise(r=>resolveReady=r);

const flagGet=()=>{try{return Number(localStorage.getItem(FLAG))||0}catch(e){return 0}};
const flagOn=()=>{try{localStorage.setItem(FLAG,String(Date.now()))}catch(e){}};
const flagOff=()=>{try{localStorage.removeItem(FLAG)}catch(e){}};
const say=m=>{try{if(typeof toast==='function')toast(m)}catch(e){}};
/* true only right after the visitor pressed "Continue with Google" (also survives the redirect back to the site) */
const freshPeek=()=>{try{const t=Number(sessionStorage.getItem(FRESH))||0;return t>0&&Date.now()-t<10*60*1000}catch(e){return false}};
const freshTake=()=>{const f=freshPeek();try{sessionStorage.removeItem(FRESH)}catch(e){}return f};

/* remember the page the visitor was on before the login screen (to return there after Google sign-in) */
const track=()=>{const h=window.__lh||'';if(h&&!/^#\/login/.test(h))prev=h};
addEventListener('hashchange',track);setTimeout(track,0);

/* Back from Google: finish the sign-in that Google/Clerk started (existing account, or a brand-new one) */
async function finishRedirect(C){
  try{
    if(C.user||C.session||!freshPeek())return;
    const si=C.client&&C.client.signIn,su=C.client&&C.client.signUp;
    if(si&&si.firstFactorVerification&&si.firstFactorVerification.status==='transferable'){
      const r=await su.create({transfer:true});
      if(r.status==='complete'&&r.createdSessionId)await C.setActive({session:r.createdSessionId});
      else C.openSignUp({forceRedirectUrl:HOME(),fallbackRedirectUrl:HOME()});
    }else if(si&&si.status==='complete'&&si.createdSessionId){
      await C.setActive({session:si.createdSessionId});
    }else if(su&&su.status==='complete'&&su.createdSessionId){
      await C.setActive({session:su.createdSessionId});
    }
  }catch(e){console.warn('Clerk redirect',e)}
}

function loadClerk(){
  if(started)return;started=true;
  const s=document.createElement('script');
  s.async=true;s.crossOrigin='anonymous';
  s.setAttribute('data-clerk-publishable-key',PK);
  s.src=FAPI+'/npm/@clerk/clerk-js@5/dist/clerk.browser.js';
  s.onload=async()=>{
    try{
      await window.Clerk.load({signInFallbackRedirectUrl:HOME(),signUpFallbackRedirectUrl:HOME(),afterSignOutUrl:HOME()});
      await finishRedirect(window.Clerk);
      window.Clerk.addListener(()=>sync());
      await sync();
      /* stale marker from an abandoned sign-in: stop loading Clerk on every visit */
      if(!CU&&!window.Clerk.session&&Date.now()-flagGet()>10*60*1000)flagOff();
    }catch(e){console.warn('Clerk',e)}
    resolveReady();
  };
  s.onerror=()=>{started=false;resolveReady()};
  document.head.appendChild(s);
}

async function setAuthRealtime(){
  clearInterval(rt);
  const set=async()=>{try{const t=await window.Clerk.session.getToken();if(t&&real)real.realtime.setAuth(t)}catch(e){}};
  await set();rt=setInterval(set,45000);
}
const sessionOf=()=>({data:{session:{user:CU,access_token:'clerk',token_type:'bearer'}},error:null});
function emit(ev,session){subs.slice().forEach(cb=>{try{cb(ev,session)}catch(e){console.error(e)}})}

async function setCU(u){
  CU=u;
  if(u){
    flagOn();
    /* the realtime token is ready before listeners start (notification channel needs it), but never waits long */
    await Promise.race([setAuthRealtime(),sleep(1500)]);
    /* signed in from the login screen: go back to where the visitor came from */
    if(window.__lh&&/^#\/login/.test(window.__lh))window.__lh=prev||'#/profile';
    emit(freshTake()?'SIGNED_IN':'INITIAL_SESSION',{user:u,access_token:'clerk',token_type:'bearer'});
  }else{
    clearInterval(rt);flagOff();emit('SIGNED_OUT',null);
  }
}

async function sync(){
  const C=window.Clerk;
  if(!C||!C.loaded||!real)return;
  if(busy){again=true;return}
  busy=true;
  try{
    do{
      again=false;
      if(C.user&&C.session){
        if(CU&&CU.clerk_id===C.user.id)continue;
        let uid=null,err=null;
        try{const r=await real.rpc('ensure_clerk_profile');uid=r.data;err=r.error}catch(e){err=e}
        if(err||!uid){
          console.warn('ensure_clerk_profile',err);
          say(err&&/email claim/i.test(err.message||'')?'Sign-in setup incomplete: Clerk session token needs the email claim.':'Sign-in could not be completed. Please try again.');
          try{await C.signOut()}catch(e){}
          if(CU)await setCU(null);else flagOff();
          continue;
        }
        const em=C.user.primaryEmailAddress&&C.user.primaryEmailAddress.emailAddress||'';
        await setCU({id:uid,email:em,clerk_id:C.user.id,user_metadata:{full_name:C.user.fullName||'',avatar_url:C.user.imageUrl||''},app_metadata:{provider:'clerk'}});
      }else if(CU){
        await setCU(null);
      }
    }while(again);
  }finally{busy=false}
}

/* Supabase requests carry the Clerk session token while a Clerk session is active */
async function wrapFetch(input,init){
  const C=window.Clerk;
  if(C&&C.loaded&&C.session){
    try{
      const t=await C.session.getToken();
      if(t){
        const h=new Headers((init&&init.headers)||(input instanceof Request?input.headers:undefined));
        h.set('Authorization','Bearer '+t);
        init=Object.assign({},init,{headers:h});
      }
    }catch(e){}
  }
  return fetch(input,init);
}

/* Used by the site in place of supabase.createClient(...) */
window.__mkSb=function(url,key,opts){
  opts=opts||{};
  real=supabase.createClient(url,key,Object.assign({},opts,{global:Object.assign({},opts.global,{fetch:wrapFetch})}));
  const A=real.auth;
  const auth=new Proxy(A,{get(t,p){
    if(p==='getSession')return async()=>{
      if(CU)return sessionOf();
      const r=await A.getSession();
      if(!flagGet()||(r.data&&r.data.session))return r;
      loadClerk();await Promise.race([ready,sleep(4000)]);
      return CU?sessionOf():r;
    };
    if(p==='onAuthStateChange')return cb=>{
      subs.push(cb);
      const r=A.onAuthStateChange((ev,s)=>{if(CU&&ev!=='SIGNED_OUT')return;cb(ev,s)});
      return {data:{subscription:{unsubscribe(){const i=subs.indexOf(cb);if(i>-1)subs.splice(i,1);try{r.data.subscription.unsubscribe()}catch(e){}}}}};
    };
    if(p==='getUser')return async jwt=>CU?{data:{user:CU},error:null}:A.getUser(jwt);
    if(p==='signOut')return async o=>{
      if(CU){try{await window.Clerk.signOut()}catch(e){}if(CU)await setCU(null);return {error:null}}
      return A.signOut(o);
    };
    const v=t[p];return typeof v==='function'?v.bind(t):v;
  }});
  return new Proxy(real,{get(t,p){if(p==='auth')return auth;const v=t[p];return typeof v==='function'?v.bind(t):v}});
};

/* Returning Clerk user: start Clerk early so the session is restored */
if(flagGet())loadClerk();

/* Called when the sign-in screen opens (or the Google button is touched): download Clerk ahead of the click */
window.__clerkWarm=function(){loadClerk()};

/* "Continue with Google": straight to Google, no Clerk pop-up */
window.__clerkGoogle=async function(){
  flagOn();loadClerk();await Promise.race([ready,sleep(8000)]);
  const C=window.Clerk;
  if(!C||!C.loaded){say('Google sign-in is unavailable right now. Please try again.');return}
  /* after Google, come back to the page the visitor was on, inside this site (never the bare github.io root) */
  const back=HOME()+(prev||'#/profile').replace(/^#\/?/,'');
  const ret=HOME()+'login';
  try{sessionStorage.setItem(FRESH,String(Date.now()));sessionStorage.setItem(PREV,prev||'')}catch(e){}
  try{
    await C.client.signIn.authenticateWithRedirect({strategy:'oauth_google',redirectUrl:ret,redirectUrlComplete:ret});
    return;
  }catch(e){console.warn('Google redirect',e)}
  /* fallback: the old pop-up, only if the direct redirect could not start */
  C.openSignIn({forceRedirectUrl:back,signUpForceRedirectUrl:back,fallbackRedirectUrl:back,signUpFallbackRedirectUrl:back});
};
})();
