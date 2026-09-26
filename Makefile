# md-preview — install, link and self-check.
#
#   make install            copy into $(PREFIX)  (default ~/.local)
#   make link               symlink bin/md-preview into $(PREFIX)/bin (for hacking)
#   make uninstall          remove what install/link created
#   make check              render test-sample.md and sanity-check the HTML

PREFIX   ?= $(HOME)/.local
BINDIR   ?= $(PREFIX)/bin
SHAREDIR ?= $(PREFIX)/share/md-preview
LISPDIR  ?= $(PREFIX)/share/emacs/site-lisp

SHARE_FILES := share/md-preview/template.html \
               share/md-preview/filter.lua \
               share/md-preview/style.css

CHECK_OUT := test-sample.html

.PHONY: install link uninstall check clean

install:
	install -Dm755 bin/md-preview $(BINDIR)/md-preview
	install -Dm644 -t $(SHAREDIR) $(SHARE_FILES) VERSION
	install -Dm644 emacs/md-preview.el $(LISPDIR)/md-preview.el
	@echo "installed; run 'md-preview doctor' and 'md-preview fetch'"

link:
	mkdir -p $(BINDIR)
	ln -sf $(CURDIR)/bin/md-preview $(BINDIR)/md-preview
	@echo "linked $(BINDIR)/md-preview -> $(CURDIR)/bin/md-preview"

uninstall:
	rm -f $(BINDIR)/md-preview $(LISPDIR)/md-preview.el
	rm -rf $(SHAREDIR)

check:
	bin/md-preview build test-sample.md -o $(CHECK_OUT) 2> .check.log || { cat .check.log; exit 1; }
	@if grep -q '^\[WARNING\]' .check.log; then cat .check.log; echo "FAIL: pandoc warnings"; exit 1; fi
	@n=$$(grep -c '<pre class="mermaid"' $(CHECK_OUT)); \
	  test $$n -eq 10 || { echo "FAIL: expected 10 mermaid blocks, got $$n"; exit 1; }
	@n=$$(grep -o 'class="math display"' $(CHECK_OUT) | wc -l); \
	  test $$n -eq 13 || { echo "FAIL: expected 13 display math spans, got $$n"; exit 1; }
	@grep -q 'class="mdp-frontmatter"' $(CHECK_OUT) || { echo "FAIL: no frontmatter table"; exit 1; }
	@grep -q 'id="title-block-header"' $(CHECK_OUT) || { echo "FAIL: no title block"; exit 1; }
	@grep -q 'class="note"' $(CHECK_OUT) || { echo "FAIL: no GitHub alerts"; exit 1; }
	@rm -f .check.log
	@echo "check passed: $(CHECK_OUT)"

clean:
	rm -f $(CHECK_OUT) .check.log
