# tests/ — regression tests for md-preview.
#
#   make              run every suite
#   make build        rendering, output modes, options, CLI, install,
#                     View Source round trip                  (pandoc)
#   make site         the project website, links, HTTP        (pandoc)
#   make serve        live preview end to end                 (entr, browser-sync)
#   make browser      the site in headless Chromium           (chromium or Chrome)
#   make emacs        the Emacs package                       (emacs)
#   make folder       folder mode: build a folder of Markdown (pandoc)
#   make completions  bash and zsh completion, man page       (zsh, pandoc)
#   make aur          build the AUR package and run it        (makepkg; Arch only)
#   make release      version strings and CHANGELOG agree; with
#                     TAG=vX.Y.Z also the tag                 (nothing)
#   make ci           release build site browser serve: what GitHub Actions runs
#   make clean        remove _work/
#
# A suite whose tools are missing is skipped, not failed. Add -k to keep
# going after a failing suite. Scratch files go to _work/; KaTeX and mermaid
# are fetched once into $(MD_PREVIEW_DATA) (default _work/data). Point
# MD_PREVIEW_DATA at an existing data directory to reuse its downloads.

SUITES := release build folder completions site serve browser emacs aur
MDP    := ../bin/md-preview

MD_PREVIEW_DATA ?= $(CURDIR)/_work/data
export MD_PREVIEW_DATA

.PHONY: all ci vendor clean $(SUITES)

all: $(SUITES)

ci: release build folder completions site browser serve

# Idempotent; only downloads what is missing.
vendor:
	@$(MDP) fetch

release:
	@bash test-release.sh

build: vendor
	@bash test-build.sh

folder:
	@bash test-folder.sh

completions:
	@bash test-completions.sh

site: vendor
	@bash test-site.sh

# Probes the site that the site suite builds.
browser: site
	@bash test-browser.sh

serve: vendor
	@bash test-serve.sh

emacs:
	@bash test-emacs.sh

# Downloads KaTeX and mermaid into the package's build directory.
aur:
	@bash test-aur.sh

clean:
	rm -rf _work
