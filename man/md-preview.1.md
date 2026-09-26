---
title: MD-PREVIEW
section: 1
header: User Commands
footer: md-preview
---

# NAME

md-preview - live browser preview of Markdown with frontmatter, mermaid and KaTeX

# SYNOPSIS

**md-preview** [**serve**] [*options*] *FILE.md*|*DIR* [**\-\-** *pandoc-args*...]\
**md-preview build** [*options*] *FILE.md*|*DIR* [**\-\-** *pandoc-args*...]\
**md-preview fetch** [**\-\-force**]\
**md-preview assets** *DIR*\
**md-preview docs** [*options*]\
**md-preview doctor**\
**md-preview help** | **version**

# DESCRIPTION

**md-preview** renders a Markdown file with **pandoc**(1) and shows it in a
browser. **serve** watches the file with **entr**(1) and re-renders and
reloads the page on every save, through a local **browser-sync** server.

Pages support YAML frontmatter (shown as a title block and a table of all
keys), KaTeX math (**\$\...\$**, **\$\$\...\$\$**, **\\(\...\\)**,
**\\\[\...\\\]**, fenced **math** blocks, LaTeX environments), mermaid
diagrams (fenced **mermaid** blocks), GitHub-style alerts, an automatic
table of contents, heading anchors and copy buttons on code blocks.

Given a folder, **md-preview** works on every Markdown file in it: each
becomes a page (a folder's *README.md* its *index.html*), links between them
are rewritten to the pages, and every page gets a file tree.

The complete reference, with examples, is served by **md-preview docs**.

# COMMANDS

**serve** *FILE.md*|*DIR*
:   Live preview; the default when the first argument is not a command.
    Runs until interrupted, then removes its temporary files. For a folder,
    a save re-renders just that page, and new or removed files update the
    file tree.

**build** *FILE.md*|*DIR*
:   Render once to HTML and exit. A folder is rendered to a folder of pages
    (default *DIR/_site*), incrementally and in parallel.

**fetch**
:   Download KaTeX and mermaid into *\$MD_PREVIEW_DATA/vendor* for offline
    use. With **\-\-force**, download again.

**assets** *DIR*
:   Copy the stylesheet, script, KaTeX and mermaid into *DIR*, laid out as
    pages built with **build \-\-assets** expect.

**docs**
:   Serve the md-preview documentation at http://localhost:6996.

**doctor**
:   Show where each dependency and asset was found. Exits 1 if something
    required is missing.

**help**, **version**
:   Print usage, or the version.

# OPTIONS

## serve

**-p**, **\-\-port** *N*
:   Port for browser-sync (default 3000, or the next free one).

**-b**, **\-\-browser** *NAME*
:   Browser to open (default: the system default).

**\-\-no-open**
:   Don't open a browser; open the printed URL yourself.

**\-\-listen** *ADDR*
:   Address to bind (default **localhost**; **0.0.0.0** exposes the preview
    on the network).

## build

**-o**, **\-\-output** *FILE*
:   Output file (default *FILE.html* next to *FILE.md*; **-** for stdout).

**\-\-embed**
:   Self-contained HTML, with the stylesheet, scripts, fonts and images
    inlined.

**\-\-assets** *PREFIX*
:   Link the stylesheet, KaTeX and mermaid relative to *PREFIX/*, for
    publishing; lay them out with **md-preview assets**. Single files only.

**\-\-force**
:   Folders: render every page, not only those whose source changed.

## docs

**-p**, **\-\-port** *N*
:   Port (default 6996).

**-b**, **\-\-browser** *NAME*, **\-\-no-open**
:   As for **serve**.

## pandoc arguments

Arguments after **\-\-** are passed to pandoc, for example
**\-\-toc-depth=2**, **\-\-number-sections** or **\-\-citeproc**.

# ENVIRONMENT

**MD_PREVIEW_FROM**
:   pandoc input format (default
    **markdown+tex_math_single_backslash+alerts+mark+emoji**).

**MD_PREVIEW_PANDOC_ARGS**
:   Extra pandoc arguments for every render, split on whitespace.

**MD_PREVIEW_FRONTMATTER**
:   Frontmatter table: **open**, **closed** or **hide**.

**MD_PREVIEW_TOC**
:   Table of contents: **true** or **false** (default: shown when a page has
    3 or more headings).

**MD_PREVIEW_LISTEN**
:   Default for **serve \-\-listen**.

**MD_PREVIEW_BROWSER_SYNC**
:   Path to browser-sync. Otherwise it is looked up on **PATH**, then under
    nvm.

**MD_PREVIEW_NVM_VERSION**
:   Node version for **nvm use** when looking under nvm (default
    **stable**).

**MD_PREVIEW_DATA**
:   Data directory (default *\$XDG_DATA_HOME/md-preview*).

**MD_PREVIEW_KATEX_VERSION**, **MD_PREVIEW_MERMAID_VERSION**
:   Versions for **fetch** and the CDN fallback.

**MD_PREVIEW_JOBS**
:   Pages a folder build renders at once (default: the number of CPUs).

**MD_PREVIEW_STATE**
:   Where a folder build keeps its state (default *OUT/.md-preview*).

**MD_PREVIEW_DOCS**, **MD_PREVIEW_DOCS_PORT**, **MD_PREVIEW_DOCS_SERVER**
:   Site directory, port, and server (**auto**, **browser-sync** or
    **python**) for **docs**.

# FILES

*\$MD_PREVIEW_DATA/vendor/*
:   KaTeX and mermaid downloaded by **fetch**; used first.

*/usr/share/md-preview/*
:   Template, Lua filter, stylesheet and script; *vendor/* holds KaTeX and
    mermaid when installed with md-preview.

*/usr/share/doc/md-preview/html/*
:   The documentation served by **docs**.

*\$XDG_RUNTIME_DIR/md-preview.XXXXXX/*
:   Per-preview directory, removed when **serve** exits.

# EXIT STATUS

**0** on success; **1** on a usage error, a missing dependency or an
unreadable file; pandoc's status when **build** fails; **130** or **143**
when **serve** is stopped by SIGINT or SIGTERM.

# EXAMPLES

    md-preview notes.md
    md-preview ~/notes                      # a whole folder
    md-preview build ~/notes -o ~/notes-html
    md-preview serve --port 4000 --browser firefox notes.md
    md-preview build --embed notes.md -o notes.html
    md-preview docs

# SEE ALSO

**pandoc**(1), **entr**(1), **md-preview docs**,
<https://bvraghav.github.io/md-preview/>
