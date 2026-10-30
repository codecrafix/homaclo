#!/usr/bin/env python3
"""SEO keyword boost (runs in CI before the site is assembled).

Adds a broad keyword set (cleaning, wash, repair, home maintenance, Urban Company style searches, Homaclo misspellings)
to every page's meta keywords and to the crawlable <noscript> text, and enriches the home-page service cards in seo.js.
Water tank cleaning is the only service that is bookable today; the rest are described as being added.
"""
import glob
import os
import re

SITE = "web/site"

KEYWORDS = (
    "Homaclo, Homeclo, Home Clo, Homa Clo, Homaklo, Homeklo, Homacloo, Homaclo.in, होमाक्लो, "
    "home services Satna, home services near me, home service app, home services at doorstep, "
    "urban company alternative, urban company Satna, urbanclap alternative, housejoy alternative, best home service app in Satna, "
    "cleaning services in Satna, home cleaning, house cleaning near me, deep cleaning service, full home deep cleaning, "
    "bathroom cleaning, kitchen cleaning, sofa cleaning, carpet cleaning, balcony cleaning, floor cleaning, "
    "water tank cleaning Satna, water tank cleaning near me, sump cleaning, overhead tank cleaning, underground tank cleaning, "
    "solar panel cleaning, car wash at home, bike wash at home, car cleaning service, "
    "home repair services, home maintenance services, repair and maintenance near me, plumber in Satna, electrician in Satna, "
    "carpenter in Satna, AC repair and service, RO water purifier service, appliance repair, painting services, pest control, "
    "book home services online, affordable home services, trained professionals, fixed price home services, Satna Madhya Pradesh, "
    "पानी की टंकी सफाई, टंकी सफाई सतना, घर की सफाई, घर की मरम्मत, होम सर्विस सतना"
)

EXTRA = (
    '<h2>Home cleaning, wash, repair and maintenance in Satna</h2>'
    '<p>Homaclo is a Satna home services app and an easy Urban Company style alternative for local families. '
    'Water tank cleaning (overhead tanks and underground sumps, 500L to 2000L, from ₹1,000) can be booked online today. '
    'We are adding home deep cleaning, bathroom, kitchen and sofa cleaning, solar panel cleaning, car and bike wash at home, '
    'and home repair and maintenance such as plumber, electrician, carpenter, AC service, RO service and painting.</p>'
)

KW_RE = re.compile(r'(<meta name="keywords" content=")[^"]*(")')
NOS_END = '</div></noscript>'

for f in glob.glob(f"{SITE}/*.html"):
    s = open(f, encoding="utf-8").read()
    n = KW_RE.sub(lambda m: m.group(1) + KEYWORDS + m.group(2), s, count=1)
    if EXTRA not in n and NOS_END in n:
        n = n.replace(NOS_END, EXTRA + NOS_END, 1)
    if n != s:
        open(f, "w", encoding="utf-8").write(n)
        print("keywords boosted:", f)

seo = f"{SITE}/seo.js"
if os.path.exists(seo):
    s = open(seo, encoding="utf-8").read()
    s = s.replace(
        "Professional cleaning for your home and rooftop solar panels. Being added to Homaclo soon.",
        "Deep cleaning for your home, bathroom, kitchen and sofa, plus car wash and rooftop solar panel cleaning. Being added to Homaclo soon.")
    s = s.replace(
        "Home repair and maintenance by verified technicians. Being added to Homaclo soon.",
        "Home repair and maintenance by verified technicians: plumber, electrician, AC and RO service. A simple Urban Company alternative in Satna, being added soon.")
    open(seo, "w", encoding="utf-8").write(s)
    print("seo.js service cards enriched")
