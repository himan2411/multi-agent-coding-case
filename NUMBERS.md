# Numbers

Two sources. The first you can rerun against any Firstmate home with `scripts/counts.sh`. The second came from one scout task that parsed my private session transcripts, so you cannot rerun it from this repo.

## 1. Counts from the Firstmate home

Run on 7 Nov 2026 at 17:08 against my live home, with `scripts/counts.sh ~/Work/firstmate`. The script prints aggregates only, so client task names never leave the machine. The fleet was running while I measured, so a rerun later gives larger task counts. When I rerun it, I update this file plus three places in the README: the commit count and the two count bullets.

```text
== Local commits on top of origin/main
commits: 43
first: 2026-09-28
last: 2026-10-22
type chore: 1
type feat: 1
type fix: 33
type test: 8
== Tasks
task directories: 481
with a worker brief: 471
successor workers (-rN): 22
== Independent review rounds
changes with 2+ rounds: 28
reviewer workers in them: 83
  13 change(s) took 2 rounds
  6 change(s) took 3 rounds
  6 change(s) took 4 rounds
  3 change(s) took 5 rounds
Firstmate's own changes:
  fm-cmux-worker-tabs: 2
  fm-quiet-watch: 5
  fm-rearm-loop: 1
  fm-spawn-account-pin: 1
  fm-tabs-bugs: 2
  fm-upgrade: 3
  fm-wake-noise: 4
== Backlog records (unique task ids by kind)
kind decision-hold: 204
kind scout: 192
kind ship: 126
kind task: 2
ids with no kind: 89
== Registered projects by delivery mode
projects: 42
mode local-only: 11
mode no-mistakes: 2
mode no-mistakes-prod-only: 29
auto-merge (+yolo): 2
```

What each line means, and its limits:

- **Local commits** are commits on my `main` that are not on upstream `origin/main` as of my last fetch. All 43 are mine.
- **Task directories** are folders under `data/` and `data/archive/`. Firstmate makes one per task for its brief, report and proof files. **With a worker brief** counts the ones where a worker was actually briefed. The folders without a brief hold notes, backups or shared records, not workers.
- **Successor workers** are tasks named `<task>-r2`, `-r3` and so on. Each one replaced a worker that was lost, stopped, or sent back to redo the work. The name does not record which. Review rounds named `<task>-review-r2` and so on are not counted here.
- **Review rounds** come from reviewer folders; each is one fresh reviewer worker. Rounds are named `<task>-review-<n>` or `<task>-review-r<n>`, and round 1 is often an unnumbered `<task>-review`, which counts only next to numbered rounds. A change that passed on its first round leaves one unnumbered folder, which looks the same as a one-off review of someone else's PR, so only changes with 2 or more rounds are reported. These counts are close, not exact. A few unnumbered folders were an earlier, different kind of review, which adds a round. More often a round's folder was deleted or filed under another name: 7 changes show gaps in their round numbers, 4 of them drop out of this list, and `fm-upgrade` shows 3 rounds where it had 4. Overall the counts run slightly low.
- **Backlog records** count unique task ids in Firstmate's backlog files by their recorded kind. A decision hold is a question parked for me to answer, not a worker. A kind written with extra notes, such as `(kind: ship, mode=direct-PR)`, still counts. **Ids with no kind** did not record one in the standard `(kind: ...)` form on any line; they are left out of the kinds above.
- **Delivery modes** are the first mode of each project in the registry. `local-only` is a delivery mode: the worker hands back a ready branch instead of opening a PR.

## 2. Where the supervisor's time went (6 Aug to 21 Sep)

On 21 Sep a scout task parsed all 16 transcripts of Firstmate's own session over 47 days (107 MB, 81,164 records) and classified each turn by what triggered it and whether it changed any state. It cross-checked its parser with an independent raw count; the two agreed within 1%.

| | Turns | Wall clock |
|---|---|---|
| All turns | 3,310 | 45.4 h |
| Turns handling a wake | 2,652 (80%) | 29.3 h |
| ... that changed nothing | 2,175 (66% of all) | 18.0 h |
| Turns I started | 498 (15%) | 12.3 h |

A turn counted as changing state if it spawned, steered, controlled, merged or tore down a worker, recorded a decision, or edited a file.

The fixes in [FAILURES.md](FAILURES.md#1-the-supervisor-drowned-in-wakes) target exactly this. I have not re-run this measurement since they landed, so I have no "after" number yet.

## Not measured

- Wall-clock time per task, and how much of it was waiting on me.
- Cost in tokens or money per task.
- How many review findings were real defects versus noise. Every finding had to come with a repro or failing test, but I have not tallied them.
