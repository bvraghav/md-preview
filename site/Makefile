# site/ — build the project website with md-preview itself.
#
#   make              build the site into _site/
#   make serve        preview _site/ at http://localhost:8000
#   make check        verify demo-source.html reproduces test-sample.md exactly
#   make clean        remove _site/ and _build/
#
# Pages:
#   README.md       -> index.html        test-sample.md -> demo.html
#   CHANGELOG.md    -> changelog.html    LICENSE        -> license.html
#   MANIFEST.md     -> manifest.html     REFERENCE.md   -> reference.html
#   TODO.md         -> todo.html         INSTALL.md     -> install.html
#   CONTRIBUTING.md -> contributing.html
#   test-sample.md  -> demo-source.html  (View source: verbatim, round-trip checked)
#
# KaTeX and mermaid are fetched once (md-preview fetch) and self-hosted
# under _site/_md-preview/, laid out by `md-preview assets`.

ROOT     := ..
OUT      := _site
BUILD    := _build
MDP      := $(ROOT)/bin/md-preview
ASSETS   := _md-preview

VERSION  := $(shell cat $(ROOT)/VERSION)
REPO_URL ?= https://github.com/bvraghav/md-preview
# The commit the site is built from. Only if $(ROOT) is itself the top of a
# git checkout: a release tarball unpacked inside another repository (as AUR
# builds are) must not pick up that repository's commit. Otherwise the tag.
REF      ?= $(shell cd $(ROOT) && [ "$$(git rev-parse --show-toplevel 2>/dev/null)" = "$$(pwd -P)" ] \
                && git rev-parse HEAD || echo v$(VERSION))
SHORT    := $(shell printf %.7s $(REF))

# Everything a page depends on besides its own source.
DEPS := $(MDP) $(wildcard $(ROOT)/share/md-preview/*) $(ROOT)/VERSION \
        links.lua $(BUILD)/nav.html $(BUILD)/source-link.html site.css Makefile

PANDOC_ARGS := --lua-filter links.lua \
               --css $(ASSETS)/site.css \
               --include-before-body $(BUILD)/nav.html \
               -M md-preview-site-repo=$(REPO_URL) -M md-preview-site-ref=$(REF)

.DEFAULT_GOAL := all

PAGE_FILES :=

# $(call page,NAME,SOURCE,PAGETITLE,EXTRA-ARGS,INPUT)
#   SOURCE      repository-relative source, linked from the footer
#   PAGETITLE   empty: use the document's title
#   EXTRA-ARGS  more pandoc arguments for this page
#   INPUT       file to render when it isn't SOURCE itself (a generated one)
define page
$(OUT)/$(1).html: $(or $(5),$(ROOT)/$(2)) $(DEPS) | $(OUT) fetch
	@printf '%s\n' \
	  '<footer class="site-footer">' \
	  'Rendered by md-preview $(VERSION) from' \
	  '<a href="$(REPO_URL)/blob/$(REF)/$(2)"><code>$(2)</code></a>' \
	  'at <a href="$(REPO_URL)/commit/$(REF)"><code>$(SHORT)</code></a>.' \
	  '</footer>' > $(BUILD)/$(1).footer.html
	$(MDP) build --assets $(ASSETS) -o $$@ $$< -- $(PANDOC_ARGS) \
	  --include-after-body $(BUILD)/$(1).footer.html $(4) \
	  $(if $(3),-M 'pagetitle=$(3)')
PAGE_FILES += $(OUT)/$(1).html
endef

# README has its own hand-written Contents, so no automatic TOC.
$(eval $(call page,index,README.md,md-preview,-M md-preview-toc=false))
$(eval $(call page,demo,test-sample.md,,--include-before-body $(BUILD)/source-link.html))
$(eval $(call page,demo-source,test-sample.md,md-preview · Source of test-sample.md,--preserve-tabs,$(BUILD)/demo-source.md))
$(eval $(call page,changelog,CHANGELOG.md,md-preview · Changelog))
$(eval $(call page,license,LICENSE,md-preview · License))
$(eval $(call page,manifest,MANIFEST.md,md-preview · Manifest))
$(eval $(call page,reference,REFERENCE.md,md-preview · Reference))
$(eval $(call page,todo,TODO.md,md-preview · TODO))
$(eval $(call page,install,INSTALL.md,md-preview · Install))
$(eval $(call page,contributing,CONTRIBUTING.md,md-preview · Contributing))

.PHONY: all fetch assets check serve clean

all: $(PAGE_FILES) assets
	@echo "site built in $(OUT)/ ($(words $(PAGE_FILES)) pages, $(SHORT))"

# Idempotent: skips what is already downloaded.
fetch:
	@$(MDP) fetch

assets: | $(OUT) fetch
	$(MDP) assets $(OUT)/$(ASSETS)
	cp site.css $(OUT)/$(ASSETS)/site.css
	rm -rf $(OUT)/test-assets
	cp -r $(ROOT)/test-assets $(OUT)/test-assets

# View source: test-sample.md verbatim inside a fence nothing in it can close.
# The back link is written as test-sample.md; links.lua maps it to demo.html.
$(BUILD)/demo-source.md: $(ROOT)/test-sample.md source-page.sh | $(BUILD)
	sh source-page.sh $< '[← Back to the rendered demo](test-sample.md)' > $@

$(BUILD)/source-link.html: Makefile | $(BUILD)
	printf '%s\n' '<p class="site-source-link"><a href="demo-source.html">View source</a></p>' > $@

check: $(OUT)/demo-source.html
	python3 roundtrip.py $< $(ROOT)/test-sample.md

$(BUILD)/nav.html: nav.html.in Makefile | $(BUILD)
	sed 's|@REPO_URL@|$(REPO_URL)|g' $< > $@

$(OUT) $(BUILD):
	mkdir -p $@

serve: all
	python3 -m http.server --directory $(OUT) 8000

clean:
	rm -rf $(OUT) $(BUILD)
