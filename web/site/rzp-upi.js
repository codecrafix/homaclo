(function(){
'use strict';
/* Razorpay checkout: always show the UPI block first, then cards / netbanking / wallets.
   Loaded right after checkout.js; only adds `config` when the caller did not pass one. */
const R=window.Razorpay;
if(typeof R!=='function')return;
function W(o){
  o=o||{};
  if(!o.config)o.config={display:{
    blocks:{
      upi:{name:'Pay via UPI',instruments:[{method:'upi'}]},
      other:{name:'Cards, Netbanking & more',instruments:[{method:'card'},{method:'netbanking'},{method:'wallet'},{method:'emi'},{method:'paylater'}]}
    },
    sequence:['block.upi','block.other'],
    preferences:{show_default_blocks:false}
  }};
  return new R(o);
}
W.prototype=R.prototype;
Object.assign(W,R);
window.Razorpay=W;
})();
