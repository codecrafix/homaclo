(function(){
'use strict';
/* Mobile polish for the booking page (screens up to 900px wide). Desktop is not touched at all.
   Every tap on the booking page (tank +/-, date, time slot, coins, terms, coupon, Next / Back) re-draws the page.
   On a phone that showed up as:
   1) a blink: the whole page fades in again after every tap  -> now only a real step change fades in, taps just update;
   2) the page sliding / content appearing from below: the browser scrolled "smoothly" after each redraw, and moving to the
      next step kept the old scroll position -> redraws now keep the exact scroll position, and a new step starts at the top;
   3) the bottom "Order summary" bar losing its title / total after solar panel +/- (it is updated in place there). */
const mq=matchMedia('(max-width:900px)');
const root=document.documentElement;
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const keyOf=()=>{const k=String(window.__lh||'').replace(/^#\/?/,'').split('?')[0];return ROUTES[k]??'home'};
const stepOf=()=>{const s=$('#app .steps span.on');return s?parseInt(s.textContent,10)||0:0};
/* the page normally scrolls "smoothly" (html{scroll-behavior:smooth}); while the site redraws it must jump exactly */
const instant=on=>{root.style.scrollBehavior=on?'auto':''};

/* redraws done by tapping (same booking page): keep the scroll position, no fade-in replay, new step -> top of the page */
if(typeof route==='function'){
  const _route=route;
  route=function(){
    if(!mq.matches)return _route.apply(this,arguments);
    const same=keyOf()==='book'&&!!$('#app .bk');
    const before=stepOf();
    instant(true);
    try{_route.apply(this,arguments)}
    finally{
      if(same){
        if(stepOf()!==before)window.scrollTo(0,0);
        else $$('#app .fade').forEach(el=>{el.style.animation='none'});
      }
      instant(false);
    }
  };
}

/* opening another page (address change): the new page must start at the top at once, not slide up from where the old one was.
   The first listener runs before the site's own router (capture phase), the second one right after it. */
addEventListener('hashchange',()=>{if(mq.matches)instant(true)},true);
addEventListener('hashchange',()=>instant(false));

/* bottom "Order summary" bar: keep its title and total in step with the order (solar panel +/- updates the summary in place) */
let q=0;
function bar(){
  q=0;
  if(!mq.matches)return;
  const s=$('#app .sum.dr');if(!s)return;
  const t=$('.line.t',s),total=t&&t.lastElementChild?t.lastElementChild.textContent:'';
  let d=[...s.children].find(c=>c.classList.contains('dh'));
  if(!d){
    d=document.createElement('div');d.className='dh';
    d.innerHTML='<span>Order summary ▴</span><span></span>';
    d.onclick=()=>s.classList.toggle('open');
    s.prepend(d);
  }
  const v=d.lastElementChild;
  if(v&&total&&v.textContent!==total)v.textContent=total;
}
const app=$('#app');
if(app)new MutationObserver(()=>{if(!q)q=requestAnimationFrame(bar)}).observe(app,{childList:true,subtree:true});
})();
