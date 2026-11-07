#!/usr/bin/env bash
# Self-check for counts.sh on a synthetic Firstmate home. Exits non-zero on a wrong count.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT

git -C "$home" init -q -b main
git -C "$home" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m "upstream"
git -C "$home" branch upstream
for m in "fix: one" "fix(bin): two" "test: three"; do
  git -C "$home" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m "$m"
done

d="$home/data"
mkdir -p "$d/archive"
for id in task-a task-a-review-1 task-a-review-2 task-b task-b-r2 fm-x-review-1; do
  mkdir -p "$d/$id"; touch "$d/$id/brief.md"
done
mkdir -p "$d/archive/old-task" "$d/no-brief"
touch "$d/archive/old-task/brief.md"
printf -- '- [x] task-a - a (kind: ship)\n- [ ] task-b - b (kind: scout)\n- [ ] task-b - dup (kind: scout)\n' > "$d/backlog.md"
printf -- '- p1 [local-only] - a\n- p2 [no-mistakes +yolo] - b\n- p3 [local-only] - c\n' > "$d/projects.md"

out=$("$here/counts.sh" "$home" upstream)
fail=0
for want in "commits: 3" "type fix: 2" "type test: 1" "task directories: 8" "with a worker brief: 7" \
  "successor workers (-rN): 1" "changes reviewed: 2" "reviewer workers: 3" \
  "1 change(s) took 2 round(s)" "fm-x: 1" "kind ship: 1" "kind scout: 1" "mode local-only: 2" "mode no-mistakes: 1" "auto-merge (+yolo): 1"; do
  grep -qF -- "$want" <<<"$out" || { echo "missing: $want"; fail=1; }
done
[ "$fail" = 0 ] && echo "counts-check: ok"
exit "$fail"
