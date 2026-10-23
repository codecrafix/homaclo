(function(){
const $$=(s,e=document)=>[...e.querySelectorAll(s)];
function fix(){$$('#svc .card').forEach(c=>{const i=c.querySelector('.ph img');if(!i||i.dataset.s)return;const t=c.textContent;if(/solar/i.test(t)&&/cleaning/i.test(t)&&!/maintenance|repair/i.test(t)){i.dataset.s=1;i.onerror=()=>{i.onerror=null;i.src='img/maintix-7.png'};i.src='img/maintix-9.png'}})}
new MutationObserver(()=>requestAnimationFrame(fix)).observe(document.getElementById('app'),{childList:true,subtree:true});fix();
})();

/* Signup bonus (parity with the app): the Supabase trigger credits 50 welcome coins at account
   creation. claim_signup_bonus() is an idempotent server-side fallback for accounts the trigger
   missed (e.g. created before it existed). Safe to call on every login: it can only ever pay once. */
(function(){
const tried=new Set();
const seenKey=id=>'mx_welcome_'+id;
const seen=id=>{try{return !!localStorage.getItem(seenKey(id))}catch(e){return false}};
const mark=id=>{try{localStorage.setItem(seenKey(id),'1')}catch(e){}};
sb.auth.onAuthStateChange((ev,session)=>{
  const u=session&&session.user;
  if(!u||tried.has(u.id))return;
  tried.add(u.id);
  // Never await Supabase calls inside this callback (known deadlock); defer instead.
  setTimeout(async()=>{
    try{
      const {data,error}=await sb.rpc('claim_signup_bonus');
      if(error){tried.delete(u.id);return}
      let show=data===true;
      if(!show&&!seen(u.id)){
        const since=new Date(Date.now()-7*864e5).toISOString();
        const {data:w}=await sb.from('coin_transactions').select('id').eq('user_id',u.id).eq('type','welcome').gte('created_at',since).limit(1);
        show=!!(w&&w.length);
      }
      if(show){
        mark(u.id);
        await refreshCoins();
        toast('Welcome to Maintix! 50 bonus coins added 🪙');
        route();
      }
    }catch(e){tried.delete(u.id)}
  },600);
});
})();
