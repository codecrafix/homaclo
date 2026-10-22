(function(){
const $$=(s,e=document)=>[...e.querySelectorAll(s)];
function fix(){$$('#svc .card').forEach(c=>{const i=c.querySelector('.ph img');if(!i||i.dataset.s)return;const t=c.textContent;if(/solar/i.test(t)&&/cleaning/i.test(t)&&!/maintenance|repair/i.test(t)){i.dataset.s=1;i.onerror=()=>{i.onerror=null;i.src='img/maintix-7.png'};i.src='img/maintix-9.png'}})}
new MutationObserver(()=>requestAnimationFrame(fix)).observe(document.getElementById('app'),{childList:true,subtree:true});fix();
})();
