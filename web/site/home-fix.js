(function(){
'use strict';
/* Home stats.
   - Numbers count up ONCE per page load with one shared timer (page re-renders while loading just continue it).
   - Customer rating: shows 0.0, then counts up to the real average once the reviews are loaded (5.0 if none).
   - Text is changed through the existing text node, so the animation does not wake up the page's DOM watchers on every frame (smoother). */
const D=1200,RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
const $=s=>document.querySelector(s);
const setT=(el,t)=>{const n=el.firstChild;if(n&&n.nodeType===3)n.nodeValue=t;else el.textContent=t};
const ease=p=>1-Math.pow(1-p,3);
let T0=0,fin=false,AVG=null,T1=0;

const _hv=homeView;
homeView=function(){
  return _hv()
    .replace(/<b id="st-r">[^<]*<\/b>/,'<b id="st-r" data-run="1">0.0 ★</b>')
    .replace(/(<div class="stat">)<b>/g,'$1<b data-run="1" data-final="1">');
};

function paint(){
  const p=Math.min(1,(performance.now()-T0)/D),e=ease(p);
  document.querySelectorAll('#app .stat b[data-final]').forEach(el=>{
    if(el._m===undefined){
      const m=el.textContent.trim().match(/^(\D*?)(\d[\d,]*(?:\.\d+)?)(.*)$/);
      if(!m){el._m=0}else{el._m=m;el._F=el.textContent;el._n=parseFloat(m[2].replace(/,/g,''));el._d=(m[2].split('.')[1]||'').length;el._c=m[2].includes(',')}
    }
    if(!el._m)return;
    const v=el._n*e;
    setT(el,p>=1?el._F:el._m[1]+(el._c?v.toLocaleString('en-IN',{minimumFractionDigits:el._d,maximumFractionDigits:el._d}):v.toFixed(el._d))+el._m[3]);
  });
  return p;
}
function loop(){if(paint()<1)requestAnimationFrame(loop);else fin=true}

function paintR(){
  const el=$('#st-r');if(!el)return 1;
  if(AVG===null){setT(el,'0.0 ★');return 0}
  const p=RM?1:Math.min(1,(performance.now()-T1)/D);
  setT(el,(AVG*ease(p)).toFixed(1)+' ★');
  return p;
}
function loopR(){if(paintR()<1)requestAnimationFrame(loopR)}

const _ha=homeAfter;
homeAfter=async function(){
  if(!fin&&!RM){
    if(!T0){T0=performance.now();requestAnimationFrame(loop)}
    paint();
  }
  paintR();
  await _ha();
  const el=$('#st-r');
  if(el&&AVG===null){
    const v=parseFloat(el.textContent);
    AVG=v>0?v:5;T1=performance.now();
    if(!RM)requestAnimationFrame(loopR);
  }
  paintR();
};
})();
