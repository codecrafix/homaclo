(function(){
'use strict';
/* Home "Customer rating": render the final-looking value straight away (same 5.0 fallback as the Reviews page)
   and keep it out of the count-up animation. Before: it showed a dash, then jumped to the number, then
   re-counted from 0 when the real average arrived. Now it is stable; the real average just replaces the text. */
const _hv=homeView;
homeView=function(){
  return _hv().replace(/<b id="st-r">[^<]*<\/b>/,'<b id="st-r" data-run="1">5.0 ★</b>');
};
})();
