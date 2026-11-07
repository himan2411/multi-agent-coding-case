#!/usr/bin/env bash
# Recount the numbers in NUMBERS.md from a Firstmate home. Read-only.
# Usage: scripts/counts.sh <firstmate-home> [upstream-ref]
# Prints aggregates only, so client task names never leave the home.
set -euo pipefail

home=${1:?usage: counts.sh <firstmate-home> [upstream-ref]}
upstream=${2:-origin/main}
data="$home/data"
[ -d "$data" ] || { echo "no data/ under $home" >&2; exit 1; }
git -C "$home" rev-parse -q --verify "$upstream^{commit}" >/dev/null 2>&1 ||
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
# A <task>-review-rN folder is a review round, not a successor.
echo "successor workers (-rN): $(grep -E -- '-r[0-9]+$' <<<"$ids" | grep -vcE -- '-review-r[0-9]+$' || true)"

echo "== Independent review rounds"
# Rounds are <task>-review-<n> or -review-r<n>; an unnumbered <task>-review
# counts as round 1 only beside numbered rounds. NUMBERS.md explains why.
numbered=$(grep -E -- '-review-r?[0-9]+$' <<<"$ids" | sed -E 's/-review-r?[0-9]+$//' || true)
first=$(grep -E -- '-review$' <<<"$ids" | sed -E 's/-review$//' | grep -Fx -f <(sort -u <<<"$numbered") || true)
rounds=$(printf '%s\n%s\n' "$numbered" "$first" | grep . | sort | uniq -c || true)
multi=$(awk '$1 >= 2' <<<"$rounds")
echo "changes with 2+ rounds: $(grep -c . <<<"$multi" || true)"
echo "reviewer workers in them: $(awk '{s+=$1} END {print s+0}' <<<"$multi")"
awk 'NF {print $1}' <<<"$multi" | sort -n | uniq -c | awk '{print "  " $1 " change(s) took " $2 " rounds"}'
echo "Firstmate's own changes:"
printf '%s\n' "$rounds" | awk '$2 ~ /^fm-/ {print "  " $2 ": " $1}'

echo "== Backlog records (unique task ids by kind)"
entries=$(grep -hE '^- \[.\] ' "$data"/backlog*.md "$data"/done-archive.md 2>/dev/null || true)
kinded=$(sed -nE 's/^- \[.\] ([^ ]+) .*\(kind: ([a-z]+)[,)].*/\2 \1/p' <<<"$entries" | sort -u)
awk 'NF {print $1}' <<<"$kinded" | sed 's/^captain$/decision-hold/' | sort | uniq -c | awk '{print "kind " $2 ": " $1}'
# Ids that never carry a kind on any line.
echo "ids with no kind: $(sed -nE 's/^- \[.\] ([^ ]+) .*/\1/p' <<<"$entries" | sort -u |
  comm -23 - <(awk 'NF {print $2}' <<<"$kinded" | sort -u) | grep -c . || true)"

echo "== Registered projects by delivery mode"
projects=$(grep -E '^- [^ ]+ \[' "$data/projects.md" 2>/dev/null || true)
echo "projects: $(grep -c . <<<"$projects" || true)"
sed -nE 's/^- [^ ]+ \[([a-zA-Z-]+).*/\1/p' <<<"$projects" | sort | uniq -c | awk '{print "mode " $2 ": " $1}'
echo "auto-merge (+yolo): $(grep -cE '^- [^ ]+ \[[^]]*\+yolo' <<<"$projects" || true)"
