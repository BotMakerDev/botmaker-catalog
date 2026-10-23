# CLAUDE.md

Guidance for working in **botmaker-catalog**, the list of published BotMaker bots and plugins (the plugin
registry, renamed on 2026-10-23; the design is the umbrella's `docs/superpowers/specs/2026-10-23-catalog-design.md`).

This is a **data repository**: no pom, not in the umbrella's reactor, nothing here is compiled. Read the umbrella
`../CLAUDE.md` and `../botmaker-cli/CLAUDE.md` — every rule lives in `com.botmaker.cli.catalog` there.

## Entries are written by authors, catalog.json by index.yml only

- An entry file holds only what its author decides (`repo`, `tag`, a plugin's `id`, a bot's `detached`). Every
  other field of `catalog.json` is derived by `IndexCommand`. Never add a field to an entry that GitHub or the pom
  already answers.
- `catalog.json` is the only file Studio reads, at `raw.githubusercontent.com/BotMakerDev/botmaker-catalog/main/
  catalog.json` (`GitHubConfig.catalogRawUrls()` in shared). Its path never moves.
- A pull request changes exactly one entry file, or `publishers.json` alone; everything else (`tools/`, a
  workflow) is the admin's, committed by hand.
- **An admin may change anyone's entry, and only an admin changes `publishers.json`** (2026-10-23, the dashboard's
  edits): an admin is the pull request author's account id among `admin` in main's `publishers.json`
  (`--author-id`), never a login. Rules 3 and 4 pass for an admin; the release must still be published and the
  kind's checks still run. So the SDK and basics, whose releases `github-actions[bot]` made, are listed by an
  admin's pull request like any other entry.

## No rule lives here

The workflows resolve botmaker-cli's **main** artifact at `tools/botmaker-cli.version` and call `EntryGate`,
`ListingPolicy` and `IndexCommand`. A rule added here is one the author's `publish` cannot run on their machine
first: put it in the cli. The version is a **released tag**, pinned so a verdict does not change under an open
pull request; bump it in a commit of its own.

## Which job may hold which token

- `validate.yml` runs the entry's code (a plugin's constructor in the check's JVM, a bot's Maven build), so the
  step doing that (`--part kind`) holds **no token**, and the checkout keeps no credentials. `--part rules` holds
  the read-only token and runs no entry code. The tools come from the base tree, never the pull request's. The
  kind step's GitHub calls are anonymous (60 an hour per runner), so a rate limit is a false refusal that a re-run
  clears — never a reason to give that step a token.
- A plugin's constructor can end the kind step's JVM itself (`System.exit(0)`), skipping the plugin's id and
  JitPack checks; Studio checks a loaded plugin's id against its entry (accepted 2026-10-23).
- `automerge.yml` holds the write token, so it checks out only `main` and reads pull requests through the API as
  data (`tools/entry-facts.sh`); `ListingPolicy` is pure.
- `index.yml` holds the write token and runs no entry code: GitHub's API and each pom read as data.

Keep it that way: a step that runs an entry's code never gets a token.

## Changed paths never reach a shell

A pull request chooses its own filenames, so a path is attacker-controlled text. `validate.yml` writes
`git diff --name-only` to `target/changed.txt` and `EntryGate` reads it through its `@file` form; `entry-facts.sh`
only ever holds a path in a quoted variable.

## What this repository never claims

Every check asks whether an entry works and whether its author controls it. Nothing here is a safety review, and
the README says so first — keep it that way; ranks say who published, not that the code was read.
