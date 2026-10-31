/* Homaclo service worker: fast images + cached JS/CSS (stale-while-revalidate) + notification taps.
   Bump C whenever the pictures in /img are replaced (and IMG_V in router.js): old caches are deleted on activate.
   Bump S if you ever need to force every visitor to drop the cached JS/CSS. */
const C='mx-img-v3';
const S='mx-static-v12';
const CDN=/^https:\/\/cdn\.jsdelivr\.net\/npm\/@supabase\//;
self.addEventListener('install',()=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(
  caches.keys().then(ks=>Promise.all(ks.filter(k=>(k.indexOf('mx-img-')===0&&k!==C)||(k.indexOf('mx-static-')===0&&k!==S)).map(k=>caches.delete(k)))).then(()=>self.clients.claim())
));
self.addEventListener('fetch',e=>{
  const r=e.request;if(r.method!=='GET')return;
  const u=new URL(r.url);
  const same=u.origin===location.origin;
  /* pictures: show the cached copy instantly, refresh it in the background */
  if(same&&/\/img\/.+\.(png|jpe?g|webp|svg)$/i.test(u.pathname)){
    e.respondWith(caches.open(C).then(async c=>{
      const m=await c.match(r);
      const net=fetch(r,{cache:'no-cache'}).then(res=>{if(res&&res.ok)c.put(r,res.clone());return res}).catch(()=>m);
      return m||net;
    }));
    return;
  }
  /* site scripts, styles and the Supabase library: cached copy first (instant repeat visits), updated in the background */
  if((same&&/\.(js|css)$/i.test(u.pathname)&&!/\/sw\.js$/i.test(u.pathname)&&u.pathname.indexOf('/push/')<0)||CDN.test(r.url)){
    e.respondWith(caches.open(S).then(async c=>{
      const m=await c.match(r);
      const net=fetch(r,{cache:'no-cache'}).then(res=>{if(res&&(res.ok||res.type==='opaque'))c.put(r,res.clone());return res}).catch(()=>m);
      return m||net;
    }));
  }
});
self.addEventListener('notificationclick',e=>{
  e.notification.close();
  const url=(e.notification.data&&e.notification.data.url)||self.registration.scope;
  e.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(l=>{
    for(const c of l){if('focus' in c){if(c.navigate)c.navigate(url);return c.focus()}}
    return self.clients.openWindow(url);
  }));
});
