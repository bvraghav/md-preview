# bash completion for md-preview                          -*- shell-script -*-
#
# Installed to share/bash-completion/completions/md-preview. Self-contained:
# doesn't need the bash-completion package's helpers.

_md_preview() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
  local commands='serve build fetch assets docs doctor help version'
  local cmd='' i
  COMPREPLY=()

  for (( i = 1; i < COMP_CWORD; i++ )); do
    case ${COMP_WORDS[i]} in
      --)
        # Everything after -- goes to pandoc: complete file names.
        mapfile -t COMPREPLY < <(compgen -f -- "$cur")
        return 0 ;;
      serve|build|fetch|assets|docs|doctor|help|version)
        [[ -z $cmd ]] && cmd=${COMP_WORDS[i]} ;;
    esac
  done

  case $prev in
    -p|--port|--listen|--base-url) return 0 ;;
    -b|--browser)
      mapfile -t COMPREPLY < <(compgen -W 'firefox chromium google-chrome' -- "$cur")
      return 0 ;;
    -o|--output)
      mapfile -t COMPREPLY < <(compgen -f -- "$cur")
      return 0 ;;
    --assets)
      mapfile -t COMPREPLY < <(compgen -d -- "$cur")
      return 0 ;;
  esac

  local opts
  case $cmd in
    ''|serve) opts='-p --port -b --browser --no-open --listen --' ;;
    build)    opts='-o --output --embed --assets --force --base-url --' ;;
    fetch)    opts='--force' ;;
    docs)     opts='-p --port -b --browser --no-open' ;;
    assets)
      mapfile -t COMPREPLY < <(compgen -d -- "$cur")
      return 0 ;;
    *) return 0 ;;
  esac

  if [[ $cur == -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "$opts" -- "$cur")
    return 0
  fi
  [[ $cmd == fetch || $cmd == docs ]] && return 0

  # A command (only first), Markdown files, and directories to walk into.
  [[ -z $cmd ]] && mapfile -t COMPREPLY < <(compgen -W "$commands" -- "$cur")
  local f
  while IFS= read -r f; do COMPREPLY+=("$f"); done < <(
    compgen -f -X '!*.md' -- "$cur"
    compgen -f -X '!*.markdown' -- "$cur"
    compgen -d -- "$cur")
}

complete -o filenames -F _md_preview md-preview
