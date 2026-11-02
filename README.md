# YourGeeky

A friendly Terminal helper for people who are not technical. Tell it what you need in
plain words, like "install Python", and it does the work with an AI assistant, explaining
each step and asking before it changes anything. It uses Google's free Antigravity CLI by
default, or Claude Code for people with a paid Claude plan.

Version 1 is for Mac.

## Install

Open the Terminal app, paste this line, and press Return:

```
curl -fsSL https://yourgeeky.com/install.sh | bash
```

The installer asks whether you have a paid Claude plan. If not, it sets up Google's free
AI (sign in with any Google account); if so, it sets up Claude Code. It also adds a
YourGeeky icon to the Dock and the Applications folder. Click it, or type `yourgeeky`.

## Use

```
yourgeeky                      # start a conversation
yourgeeky "install Python"     # start with a request
yourgeeky --show-commands      # also show the real commands, so you can learn them
yourgeeky --notes              # open your notes: what YourGeeky has done on this Mac
yourgeeky --use claude         # switch to Claude Code (or --use google to switch back)
```

## What it helps with

Installing tools, running instructions from a guide, explaining errors, fixing
"command not found" and "permission denied", setting up Homebrew, finding folders,
getting unstuck, running a project someone shared, and updating or removing software.

## Notes of what was done

After YourGeeky installs, removes or changes something, it adds a dated, plain-English
entry to `~/YourGeeky notes.txt`, with how to undo it where that helps. People can look
back later, show the notes to someone helping them, or ask YourGeeky to undo something.

## How it works

`bin/yourgeeky` starts the chosen AI with the guidance in `prompts/guide.md`: added to
Claude Code's system prompt, or sent as the opening message to Antigravity CLI, which has no
system prompt option. That file sets the plain-English tone, the safety rules, and how to
handle the ten most common requests. Each tool's own permission prompts still apply,
so nothing runs without the person's say-so.

## Development

```
bash tests/run.sh
```

The Dock icon is made by the installer from `assets/icon.png` (drawn in `assets/icon.svg`),
using the Mac's built-in `sips` and `iconutil`.
