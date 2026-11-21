#!/usr/bin/env bash
# ops-guard.sh: Claude Code PreToolUse hook on Bash (hooks/hooks.json). In a repository set up
# for operation it refuses a command the user has ruled out for agents: docs/ops/charter.md,
# read from HEAD, lists them under `## Never`, one list line each (`-`, `*` or `+`), as an
# extended regular expression in backticks followed by the reason. A pattern that holds a
# backtick is written between double backticks. A command that matches one is refused. The
# section ends at the next heading of its level or above, and a list line inside a comment or a
# code fence counts like any other.
# `ops-guard.sh --list [file]` prints the patterns it enforces, from that file or from HEAD, so
# a setup or a doctor can see them. It names each pattern grep cannot compile on stderr and
# exits 1, as it does for a file it cannot read: such a pattern refuses nothing.
#   - Every repository the call may act in answers: the one its cwd is in, the one the session
#     was started in (CLAUDE_PROJECT_DIR), and the one holding any path the command names, so
#     `cd product && …` and `product/bin/…` from a home repo meet the product's charter. A path
#     need not exist yet, may be quoted or escaped around a space, and one `cd` after another
#     is followed.
#   - The charter is read from HEAD, so an uncommitted edit changes nothing, and a worktree
#     answers to the branch it has checked out.
#   - A `git commit` is refused while the charter in the index or the work tree lacks a pattern
#     that HEAD has: only the user commits a change that takes a line out of `## Never`.
#   - The whole command text is matched, so a message that quotes a refused command is refused
#     too, and the refusal says so. grep reads the command from a here-string: in a pipe, a
#     writer cut short would decide the status.
# It runs only where Claude Code runs its hooks: a child on another provider is not covered.
# It guards against mistakes, not an adversary with a shell: a command that reaches a repository
# through a variable, a symbolic link to a file or a bare clone, or moves HEAD to a commit with
# another charter, is not seen.
# Exit 0 allows, exit 2 blocks with the reason on stderr. Bash 3.2 compatible.
# Only the user switches it off, by starting Claude Code with BSTACK_NO_ENFORCE=1.
set -uo pipefail
CHARTER=docs/ops/charter.md

block() { printf 'bstack ops guard: %s\n' "$1" >&2; exit 2; }

field() { # field <key>...: a string at that path in the hook input, else empty
  if command -v jq >/dev/null 2>&1; then
    local p; p=$(printf '.%s' "$@"); printf '%s' "$input" | jq -r "$p // empty | strings"
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c 'import json,sys
d=json.load(sys.stdin)
for k in sys.argv[1:]: d=d.get(k) if isinstance(d,dict) else None
print(d if isinstance(d,str) else "")' "$@"
  elif command -v node >/dev/null 2>&1; then
    printf '%s' "$input" | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>{
let d=JSON.parse(s);for(const k of process.argv.slice(1))d=d&&typeof d==="object"?d[k]:undefined;
process.stdout.write(typeof d==="string"?d:"")})' "$@"
  else return 9; fi
}
patterns() { # stdin: a charter. stdout: the patterns of its ## Never section, one a line
  awk '
    /^##[[:space:]]+Never[[:space:]#]*$/ { f = 1; next }
    /^##?[[:space:]]/ { f = 0 }
    f && /^[[:space:]]*[-*+][[:space:]]*`/ {
      s = $0; sub(/^[[:space:]]*[-*+][[:space:]]*/, "", s)
      d = (substr(s, 1, 2) == "``") ? "``" : "`"
      s = substr(s, length(d) + 1); i = index(s, d)
      if (i > 1) {
        q = substr(s, 1, i - 1)
        if (d == "``") { sub(/^ /, "", q); sub(/ $/, "", q) }
        if (q != "") print q
      }
    }'
}
never() { git -C "$1" show "HEAD:$CHARTER" 2>/dev/null | patterns; }   # never <repository root>

if [ "${1:-}" = --list ]; then
  if [ -n "${2:-}" ]; then
    [ -f "$2" ] && [ -r "$2" ] || { printf 'bstack ops guard: cannot read %s\n' "$2" >&2; exit 1; }
    pats=$(patterns < "$2")
  else pats=$(never "$PWD"); fi
  st=0
  while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    rc=0; grep -Eq -e "$pat" <<<'' 2>/dev/null || rc=$?
    if [ "$rc" -gt 1 ]; then
      printf 'bstack ops guard: grep -E cannot compile %s, so it refuses nothing\n' "\`$pat\`" >&2; st=1
    else printf '%s\n' "$pat"; fi
  done <<EOF
$pats
EOF
  exit "$st"
fi

input=$(cat)
if ! cmd=$(field tool_input command); then
  # The input cannot be read: no jq, python3 or node, or it is not JSON. Refuse only where
  # there is something to guard, taking the cwd from the raw text.
  [ "${BSTACK_NO_ENFORCE:-}" = 1 ] && exit 0
  raw=$(sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<EOF
$input
EOF
)
  raw=${raw%%$'\n'*}
  for d in "$raw" "$PWD" "${CLAUDE_PROJECT_DIR:-}"; do
    [ -n "$d" ] || continue
    [ -z "$(never "$d")" ] || block "cannot read the hook input: it needs jq, python3 or node"
  done
  exit 0
