#!/usr/bin/env bash
# Self-check for counts.sh on a synthetic Firstmate home. Exits non-zero on a wrong count.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
fail=0

commit() { GIT_AUTHOR_DATE="$1T12:00:00" git -C "$home" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m "$2"; }
# Each expected line must appear whole (leading spaces ignored).
expect() { for want in "$@"; do awk '{sub(/^ +/, "")} 1' <<<"$out" | grep -qxF -- "$want" || { echo "missing: $want"; fail=1; }; done; }
reject() { for bad in "$@"; do ! grep -qF -- "$bad" <<<"$out" || { echo "unexpected: $bad"; fail=1; }; done; }

git -C "$home" init -q -b main
commit 2026-01-01 "upstream"
git -C "$home" branch upstream
commit 2026-02-01 "fix: one"
commit 2026-03-01 "fix(bin): two"
commit 2026-04-01 "test: three"

d="$home/data"
mkdir -p "$d/archive/task-a" "$d/archive/old-task" "$d/no-brief"
for id in task-a task-a-review task-a-review-2 task-b task-b-r2 task-b-r2x fm-x-review-1 pr-9-review; do
  mkdir -p "$d/$id"; touch "$d/$id/brief.md"
done
touch "$d/archive/old-task/brief.md" "$d/archive/task-a/brief.md"
printf -- '- [x] task-a - a (kind: ship)\n- [ ] task-a - again\n- [ ] task-b - b (kind: scout)\n- [ ] task-b - dup (kind: scout)\n- [ ] ask-1 - q (kind: captain)\n- [ ] task-c - no kind\n' > "$d/backlog.md"
printf -- '- [ ] task-d - d (kind: ship, mode=direct-PR)\n' > "$d/backlog-x.md"
printf -- '- [x] task-e - e (kind: scout) (done 2026-01-01)\n' > "$d/done-archive.md"
printf -- '- p1 [local-only] - a\n- p2 [no-mistakes +yolo] - b\n- p3 [local-only] - c\n' > "$d/projects.md"

out=$("$here/counts.sh" "$home" upstream)
expect "commits: 3" "first: 2026-02-01" "last: 2026-04-01" "type fix: 2" "type test: 1" \
  "task directories: 10" "with a worker brief: 9" "successor workers (-rN): 1" \
  "changes reviewed: 2" "reviewer workers: 3" "1 change(s) took 1 round(s)" "1 change(s) took 2 round(s)" "fm-x: 1" \
  "kind decision-hold: 1" "kind ship: 2" "kind scout: 2" "ids with no kind: 1" \
  "projects: 3" "mode local-only: 2" "mode no-mistakes: 1" "auto-merge (+yolo): 1"
reject "task-a" "task-b" "task-c" "task-d" "task-e" "ask-1" "pr-9" "kind captain"

# One local commit: first and last are the same plain date.
out=$("$here/counts.sh" "$home" HEAD~1)
expect "commits: 1" "first: 2026-04-01" "last: 2026-04-01"

# No backlog files: the script still reaches the end.
rm "$d"/backlog*.md "$d/done-archive.md"
out=$("$here/counts.sh" "$home" upstream)
expect "ids with no kind: 0" "projects: 3"

# A missing upstream ref fails before printing any count.
if out=$("$here/counts.sh" "$home" no-such-ref 2>/dev/null); then echo "bad ref did not fail"; fail=1; fi
reject "commits:"

[ "$fail" = 0 ] && echo "counts-check: ok"
exit "$fail"
