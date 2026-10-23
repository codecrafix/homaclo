(function(){
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const P=n=>`img/maintix-${n}.png`;
function fig(n,alt,cap,cls){const f=document.createElement('figure');f.className='ph '+(cls||'');const i=new Image();i.src=P(n);i.alt=alt;i.loading='lazy';i.onerror=()=>f.remove();f.append(i);if(cap){const c=document.createElement('figcaption');c.textContent=cap;f.append(c)}return f}
function hero(){const t=$('.hero .tankart');if(!t||t.dataset.fail)return;const w=document.createElement('div');w.className='hero-img';const i=new Image();i.src=P(8);i.alt='Maintix technician cleaning a rooftop water tank with a pressure washer';i.onerror=()=>{t.dataset.fail=1;w.replaceWith(t)};w.append(i);w.insertAdjacentHTML('beforeend','<span class="hb">Starting ₹1,000</span><span class="hb2">TDS tested &amp; certified</span>');t.replaceWith(w)}
const ROWS=[[2,'Trained, uniformed professionals','Every visit is handled by a uniformed Maintix technician with gloves and proper gear, so your tank is cleaned carefully and hygienically.',['Careful, step-by-step cleaning','Safety gear on every job','Respectful of your home']],
[3,'Professional equipment, no shortcuts','High-pressure washer, wet-and-dry vacuum, cleaning agents, boots, gloves and a safety harness all arrive with the team.',['High-pressure washing','Sludge vacuum removal','Safety-first rooftop work']],
[5,'Tested after cleaning','We check your water with a TDS meter after the clean, so you can see the result and not just take our word for it.',['TDS meter reading shown','Clean, clear sample','Transparent process']],
[6,'A tank you can trust again','Scrubbed walls, flushed pipes and fresh water, ready to store safe drinking water for your family.',['Spotless inner walls','Clean inlet and outlet pipes','Fresh-water ready']]];
function story(){const p=$('#proof');if(!p||$('#story'))return;const s=document.createElement('section');s.id='story';s.className='sec';let h='<div class="wrap"><div class="head c"><h2>How we keep your water safe</h2><p>Real people, real tools, a result you can see.</p></div>';
ROWS.forEach((r,i)=>{h+=`<div class="story${i%2?' rev':''}" data-n="${r[0]}"><div><h3>${r[1]}</h3><p>${r[2]}</p><ul>${r[3].map(x=>'<li>'+x+'</li>').join('')}</ul></div></div>`});
s.innerHTML=h+'</div>';p.after(s);$$('.story',s).forEach(d=>{const n=d.dataset.n,r=ROWS.find(x=>x[0]==n);d.prepend(fig(n,r[1]))})}
function extras(){
  const hr=$('#hrev');if(hr&&!$('.rvimg')){const d=document.createElement('div');d.className='rvimg';d.append(fig(1,'A mother handing her daughter a glass of clean water in a Satna kitchen','Clean water for the people you love'));hr.before(d)}
  const rl=$('#rl');if(rl&&!$('.rvimg')){const d=document.createElement('div');d.className='rvimg';d.append(fig(1,'A mother handing her daughter a glass of clean water','Clean water for the people you love'));rl.before(d)}
  const sv=$('#svc');if(sv&&!$('.svbn')){const g=$('.page .grid');if(g)g.before(fig(4,'Rooftop water tanks serviced by Maintix','Tank cleaning from 500L to 2000L','svbn'))}
  $$('#svc .card').forEach(c=>{if(/solar/i.test(c.textContent)&&!$('.ph',c))c.prepend(fig(7,'Maintix technician inspecting a rooftop solar installation','', 'thumb'))});
  /* Water Tank Cleaning service card: img/maintix-10.png (card shows without image until the file exists) */
  $$('#svc .card').forEach(c=>{const t=($('h3',c)||{}).textContent||'';if(/tank/i.test(t)&&!/solar/i.test(t)&&!$('.ph',c))c.prepend(fig(10,'Maintix water tank cleaning service','','thumb'))});
}
function run(){hero();story();extras()}
let q=0;new MutationObserver(()=>{cancelAnimationFrame(q);q=requestAnimationFrame(run)}).observe($('#app'),{childList:true,subtree:true});run();
})();
