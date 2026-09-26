#!/usr/bin/env python3
"""roundtrip.py HTML SOURCE — check a rendered source page against its source.

Takes the first <pre><code> block in HTML (as produced from source-page.sh
output), strips the markup that syntax highlighting and line numbers add,
decodes HTML entities, and compares the text with SOURCE byte for byte.
The only allowed difference is the final newline, which pandoc drops from
every code block. Exits 1 with a unified diff on mismatch.
"""

import difflib
import html
import re
import sys


def extract(page: str) -> str:
    m = re.search(r"<pre[^>]*>\s*<code[^>]*>(.*?)</code>\s*</pre>", page, re.S)
    if not m:
        sys.exit("roundtrip: no <pre><code> block found")
    # Inside the block, '<' only ever starts a tag: text '<' is escaped.
    return html.unescape(re.sub(r"<[^>]*>", "", m.group(1)))


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__.strip().splitlines()[0])
    page_path, source_path = sys.argv[1:]
    with open(page_path, encoding="utf-8") as f:
        got = extract(f.read())
    with open(source_path, encoding="utf-8", newline="") as f:
        want = f.read()
    if want.endswith("\n"):
        want = want[:-1]

    if got == want:
        print(f"roundtrip: {source_path} reproduced exactly "
              f"({want.count(chr(10)) + 1} lines, {len(want.encode())} bytes)")
        return
    diff = difflib.unified_diff(want.splitlines(keepends=True), got.splitlines(keepends=True),
                                source_path, page_path + " (extracted)")
    sys.stdout.writelines(diff)
    sys.exit("roundtrip: MISMATCH")


if __name__ == "__main__":
    main()
