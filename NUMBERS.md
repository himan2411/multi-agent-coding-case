# Numbers

Two sources. The first you can rerun against any Firstmate home with `scripts/counts.sh`. The second came from one scout task that parsed my private session transcripts, so you cannot rerun it from this repo.

## 1. Counts from the Firstmate home

Run on 7 Nov 2026 at 16:52 against my live home, with `scripts/counts.sh ~/Work/firstmate`. The script prints aggregates only, so client task names never leave the machine. The fleet was running while I measured, so a rerun later gives larger task counts. When I rerun it, I update this file and the two count bullets in the README.

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
task directories: 479
with a worker brief: 469
successor workers (-rN): 33
== Independent review rounds (<task>-review-N)
changes reviewed: 38
reviewer workers: 80
  16 change(s) took 1 round(s)
  11 change(s) took 2 round(s)
  4 change(s) took 3 round(s)
  5 change(s) took 4 round(s)
  2 change(s) took 5 round(s)
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
kind scout: 190
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
- **Successor workers** are tasks named `<task>-r2`, `-r3` and so on. Each one replaced a worker that was lost, stopped, or sent back to redo the work. The name does not record which.
- **Review rounds** come from reviewer folders. Each is one fresh reviewer worker. Later rounds are named `<task>-review-<n>`. Round 1 is often an unnumbered `<task>-review`, so the script counts one only when the same task also has numbered rounds; an unnumbered folder on its own is usually a one-off review of a PR and is left out. The name rule has limits both ways. For a few changes the unnumbered folder was an earlier, different kind of review, so the multi-round counts run high: counting numbered folders only gives 24 changes passing the first round instead of 16. And at least one change (`fm-upgrade`) is missing a folder for one of its rounds. So I quote first-round passes as 16 to 24. The Firstmate-only lines are unaffected: none of those changes has an unnumbered folder.
- **Backlog records** count unique task ids in Firstmate's backlog files by their recorded kind. A decision hold is a question parked for me to answer, not a worker. A kind written with extra notes, such as `(kind: ship, mode=direct-PR)`, still counts. **Ids with no kind** never recorded one on any line; they are left out of the kinds above.
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
