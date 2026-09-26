# site/ — build the project website with md-preview itself.
#
#   make              build the site into _site/
#   make serve        preview _site/ at http://localhost:8000
#   make clean        remove _site/ and _build/
#
# Pages:
#   README.md       -> index.html        test-sample.md -> demo.html
#   CHANGELOG.md    -> changelog.html    LICENSE        -> license.html
#   MANIFEST.md     -> manifest.html     REFERENCE.md   -> reference.html
#
# KaTeX and mermaid are fetched once (md-preview fetch) and self-hosted
# under _site/_md-preview/, laid out by `md-preview assets`.

ROOT     := ..
OUT      := _site
BUILD    := _build
MDP      := $(ROOT)/bin/md-preview
ASSETS   := _md-preview

REPO_URL ?= https://github.com/bvraghav/md-preview
REF      ?= $(shell git -C $(ROOT) rev-parse HEAD 2>/dev/null || echo main)
SHORT    := $(shell printf %.7s $(REF))
VERSION  := $(shell cat $(ROOT)/VERSION)

# Everything a page depends on besides its own source.
DEPS := $(MDP) $(wildcard $(ROOT)/share/md-preview/*) $(ROOT)/VERSION \
        links.lua $(BUILD)/nav.html Makefile

PANDOC_ARGS := --lua-filter links.lua \
               --css $(ASSETS)/site.css \
               --include-before-body $(BUILD)/nav.html \
               -M md-preview-site-repo=$(REPO_URL) -M md-preview-site-ref=$(REF)

.DEFAULT_GOAL := all

PAGE_FILES :=

# $(call page,NAME,SOURCE,PAGETITLE) — PAGETITLE empty: use the document's title.
define page
$(OUT)/$(1).html: $(ROOT)/$(2) $(DEPS) | $(OUT) fetch
	@printf '%s\n' \
	  '<footer class="site-footer">' \
	  'Rendered by md-preview $(VERSION) from' \
	  '<a href="$(REPO_URL)/blob/$(REF)/$(2)"><code>$(2)</code></a>' \
	  'at <a href="$(REPO_URL)/commit/$(REF)"><code>$(SHORT)</code></a>.' \
	  '</footer>' > $(BUILD)/$(1).footer.html
	$(MDP) build --assets $(ASSETS) -o $$@ $$< -- $(PANDOC_ARGS) \
	  --include-after-body $(BUILD)/$(1).footer.html \
	  $(if $(3),-M 'pagetitle=$(3)')
PAGE_FILES += $(OUT)/$(1).html
endef

$(eval $(call page,index,README.md,md-preview))
$(eval $(call page,demo,test-sample.md,))
$(eval $(call page,changelog,CHANGELOG.md,md-preview · Changelog))
$(eval $(call page,license,LICENSE,md-preview · License))
$(eval $(call page,manifest,MANIFEST.md,md-preview · Manifest))
$(eval $(call page,reference,REFERENCE.md,md-preview · Reference))

.PHONY: all fetch assets serve clean

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

$(BUILD)/nav.html: nav.html.in Makefile | $(BUILD)
	sed 's|@REPO_URL@|$(REPO_URL)|g' $< > $@

$(OUT) $(BUILD):
	mkdir -p $@

serve: all
	python3 -m http.server --directory $(OUT) 8000

clean:
	rm -rf $(OUT) $(BUILD)
