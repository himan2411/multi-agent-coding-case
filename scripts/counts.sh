#!/usr/bin/env bash
# Recount the numbers in NUMBERS.md from a Firstmate home. Read-only.
# Usage: scripts/counts.sh <firstmate-home> [upstream-ref]
# Prints aggregates only, so client task names never leave the home.
set -euo pipefail

home=${1:?usage: counts.sh <firstmate-home> [upstream-ref]}
upstream=${2:-origin/main}
data="$home/data"
[ -d "$data" ] || { echo "no data/ under $home" >&2; exit 1; }
git -C "$home" rev-parse -q --verify "$upstream^{commit}" >/dev/null ||
  { echo "no $upstream in $home; pass an upstream ref" >&2; exit 1; }

echo "== Local commits on top of $upstream"
git -C "$home" log --format='%s' "$upstream..HEAD" | wc -l | awk '{print "commits:", $1}'
dates=$(git -C "$home" log --format='%ad' --date=short "$upstream..HEAD" | sort)
[ -z "$dates" ] || printf 'first: %s\nlast: %s\n' "$(head -1 <<<"$dates")" "$(tail -1 <<<"$dates")"
git -C "$home" log --format='%s' "$upstream..HEAD" | sed -E 's/[(:].*//' | sort | uniq -c | awk '{print "type", $2":", $1}'

# One directory per task under data/ or data/archive/.
roots=("$data"); [ -d "$data/archive" ] && roots+=("$data/archive")
ids=$(find "${roots[@]}" -mindepth 1 -maxdepth 1 -type d ! -name archive -exec basename {} \; | sort -u)
briefed=$(find "${roots[@]}" -mindepth 2 -maxdepth 2 -name brief.md | awk -F/ '{print $(NF-1)}' | sort -u)

echo "== Tasks"
echo "task directories: $(printf '%s\n' "$ids" | grep -c .)"
echo "with a worker brief: $(printf '%s\n' "$briefed" | grep -c .)"
echo "successor workers (-rN): $(printf '%s\n' "$ids" | grep -cE -- '-r[0-9]+$' || true)"

echo "== Independent review rounds (<task>-review-N)"
rounds=$(printf '%s\n' "$ids" | grep -E -- '-review-[0-9]+$' | sed -E 's/-review-[0-9]+$//' | sort | uniq -c || true)
echo "changes reviewed: $(printf '%s\n' "$rounds" | grep -c . || true)"
echo "reviewer workers: $(printf '%s\n' "$rounds" | awk '{s+=$1} END {print s+0}')"
printf '%s\n' "$rounds" | awk 'NF {print $1}' | sort -n | uniq -c | awk '{print "  " $1 " change(s) took " $2 " round(s)"}'
echo "Firstmate's own changes:"
printf '%s\n' "$rounds" | awk '$2 ~ /^fm-/ {print "  " $2 ": " $1}'

echo "== Backlog records (unique task ids by kind)"
entries=$(grep -hE '^- \[.\] ' "$data"/backlog*.md "$data"/done-archive.md 2>/dev/null || true)
kinded=$(sed -nE 's/^- \[.\] ([^ ]+) .*\(kind: ([a-z]+)\).*/\2 \1/p' <<<"$entries" | sort -u)
awk 'NF {print $1}' <<<"$kinded" | sed 's/^captain$/decision-hold/' | sort | uniq -c | awk '{print "kind " $2 ": " $1}'
# Ids that never carry a kind on any line.
echo "ids with no kind: $(sed -nE 's/^- \[.\] ([^ ]+) .*/\1/p' <<<"$entries" | sort -u |
  comm -23 - <(awk 'NF {print $2}' <<<"$kinded" | sort -u) | grep -c . || true)"

echo "== Registered projects by delivery mode"
echo "projects: $({ grep -E '^- [^ ]+ \[' "$data/projects.md" 2>/dev/null || true; } | grep -c . || true)"
{ grep -E '^- [^ ]+ \[' "$data/projects.md" 2>/dev/null || true; } |
  sed -E 's/^- [^ ]+ \[([a-zA-Z-]+).*/\1/' | sort | uniq -c | awk '{print "mode " $2 ": " $1}'
echo "auto-merge (+yolo): $({ grep -E '^- [^ ]+ \[[^]]*\+yolo' "$data/projects.md" 2>/dev/null || true; } | wc -l | tr -d ' ')"
