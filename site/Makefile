# site/ — build the project website with md-preview itself, in folder mode.
#
#   make              build the site into _site/
#   make serve        preview _site/ at http://localhost:8000
#   make check        verify demo-source.html reproduces test-sample.md exactly
#   make clean        remove _site/ and _build/
#
# The pages are listed in pages.yaml. Each source is staged in _build/src as
# <page>.md (a symlink; demo-source.md is generated from test-sample.md), and
# the folder is built with `md-preview build`. links.lua maps links between
# repository files to pages and adds titles, footers and the "View source"
# link. KaTeX and mermaid are fetched once and self-hosted under
# _site/_md-preview/. _site/folder-demo/ is tests/folder-sample built as it
# is, to show folder mode. Both builds write a sitemap.xml (--base-url):
# _site/sitemap.xml and _site/folder-demo/sitemap.xml.

ROOT     := ..
OUT      := _site
BUILD    := _build
STAGE    := $(BUILD)/src
MDP      := $(ROOT)/bin/md-preview
ASSETS   := _md-preview
ABSROOT  := $(abspath $(ROOT))

VERSION  := $(shell cat $(ROOT)/VERSION)
REPO_URL ?= https://github.com/bvraghav/md-preview
SITE_URL ?= https://bvraghav.github.io/md-preview/
# The commit the site is built from. Only if $(ROOT) is itself the top of a
# git checkout: a release tarball unpacked inside another repository (as AUR
# builds are) must not pick up that repository's commit. Otherwise the tag.
REF      ?= $(shell cd $(ROOT) && [ "$$(git rev-parse --show-toplevel 2>/dev/null)" = "$$(pwd -P)" ] \
                && git rev-parse HEAD || echo v$(VERSION))
SHORT    := $(shell printf %.7s $(REF))

PANDOC_ARGS := --lua-filter links.lua --metadata-file pages.yaml \
               --css $(ASSETS)/site.css \
               --include-before-body $(BUILD)/nav.html \
               --preserve-tabs \
               -M md-preview-tree=false \
               -M md-preview-site-repo=$(REPO_URL) \
               -M md-preview-site-ref=$(REF) \
               -M md-preview-site-version=$(VERSION)

.DEFAULT_GOAL := all
.PHONY: all stage fetch check serve clean

all: stage $(BUILD)/nav.html | fetch
	MD_PREVIEW_STATE=$(abspath $(BUILD))/state $(MDP) build $(STAGE) -o $(OUT) --base-url $(SITE_URL) -- $(PANDOC_ARGS)
	cp site.css $(OUT)/$(ASSETS)/site.css
	@# Folder mode, as md-preview renders a folder: tests/folder-sample.
	MD_PREVIEW_STATE=$(abspath $(BUILD))/folder-demo-state $(MDP) build $(ROOT)/tests/folder-sample -o $(OUT)/folder-demo \
	  --base-url $(SITE_URL)folder-demo/
	@echo "site built in $(OUT)/ ($(SHORT))"

# Rebuilt every time; cheap. Symlinks keep each source's own mtime, so the
# folder build still only renders pages whose source changed.
stage: $(BUILD)/demo-source.md
	rm -rf $(STAGE)
	mkdir -p $(STAGE)
	awk '/^ *- page:/ { page = $$3 } /^ *source:/ { print page, $$2 }' pages.yaml | \
	  while read -r page source; do \
	    if [ "$$page" = demo-source ]; then ln -s $(abspath $(BUILD))/demo-source.md $(STAGE)/$$page.md; \
	    else ln -s $(ABSROOT)/$$source $(STAGE)/$$page.md; fi; \
	  done
	ln -s $(ABSROOT)/test-assets $(STAGE)/test-assets

# View source: test-sample.md verbatim inside a fence nothing in it can close.
# The back link is written as test-sample.md; links.lua maps it to demo.html.
# Only replaced when its content changes, so its page isn't re-rendered.
$(BUILD)/demo-source.md: $(ROOT)/test-sample.md source-page.sh | $(BUILD)
	sh source-page.sh $< '[← Back to the rendered demo](test-sample.md)' > $@.tmp
	cmp -s $@.tmp $@ && rm $@.tmp || mv $@.tmp $@

# Idempotent: skips what is already downloaded.
fetch:
	@$(MDP) fetch

check:
	python3 roundtrip.py $(OUT)/demo-source.html $(ROOT)/test-sample.md

$(BUILD)/nav.html: nav.html.in Makefile | $(BUILD)
	sed 's|@REPO_URL@|$(REPO_URL)|g' $< > $@

$(BUILD):
	mkdir -p $@

serve: all
	python3 -m http.server --directory $(OUT) 8000

clean:
	rm -rf $(OUT) $(BUILD)
