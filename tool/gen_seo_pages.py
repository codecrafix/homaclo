#!/usr/bin/env python3
"""Generate crawlable static HTML per route (services.html, book.html, ...) from web/site/index.html.

GitHub Pages serves the SPA shell through 404.html, so routes like /services answered with an HTTP 404 status
and per-page tags only existed after JavaScript ran. These files give every public route a real 200 response with
its own title, description, canonical, social tags, JSON-LD and readable content (replaced by the app once JS loads).
Usage: python3 tool/gen_seo_pages.py <public_dir>
"""
import html
import json
import os
import re
import sys

ORIGIN = 'https://homaclo.in'
SRC = os.path.join('web', 'site', 'index.html')
OUT = sys.argv[1] if len(sys.argv) > 1 else 'public'
LINKS = ('<p><a href="/">Home</a> · <a href="/services">Services &amp; pricing</a> · <a href="/book">Book water tank cleaning</a> · '
         '<a href="/reviews">Reviews</a> · <a href="/about">About</a> · <a href="/faq">FAQ</a> · <a href="/contact">Contact</a> · '
         '<a href="/refund">Refund policy</a> · <a href="/privacy">Privacy</a> · <a href="/terms">Terms</a></p>')

PAGES = {
    'services': dict(
        t='Services & Pricing: Water Tank Cleaning, Home Cleaning & Maintenance | Homaclo',
        d='Homaclo services and fixed pricing in Satna: water tank cleaning from ₹1,000 (500L to 2000L), plus home cleaning, solar panel cleaning, repair and maintenance.',
        h='Homaclo services and pricing in Satna',
        body='<p>Homaclo is a home services app in Satna, Madhya Pradesh. Water tank cleaning is available to book online today at fixed prices: '
             '500 litre tank ₹1,000, 750 litre ₹1,500, 1000 litre ₹1,800, 1500 litre ₹2,000 and 2000 litre ₹2,500. We clean overhead tanks and underground sumps '
             'for homes, apartments and businesses.</p><p>Home cleaning, solar panel cleaning, and repair and maintenance services are coming soon to Homaclo.</p>'),
    'book': dict(
        t='Book Water Tank Cleaning in Satna Online | Homaclo',
        d='Book water tank cleaning in Satna in under two minutes. Pick tank size and a 2-hour slot, pay securely online. Save ₹500 on 3+ tanks and ₹100 off with WEL100.',
        h='Book water tank cleaning in Satna',
        body='<p>Choose your tank size from 500L to 2000L, pick a 2-hour time slot and pay securely online with Razorpay. Prices start at ₹1,000. '
             'Book 3 or more tanks and save ₹500, and use coupon WEL100 for ₹100 off. Trained Homaclo professionals visit your home in Satna.</p>'),
    'reviews': dict(
        t='Customer Reviews | Homaclo Home Services, Satna',
        d='Read customer reviews of Homaclo home services and water tank cleaning in Satna, Madhya Pradesh.',
        h='Homaclo customer reviews',
        body='<p>See what customers in Satna say about Homaclo water tank cleaning and home services, and share your own review after your booking.</p>'),
    'about': dict(
        t='About Homaclo | Trusted Home Services in Satna',
        d='Homaclo delivers safe, hygienic and affordable home services in Satna, Madhya Pradesh: water tank cleaning today, with home cleaning, repair and maintenance on the way.',
        h='About Homaclo',
        body='<p>Homaclo (also searched as Homeclo, Home Clo or Homa Clo) is a home services brand based in Satna, Madhya Pradesh. We deliver safe, hygienic and affordable '
             'water tank cleaning, with home cleaning, solar panel cleaning, repair and maintenance on the way.</p>'),
    'faq': dict(
        t='FAQs: Booking, Payments & Refunds | Homaclo',
        d='Answers about booking Homaclo services in Satna: pricing, payment methods, WEL100 coupon, reward coins, cancellation and refunds.',
        h='Homaclo frequently asked questions',
        body='<p>Find answers about booking Homaclo services in Satna, fixed pricing, payment methods, the WEL100 coupon, reward coins, cancellation and refunds.</p>'),
    'contact': dict(
        t='Contact Homaclo | Satna, Madhya Pradesh',
        d='Contact Homaclo for bookings, support and privacy requests in Satna, Madhya Pradesh.',
        h='Contact Homaclo',
        body='<p>Email <a href="mailto:homaclo.official@gmail.com">homaclo.official@gmail.com</a>, call <a href="tel:+916262262913">+91 62622 62913</a> '
             'or message us on <a href="https://wa.me/916262262913">WhatsApp</a>. Homaclo, Satna, Madhya Pradesh.</p>'),
    'refund': dict(
        t='Cancellation & Refund Policy | Homaclo',
        d='Homaclo cancellation and refund policy: when refunds apply and how long they take.',
        h='Homaclo cancellation and refund policy',
        body='<p>Read when a Homaclo booking can be cancelled, when refunds apply and how long refunds take.</p>'),
    'privacy': dict(
        t='Privacy & Refund Policy | Homaclo',
        d='How Homaclo collects, uses and protects your data, plus our cancellation and refund policy.',
        h='Homaclo privacy policy',
        body='<p>How Homaclo collects, uses and protects your data.</p>'),
    'terms': dict(
        t='Terms & Conditions | Homaclo',
        d='Terms & Conditions for booking Homaclo home services and water tank cleaning in Satna.',
        h='Homaclo terms and conditions',
        body='<p>Terms for booking Homaclo home services and water tank cleaning in Satna.</p>'),
}

