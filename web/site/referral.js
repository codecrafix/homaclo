(function(){
'use strict';
try{
const $=(s,e=document)=>e.querySelector(s),$$=(s,e=document)=>[...e.querySelectorAll(s)];
const KEY='hm_ref';
const ls=(k,v)=>{try{if(v===undefined)return localStorage.getItem(k);if(v===null)localStorage.removeItem(k);else localStorage.setItem(k,v)}catch(e){return null}};
const base=()=>location.origin+(window.__BASE||'/');
const user=()=>S&&S.user;
const fmt=d=>{try{return new Date(d).toLocaleDateString('en-IN',{day:'numeric',month:'short',year:'numeric'})}catch(e){return ''}};
const LANGS=[['en','English'],['hi','हिन्दी'],['bn','বাংলা'],['mr','मराठी'],['gu','ગુજરાતી'],['ta','தமிழ்'],['te','తెలుగు'],['kn','ಕನ್ನಡ'],['ml','മലയാളം'],['pa','ਪੰਜਾਬੀ'],['ur','اردو'],['or','ଓଡ଼ିଆ'],['as','অসমীয়া'],['ne','नेपाली'],['sa','संस्कृतम्'],['sd','سنڌي'],['mai','मैथिली'],['doi','डोगरी'],['bho','भोजपुरी'],['gom','कोंकणी'],['ar','العربية'],['fa','فارسی'],['zh-CN','中文'],['ja','日本語'],['ko','한국어'],['es','Español'],['fr','Français'],['de','Deutsch'],['pt','Português'],['ru','Русский'],['it','Italiano'],['tr','Türkçe'],['id','Indonesia'],['ms','Melayu'],['th','ไทย'],['vi','Tiếng Việt'],['sw','Kiswahili'],['si','සිංහල'],['my','မြန်မာ']];

const css=`
.hm{min-width:32px;height:32px;padding:0 7px;font-size:15px;display:inline-flex;align-items:center;justify-content:center;gap:5px;cursor:pointer}
.hm span{display:none;font-size:13px;font-weight:600;line-height:1}
@media(min-width:820px){.hm span{display:inline}}
.hm-d{position:relative}
.hm-x{position:absolute;top:-8px;right:-8px;width:30px;height:30px;border-radius:50%;border:0;cursor:pointer;font-size:18px;line-height:1;background:rgba(127,127,127,.25);color:inherit}
.hm-steps{margin:12px 0;padding-left:22px}.hm-steps li{margin:8px 0}
.hm-link{display:flex;gap:8px;margin:12px 0}.hm-link input{flex:1;min-width:0}
.hm-sh{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px}
.hm-rules{margin-top:10px;font-size:.9rem}.hm-rules li{margin:5px 0}
.hm-lang{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:8px;max-height:58vh;overflow:auto;margin-top:12px}
.hm-lang button{padding:10px 8px;border-radius:10px;border:1px solid rgba(127,127,127,.35);background:transparent;color:inherit;cursor:pointer;font:inherit}
.hm-lang button.on{border-color:#06b6d4;background:rgba(6,182,212,.15);font-weight:700}
.hm-stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(110px,1fr));gap:10px;margin:14px 0}
.hm-stats div{background:rgba(127,127,127,.12);border-radius:12px;padding:12px;text-align:center}
.hm-stats b{display:block;font-size:1.4rem}
.hm-prof{margin-top:20px}
.goog-te-banner-frame,.goog-te-balloon-frame,#goog-gt-tt,.goog-tooltip,.skiptranslate iframe{display:none!important}
body{top:0!important}
.goog-text-highlight{background:none!important;box-shadow:none!important}
#hm_gt{display:none}
`;
const st=document.createElement('style');st.textContent=css;document.head.appendChild(st);

/* ---------- 1) capture ?ref= from the shared link ---------- */
let arrived=false;
try{
  const p=new URLSearchParams(location.search).get('ref');
  if(p&&/^[A-Za-z0-9]{8}$/.test(p)){
    ls(KEY,p.toUpperCase());arrived=true;
    const u=new URL(location.href);u.searchParams.delete('ref');history.replaceState(null,'',u.pathname+u.search+u.hash);
  }
}catch(e){}
if(arrived)setTimeout(()=>{if(!user())toast('Referral link applied 🎁 Sign up and make your first booking of ₹500 or more to get 50 coins.')},2200);

/* ---------- 2) after sign-in, claim the referral (the database checks every rule) ---------- */
let claiming=false,tries=0;
async function claim(){
  const c=ls(KEY);if(!c||claiming||!user())return;
  claiming=true;
  try{
    const r=await sb.rpc('claim_referral',{p_code:c});
    if(r.error){if(++tries>20)ls(KEY,null);return}
    const d=r.data;
    if(d&&d.final){ls(KEY,null);if(!d.already&&d.message)toast(d.message)}
  }catch(e){}finally{claiming=false}
}
setInterval(claim,2500);

/* ---------- 3) popup, header buttons ---------- */
const STEPS=[['Get your link','Sign in and copy your personal referral link.'],['Friend joins','Your friend opens your link and signs up as a new customer.'],['Friend books','They book any service worth ₹500 or more.'],['Both earn','50 coins (₹50) go to your wallet and your friend’s wallet automatically.']];
const RULES=['Only new customers: your friend must be a new account (created within the last 7 days) making their first booking.','The booking must be ₹500 or more after discounts, paid online.','Coins are added automatically once the paid booking is confirmed. 1 coin = ₹1, and up to 50 coins can be used per booking.','No self-referrals: your own extra accounts, the same email (including Gmail dot or plus tricks) or the same address do not qualify.','Up to 10 rewarded referrals in any 30 days.','Homaclo can cancel rewards that look fake or abusive.'];
const msg=l=>`Book professional water tank cleaning with Homaclo in Satna. Sign up with my link and we both get 50 coins after your first booking of ₹500 or more: ${l}`;
const boxHTML=l=>`<div class='hm-link'><input id='hmL' class='notranslate' readonly value='${h(l)}' aria-label='Your referral link'><button class='btn sm' data-hm='copy' data-link='${h(l)}'>Copy</button></div><div class='hm-sh'><button class='btn sm ghost' data-hm='share' data-link='${h(l)}'>Share</button><a class='btn sm ghost' target='_blank' rel='noopener' href='${h('https://wa.me/?text='+encodeURIComponent(msg(l)))}'>WhatsApp</a></div>`;
const stepsHTML=`<ol class='hm-steps'>${STEPS.map(s=>`<li><b>${s[0]}.</b> ${s[1]}</li>`).join('')}</ol>`;
const rulesHTML=`<details class='hm-rules'><summary><b>Rules that keep it fair</b></summary><ul>${RULES.map(r=>`<li>${r}</li>`).join('')}</ul></details>`;

async function openRef(){
  const d=$('#dlg');if(!d)return;
  const logged=!!user();
  d.innerHTML=`<div class='hm-d'><button class='hm-x' data-act='close' aria-label='Close'>×</button><h3>🎁 Refer &amp; Earn</h3><p class='muted'>Share Homaclo with friends. When they make their first booking, you both get <b>50 coins (₹50)</b>.</p>${stepsHTML}<div id='hmBox'>${logged?`<p class='muted small'>Loading your link…</p>`:`<button class='btn block' data-act='auth'>Sign in to get your link</button>`}</div>${logged?`<p style='margin:10px 0 0'><a href='profile' data-act='close'>See my referrals →</a></p>`:''}${rulesHTML}</div>`;
  if(!d.open)d.showModal();
  if(!logged)return;
  try{
    const r=await sb.rpc('get_my_referral_code');
    if(r.error||!r.data)throw new Error('no code');
    const b=$('#hmBox');if(b)b.innerHTML=boxHTML(base()+'?ref='+r.data);
  }catch(e){const b=$('#hmBox');if(b)b.innerHTML=`<p class='muted small'>We could not load your link right now. Please try again in a moment.</p>`}
}
function curLang(){
  const c=document.cookie.split(';').map(x=>x.trim()).find(x=>x.indexOf('googtrans=')===0);
  if(!c)return 'en';
  const p=decodeURIComponent(c.slice(10)).split('/');return p[2]||'en';
}
function openLang(){
  const d=$('#dlg');if(!d)return;const cur=curLang();
  d.innerHTML=`<div class='hm-d'><button class='hm-x' data-act='close' aria-label='Close'>×</button><h3>🌐 Choose your language</h3><p class='muted small'>The whole website will be translated automatically.</p><div class='hm-lang'>${LANGS.map(l=>`<button class='${l[0]===cur?'on':''}' data-hm='setlang' data-l='${l[0]}'>${l[1]}</button>`).join('')}</div></div>`;
  if(!d.open)d.showModal();
}
function setLang(c){
  const host=location.hostname,v=c==='en'?'':'/en/'+c,exp=c==='en'?'; expires=Thu, 01 Jan 1970 00:00:00 GMT':'';
  document.cookie='googtrans='+v+'; path=/'+exp;
  document.cookie='googtrans='+v+'; path=/; domain='+host+exp;
  document.cookie='googtrans='+v+'; path=/; domain=.'+host+exp;
  location.reload();
}
function loadGT(){
  if($('#hm_gt'))return;
  const g=document.createElement('div');g.id='hm_gt';document.body.appendChild(g);
  window.hmGT=()=>{try{new google.translate.TranslateElement({pageLanguage:'en',autoDisplay:false},'hm_gt')}catch(e){}};
  const s=document.createElement('script');s.src='https://translate.google.com/translate_a/element.js?cb=hmGT';s.async=true;document.head.appendChild(s);
}
if(curLang()!=='en')loadGT();

function copy(b){
  const l=b.dataset.link,done=()=>toast('Referral link copied ✅');
  const fb=()=>{const i=$('#hmL')||b.parentNode.querySelector('input');if(i){i.select();i.setSelectionRange(0,9999)}try{document.execCommand('copy');done()}catch(e){toast('Press and hold the link to copy it')}};
  if(navigator.clipboard&&navigator.clipboard.writeText)navigator.clipboard.writeText(l).then(done,fb);else fb();
}
function share(b){
  const l=b.dataset.link;
  if(navigator.share)navigator.share({title:'Homaclo',text:msg(l)}).catch(()=>{});else copy(b);
}
document.addEventListener('click',e=>{
  const b=e.target.closest&&e.target.closest('[data-hm]');if(!b)return;
  const a=b.dataset.hm;
  if(a==='ref')openRef();else if(a==='lang')openLang();else if(a==='setlang')setLang(b.dataset.l);else if(a==='copy')copy(b);else if(a==='share')share(b);
});

function mount(){
  const r=$('.nav-r');if(!r||$('#hmRef'))return;
  const a=document.createElement('button');a.id='hmRef';a.className='icon hm';a.dataset.hm='ref';a.title='Refer & Earn';a.setAttribute('aria-label','Refer and Earn');a.innerHTML='🎁<span>Refer &amp; Earn</span>';
  const b=document.createElement('button');b.id='hmLang';b.className='icon hm';b.dataset.hm='lang';b.title='Language';b.setAttribute('aria-label','Change language');b.innerHTML='🌐';
  r.prepend(a,b);
  $$('.logo').forEach(x=>x.setAttribute('translate','no'));
}

/* ---------- 4) Refer & Earn section on the profile page ---------- */
function render(sec,d){
  const by=d.referred_by;
  const note=by?`<p class='small' style='margin:10px 0'>${by.status==='pending'?'You joined through a friend’s link. Make your first booking of ₹500 or more to get your 50 coins.':by.status==='rewarded'?'🎉 You received 50 coins for joining through a friend’s link.':'Your referral reward was not eligible.'}</p>`:'';
  const lab={pending:['Signed up, waiting to book',''],rewarded:['Booked, +50 coins','g'],rejected:['Not eligible','']};
  const rows=(d.items||[]).map(i=>{const l=lab[i.status]||[i.status,''];return `<div class='line'><span><b>${h(i.name)}</b> <span class='muted small'>joined ${fmt(i.joined)}</span></span><span class='pill ${l[1]}'>${l[0]}</span></div>`}).join('');
  sec.innerHTML=`<h3>🎁 Refer &amp; Earn</h3><p class='muted small'>Earn 50 coins (₹50) for every friend who makes a first booking of ₹500 or more through your link. Your friend gets 50 coins too.</p>${boxHTML(base()+'?ref='+d.code)}<button class='btn sm ghost' data-hm='ref'>How it works</button>${note}<div class='hm-stats'><div><b>${d.invited}</b><span class='muted small'>Friends joined</span></div><div><b>${d.rewarded}</b><span class='muted small'>Booked</span></div><div><b>${d.pending}</b><span class='muted small'>Waiting to book</span></div><div><b>${d.coins_earned}</b><span class='muted small'>Coins earned</span></div></div><h4 style='margin-bottom:6px'>Your referrals</h4>${rows||`<p class='muted small'>No referrals yet. Share your link to get started.</p>`}`;
}
async function profile(){
  const save=$('#app [data-act=psave]');if(!save||$('#hmProf'))return;
  const grid=save.closest('.grid');if(!grid)return;
  const sec=document.createElement('div');sec.id='hmProf';sec.className='card hm-prof';
  sec.innerHTML=`<h3>🎁 Refer &amp; Earn</h3><p class='muted small'>Loading your referral details…</p>`;
  grid.after(sec);
  try{
    const r=await sb.rpc('my_referral_summary');
    if(r.error||!r.data)throw new Error('no data');
    render(sec,r.data);
  }catch(e){sec.innerHTML=`<h3>🎁 Refer &amp; Earn</h3><p class='muted small'>Your referral details will appear here shortly.</p><button class='btn sm ghost' data-hm='ref'>How it works</button>`}
}

let q=0;
function run(){mount();profile()}
new MutationObserver(()=>{cancelAnimationFrame(q);q=requestAnimationFrame(run)}).observe($('#app'),{childList:true,subtree:true});
run();
}catch(e){console.error('referral',e)}
})();
