# YourGeeky

YourGeeky: a friendly Terminal helper for non-technical Mac users. They type what they need in plain words and an AI assistant (Google's Antigravity CLI by default, or Claude Code) does it, explaining each step and asking before changes. See `README.md`.

## Where it runs
- The yourgeeky.com website and installer are in `docs/` (`docs/CNAME`, `docs/install.sh`).
- The command itself is `bin/yourgeeky`. Prompts are in `prompts/`, tests in `tests/`.
- `LAUNCH-CHECKLIST.md` lists what's left before launch.

## Git
- Steve works from two Macs. Before starting work, run `git pull --rebase origin main`.
- After finishing a change, commit it and push to `origin main` (https://github.com/Chobasoft/YourGeeky). No need to ask first.
- Record settled choices in `DECISIONS.md` (alternatives and reasons, newest last).
