(function(){
'use strict';
/* Home: customer rating + stat numbers.
   - Rating renders its final-looking value at once (5.0 fallback, same as the Reviews page) and is never animated.
   - The other numbers count up ONCE per page load. The page re-renders several times while it loads (login state,
     profile, etc.); before, every re-render restarted the count from 0. Now one shared timer drives whatever is on screen,
     so a re-render just continues the same animation and later visits show the final numbers straight away. */
const D=1200,RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
let T0=0,fin=false;
const _hv=homeView;
homeView=function(){
  return _hv()
    .replace(/<b id="st-r">[^<]*<\/b>/,'<b id="st-r" data-run="1">5.0 ★</b>')
    .replace(/(<div class="stat">)<b>/g,'$1<b data-run="1" data-final="1">');
};
function paint(){
  const p=Math.min(1,(performance.now()-T0)/D),e=1-Math.pow(1-p,3);
  document.querySelectorAll('#app .stat b[data-final]').forEach(el=>{
    if(el._m===undefined){
      const m=el.textContent.trim().match(/^(\D*?)(\d[\d,]*(?:\.\d+)?)(.*)$/);
      if(!m){el._m=0}else{el._m=m;el._F=el.textContent;el._n=parseFloat(m[2].replace(/,/g,''));el._d=(m[2].split('.')[1]||'').length;el._c=m[2].includes(',')}
    }
    if(!el._m)return;
    const v=el._n*e;
    el.textContent=p>=1?el._F:el._m[1]+(el._c?v.toLocaleString('en-IN',{minimumFractionDigits:el._d,maximumFractionDigits:el._d}):v.toFixed(el._d))+el._m[3];
  });
  return p;
}
function loop(){if(paint()<1)requestAnimationFrame(loop);else fin=true}
const _ha=homeAfter;
homeAfter=async function(){
  if(!fin&&!RM){
    if(!T0){T0=performance.now();paint();requestAnimationFrame(loop)}
    else paint();
  }
  await _ha();
};
})();
