(function(){
'use strict';
/* Homaclo SEO: per-page title, description, canonical, social tags and robots for every route,
   plus a crawlable "home services in Satna" section on the home page.
   Runs on its own (independent of router.js) and re-applies the title if another script changes it. */
var ORIGIN='https://homaclo.in';
var $=function(s,e){return (e||document).querySelector(s)};
var HOME_D='Homaclo: home services in Satna. Book water tank cleaning online, with home cleaning, repair & maintenance. Fixed prices from ₹1,000, trained pros, secure payment.';
var PAGES={
 '':{t:'Homaclo | Home Cleaning, Repair & Water Tank Cleaning in Satna',d:HOME_D},
 services:{t:'Services & Pricing: Water Tank Cleaning, Home Cleaning & Maintenance | Homaclo',d:'Homaclo services and fixed pricing in Satna: water tank cleaning from ₹1,000 (500L to 2000L), plus home cleaning, solar panel cleaning, repair and maintenance.'},
 book:{t:'Book Water Tank Cleaning in Satna Online | Homaclo',d:'Book water tank cleaning in Satna in under two minutes. Pick tank size and a 2-hour slot, pay securely online. Save ₹500 on 3+ tanks and ₹100 off with WEL100.'},
 reviews:{t:'Customer Reviews | Homaclo Home Services, Satna',d:'Read customer reviews of Homaclo home services and water tank cleaning in Satna, Madhya Pradesh.'},
 about:{t:'About Homaclo | Trusted Home Services in Satna',d:'Homaclo delivers safe, hygienic and affordable home services in Satna, Madhya Pradesh: water tank cleaning today, with home cleaning, repair and maintenance on the way.'},
 faq:{t:'FAQs: Booking, Payments & Refunds | Homaclo',d:'Answers about booking Homaclo services in Satna: pricing, payment methods, WEL100 coupon, reward coins, cancellation and refunds.'},
 privacy:{t:'Privacy & Refund Policy | Homaclo',d:'How Homaclo collects, uses and protects your data, plus our cancellation and refund policy.'},
 terms:{t:'Terms & Conditions | Homaclo',d:'Terms & Conditions for booking Homaclo home services and water tank cleaning in Satna.'},
 refund:{t:'Cancellation & Refund Policy | Homaclo',d:'Homaclo cancellation and refund policy: when refunds apply and how long they take.'},
 contact:{t:'Contact Homaclo | Satna, Madhya Pradesh',d:'Contact Homaclo for bookings, support and privacy requests in Satna, Madhya Pradesh.'}
};
var ALIAS={cancellation:'refund'};
var PRIVATE={login:'Sign in',profile:'My profile',bookings:'My bookings',notifications:'Notifications'};
var has=function(o,k){return Object.prototype.hasOwnProperty.call(o,k)};
var want='';

function route(){
  var B=window.__BASE||'/',p=location.pathname;
  try{p=decodeURIComponent(p)}catch(e){}
  return p.slice(B.length).replace(/index\.html$/,'').replace(/\.html$/,'').replace(/\/+$/,'');
}
function tag(sel,make){var e=$(sel);if(!e){e=make();document.head.appendChild(e)}return e}
function meta(k,v,prop){
  var a=prop?'property':'name';
  var e=tag('meta['+a+'="'+k+'"]',function(){var m=document.createElement('meta');m.setAttribute(a,k);return m});
  e.setAttribute('content',v);
}
function canon(u){
  var e=tag('link[rel="canonical"]',function(){var l=document.createElement('link');l.rel='canonical';return l});
  e.href=u;
}
function apply(){
  var k=route(),a=has(ALIAS,k)?ALIAS[k]:k,pg=has(PAGES,a)?PAGES[a]:null,priv=has(PRIVATE,k);
  var t,d,url,idx=true;
  if(pg){t=pg.t;d=pg.d;url=ORIGIN+(a?'/'+a:'/')}
  else if(priv){t=PRIVATE[k]+' · Homaclo';d=HOME_D;url=ORIGIN+'/'+k;idx=false}
  else{t=PAGES[''].t;d=HOME_D;url=ORIGIN+'/';idx=false}
  want=t;
  if(document.title!==t)document.title=t;
  meta('description',d);
  meta('robots',idx?'index,follow,max-image-preview:large':'noindex,follow');
  canon(url);
  meta('og:title',t,1);meta('og:description',d,1);meta('og:url',url,1);
  meta('twitter:title',t);meta('twitter:description',d);
}

/* keep our title even when app scripts rewrite it after rendering */
var te=$('title');
if(te&&window.MutationObserver)new MutationObserver(function(){if(want&&document.title!==want)document.title=want}).observe(te,{childList:true,characterData:true,subtree:true});

/* Home: crawlable section describing the services in plain words */
function homeSec(){
  if(route()!=='')return;
  var band=$('#app .band');if(!band||$('#seoSec'))return;
  var sec=band.closest('section');if(!sec)return;
  var s=document.createElement('section');s.className='sec';s.id='seoSec';
  s.innerHTML='<div class="wrap"><div class="head c"><h2>Home services in Satna, made simple</h2><p>Homaclo is a local home services app in Satna, Madhya Pradesh. Book trusted professionals online with clear prices and secure payment.</p></div>'+
  '<div class="grid g3">'+
  '<div class="card hov"><h3 style="margin:0 0 6px">Water tank cleaning</h3><p class="muted small">Overhead tank and underground sump cleaning for homes and businesses, 500L to 2000L, from ₹1,000. Book online now.</p><a class="btn sm" href="book" style="margin-top:12px">Book tank cleaning</a></div>'+
  '<div class="card hov"><h3 style="margin:0 0 6px">Home &amp; solar panel cleaning</h3><p class="muted small">Professional cleaning for your home and rooftop solar panels. Being added to Homaclo soon.</p><a class="btn sm ghost" href="services" style="margin-top:12px">See all services</a></div>'+
  '<div class="card hov"><h3 style="margin:0 0 6px">Repair &amp; maintenance</h3><p class="muted small">Home repair and maintenance by verified technicians. Being added to Homaclo soon.</p><a class="btn sm ghost" href="services" style="margin-top:12px">See all services</a></div>'+
  '</div></div>';
  sec.before(s);
}
var q=0;
function boot(){
  apply();
  var app=$('#app');
  if(app&&window.MutationObserver)new MutationObserver(function(){cancelAnimationFrame(q);q=requestAnimationFrame(homeSec)}).observe(app,{childList:true,subtree:true});
  homeSec();
}
window.addEventListener('hashchange',function(){setTimeout(function(){apply();homeSec()},0)});
window.addEventListener('popstate',function(){setTimeout(function(){apply();homeSec()},0)});
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot);else boot();
})();