fi
cwd=$(field cwd); [ -n "$cwd" ] || cwd=$PWD

# The repositories this call may act in, one root a line. A root is the nearest directory at or
# above a path that holds `.git`, found without starting git: a command may name thousands of
# paths, and the hook has 30 seconds.
roots=''; seen=''; ldir=''; lroot=''
up() { # up <dir>: set t to the nearest of it and its parents that holds .git, else to ''
  t=$1
  while :; do
    [ -e "$t/.git" ] && return 0
    case $t in */*) t=${t%/*} ;; *) t=''; return 0 ;; esac
  done
}
add() { # add <absolute path>: note the repository that holds it, or would once it exists
  local p=$1 d t
  if [ -e "$p/.git" ]; then t=$p
  else
    d=${p%/*}
    if [ "$d" != "$ldir" ]; then up "$d"; ldir=$d; lroot=$t; fi
    t=$lroot
  fi
  [ -n "$t" ] || return 0
  case "
$seen
" in *"
$t
"*) return 0 ;; esac
  seen="$seen
$t"
  t=$(cd "$t" 2>/dev/null && pwd -P) || return 0
  case "
$roots
" in *"
$t
"*) ;; *) roots="$roots
$t" ;; esac
}
path() { # path <word of the command>: add the path it names, read from the cwd
  local w=$1
  case $w in *$'\001'*) w=${w//$'\001'/ } ;; esac
  case $w in ''|-*|*[\$\`*?]*) return 0 ;; esac
  case $w in /*) add "$w" ;; "~"/*) add "${HOME:-}${w#\~}" ;; *) add "$cwd/$w" ;; esac
}
add "$cwd/."
[ -z "${CLAUDE_PROJECT_DIR:-}" ] || add "$CLAUDE_PROJECT_DIR/."
# Every word of the command, however long it is. Quotes, separators and `=` become line breaks,
# so `-chdir=infra`, `"cd" 'product'` and `(cd product; …)` each yield their path, and a space
# after a backslash stays in its word. Each distinct word is looked at once.
# shellcheck disable=SC2001  # sed stays linear on a very long command; ${cmd//…} in bash 3.2 does not
words=$(sed $'s/\\\\ /\001/g' <<<"$cmd" | tr ' \t;&|()<>"'"'"'=' '[\n*]')
while IFS= read -r w; do path "$w"; done <<EOF
$(sort -u <<<"$words")
EOF
# A quoted string with a space in it, whole, and each `cd` taken from where the one before led.
more=$(
  grep -oE "\"[^\"]* [^\"]*\"|'[^']* [^']*'" <<<"$cmd" | sed 's/^.//; s/.$//'
  awk '$0 == "" { next }
    p { p = 0; v = ($0 ~ /^[\/~]/ || v == "") ? $0 : v "/" $0; print v }
    $0 == "cd" || $0 == "pushd" { p = 1 }' <<<"$words"
)
while IFS= read -r w; do path "$w"; done <<EOF
$more
EOF

# Is there anything to guard?
any=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  [ -z "$(never "$r")" ] || { any=1; break; }
done <<EOF
$roots
EOF
[ "$any" = 1 ] || exit 0
case $cmd in *BSTACK_NO_ENFORCE=*) block "BSTACK_NO_ENFORCE is the user's switch; never set it in a command" ;; esac
[ "${BSTACK_NO_ENFORCE:-}" = 1 ] && exit 0

# `git … commit` as words of one command: `git log --committer=…` and `HEAD^{commit}` are not it.
commit=0
grep -Eq '(^|[^[:alnum:]_.-])git[[:space:]]([^;&|]*[[:space:]])?commit([[:space:];&|)]|$)' <<<"$cmd" && commit=1
while IFS= read -r r; do
  [ -n "$r" ] || continue
  pats=$(never "$r"); [ -n "$pats" ] || continue
  if [ "$commit" = 1 ]; then
    staged=$(git -C "$r" show ":$CHARTER" 2>/dev/null | patterns)
    tree=$(patterns < "$r/$CHARTER" 2>/dev/null)
  fi
  while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    if [ "$commit" = 1 ]; then
      if ! grep -Fxq -e "$pat" <<<"$staged" || ! grep -Fxq -e "$pat" <<<"$tree"; then
        block "refused: the charter to be committed lacks \`$pat\`, which is under ## Never in $r/$CHARTER at HEAD. Only the user commits a change that takes a line out of ## Never."
      fi
    fi
    if grep -Eq -e "$pat" <<<"$cmd" 2>/dev/null; then
      block "refused: \`$pat\` is under ## Never in $r/$CHARTER. No agent runs this here; the user does. Do not rephrase or wrap it to get past this. A command that only mentions it, such as a log line or a commit message, is refused too: say it in other words."
    fi
  done <<EOF
$pats
EOF
done <<EOF
$roots
EOF
exit 0
