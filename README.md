# Portable Ralph Loop

This repository packages a Ralph-style coding loop that can be copied into another project as `loop/`. Each iteration starts a fresh coding-agent process, completes at most one task, and persists memory through `loop/prd.json`, `loop/progress.txt`, and Git history.

Start with the single-run workflow before enabling the bounded outer loop. See [loop/README.md](loop/README.md) for setup, task format, agent configuration, safety rules, and skill installation, or open [The Fresh-Context Relay](https://mtahafarooq.github.io/ralph-loop/loop/docs/ralph-flowchart.html) for an interactive step-by-step walkthrough.
