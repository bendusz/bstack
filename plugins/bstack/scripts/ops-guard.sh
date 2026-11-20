#!/usr/bin/env bash
# ops-guard.sh: Claude Code PreToolUse hook on Bash (hooks/hooks.json). In a repository set up
# for operation it refuses a command the user has ruled out for every agent: docs/ops/charter.md,
# read from HEAD, lists them under `## Never`, one list line each, as an extended regular
# expression in backticks followed by the reason. A command that matches one is refused.
#   - Every repository the call may act in answers: the one its cwd is in, the one the session
#     was started in (CLAUDE_PROJECT_DIR), and the one holding any path the command names, so
#     `cd product && …` and `product/bin/…` from a home repo meet the product's charter.
#   - The charter is read from HEAD, so an uncommitted edit changes nothing, and a worktree
#     answers to the branch it has checked out.
#   - A `git commit` is refused while the charter in the index or the work tree lacks a pattern
#     that HEAD has: only the user commits a change that takes a line out of `## Never`.
#   - The whole command text is matched, so a message that quotes a refused command is refused
#     too, and the refusal says so. A pattern grep cannot compile matches nothing.
# It guards against mistakes, not an adversary with a shell: a command that reaches a repository
# through a variable, or moves HEAD to a commit with another charter, is not seen.
# Exit 0 allows, exit 2 blocks with the reason on stderr. Bash 3.2 compatible.
# Only the user switches it off, by starting Claude Code with BSTACK_NO_ENFORCE=1.
set -uo pipefail
CHARTER=docs/ops/charter.md

block() { printf 'bstack ops guard: %s\n' "$1" >&2; exit 2; }
input=$(cat)

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
    /^## Never[[:space:]]*$/ { f = 1; next }
    /^## / { f = 0 }
    f && /^[[:space:]]*[-*][[:space:]]*`/ {
      s = $0; sub(/^[^`]*`/, "", s); i = index(s, "`")
      if (i > 1) print substr(s, 1, i - 1)
    }'
}
never() { git -C "$1" show "HEAD:$CHARTER" 2>/dev/null | patterns; }   # never <repository root>

if ! cmd=$(field tool_input command); then
  # No JSON reader. Refuse only where there is something to guard.
  [ -n "$(never "$PWD")" ] || exit 0
  block "cannot read the hook input: install jq, python3 or node"
fi
cwd=$(field cwd); [ -n "$cwd" ] || cwd=$PWD

# The repositories this call may act in, one root a line.
roots=''; dirs=''
add() { # add <path>: note the repository that holds it, if it exists and is in one
  local d=$1 t
  [ -e "$d" ] || return 0
  [ -d "$d" ] || d=$(dirname "$d")
  case "
$dirs
" in *"
$d
"*) return 0 ;; esac
  dirs="$dirs
$d"
  t=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) || return 0
  [ -n "$t" ] || return 0
  case "
$roots
" in *"
$t
"*) ;; *) roots="$roots
$t" ;; esac
}
add "$cwd"
[ -z "${CLAUDE_PROJECT_DIR:-}" ] || add "$CLAUDE_PROJECT_DIR"
# Every word of the command that names an existing path. Quotes, separators and `=` become
# spaces, so `-chdir=infra`, `"cd" 'product'` and `(cd product; …)` each yield their path.
set -f
n=0
for w in $(printf '%s' "$cmd" | tr '\n\t;&|()<>"'"'"'=' '             '); do
  n=$((n + 1)); [ "$n" -le 80 ] || break
  case $w in -*|*[\$\`*?]*) continue ;; esac
  case $w in /*) add "$w" ;; "~"/*) add "$HOME${w#\~}" ;; *) add "$cwd/$w" ;; esac
done
set +f

# Is there anything to guard?
any=0
while IFS= read -r r; do
  [ -n "$r" ] || continue
  [ -z "$(never "$r")" ] || { any=1; break; }
done <<EOF
$roots
EOF
[ "$any" = 1 ] || exit 0
case $cmd in *BSTACK_NO_ENFORCE*) block "BSTACK_NO_ENFORCE is the user's switch; never set it in a command" ;; esac
[ "${BSTACK_NO_ENFORCE:-}" = 1 ] && exit 0

while IFS= read -r r; do
  [ -n "$r" ] || continue
  pats=$(never "$r"); [ -n "$pats" ] || continue
  commit=0; case $cmd in *git*commit*) commit=1 ;; esac
  if [ "$commit" = 1 ]; then
    staged=$(git -C "$r" show ":$CHARTER" 2>/dev/null | patterns)
    tree=$(patterns < "$r/$CHARTER" 2>/dev/null)
  fi
  while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    if [ "$commit" = 1 ]; then
      if ! printf '%s\n' "$staged" | grep -Fxq -e "$pat" || ! printf '%s\n' "$tree" | grep -Fxq -e "$pat"; then
        block "refused: the charter to be committed lacks \`$pat\`, which is under ## Never in $r/$CHARTER at HEAD. Only the user commits a change that takes a line out of ## Never."
      fi
    fi
    if printf '%s\n' "$cmd" | grep -Eq -e "$pat" 2>/dev/null; then
      block "refused: \`$pat\` is under ## Never in $r/$CHARTER. No agent runs this here; the user does. Do not rephrase or wrap it to get past this. A command that only mentions it, such as a log line or a commit message, is refused too: say it in other words."
    fi
  done <<EOF
$pats
EOF
done <<EOF
$roots
EOF
exit 0
