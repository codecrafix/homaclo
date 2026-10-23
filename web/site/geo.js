'use strict';
/* Maintix geolocation: post-login permission gate, auto-fill everywhere, desktop-style nav.
   Reverse-geocode chain mirrors the app: Mappls -> LocationIQ -> BigDataCloud. */
(function(){
  const MAPPLS_KEY='afrxvvpdutbnfrctntffykqkdtebbqojdsej';
  const LOCATIONIQ_KEY='pk.9021ca0351eccb4c4a9ae57085c14964';
  const FIELDS=[{id:'f-addr',label:'📍 Use my current location'},{id:'p-l',label:'📍 Detect my location'}];

  /* ---- desktop-style navigation at every width (no burger/toggle) ---- */
  const st=document.createElement('style');
  st.textContent='.burger{display:none!important}.bnav{display:none!important}.nav{flex-wrap:nowrap}'+
    '#links{position:static!important;flex-direction:row!important;display:flex!important;background:transparent!important;border:0!important;padding:0!important;margin:0 0 0 18px!important;flex:1;overflow-x:auto;white-space:nowrap;scrollbar-width:none}'+
    '#links::-webkit-scrollbar{display:none}#links a{flex:none}.authed .auth-only{display:block!important}.geo-btn{margin-top:8px}';
  document.head.appendChild(st);

  /* ---- helpers ---- */
  const clean=v=>{if(typeof v!=='string')return null;const t=v.trim();return t&&t.toUpperCase()!=='NA'?t:null};
  const uniq=a=>a.filter((v,i)=>v&&a.indexOf(v)===i);
  const count=s=>(s||'').split(',').filter(x=>x.trim()).length;
  const say=m=>{if(typeof toast==='function')toast(m)};
  async function getJson(url){
    const ctl=new AbortController(),t=setTimeout(()=>ctl.abort(),10000);
    try{const r=await fetch(url,{signal:ctl.signal,headers:{Accept:'application/json'}});if(!r.ok)return null;return await r.json()}
    catch(e){return null}finally{clearTimeout(t)}
  }
  async function mappls(lat,lon){
    const urls=[`https://search.mappls.com/search/address/rev-geocode?lat=${lat}&lng=${lon}&access_token=${MAPPLS_KEY}`,`https://apis.mappls.com/advancedmaps/v1/${MAPPLS_KEY}/rev_geocode?lat=${lat}&lng=${lon}`];
    for(const u of urls){
      const d=await getJson(u),r=d&&Array.isArray(d.results)?d.results[0]:null;if(!r)continue;
      const dist=v=>clean(v)?clean(v).replace(/\s+District$/i,''):null;
      let street=clean(r.street);if(street&&/^unnamed road/i.test(street))street=null;
      const hn=clean(r.houseNumber),line=hn&&street?`${hn}, ${street}`:(hn||clean(r.houseName)||clean(r.poi)||street);
      const parts=uniq([line,clean(r.subSubLocality),clean(r.subLocality),clean(r.locality)||clean(r.village),clean(r.city)||dist(r.district)||dist(r.subDistrict),clean(r.state),clean(r.pincode)]);
      if(parts.length)return parts.join(', ');
      if(clean(r.formatted_address))return clean(r.formatted_address);
    }
    return null;
  }
  async function locationIq(lat,lon){
    const d=await getJson(`https://us1.locationiq.com/v1/reverse?key=${LOCATIONIQ_KEY}&lat=${lat}&lon=${lon}&format=json&addressdetails=1&zoom=18`);
    if(!d)return null;const a=d.address;
    if(a){
      const road=clean(a.road)||clean(a.pedestrian)||clean(a.footway)||clean(a.path),hn=clean(a.house_number);
      const line=hn&&road?`${hn}, ${road}`:(clean(a.building)||clean(a.house_name)||road);
      const parts=uniq([line,clean(a.neighbourhood)||clean(a.suburb)||clean(a.quarter)||clean(a.residential),clean(a.city)||clean(a.town)||clean(a.village)||clean(a.county),clean(a.state)]);
      if(parts.length)return parts.join(', ');
    }
    return d.display_name?d.display_name.split(',').slice(0,4).map(s=>s.trim()).filter(Boolean).join(', '):null;
  }
  async function bigDataCloud(lat,lon){
    const d=await getJson(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lon}&localityLanguage=en`);
    if(!d)return null;const parts=uniq([clean(d.locality),clean(d.city),clean(d.principalSubdivision),clean(d.postcode)]);
    return parts.length?parts.join(', '):null;
  }
  async function reverseGeocode(lat,lon){
    const m=await mappls(lat,lon);if(m&&count(m)>=4)return m;
    const l=await locationIq(lat,lon);if(m&&count(m)>=count(l))return m;if(l)return l;
    return (await bigDataCloud(lat,lon))||`${lat.toFixed(5)}, ${lon.toFixed(5)}`;
  }
  function getPosition(){
    return new Promise((res,rej)=>{
      if(!navigator.geolocation)return rej({code:-1});
      navigator.geolocation.getCurrentPosition(res,rej,{enableHighAccuracy:true,timeout:15000,maximumAge:60000});
    });
  }

  /* ---- shared location state ---- */
  let LOC=null,pending=null,running=false;
  try{LOC=JSON.parse(sessionStorage.getItem('mx_loc')||'null')}catch(e){}
  function locate(fresh){
    if(fresh)LOC=null;
    if(LOC)return Promise.resolve(LOC);
    if(pending)return pending;
    pending=(async()=>{
      const p=await getPosition();
      const addr=await reverseGeocode(p.coords.latitude,p.coords.longitude);
      LOC={addr,lat:p.coords.latitude,lon:p.coords.longitude};
      try{sessionStorage.setItem('mx_loc',JSON.stringify(LOC))}catch(e){}
      return LOC;
    })();
    pending.then(()=>{pending=null},()=>{pending=null});
    return pending;
  }
  function setVal(el,v){el.value=v;el.dispatchEvent(new Event('input',{bubbles:true}))}
  function fillEmpty(){
    if(!LOC)return;
    for(const f of FIELDS){const el=document.getElementById(f.id);if(el&&!el.value.trim())setVal(el,LOC.addr)}
  }
  async function saveToProfile(){
    if(!LOC)return;
    for(let i=0;i<20&&!(S.user&&S.profile);i++)await new Promise(r=>setTimeout(r,500));
    if(!S.user||!S.profile||(S.profile.location||'').trim())return;
    try{
      await sb.from('profiles').update({location:LOC.addr,updated_at:new Date().toISOString()}).eq('id',S.user.id);
      S.profile.location=LOC.addr;fillEmpty();
    }catch(e){}
  }
  function applyLoc(){fillEmpty();saveToProfile()}

  /* ---- permission-denied / location-off dialog ---- */
  const help=e=>{
    if(e&&e.code===-1)return {t:'Location not supported',b:'Your browser does not support location access. Please type your address manually.'};
    if(e&&e.code===1)return {t:'Location access is blocked',b:'<p>Maintix needs your location to auto-fill your service address. To allow it:</p><ol style="margin:10px 0 0 18px"><li>Tap the 🔒 / ⚙ icon at the left of the address bar</li><li>Open <b>Site settings</b> → <b>Location</b></li><li>Choose <b>Allow</b>, then press <b>Try again</b> below</li></ol>'};
    return {t:'Turn on your device location',b:'<p>We could not get your location. Please switch on <b>Location / GPS</b> in your device settings, then press <b>Try again</b>.</p>'};
  };
  function showDialog(e){
    const d=document.getElementById('dlg');if(!d)return;
    const h2=help(e);
    d.innerHTML=`<div class="c"><div style="font-size:2.6rem">📍</div><h3>${h2.t}</h3></div><div class="small muted" style="margin:12px 0 4px">${h2.b}</div><p id="geo-msg" class="small err" style="min-height:1.2em"></p>
    <button class="btn block" id="geo-retry" style="margin-top:10px">Allow / Try again</button><button class="btn ghost block" id="geo-skip" style="margin-top:10px">Not now</button>`;
    d.dataset.geo='1';d.addEventListener('close',()=>{delete d.dataset.geo},{once:true});
    if(!d.open)d.showModal();
    document.getElementById('geo-skip').onclick=()=>d.close();
    document.getElementById('geo-retry').onclick=async()=>{
      const b=document.getElementById('geo-retry');b.disabled=true;b.textContent='Checking…';
      try{await locate(true);d.close();say('Location added ✅');applyLoc()}
      catch(err){const m=document.getElementById('geo-msg');if(m)m.textContent=err&&err.code===1?'Still blocked. Please allow location in site settings.':'Still unavailable. Make sure device location is ON.';b.disabled=false;b.textContent='Allow / Try again'}
    };
  }

  /* ---- gate: ask right after login ---- */
  async function gate(force){
    if(running)return;running=true;
    try{await locate();applyLoc()}
    catch(e){
      let shown=false;try{shown=!!sessionStorage.getItem('mx_gate')}catch(_){}
      if(force||!shown){try{sessionStorage.setItem('mx_gate','1')}catch(_){}setTimeout(()=>showDialog(e),1200)}
    }finally{running=false}
  }
  if(navigator.permissions&&navigator.permissions.query){
    navigator.permissions.query({name:'geolocation'}).then(p=>{p.onchange=()=>{
      if(p.state==='granted'){const d=document.getElementById('dlg');if(d&&d.dataset.geo&&d.open)d.close();if(S.user)gate(false)}
    }}).catch(()=>{});
  }
  sb.auth.onAuthStateChange((ev,session)=>{
    if(!session||!session.user)return;
    if(ev!=='SIGNED_IN'&&ev!=='INITIAL_SESSION')return;
    setTimeout(()=>{if(LOC)applyLoc();else gate(ev==='SIGNED_IN')},0);
  });

  /* ---- manual buttons + auto-fill on every render ---- */
  function inject(){
    for(const f of FIELDS){
      const input=document.getElementById(f.id);if(!input||input.dataset.geo)continue;
      input.dataset.geo='1';
      const btn=document.createElement('button');
      btn.type='button';btn.className='btn sm ghost geo-btn';btn.textContent=f.label;
      btn.addEventListener('click',async()=>{
        const o=btn.textContent;btn.disabled=true;btn.textContent='Detecting…';
        try{await locate(true);setVal(input,LOC.addr);say('Location added ✅ Please check and edit if needed');saveToProfile()}
        catch(e){showDialog(e)}
        finally{btn.disabled=false;btn.textContent=o}
      });
      input.insertAdjacentElement('afterend',btn);
    }
    fillEmpty();
  }
  const app=document.getElementById('app');
  if(app){new MutationObserver(inject).observe(app,{childList:true,subtree:true});inject()}
})();
