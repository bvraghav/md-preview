# TODO

## Intent

1. Can we also have a [View Source] link inside of the demo?  I'd prefer it to be a markdown source set within a `.md` file and then compiled to see how robust our mechanism is.  If it succeeds, just mention the robustness in the README.md with interesting examples.
2. Can we also create a toc on the fly?  How good an option would that be?
3. Since we are using template in pandoc, can we use svelte to implement bells and whistles (BANDW)?
4. BANDW 1: [folder-tree] when invoked inside of a folder (without an index document) and also in any page.md albeit with (hide/unhide) toggle.
5. BANDW 2: [toc] page toc, relevant for jumping in very long pages again with (hide/unhide) toggle.
6. BANDW: in general, anything that can be formulated once, and statically templated to be filled in on every site build.
7. BANDW: also for use directly by md-preview, not just `site/`
8. BANDW: may require refactoring `md-preview` as Makefile instead of script for better management.

You opinion solicited.  Only your opinion.

## Plan

Here's my view, point by point, with a suggested order at the end.

**1. View Source for the demo: yes, and make it a real test.**
Have the site build generate a `demo-source.md` that wraps `test-sample.md` verbatim in a fenced `markdown` block, compile it to `demo-source.html` like any other page, and link to it from the demo.
- **Good stress test.** The page puts everything our pipeline treats specially inside a code block, where it must come out untouched:
  - the frontmatter and its `---` markers
  - `$…$` math, `\newcommand` (pandoc must not expand it inside code), `\(`
  - fences inside fences, `mermaid` and `math` fences (the filter must not convert them)
  - raw HTML
- **One real trap: the outer fence.** It must be longer than any run of backticks inside the file. The sample has none longer than three, but REFERENCE.md has four. So the build should compute the fence length rather than hard-code it.
- **Only claim robustness if we check it.** Add a step to `make check` that pulls the text back out of the rendered `<code>`, unescapes it, and diffs it against the source byte for byte. Then the README can say "the demo's own source round-trips exactly", with examples like the ones above.

**2. TOC on the fly: good option, and pandoc already does it.**
`--toc` builds the TOC at render time from the real heading IDs. It works without JavaScript and respects `--toc-depth`, so there's no reason to build it in the browser.
- **You need an opt-out.** README already has a hand-written Contents section, so an automatic TOC would duplicate it.
- **How the opt-out works:** always pass `--toc`, and have the template skip it when the frontmatter says `md-preview-toc: false`. The metadata can't switch `--toc` off itself because it's a writer option, but the template can decide whether to show the result.

**3. Svelte: not now.**
The widgets you describe (collapsible tree, collapsible TOC, highlighting the current section while scrolling, remembering hide/show) come to about 100–150 lines of plain JS plus `<details>`. Their data (headings, file list) is already known at build time, so there's almost no state for Svelte to manage.
- **What Svelte would add:** a compile step, a toolchain to keep updated, and a split between "pandoc renders the page" and "components render parts of it", for very little gain.
- **When I'd reconsider:** if the tree grows search, filtering or keyboard navigation. Even then, I'd commit the compiled JS bundle so users never need the Svelte toolchain.
- **Better model for now:** build the HTML at build time and add a small plain-JS enhancement script.

**4. Folder tree: worth it, and folder mode is the bigger feature.**
There are really two features here:
- **The tree fragment:** easy. Generate a nested `<ul>` from `find` once per build and include it in each page, behind a hide/show toggle.
- **Folder mode**, `md-preview serve DIR`: this is an architecture change. It means rendering many files, rewriting `.md` links to `.html` (today that's `site/links.lua`, which would move into the core), and re-rendering everything when a file is added or removed, because the tree changes.
  - entr's `-d` behaviour fits well here, since it already exits when files are added.
  - The pain point is pandoc taking about 1.6 s to start, multiplied by N files. That's where parallel builds and the static pandoc build matter.
- **The real payoff:** `site/` becomes just a folder-mode build plus a page-name mapping, instead of a special case.

**5. Page TOC sidebar: yes, cheap and high value.**
Put pandoc's TOC in a sticky side panel, highlight the current section as you scroll, and add a toggle. Show it only when a page has more than a few headings. REFERENCE.md is the obvious beneficiary.

**6. "Formulate once, fill in at every build": agreed.**
The rule should be: compute everything at build time, and only add behaviour in the browser. Good candidates:
- clickable anchor links on headings
- copy buttons on code blocks
- "last modified" from `git log`
- "edit on GitHub" links
- previous/next page links in folder mode
- build info, which we already have

Anchors and copy buttons give the most value for the least work.

**7. Features in core, not just `site/`: yes.**
Everything generic goes in `share/md-preview/` (template, filters, one JS file, CSS), so `serve`, `build` and folder mode all get it. `site/` keeps only site-specific parts: the nav bar and the page-name mapping.

**8. Replace the script with a Makefile: partly.**
Make is the right tool for multi-file builds: it knows what depends on what, rebuilds only what changed, and `-j` runs pandoc in parallel. It's the wrong tool for the interactive side: supervising processes, handling signals and cleanup, finding nvm, parsing options, and the error page.

My suggestion is a hybrid:
- Keep `md-preview` as the bash front end.
- Ship `share/md-preview/md-preview.mk` with the generic rules (`%.html` from `%.md`, the tree fragment, assets).
- The script runs it with `make -f … -j` for folder and site builds.
- `site/Makefile` just `include`s it.
- Single-file `serve` stays in bash.

**Suggested order**
- **0.0.3:** View Source with the round-trip check, `--toc` with the sidebar and toggle, heading anchors, code copy buttons, and one shared JS file in `share/`.
- **0.1.0:** folder mode, the tree, `md-preview.mk`, and link rewriting moved into the core. `site/` is rebuilt on top of folder mode.
- **Later, only if needed:** Svelte, for a searchable tree.
