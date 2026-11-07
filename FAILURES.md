# Failure log

What broke while I ran this setup, why, and what changed afterwards. Dates are 2026. Commit hashes are from my local Firstmate history. Where I never proved a cause, I say so.

| # | When | Failure | What changed |
|---|---|---|---|
| 1 | Aug to Oct | The supervisor spent most of its turns on noise | Watcher stays silent for working and paused workers; three rounds of fixes |
| 2 | Oct | An author's own tests passed on changes that still had blockers | Firstmate's own changes go through the independent review loop too |
| 3 | 20 Oct | The tmux server died three times and took live workers with it | Test cleanup only signals processes it can prove it started; risky suites banned on this host |
| 4 | 11 Oct | Workers ran under the wrong Claude account | Every launch pins or clears the account and drops the parent session's identity |
| 5 | 22 Oct | Worker tabs never closed, and a slow terminal app made duplicates | Close is forced and recorded; a timed-out open adopts the tab it created |
| 6 | 20 Oct | A timezone change caused an endless loop of empty wakes | Process identities read start times in UTC |
| 7 | 21 Oct | Every time the Mac woke from sleep, the live watcher looked dead | Watcher age ignores time the machine spent asleep |
| 8 | 19 Oct | Away mode would have typed into a worker's window | It refuses to start instead of guessing a target |
| 9 | 28 Sep | Bash crashed in subshells on a machine with no `LANG` | A locale guard is sourced wherever scripts reset the locale |
| 10 | 11 Oct | A worker in a project with no remote started from stale history | Spawn resolves the local default branch for remote-less projects |
| 11 | Sep to Oct | Workers said "done" when delivery had not happened, and test suites passed while running nothing | Delivery is checked against the real head and checks; briefs require proof the suite ran |
| 12 | Sep | A change passed eight review rounds but would have failed every real run | Any new join needs a measured key-overlap count as evidence |

## 1. The supervisor drowned in wakes

**What happened.** On 21 Sep I had a scout task parse 47 days of Firstmate's own session transcripts (6 Aug to 21 Sep, 3,310 turns). 80% of turns (2,652) were Firstmate handling a wake, and 2,175 turns, 66% of all, changed nothing at all. That is 18 of 45 working hours spent reading a worker's pane, deciding it was fine, and replying with one line. On 7 Oct a narrower check of the previous 15 hours found 41 wakes delivered, of which about 6 to 8 were useful.

**Cause.** The watcher re-surfaced every paused worker every few hours to "confirm the wait still holds", escalated busy workers on long jobs as possibly stuck, and re-reported workers that had already said `done:` and were waiting on a reviewer.

**What changed.**
- 7 to 8 Oct (`7271a8aa` and 4 follow-ups): a paused worker whose agent is alive never wakes Firstmate; only a dead or missing worker does. A worker whose own adapter says it is busy is never escalated as stuck. This change took 5 review rounds (see failure 2).
- 20 Oct (`014d8164`): closing the watcher no longer queues a "watcher was down" alert when nothing was queued.
- 20 to 21 Oct (`cd9e0c7d`, `d24814f7`, `1fb4ec02`): a `done:` worker that already surfaced stays quiet until something new happens, and a steering message sent to it still wakes once.

**Not measured yet.** I have not re-run the transcript count since these fixes, so I cannot say how far the empty-turn share dropped.

## 2. Authors miss their own blockers

**What happened.** The first watcher change above came back with its own tests green and passing lint. The first independent reviewer found that it turned one case that used to wake (a dead worker) into one that never woke. That was a blocker. In a later change, the reviewer of round 2 found that the round 1 fix had reintroduced the bug it was meant to close, because it compared a steering message's time against a marker that every heartbeat rewrote.

**Cause.** An author checks the cases it thought of. Its tests encode the same assumptions as its code.

