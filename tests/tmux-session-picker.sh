#!/usr/bin/env bash
# Test recency, pi grouping, selection, and cancellation.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
picker="$root/home/.local/bin/tmux-session-picker"
real_fzf=$(command -v fzf)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export PICKER_TEST_DIR="$tmp"
mkdir "$tmp/bin"

cat > "$tmp/bin/tmux" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ $1 == -S && $2 == 'socket with spaces' ]]
case "$3" in
  list-sessions) cat "$PICKER_TEST_DIR/input" ;;
  switch-client) printf '%s\n' "$@" > "$PICKER_TEST_DIR/switch" ;;
  *) exit 2 ;;
esac
SH

cat > "$tmp/bin/fzf" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$PICKER_TEST_DIR/fzf-args"
cat > "$PICKER_TEST_DIR/fzf-input"
if [[ ${PICKER_TEST_FZF_STATUS:-0} != 0 ]]; then
  exit "$PICKER_TEST_FZF_STATUS"
fi
sed -n '3p' "$PICKER_TEST_DIR/fzf-input"
SH
chmod +x "$tmp/bin/tmux" "$tmp/bin/fzf"
export PATH="$tmp/bin:$PATH"

cat > "$tmp/input" <<'TSV'
$1	100	50	zeta
$2	300	50	alpha work
$3	999	50	pi abc123
$4	600	50	pi ABCDEF
$5		250	fresh
$6	200	50	pi project
$7	300	50	beta#branch
$8	300	50	odd $HOME "quote" ; false
$9	0	275	zero
TSV

cat > "$tmp/expected" <<'TSV'
$2	alpha work
$7	beta#branch
$8	odd $HOME "quote" ; false
$9	zero
$5	fresh
$6	pi project
$1	zeta
$3	pi abc123
$4	pi ABCDEF
TSV

"$picker" --list 'socket with spaces' > "$tmp/actual"
diff -u "$tmp/expected" "$tmp/actual"
"$picker" 'socket with spaces' 'client with spaces'
diff -u "$tmp/expected" "$tmp/fzf-input"
printf '%s\n' -S 'socket with spaces' switch-client -c 'client with spaces' -t "\$8" > "$tmp/switch-expected"
diff -u "$tmp/switch-expected" "$tmp/switch"
grep -qx -- --no-sort "$tmp/fzf-args"
grep -qx -- --no-multi "$tmp/fzf-args"

"$real_fzf" --no-sort --delimiter=$'\t' --with-nth=2.. \
  --filter='pi ' < "$tmp/actual" > "$tmp/filtered"
printf '%s\n' $'$6\tpi project' $'$3\tpi abc123' $'$4\tpi ABCDEF' > "$tmp/filter-expected"
diff -u "$tmp/filter-expected" "$tmp/filtered"

# The hidden id column must not match a query.
if "$real_fzf" --no-sort --delimiter=$'\t' --with-nth=2.. --filter="\$1" < "$tmp/actual" > "$tmp/id-hits"; then
  exit 1
fi
[[ ! -s "$tmp/id-hits" ]]

rm "$tmp/switch"
for status in 1 130; do
  PICKER_TEST_FZF_STATUS=$status "$picker" 'socket with spaces' 'client with spaces'
  [[ ! -e "$tmp/switch" ]]
done

if PICKER_TEST_FZF_STATUS=2 "$picker" 'socket with spaces' 'client with spaces'; then
  exit 1
else
  [[ $? == 2 ]]
fi
[[ ! -e "$tmp/switch" ]]

awk -F '\t' 'BEGIN { OFS = FS } $1 == "$1" { $2 = 400 } { print }' "$tmp/input" > "$tmp/new-input"
mv "$tmp/new-input" "$tmp/input"
"$picker" --list 'socket with spaces' > "$tmp/reordered"
[[ $(sed -n '1p' "$tmp/reordered") == $'$1\tzeta' ]]

printf '%s\n' 'The session picker tests pass.'
