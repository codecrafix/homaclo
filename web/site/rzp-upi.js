(function(){
'use strict';
/* Razorpay checkout: unchanged options (UPI, cards, netbanking, wallets all come from the account's own settings).
   Only adds a check: when Razorpay reports that UPI is OFF for the account/key in use, say so clearly. */
const R=window.Razorpay;
if(typeof R!=='function')return;
let told=false;
function W(o){
  const rz=new R(o);
  try{
    rz.once('ready',r=>{
      const m=r&&r.methods;
      window.__rzpMethods=m;
      if(m&&m.upi===false&&!told){
        told=true;
        console.warn('Razorpay: UPI is disabled for this account/key',m);
        if(typeof toast==='function')toast('UPI is turned off for this Razorpay account. Enable it in Razorpay Dashboard → Payment Methods.');
      }
    });
  }catch(e){}
  return rz;
}
W.prototype=R.prototype;
Object.assign(W,R);
window.Razorpay=W;
})();
