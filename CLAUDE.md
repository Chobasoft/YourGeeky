# YourGeeky

YourGeeky: a friendly Terminal helper for non-technical Mac users. They type what they need in plain words and an AI assistant (Google's Antigravity CLI by default, or Claude Code) does it, explaining each step and asking before changes. See `README.md`.

## Where it runs
- The yourgeeky.com website and installer are in `docs/` (`docs/CNAME`, `docs/install.sh`).
- The command itself is `bin/yourgeeky`. Prompts are in `prompts/`, tests in `tests/`.
- `LAUNCH-CHECKLIST.md` lists what's left before launch.

## Names
Steve dictates by voice, so names often arrive misspelled or split into words. Always spell them exactly like this:
- **Bask Jewelry**, **Steven Battelle**, **Everbust**
- **ChobaSoft**, the parent company of:
  - **Geeky sites**: EmailSetupGeek, SiteSetupGeek, SiteFixGeek (a separate site from SiteSetupGeek), YourGeeky
  - **ShippyMonster** (formerly Shipperator)
  - **DrinkGauge**
  - **4DPort**
  - **NumisPair**: NumisGuess (= NumisPairIdentify), NumisPairPhone, NumisPairWebsite, NumisPairDesktop, NumisPairAlbum, NumisPairSeller (formerly NumisPairStore)
  - **HelpTalkin** (one word, no "g")
  - **MyEBizGuide** (capital M, E, B, G; formerly the EBizStartup project)

Common mishearings: "numis pair" / "numa spare" → NumisPair, "numis guess" → NumisGuess, "choba soft" / "chobo soft" / "JovaSoft" / "Shobasoft" / "Chobasov" → ChobaSoft, "help talking" → HelpTalkin, "shippy monster" → ShippyMonster, "drink gauge" / "drink gage" → DrinkGauge, "four D port" → 4DPort, "sight fix geek" → SiteFixGeek, "my e biz guide" / "my ebiz guide" → MyEBizGuide.

Use the correct spelling silently when a dictated name is close; ask only when it's genuinely ambiguous. Keep this list the same in every ChobaSoft repo's `CLAUDE.md`.

## Git
- Steve works from two Macs. Before starting work, run `git pull --rebase origin main`.
- After finishing a change, commit it and push to `origin main` (https://github.com/Chobasoft/YourGeeky). No need to ask first.
- Record settled choices in `DECISIONS.md` (alternatives and reasons, newest last).
