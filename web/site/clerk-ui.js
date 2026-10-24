(function(){
'use strict';
/* Adds the "Continue with Google" button to the sign-in screen. */
const $=(s,e=document)=>e.querySelector(s);
const st=document.createElement('style');
st.textContent='.au-gb{width:100%;display:flex;gap:10px;align-items:center;justify-content:center;padding:13px 16px;border-radius:14px;border:1px solid var(--line,#d0d7e2);background:#fff;color:#1f2937;font:inherit;font-weight:700;cursor:pointer}.au-gb:hover{box-shadow:0 4px 14px rgba(0,0,0,.12)}.au-or{display:flex;align-items:center;gap:12px;color:var(--mut,#64748b);font-size:.82rem;margin:16px 0}.au-or:before,.au-or:after{content:"";flex:1;height:1px;background:var(--line,#d0d7e2)}';
document.head.appendChild(st);
const G='<svg width="18" height="18" viewBox="0 0 48 48" aria-hidden="true"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7a14.5 14.5 0 0 1 0-9.4l-7.9-6.1a24 24 0 0 0 0 21.6l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/></svg>';
function inject(){
  const c=$('#au-card');
  if(!c||c.querySelector('.au-g')||!c.querySelector('#au-f'))return;
  const w=document.createElement('div');w.className='au-g';
  w.innerHTML='<button type="button" class="au-gb" data-gs="1">'+G+' Continue with Google</button><div class="au-or"><span>or</span></div>';
  c.insertBefore(w,c.firstChild);
  /* start downloading Clerk now so the Google button opens instantly */
  if(window.__clerkWarm)setTimeout(window.__clerkWarm,300);
}
const app=$('#app');
if(app)new MutationObserver(inject).observe(app,{childList:true,subtree:true});
inject();
document.addEventListener('pointerdown',e=>{
  if(e.target.closest&&e.target.closest('[data-gs]')&&window.__clerkWarm)window.__clerkWarm();
},{passive:true});
document.addEventListener('click',async e=>{
  const b=e.target.closest('[data-gs]');if(!b)return;
  e.preventDefault();
  if(b.dataset.busy||!window.__clerkGoogle)return;
  b.dataset.busy='1';b.style.opacity='.7';
  try{await window.__clerkGoogle()}finally{delete b.dataset.busy;b.style.opacity=''}
});
})();
