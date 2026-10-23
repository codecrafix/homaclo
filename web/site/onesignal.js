(function(){
'use strict';
/* OneSignal web push: same OneSignal app + same user link (external_id = Supabase user id) as the mobile app.
   Pushes are sent by the existing send-push-notification edge function, no server change needed.
   Own service-worker scope so it does not clash with sw.js. */
const APP_ID='a791ea02-af27-4af4-9a9e-a8c062f960eb';
window.OneSignalDeferred=window.OneSignalDeferred||[];
const base=new URL('push/onesignal/',document.baseURI).pathname;
const granted=()=>'Notification' in window&&Notification.permission==='granted';
let OS=null,pending;

OneSignalDeferred.push(async function(O){
  OS=O;
  try{
    await O.init({
      appId:APP_ID,
      serviceWorkerPath:base+'OneSignalSDKWorker.js',
      serviceWorkerParam:{scope:base},
      notifyButton:{enable:false},
      allowLocalhostAsSecureOrigin:true
    });
    /* While the site is open, notify.js already shows the notification: skip OneSignal's duplicate. */
    O.Notifications.addEventListener('foregroundWillDisplay',e=>e.preventDefault());
    if(granted())O.User.PushSubscription.optIn();
  }catch(e){console.warn('OneSignal init',e)}
  if(pending!==undefined)link(pending);
});

/* Link / unlink the browser with the signed-in user (same as OneSignal.login(userId) in the app) */
function link(u){
  pending=u;
  if(!OS)return;
  try{if(u)OS.login(u.id);else OS.logout()}catch(e){}
}
sb.auth.onAuthStateChange((ev,session)=>{const u=session&&session.user||null;setTimeout(()=>link(u),0)});

/* When the user taps Allow on the existing notification prompt, subscribe this browser to push */
document.addEventListener('click',async e=>{
  const b=e.target.closest('[data-np="allow"]');if(!b||!OS)return;
  try{
    await OS.Notifications.requestPermission();
    if(granted())await OS.User.PushSubscription.optIn();
  }catch(x){}
});
})();
