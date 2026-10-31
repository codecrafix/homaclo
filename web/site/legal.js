(function(){
/* Policy & legal pages: content mirrored 1:1 from the Flutter app
   (terms_screen.dart, privacy_policy_screen.dart, about_us_screen.dart). Keep in sync with the app. */
const E=s=>h(s).replace(/homaclo\.official@gmail\.com/g,'<a href="mailto:homaclo.official@gmail.com">homaclo.official@gmail.com</a>').replace(/\+91 62622 62913/g,'<a href="tel:+916262262913">+91 62622 62913</a>');
const sub=(t,i)=>({k:'sub',t,i}),ul=(i,d)=>({k:'ul',i,d}),box=t=>({k:'box',t}),note=t=>({k:'note',t});
const S=(t,p,b)=>({t,p,b:b||[]});
const ADDR='Jawahar Nagar, Satna, Madhya Pradesh, India';

const CANCEL_REFUND=[
  sub('🚫 CANCELLATION POLICY BY CUSTOMER:',[
    '• Non-Cancellable Bookings: All service requests (including Tank Cleaning, Solar Maintenance, and Home Services) submitted through the Homaclo application are final.',
    '• Customer Obligations: Once a service booking is confirmed, customers are required to allow the assigned technician to execute the service. Requests for cash refunds or booking cancellations upon customer change of mind will not be entertained.']),
  sub('💰 REFUND ELIGIBILITY & CONDITIONS:',[
    '• Service Non-Fulfillment: Refunds are strictly issued only under extraordinary circumstances where Homaclo is unable to execute or deliver the scheduled service due to operational issues, technician unavailability, severe weather, or unforeseen technical failures.',
    '• Partial / Failed Transactions: In the event of an accidental double payment or money debited without booking generation, the excess amount is fully eligible for a refund.']),
  sub('⏳ REFUND TIMELINE & PAYMENT MODE:',[
    '• Processing Window: Upon verification of service non-fulfillment by our operations team, the refund process will be initiated immediately.',
    '• Credit Duration: All approved refunds will be credited back to the customer’s original payment source (Bank Account, Credit/Debit Card, or UPI ID) within 5 to 7 business days (approx. 1 week).']),
  sub('📞 DISPUTES & SUPPORT RESOLUTION:',[
    '• For any refund status tracking, billing discrepancies, or failed transaction queries, please contact our support desk directly with your Booking ID and payment reference number.',
    '• Official Email: homaclo.official@gmail.com',
    '• Escalation Contact: +91 62622 62913'])
];
const PRIV_CONTACT='For privacy-related questions, data requests, or concerns:\n\n📧 Email: homaclo.official@gmail.com\n📞 Phone: +91 62622 62913\n📍 Address: '+ADDR;
const TERMS_CONTACT='For questions about these Terms:\n\n📧 homaclo.official@gmail.com\n📞 +91 62622 62913\n📍 '+ADDR;

const PAGES={
 terms:{key:'terms',icon:'📄',title:'Terms & Conditions',sub:'Effective: January 1, 2026 · Homaclo Service Agreement',secs:[
  S('1. Acceptance of Terms','By using the Homaclo website or mobile application ("App"), you agree to be bound by these Terms & Conditions ("Terms"). These Terms constitute a legally binding agreement between you ("User") and Homaclo ("Company"). If you do not agree to these Terms, do not use the App or our services.'),
  S('2. Service Description','Homaclo provides professional water tank cleaning and maintenance services. Our services include:\n\n• Overhead water tank cleaning (500L – 2000L capacity)\n• Underground sump cleaning\n• Tank disinfection and sanitization\n• Post-cleaning water quality inspection\n\nAll services are performed by trained and verified Homaclo technicians.'),
  S('3. Booking & Scheduling',null,[ul(['Choose your preferred date and time slot while booking; slots (including same-day slots) are subject to availability in your area','You will receive a booking confirmation in the app or website and as a notification','Our team will contact you 1–2 hours before the scheduled service','Please ensure water access and tank accessibility at the time of service','Bookings are confirmed only after successful payment'])]),
  S('4. Cancellation Policy',null,[box('🚫 Bookings are non-cancellable'),ul(['All service requests (including Tank Cleaning, Solar Maintenance, and Home Services) submitted through the Homaclo app are final once confirmed','Once a booking is confirmed, you must allow the assigned technician to carry out the service','Cancellation or refund requests due to change of mind are not entertained','If Homaclo is unable to deliver the scheduled service, you are eligible for a refund — see the Refund Policy below and section 10 of our Privacy & Refund Policy'])]),
  S('5. Payment Policy',null,[
   sub('Accepted Payment Methods',['• Online Payment — Pay securely via Razorpay using UPI, debit/credit card or netbanking','• Reward Coins — Earn 10 coins per review; redeem for discounts on future bookings']),
   sub('Pricing & Taxes',['• All prices listed in the app are inclusive of applicable GST','• Prices are fixed and transparent — no hidden charges','• Special discounts may apply during promotional periods','• Price revisions, if any, will be communicated 30 days in advance']),
   sub('Refund Policy',['• Refunds are issued only when Homaclo is unable to deliver the scheduled service (operational issues, technician unavailability, severe weather, or unforeseen technical failures)','• An accidental double payment, or money debited without a booking being created, is fully refundable','• Approved refunds are credited to the original payment source within 5–7 business days','• Full details: Privacy & Refund Policy, section 10'])]),
  S('6. User Responsibilities',null,[ul(['Provide accurate address, contact details, and tank specifications','Ensure safe and unobstructed access to the water tank','Be present or designate a responsible adult during the service','Inform us of any special requirements or tank conditions in advance','Do not misuse the app or submit fraudulent bookings','Treat our service technicians with respect and professionalism','Report service issues within 24 hours of service completion'])]),
  S('7. Service Quality Guarantee','Homaclo guarantees professional-grade cleaning using food-safe, eco-friendly agents. If you are unsatisfied with the service quality:\n\n• Report within 24 hours via the app or email\n• We will re-inspect and re-service at no additional cost\n• If the issue persists, our support team will review it and resolve it with you\n\nThis guarantee does not cover pre-existing tank damage or structural issues.'),
  S('8. Limitation of Liability','Homaclo shall not be liable for:\n\n• Indirect, incidental, or consequential damages arising from service use\n• Pre-existing damage to tanks, pipes, or water systems\n• Delays caused by factors beyond our control (weather, emergencies)\n• Data loss due to device failure or third-party service outages\n\nOur maximum liability is limited to the amount paid for the specific service in question.'),
  S('9. Intellectual Property','All content within the Homaclo app — including logos, text, graphics, and software — is the exclusive property of Homaclo and protected under Indian copyright law. Unauthorized reproduction, distribution, or modification is strictly prohibited.'),
  S('10. Governing Law & Disputes','These Terms are governed by the laws of India. Any disputes arising from these Terms or our services shall be subject to the exclusive jurisdiction of courts in Satna, Madhya Pradesh, India. We encourage resolution through direct communication before pursuing legal action.'),
  S('11. Amendments','Homaclo reserves the right to modify these Terms at any time. Updated Terms will be posted in the app with a revised effective date. Continued use of the app after changes constitutes acceptance of the new Terms.'),
  S('12. Contact',TERMS_CONTACT)
 ]},
 privacy:{key:'privacy',icon:'🛡️',title:'Privacy & Refund Policy',sub:'Last updated: January 1, 2026 · Homaclo v1.0.0',secs:[
  S('1. Introduction','Homaclo ("we", "our", or "us") is committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services. Please read this policy carefully. If you disagree with its terms, please discontinue use of our app.'),
  S('2. Information We Collect',null,[
   sub('Personal Identification Data',['• Full Name — used to personalize your account and service bookings','• Phone Number — used for booking confirmations and service updates','• Email Address — used for account authentication and notifications']),
   sub('Location & Service Data',['• City / Area — used to match you with available service slots','• Service Address — collected only at booking time for technician dispatch','• Landmark Details — optional, used to assist our service team']),
   sub('Usage & Behavioral Data',['• App interaction logs (screens visited, features used)','• Booking history and service preferences','• Review and rating submissions'])]),
  S('3. Data Security Standards',null,[
   sub('Encryption Practices',['• All data transmitted between the app and our servers is encrypted using TLS 1.3 (Transport Layer Security)','• Stored personal data is encrypted at rest using AES-256 encryption','• Passwords and sensitive credentials are hashed using bcrypt with salt rounds','• API communications use HTTPS exclusively — no plain HTTP connections']),
   sub('Access Controls',['• Only authorized Homaclo personnel can access user data','• Role-based access control (RBAC) limits data visibility by job function','• All data access is logged and audited regularly']),
   sub('Infrastructure Security',['• Data hosted on ISO 27001-certified cloud infrastructure','• Regular security audits and penetration testing conducted','• Automated threat detection and intrusion prevention systems active'])]),
  S('4. How We Use Your Data',null,[ul(['To process and confirm your service bookings','To dispatch and coordinate our cleaning technicians','To send booking confirmations and service reminders','To improve app features and user experience','To calculate and credit loyalty reward coins','To respond to customer support inquiries','To comply with applicable legal obligations'],1)]),
  S('5. Data Sharing & Third Parties','We do NOT sell, trade, or rent your personal information to third parties. We may share limited data with:\n\n• Service technicians (name, address, phone) — only for active bookings\n• Payment processors — only transaction amounts, no card data stored by us\n• Legal authorities — only when required by law or court order\n\nAll third-party partners are contractually bound to maintain data confidentiality.'),
  S('6. Your Privacy Rights',null,[ul(['🔍 Right to Access — Request a copy of all data we hold about you','✏️ Right to Rectification — Correct inaccurate or incomplete data','🗑️ Right to Erasure — Request deletion of your account and data','🚫 Right to Object — Opt out of non-essential data processing','📦 Right to Portability — Receive your data in a portable format','🔒 Right to Restriction — Limit how we process your data'],1),note('To exercise any of these rights, contact us at homaclo.official@gmail.com')]),
  S('7. Data Retention','We retain your personal data for as long as your account is active or as needed to provide services. Booking records are retained for 3 years for legal and tax compliance. You may request deletion of your account at any time, after which personal data is purged within 30 days.'),
  S('8. Children\'s Privacy','Homaclo services are not directed to individuals under the age of 18. We do not knowingly collect personal information from minors. If we become aware that a child under 18 has provided us with personal data, we will delete it immediately.'),
  S('9. Changes to This Policy','We may update this Privacy Policy periodically. We will notify you of significant changes via in-app notification or email. Continued use of the app after changes constitutes acceptance of the updated policy.'),
  S('10. Cancellation & Refund Policy',null,CANCEL_REFUND),
  S('11. Contact Us',PRIV_CONTACT)
 ]},
 refund:{key:'refund',icon:'💰',title:'Cancellation & Refund Policy',sub:'Last updated: January 1, 2026 · Homaclo v1.0.0',secs:[S('Cancellation & Refund Policy',null,CANCEL_REFUND)]},
 contact:{key:'contact',icon:'📞',title:'Contact Us',sub:'Homaclo · Jawahar Nagar, Satna, Madhya Pradesh, India',secs:[
  S('Privacy & Data Requests',PRIV_CONTACT),
  S('Questions About Our Terms',TERMS_CONTACT)
 ]}
};
PAGES.cancellation=PAGES.refund;

const NAV=[['terms','Terms'],['privacy','Privacy & Refund'],['refund','Cancellation & Refund'],['contact','Contact'],['about','About']];
const nav=a=>`<div class="lg-nav">${NAV.map(n=>`<a href="#/${n[0]}" class="${n[0]===a?'on':''}">${h(n[1])}</a>`).join('')}</div>`;
const block=(b,p)=>{
  if(b.k==='sub')return `<div class="lg-sub"><h3>${E(b.t)}</h3><ul>${b.i.map(x=>`<li>${E(x)}</li>`).join('')}</ul></div>`;
  if(b.k==='ul')return `<ul class="lg-ul">${b.i.map(x=>`<li>${b.d?'• ':''}${E(x)}</li>`).join('')}</ul>`;
  if(b.k==='box')return `<div class="lg-box">${E(b.t)}</div>`;
  return `<p class="lg-note">${E(b.t)}</p>`;
};
const sec=s=>`<section class="lg-card"><h2>${E(s.t)}</h2>${s.p?`<p>${E(s.p)}</p>`:''}${s.b.map(block).join('')}</section>`;
const hero=(i,t,s)=>`<div class="lg-hero"><div class="ic">${i}</div><h1>${E(t)}</h1><p>${E(s)}</p></div>`;
const shell=(a,inner)=>`<div class="page"><div class="wrap fade"><div class="lg">${nav(a)}${inner}</div></div></div>`;

legalView=function(kind){
  const d=PAGES[kind]||PAGES.terms;
  return shell(d.key,hero(d.icon,d.title,d.sub)+d.secs.map(sec).join(''));
};

aboutView=function(){
  const card=(i,t,body)=>`<section class="lg-card"><h2><span class="lg-ic">${i}</span>${E(t)}</h2>${body}</section>`;
  const row=(l,v)=>`<div class="lg-row"><span>${l}:</span><b>${E(v)}</b></div>`;
  return shell('about',
   `<div class="lg-hero c"><div class="lg-logo"><span class="drop"></span>Homaclo</div><p style="font-size:.85rem;color:rgba(255,255,255,.7)">Trusted Water Tank Cleaning Services</p></div>`+
   card('🚩','Our Mission','<p>At Homaclo, our mission is to deliver safe, hygienic, and affordable water tank cleaning services to every household and business. We believe clean water storage is a fundamental right, not a luxury — and we\'re here to make it accessible to all.</p>')+
   card('👁️','Our Vision','<p>We envision a future where every family in India has access to professionally maintained water storage systems. By 2030, Homaclo aims to serve 1 million households across Madhya Pradesh and beyond, setting the gold standard for home maintenance services.</p>')+
   card('⭐','Why Choose Homaclo?','<ul class="lg-ul">'+['✅ Certified & trained cleaning professionals','✅ Eco-friendly, food-grade cleaning agents','✅ Transparent pricing — no hidden charges','✅ Same-day & scheduled booking options','✅ 100% satisfaction guarantee on every service','✅ Real-time booking tracking & updates'].map(x=>`<li>${E(x)}</li>`).join('')+'</ul>')+
   card('🧽','Our Services',Object.entries(PRICES).map(([k,p])=>`<div class="lg-svc"><span>💧 ${k} Tank Cleaning</span><b>${inr(p)}</b></div>`).join(''))+
   card('🏢','Company Details',row('Headquarters',ADDR)+row('Email','homaclo.official@gmail.com')+row('Phone','+91 62622 62913')+row('Founded','2024')+row('Version','Homaclo App v1.0.0 (2026)')));
};

Object.assign(ROUTES,{refund:'refund',cancellation:'cancellation',contact:'contact'});

function foot(){
  const c=[...document.querySelectorAll('.foot h5')].find(x=>x.textContent.trim()==='Company');
  if(!c||c.parentElement.querySelector('[href="#/refund"]'))return;
  [['#/refund','Cancellation & Refund'],['#/contact','Contact Us']].forEach(([u,t])=>{const a=document.createElement('a');a.href=u;a.textContent=t;c.parentElement.append(a)});
}
foot();
/* footer address: show the full business address */
document.querySelectorAll('.foot span').forEach(s=>{if(s.textContent.trim()==='Satna, Madhya Pradesh')s.textContent='Jawahar Nagar, Satna, Madhya Pradesh'});
})();
