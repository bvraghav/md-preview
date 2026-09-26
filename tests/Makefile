# tests/ — regression tests for md-preview.
#
#   make              run every suite
#   make build        rendering, output modes, options, CLI, install,
#                     View Source round trip                  (pandoc)
#   make site         the project website, links, HTTP        (pandoc)
#   make serve        live preview end to end                 (entr, browser-sync)
#   make browser      the site in headless Chromium           (chromium or Chrome)
#   make emacs        the Emacs package                       (emacs)
#   make ci           build site browser serve: what GitHub Actions runs
#   make clean        remove _work/
#
# A suite whose tools are missing is skipped, not failed. Add -k to keep
# going after a failing suite. Scratch files go to _work/; KaTeX and mermaid
# are fetched once into $(MD_PREVIEW_DATA) (default _work/data). Point
# MD_PREVIEW_DATA at an existing data directory to reuse its downloads.

SUITES := build site serve browser emacs
MDP    := ../bin/md-preview

MD_PREVIEW_DATA ?= $(CURDIR)/_work/data
export MD_PREVIEW_DATA

.PHONY: all ci vendor clean $(SUITES)

all: $(SUITES)

ci: build site browser serve

# Idempotent; only downloads what is missing.
vendor:
	@$(MDP) fetch

build: vendor
	@bash test-build.sh

site: vendor
	@bash test-site.sh

# Probes the site that the site suite builds.
browser: site
	@bash test-browser.sh

serve: vendor
	@bash test-serve.sh

emacs:
	@bash test-emacs.sh

clean:
	rm -rf _work
