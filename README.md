# Multi-agent coding: a working case

I run several coding agents in parallel on one Mac. One agent takes my requests and supervises the rest. Each worker gets its own git worktree, every change goes through a fresh independent reviewer until one finds nothing, and scripted gates decide what can merge. This repo explains how that works, what it has done, and what broke.

The orchestrator is [Firstmate](https://github.com/kunchenguid/firstmate), an open-source project by Kun Chen (MIT). I did not write it. I run it, set the policies on top of it, added the review loop, and fixed what broke for me in 43 local commits.

## What is here

- [CASE.md](CASE.md): the architecture, how a task goes from request to merged change, the review loop and the merge gates. With diagrams.
- [FAILURES.md](FAILURES.md): twelve real failures, their causes, and what changed after each one.
- [NUMBERS.md](NUMBERS.md): measured counts, with what each number does and does not mean.
- [scripts/counts.sh](scripts/counts.sh): recomputes those counts from a Firstmate home.

## Results so far

- 471 briefed worker tasks between August and November 2026, mostly on client data-science projects.
- 28 changes needed 2 to 5 rounds of independent review, 83 reviewer runs in all. Changes that passed on the first round are not counted, because their folder names look the same as one-off reviews of other people's PRs.
- The two counts above are from one dated snapshot in [NUMBERS.md](NUMBERS.md).
- Over 47 days, 66% of the supervisor's turns changed nothing. That finding drove the largest set of fixes. I have not re-measured since.

## Run it

The scripts need bash (3.2 or later), git and the standard Unix tools that ship with macOS and Linux.

```sh
scripts/counts-check.sh              # self-check on a synthetic home, no setup needed
scripts/counts.sh ~/path/to/firstmate   # recount from a real Firstmate home
```

The self-check builds a small synthetic home in a temp folder. It fails if any count is wrong or if a task name shows up in the output. Everything else in this repo is Markdown; the diagrams are Mermaid and render on GitHub.

## What is not here

No client code, data or names. Task names from client work are counted, never listed. The Firstmate code itself lives in its own repo.
