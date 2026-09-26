# zcomp.zsh LINE — print what an interactive zsh offers when Tab is pressed
# after LINE, using the completion functions in $FPATH_ADD. Run from the
# directory whose files should be completed. Terminal escapes are stripped.
zmodload zsh/zpty
zpty z zsh -f -i
zpty -w z "fpath=($FPATH_ADD \$fpath); autoload -Uz compinit; compinit -u -D"
zpty -w z "zstyle ':completion:*' format '<%d>'; zstyle ':completion:*' list-rows-first yes; setopt no_beep; PS1='PROMPT> '; unsetopt zle_bracketed_paste"
zpty -w z "print READY"
local out; zpty -r z out '*READY*'; zpty -r z out '*PROMPT> ' 2>/dev/null
zpty -w -n z "$1"$'\t'
sleep 1
local buf=''
while zpty -r -t z out; do buf+=$out; done
print -r -- ${${buf//$'\e'\[[0-9;?]#[a-zA-Z]/}//$'\r'/}
zpty -d z
