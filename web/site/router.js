(function(){
'use strict';
/* Clean, personal URLs for every page: /maintix/faq, /maintix/book, /maintix/reviews ... (no #/).
   The pages' own code still asks for "location.hash"; the deploy step rewrites that to window.__lh, which this file
   backs with the real address (history API). Old #/route links are converted to the clean URL automatically.
   ON is switched to true by the deploy workflow together with that rewrite; without it this file does nothing. */
const ON=false/*__CLEAN__*/;
if(!ON||!window.__BASE)return;
const B=window.__BASE,R=window.__ROUTES;
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

/* Old links like /maintix/#/faq or /maintix/book#/notifications -> clean URL; drop the trailing slash */
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
})();
