(function(){
'use strict';
/* Clean, personal URLs for every page: /maintix/faq, /maintix/book, /maintix/reviews ... (no #/).
   1) The site's own code asks for "location.hash"; while loading we rewrite that to window.__lh, which is backed by the
      real address (history API). Old #/route links are converted to the clean URL automatically.
   2) The site scripts are fetched in parallel and run in their original order, so behaviour is unchanged. */
const B=window.__BASE,R=window.__ROUTES;
const FILES=['app.js','extra.js','media.js','final.js','legal.js','auth.js','geo.js','reviews.js','promo.js','polish.js','notify.js','bookings.js','home-fix.js','onesignal.js'];

/* ---------- address <-> route ---------- */
const rel=()=>{let p=location.pathname.slice(B.length);try{p=decodeURIComponent(p)}catch(e){}return p.replace(/index\.html$/,'').replace(/\/+$/,'')};
const norm=t=>{t=String(t==null?'':t).replace(/^#\/?/,'');const q=t.indexOf('?');return {p:(q>-1?t.slice(0,q):t).replace(/^\/+|\/+$/g,''),q:q>-1?t.slice(q):''}};
const fire=()=>setTimeout(()=>dispatchEvent(new Event('hashchange')),0);
function go(t,replace){
  const n=norm(t);
  if(n.p===rel()&&n.q===location.search)return;
  history[replace?'replaceState':'pushState'](null,'',B+n.p+n.q);
  fire();
}
Object.defineProperty(window,'__lh',{configurable:true,get:()=>'#/'+rel()+location.search,set:v=>go(v)});

/* Old links like /maintix/#/faq or /maintix/book#/notifications -> clean URL; drop a trailing slash */
if(/^#\//.test(location.hash)){const n=norm(location.hash);history.replaceState(null,'',B+n.p+n.q)}
else if(rel()&&/\/$/.test(location.pathname))history.replaceState(null,'',B+rel()+location.search);

addEventListener('popstate',()=>dispatchEvent(new Event('hashchange')));

/* Links inside the site change the page without a reload */
document.addEventListener('click',e=>{
  if(e.defaultPrevented||e.button||e.metaKey||e.ctrlKey||e.shiftKey||e.altKey)return;
  const a=e.target.closest&&e.target.closest('a[href]');
  if(!a||(a.target&&a.target!=='_self')||a.hasAttribute('download'))return;
  const hv=a.getAttribute('href')||'';
  let tok=null;
  if(/^#\//.test(hv))tok=hv;
  else if(hv&&hv[0]!=='#'&&!/^[a-z][a-z0-9+.-]*:/i.test(hv)){
    const u=new URL(a.href);
    if(u.origin===location.origin&&u.pathname.indexOf(B)===0){
      const r=u.pathname.slice(B.length).replace(/\/+$/,'');
      if(r===''||R.indexOf(r)>-1)tok='#/'+r+u.search;
    }
  }
  if(tok===null)return;
  e.preventDefault();
  go(tok);
},true);

/* ---------- load the site scripts ---------- */
const fix=s=>s
  .replace(/location\.href\.split\('#'\)\[0\]\+'#\/notifications'/g,"document.baseURI+'notifications'")
  .replace(/location\.hash/g,'window.__lh');

function plain(){FILES.forEach(f=>{const s=document.createElement('script');s.src=f;s.async=false;document.body.appendChild(s)})}

/* The scripts used to run while the page was still parsing. Handlers they register for DOMContentLoaded / load
   would now miss those events, so they are collected and called right after the scripts have run. */
function run(texts){
  const dh=[],lh=[];
  document.addEventListener=function(t,fn,o){if(t==='DOMContentLoaded'){dh.push(fn);return}return EventTarget.prototype.addEventListener.call(this,t,fn,o)};
  window.addEventListener=function(t,fn,o){if(t==='load'&&document.readyState==='complete'){lh.push(fn);return}return EventTarget.prototype.addEventListener.call(this,t,fn,o)};
  try{
    texts.forEach((t,i)=>{const s=document.createElement('script');s.text=fix(t)+'\n//# sourceURL='+FILES[i];document.body.appendChild(s)});
  }finally{delete document.addEventListener;delete window.addEventListener}
  dh.forEach(fn=>{try{fn.call(document,new Event('DOMContentLoaded'))}catch(e){console.error(e)}});
  lh.forEach(fn=>{try{fn.call(window,new Event('load'))}catch(e){console.error(e)}});
}

Promise.all(FILES.map(f=>fetch(f).then(r=>{if(!r.ok)throw new Error(f);return r.text()}))).then(run,plain);
})();