HOME_BODY = ('<h1>Homaclo: home cleaning, repair &amp; water tank cleaning in Satna</h1>'
             '<p>Homaclo is a home services app in Satna, Madhya Pradesh. Book professional water tank cleaning online with fixed prices from ₹1,000, '
             'with home cleaning, solar panel cleaning, repair and maintenance services. Also searched as Homeclo, Home Clo, Homa Clo or Homaclo.in.</p>')


def esc(s):
    return html.escape(s, quote=True)


def set_meta(doc, attr, key, value):
    pat = re.compile(r'(<meta\s+%s="%s"\s+content=")[^"]*(")' % (attr, re.escape(key)))
    return pat.sub(lambda m: m.group(1) + esc(value) + m.group(2), doc, count=1)


def build(src, route, p):
    url = ORIGIN + '/' + route
    doc = src
    doc = re.sub(r'<title>.*?</title>', lambda m: '<title>%s</title>' % esc(p['t']), doc, count=1, flags=re.S)
    doc = set_meta(doc, 'name', 'description', p['d'])
    doc = set_meta(doc, 'property', 'og:title', p['t'])
    doc = set_meta(doc, 'property', 'og:description', p['d'])
    doc = set_meta(doc, 'name', 'twitter:title', p['t'])
    doc = set_meta(doc, 'name', 'twitter:description', p['d'])
    extra = ('<link rel="canonical" href="%s">\n<meta property="og:url" content="%s">\n'
             '<link rel="alternate" hreflang="en-IN" href="%s">\n' % (url, url, url))
    crumbs = json.dumps({
        '@context': 'https://schema.org', '@type': 'BreadcrumbList',
        'itemListElement': [
            {'@type': 'ListItem', 'position': 1, 'name': 'Home', 'item': ORIGIN + '/'},
            {'@type': 'ListItem', 'position': 2, 'name': p['h'], 'item': url}]}, ensure_ascii=False)
    extra += '<script type="application/ld+json">%s</script>\n' % crumbs
    doc = doc.replace('</head>', extra + '</head>', 1)
    nos = '<noscript><div style="padding:24px;max-width:760px;margin:0 auto"><h1>%s</h1>%s%s</div></noscript>' % (esc(p['h']), p['body'], LINKS)
    doc = re.sub(r'<noscript><div style="padding:24px.*?</noscript>', lambda m: nos, doc, count=1, flags=re.S)
    return doc


def main():
    with open(SRC, encoding='utf-8') as f:
        src = f.read()
    home = src.replace('</head>', '<link rel="canonical" href="%s/">\n<meta property="og:url" content="%s/">\n<link rel="alternate" hreflang="en-IN" href="%s/">\n</head>' % ((ORIGIN,) * 3), 1)
    home = re.sub(r'<noscript><div style="padding:24px.*?</noscript>',
                  lambda m: '<noscript><div style="padding:24px;max-width:760px;margin:0 auto">%s%s</div></noscript>' % (HOME_BODY, LINKS),
                  home, count=1, flags=re.S)
    with open(os.path.join(OUT, 'index.html'), 'w', encoding='utf-8') as f:
        f.write(home)
    for route, p in PAGES.items():
        with open(os.path.join(OUT, route + '.html'), 'w', encoding='utf-8') as f:
            f.write(build(src, route, p))
    print('generated %d SEO pages' % (len(PAGES) + 1))


if __name__ == '__main__':
    main()
