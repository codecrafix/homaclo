#!/usr/bin/env python3
"""Website speed: compress images (PNG -> WebP) and point the site at them.

Run ONCE from the repo root (Replit shell / any PC), then commit + push:

    pip install pillow
    python3 tool/optimize_web.py

What it does
  0. (CI deploy) generates static SEO pages web/site/<route>.html via tool/gen_seo_pages.py
     and adds the SEO keyword set via tool/seo_boost.py
  1. web/site/img/*.png  ->  *.webp  (max 1100px wide, quality 76; typically 80-90% smaller)
  2. rewrites img/xxx.png -> img/xxx.webp in web/site JS/CSS/HTML
     (og:image / twitter:image / seo.js / sw.js are left on PNG for social previews)
  3. bumps the image cache name in sw.js so visitors get the new files
The original PNGs are kept (used for social-share previews).
"""
import glob
import os
import re
import subprocess
import sys

from PIL import Image

SITE = "web/site"
IMG = f"{SITE}/img"

# Step 0: static, crawlable HTML for every public route (services.html, book.html, ...).
# index.html is restored afterwards because it is also the SPA fallback (404.html) shell.
if os.environ.get("GITHUB_ACTIONS") == "true" and os.path.exists("tool/gen_seo_pages.py"):
    _idx = f"{SITE}/index.html"
    _orig = open(_idx, encoding="utf-8").read()
    try:
        subprocess.run([sys.executable, "tool/gen_seo_pages.py", SITE], check=True)
    except Exception as e:
        print("SEO page generation skipped:", e)
    finally:
        open(_idx, "w", encoding="utf-8").write(_orig)
    try:
        subprocess.run([sys.executable, "tool/seo_boost.py"], check=True)
    except Exception as e:
        print("SEO keyword boost skipped:", e)

saved_before = saved_after = 0
for p in sorted(glob.glob(f"{IMG}/*.png")):
    dst = p[:-4] + ".webp"
    im = Image.open(p)
    im = im.convert("RGBA" if "A" in im.getbands() else "RGB")
    im.thumbnail((1100, 1100), Image.LANCZOS)
    im.save(dst, "WEBP", quality=76, method=6)
    b, a = os.path.getsize(p), os.path.getsize(dst)
    saved_before += b
    saved_after += a
    print(f"{os.path.basename(p):18} {b // 1024:5} KB -> {a // 1024:4} KB")
print(f"TOTAL {saved_before // 1024} KB -> {saved_after // 1024} KB")

pat = re.compile(r"(img/(?:maintix-[^.\"'`]*|before|after))\.png")
skip_lines = re.compile(r"og:image|twitter:image")
changed = 0
for ext in ("js", "css", "html"):
    for f in glob.glob(f"{SITE}/*.{ext}"):
        if os.path.basename(f) in ("seo.js", "sw.js"):
            continue
        out, dirty = [], False
        for line in open(f, encoding="utf-8").read().split("\n"):
            new = line if skip_lines.search(line) else pat.sub(r"\1.webp", line)
            dirty |= new != line
            out.append(new)
        if dirty:
            open(f, "w", encoding="utf-8").write("\n".join(out))
            changed += 1
            print("updated", f)

sw = f"{SITE}/sw.js"
s = open(sw, encoding="utf-8").read()
s2 = re.sub(r"const C='mx-img-v(\d+)'", lambda m: f"const C='mx-img-v{int(m.group(1)) + 1}'", s)
if s2 != s:
    open(sw, "w", encoding="utf-8").write(s2)
    print("bumped image cache in sw.js")
print(f"Done. {changed} files updated. Now: git add -A && git commit -m 'optimize images' && git push")
