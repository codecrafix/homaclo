/* Maintix service worker: fast images (stale-while-revalidate) + notification taps */
const C='mx-img-v1';
self.addEventListener('install',()=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(self.clients.claim()));
self.addEventListener('fetch',e=>{
  const r=e.request;if(r.method!=='GET')return;
  const u=new URL(r.url);
  if(u.origin!==location.origin||!/\/img\/.+\.(png|jpe?g|webp|svg)$/i.test(u.pathname))return;
  e.respondWith(caches.open(C).then(async c=>{
    const m=await c.match(r);
    const net=fetch(r).then(res=>{if(res&&res.ok)c.put(r,res.clone());return res}).catch(()=>m);
    return m||net;
  }));
});
self.addEventListener('notificationclick',e=>{
  e.notification.close();
  const url=(e.notification.data&&e.notification.data.url)||self.registration.scope;
  e.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(l=>{
    for(const c of l){if('focus' in c){if(c.navigate)c.navigate(url);return c.focus()}}
    return self.clients.openWindow(url);
  }));
});
