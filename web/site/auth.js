(function(){
/* Premium auth screen (email one-time-code). Shown on #/profile and #/bookings when logged out,
   on #/login, and whenever the app asks the user to sign in (nav button, pay step). */
const $=(s,e=document)=>e.querySelector(s);
let step='email',email='',ret='',left=0,tm=0,busy=false,msg='';
const COPY={
  profile:['Your Homaclo account','Sign in to manage your profile, wallet coins and bookings.'],
  bookings:['See all your bookings','Sign in to view and track every tank cleaning in one place.'],
  login:['Welcome to Homaclo','Sign in or create your account in seconds. No password needed.']
};
const BEN=[
  ['🪙','Get 50 Welcome Coins','Free when you sign up, use them on a booking'],
  ['📦','Track bookings & offers','Every cleaning, coupon and reward in one place'],
  ['🏷️','₹100 off your first booking','Apply code WEL100 at checkout'],
  ['🔒','No password, fully secure','Just a one-time code sent to your email']
];
const stepHtml=()=>step==='email'?`
  <h2>Continue with email</h2>
  <p class="au-s">We’ll email you a one-time code. New here? Your account is created automatically.</p>
  <form id="au-f" novalidate>
    <label for="au-em">Email address</label>
    <div class="au-fld"><span aria-hidden="true">✉️</span><input id="au-em" type="email" inputmode="email" autocomplete="email" autocapitalize="off" spellcheck="false" placeholder="you@example.com" value="${h(email)}" required></div>
    <p class="au-err" role="alert">${h(msg)}</p>
    <button class="au-btn" id="au-go" type="submit">Send code <i>→</i></button>
  </form>
  <p class="au-t">By continuing you agree to our <a href="#/terms">Terms</a> and <a href="#/privacy">Privacy Policy</a>.</p>`:`
  <button class="au-back" type="button" data-au="back">← Change email</button>
  <h2>Enter your code</h2>
  <p class="au-s">We sent a code to <b>${h(email)}</b>. Check your spam folder if you don’t see it.</p>
  <form id="au-v" novalidate>
    <label for="au-cd">One-time code</label>
    <input id="au-cd" class="au-code" inputmode="numeric" autocomplete="one-time-code" maxlength="10" placeholder="••••••" required>
    <p class="au-err" role="alert">${h(msg)}</p>
    <button class="au-btn" id="au-go" type="submit">Verify &amp; continue <i>→</i></button>
  </form>
  <p class="au-t" id="au-rs">${rs()}</p>`;
function rs(){return left>0?`Resend code in <b>${left}</b>s`:`Didn’t get it? <button class="au-link" type="button" data-au="resend">Resend code</button>`}
function paint(focus){const c=$('#au-card');if(!c)return;c.innerHTML=stepHtml();if(focus)setTimeout(()=>{const f=$('#au-em')||$('#au-cd');f&&f.focus()},60)}
function timer(n){clearInterval(tm);left=n;tm=setInterval(()=>{left--;const el=$('#au-rs');if(el)el.innerHTML=rs();if(left<=0)clearInterval(tm)},1000)}
function authScreen(ctx){
  const c=COPY[ctx]||COPY.login;
  return `<div class="au"><i class="au-o a"></i><i class="au-o b"></i><div class="au-in fade">
  <div class="au-l">
    <div class="au-top"><span class="au-brand"><span class="drop"></span>Homaclo</span><h1>${h(c[0])}</h1><p class="lead">${h(c[1])}</p></div>
    <ul class="au-bn">${BEN.map(b=>`<li><span class="ic">${b[0]}</span><div><b>${h(b[1])}</b><small>${h(b[2])}</small></div></li>`).join('')}</ul>
  </div>
  <div class="au-card" id="au-card">${stepHtml()}</div>
  </div></div>`;
}
const fail=e=>/rate|security|seconds/i.test(e.message||'')?'Please wait a few seconds before requesting another code.':(e.message||'Something went wrong. Please try again.');
function setBusy(b,txt){busy=b;const g=$('#au-go');if(!g)return;g.disabled=b;g.classList.toggle('ld',b);if(txt)g.firstChild.textContent=txt}
async function send(resend){
  if(busy)return;
  const el=$('#au-em');const v=(resend?email:(el?el.value:'')).trim().toLowerCase();
  if(!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v)){msg='Please enter a valid email address.';paint(1);return}
  email=v;msg='';setBusy(true,'Sending…');
  const {error}=await sb.auth.signInWithOtp({email:v,options:{shouldCreateUser:true}});
  busy=false;
  if(error){msg=fail(error);if(resend){toast(msg);paint();return}paint(1);return}
  step='otp';timer(30);paint(1);if(resend)toast('A new code is on its way ✉️');
}
async function verify(){
  if(busy)return;const code=($('#au-cd')||{}).value;const t=(code||'').replace(/\s/g,'');
  if(t.length<4){msg='Enter the code from your email.';paint(1);return}
  setBusy(true,'Verifying…');
  const {error}=await sb.auth.verifyOtp({email,token:t,type:'email'});
  busy=false;
  if(error){msg='That code is invalid or has expired. Please try again.';paint(1);return}
  clearInterval(tm);step='email';msg='';toast('Signed in successfully ✅');
  if(/^#\/login/.test(location.hash)){const r=ret||'#/profile';ret='';location.hash=r}
}
document.addEventListener('submit',e=>{
  if(e.target.id==='au-f'){e.preventDefault();send(false)}
  else if(e.target.id==='au-v'){e.preventDefault();verify()}
});
document.addEventListener('click',e=>{
  const b=e.target.closest('[data-au]');if(!b)return;
  if(b.dataset.au==='back'){clearInterval(tm);step='email';msg='';paint(1)}
  else if(b.dataset.au==='resend')send(true);
});
document.addEventListener('input',e=>{if(e.target.id==='au-cd'){e.target.value=e.target.value.replace(/[^0-9]/g,'')}});

/* route hooks */
const _pv=profileView,_bv=bookingsView,_lv=legalView;
profileView=function(){return S.user?_pv():authScreen('profile')};
bookingsView=function(){return S.user?_bv():authScreen('bookings')};
legalView=function(k){
  if(k==='login'){
    if(S.user){setTimeout(()=>{location.hash='#/profile'});return '<div class="boot"><span></span></div>'}
    return authScreen('login');
  }
  return _lv(k);
};
openLogin=function(em){
  if(S.user)return;
  if(em)email=em;
  const hsh=location.hash||'#/';
  if(!/^#\/login/.test(hsh))ret=hsh;
  step='email';msg='';
  if(/^#\/login/.test(hsh))route();else location.hash='#/login';
};
Object.assign(ROUTES,{login:'login'});
})();
