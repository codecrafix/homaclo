'use strict';
/* Geolocation + reverse geocoding (parity with app's lib/services/location_service.dart)
   Chain: Mappls -> LocationIQ -> BigDataCloud (keyless). Each step fails soft. */
(function(){
  const MAPPLS_KEY='afrxvvpdutbnfrctntffykqkdtebbqojdsej';
  const LOCATIONIQ_KEY='pk.9021ca0351eccb4c4a9ae57085c14964';
  const TARGETS=[{id:'f-addr',label:'📍 Use my current location'},{id:'p-l',label:'📍 Detect my location'}];

  const clean=v=>{if(typeof v!=='string')return null;const t=v.trim();return t&&t.toUpperCase()!=='NA'?t:null};
  const uniq=a=>a.filter((v,i)=>v&&a.indexOf(v)===i);
  const count=s=>(s||'').split(',').filter(x=>x.trim()).length;
  async function getJson(url){
    const ctl=new AbortController(),t=setTimeout(()=>ctl.abort(),10000);
    try{const r=await fetch(url,{signal:ctl.signal,headers:{Accept:'application/json'}});if(!r.ok)return null;return await r.json()}
    catch(e){return null}finally{clearTimeout(t)}
  }

  async function mappls(lat,lon){
    const urls=[
      `https://search.mappls.com/search/address/rev-geocode?lat=${lat}&lng=${lon}&access_token=${MAPPLS_KEY}`,
      `https://apis.mappls.com/advancedmaps/v1/${MAPPLS_KEY}/rev_geocode?lat=${lat}&lng=${lon}`
    ];
    for(const u of urls){
      const d=await getJson(u),r=d&&Array.isArray(d.results)?d.results[0]:null;
      if(!r)continue;
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
    if(!d)return null;
    const a=d.address;
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
    if(!d)return null;
    const parts=uniq([clean(d.locality),clean(d.city),clean(d.principalSubdivision),clean(d.postcode)]);
    return parts.length?parts.join(', '):null;
  }

  async function reverseGeocode(lat,lon){
    const m=await mappls(lat,lon);
    if(m&&count(m)>=4)return m;
    const l=await locationIq(lat,lon);
    if(m&&count(m)>=count(l))return m;
    if(l)return l;
    return (await bigDataCloud(lat,lon))||`${lat.toFixed(5)}, ${lon.toFixed(5)}`;
  }

  function getPosition(){
    return new Promise((res,rej)=>{
      if(!navigator.geolocation)return rej({code:-1});
      navigator.geolocation.getCurrentPosition(res,rej,{enableHighAccuracy:true,timeout:15000,maximumAge:60000});
    });
  }

  const msg=e=>e&&e.code===1?'Location permission denied. Please allow it in your browser settings or type the address.'
    :e&&e.code===-1?'Your browser does not support location.'
    :e&&e.code===3?'Location timed out. Please try again or type the address.'
    :'Could not detect your location. Please type the address.';

  async function fill(input,btn,silent){
    const orig=btn.textContent;btn.disabled=true;btn.textContent='Detecting…';
    try{
      const p=await getPosition();
      const addr=await reverseGeocode(p.coords.latitude,p.coords.longitude);
      input.value=addr;
      input.dispatchEvent(new Event('input',{bubbles:true})); // keeps app cart state (S.cart.addr) in sync
      if(!silent&&typeof toast==='function')toast('Location added ✅ Please check and edit if needed');
    }catch(e){
      if(!silent&&typeof toast==='function')toast(msg(e));
    }finally{btn.disabled=false;btn.textContent=orig}
  }

  async function inject(){
    for(const t of TARGETS){
      const input=document.getElementById(t.id);
      if(!input||input.dataset.geo)continue;
      input.dataset.geo='1';
      const btn=document.createElement('button');
      btn.type='button';btn.className='btn sm ghost geo-btn';btn.textContent=t.label;btn.style.margin='8px 0 0';
      btn.addEventListener('click',()=>fill(input,btn,false));
      input.insertAdjacentElement('afterend',btn);
      // Silent auto-fill only if permission was already granted earlier and field is empty
      if(!input.value.trim()&&t.id==='f-addr'&&navigator.permissions&&navigator.permissions.query){
        try{const s=await navigator.permissions.query({name:'geolocation'});
          if(s.state==='granted'&&document.body.contains(input)&&!input.value.trim())fill(input,btn,true)}catch(e){}
      }
    }
  }

  const app=document.getElementById('app');
  if(app){new MutationObserver(inject).observe(app,{childList:true,subtree:true});inject()}
})();