**What changed.** I had started running the review loop in [CASE.md](CASE.md#the-review-loop) on client work two days earlier, on 5 Oct. This watcher change was the first change to Firstmate itself to go through it, and from then on all of them did. The reviewer gets only the task text and the commit, a new reviewer runs each round, and each finding comes with a repro or a test that fails today. Round counts are in [NUMBERS.md](NUMBERS.md).

## 3. tmux died and took live workers with it

**What happened.** On 20 Oct the default tmux server, the one holding every worker window, exited three times between about 11:10 and 14:18 UTC. Each time, the workers running in it died mid-task. One piece of work lost its worker three times; the fourth worker finished it. Each time I saved the worker's uncommitted diff as a patch file and started a successor worker (`<task>-r2`, then `-r3`) that applied it, reviewed it critically and carried on. Teardown of the dead originals then refused, because the dead record and its successor named the same worktree slot.

**Cause, as far as I proved it.** Each of the three exits came while a worker was running one particular Firstmate test suite. Its cleanup sent a kill signal to every process ID it had recorded, with no check that the ID still belonged to its own process. Process IDs get reused within minutes on this machine. A helper in the same suite could also fall back to the default tmux server when its private socket directory was empty. I never caught the exact kill in the act, so this is a strong lead, not a proof.

**What changed.**
- `37d79886`: the cleanup records each process with its start time and only signals a process that still matches. The helper refuses an empty socket directory.
- `fe8570e2`, `802816ed`: the two suites that drive tmux use a private server.
- Briefs for Firstmate work now forbid running those two suites on this host and require a private tmux directory for any test.
- I recorded the teardown order: tear down the dead originals first, then their successors.

## 4. Workers ran under the wrong account

**What happened.** I keep two separate Claude setups on this Mac for two separate work contexts. On 11 Oct six workers started from one setup ran on the other setup's account, including one doing work for a different client.

**Cause.** The long-lived tmux server had been started by a session from the other setup. Its global environment held that setup's config directory plus that session's private identity variables. The spawn script only set the config directory when the spawning session had one, so workers from the default setup inherited the other one. A cleanup that only cleared the tmux *session* environment did nothing, because the values lived in the *global* environment.

**What changed.**
- `53bc337b`, `7458d9dd`, `6cb91f0d`: every worker launch either pins the spawner's config directory or explicitly clears it, and always drops the parent session's identity variables. A test proves a foreign value in the tmux environment no longer reaches the worker.
- `6f8f96a9`: the same launch turns off a chat-bot plugin whose single connection a worker would otherwise steal from my main session.
- A reviewer worker that later turned out to be running under the wrong account was stopped and its review restarted by a fresh one.

## 5. Worker tabs never closed, and duplicates appeared

**What happened.** On 22 Oct, the first day each worker got its own tab in the cmux terminal app, about 10 stale tabs piled up. Closing a task never closed its tab, and a slow app produced a second tab for the same worker.

**Cause.** The app refuses to close a tab with a running process unless the close is forced, and the error was silenced, so the record was deleted while the tab stayed. A tab-open call that timed out had in fact succeeded, but nothing recorded it.

**What changed.** `e72e20ad`: close is forced and targets the recorded tab, falling back to the exact `worker: <id>` label; a timed-out open adopts the tab the app created; the timeout is longer. The first reviewer found one remaining path to a duplicate under a slow app and a test that did not fail under mutation. `e97035a8` fixed both.

## 6. A timezone change looped the supervisor

**What happened.** On 20 Oct every turn end in my main session was followed by an empty "check" wake, then another.

**Cause.** `ps` prints process start times in local time. After the machine's timezone changed, the recorded identity of the running watcher no longer matched the live process. Each turn end started a new watcher, which found the lock taken and exited, and the hook woke the session again.

**What changed.** `138cb464`: every start-time read that feeds an identity pins `TZ=UTC`.

## 7. Sleep looked like a dead watcher

**What happened.** After each Mac sleep, the main session got an alert that the watcher had stalled.

**Cause.** No process runs while the Mac sleeps, so the watcher's heartbeat looked minutes old on wake.

**What changed.** `a32f22d5`: the heartbeat age counts from the later of the last beat and the last system wake. A watcher that is really hung still goes stale.

## 8. Away mode guessed the wrong window

**What happened.** On 19 Oct I tried to switch on the mode that batches wakes while I am busy. My main session ran inside cmux, so the daemon could not find its own window and fell back to a default target that was in fact a worker's window. I rolled it back before it typed anything.

**What changed.** `c48a756a`, `820def5e`: the daemon refuses to start without a window it can prove is the supervisor, and says which setting to provide.

## 9. Bash segfaults with no `LANG`

**What happened.** On 28 Sep scripts crashed with exit code 139 in forked subshells.

**Cause.** Homebrew's bash crashes when a subshell resets `LC_ALL` while `LANG` is unset.

**What changed.** `47e89c12`, `11ce68d8`, `e9156690`, `037c1462`: a locale guard sets a non-exported `LANG=C` and is sourced wherever a script resets the locale. `bb47fd62` added a lint rule that catches a missing or late guard.

## 10. Stale base in projects with no remote

**What happened.** Several of my repos live only on my machine. Workers in them could start from whatever commit their pooled worktree happened to hold.

**What changed.** `918ea942`, `84b39082`: the spawn finds the local default branch, even when it is not called `main` or `master`, and starts the worker from it.

## 11. A worker's account of delivery is not delivery

**What happened.** On client data-science projects, three workers in one session wrote `done:` with their work unpushed and no pipeline run started; two of them had worked on a side branch instead of the PR branch. One change shipped three tests that could not fail: one overrode the very function it exercised, one asserted a function name, one recomputed the list under test. Twice a test suite reported success while running nothing: once with no JVM linked, once on the wrong Python version. Workers waiting on a long external job also ended their turn on a `working:` line, which the watcher then flagged as stuck.

**What changed.** These became standing rules in every brief and in Firstmate's own notes:
- Check the pushed head and the real check state before calling work done. Trust a worker's account of the code, not of the delivery.
- Before trusting a green run, confirm the environment executed what you think it did, and say how you confirmed it.
- A long wait you are watching is a `paused:` line with a resume time, not `working:`.
- A test that cannot fail when the logic breaks does not count.

## 12. Review cannot see a data defect

**What happened.** In early September, before I had the independent review loop, a change to a client data pipeline passed its final PR review with zero findings after eight rounds. It would still have failed on every real run. It joined two tables on a key where a direct query showed none of about 1.6 million values on one side existed on the other, because the pipeline has two separate key spaces that happen to share a column name. Two days later an upstream rewrite replaced the measured table, and the change was rebased and re-verified against the new one.

**Cause.** Reviewers read code and ran tests on fixtures. Nobody measured the join against real data. A direct query found it in seconds.

**What changed.** Any new or retargeted join now needs a measured key-overlap count as evidence before review starts. More generally: the evidence has to have the same shape as the claim. "No behaviour change" needs a before-and-after diff of values, not a successful parse.
