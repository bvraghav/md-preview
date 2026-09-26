#!/usr/bin/env python3
"""anchors.py DIR: every link to a #fragment in DIR's pages (same page or
another page in DIR) must land on an element with that id. Prints each
broken link as PAGE: HREF; exits 1 if there are any."""
import os, sys
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit

root = sys.argv[1]
ids, links = {}, []

class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.path, self.ids = path, set()
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if a.get('id'): self.ids.add(a['id'])
        if tag == 'a' and a.get('name'): self.ids.add(a['name'])
        if tag == 'a' and a.get('href'): links.append((self.path, a['href']))

for d, _, files in os.walk(root):
    for f in files:
        if f.endswith('.html'):
            path = os.path.normpath(os.path.join(d, f))
            page = Page(path)
            with open(path, encoding='utf-8') as fh: page.feed(fh.read())
            ids[path] = page.ids

broken = 0
for path, href in links:
    u = urlsplit(href)
    if u.scheme or u.netloc or not u.fragment: continue
    target = os.path.normpath(os.path.join(os.path.dirname(path), unquote(u.path))) if u.path else path
    if target.endswith(os.sep) or os.path.isdir(target): target = os.path.join(target, 'index.html')
    if target not in ids: continue            # not a page here; other checks cover it
    if unquote(u.fragment) not in ids[target]:
        broken += 1
        print(f'{os.path.relpath(path, root)}: {href}')
sys.exit(1 if broken else 0)
