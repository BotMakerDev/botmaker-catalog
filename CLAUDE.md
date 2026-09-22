# CLAUDE.md

Guidance for working in **botmaker-plugin-registry**, the index of BotMaker plugins.

This is a **data repository**, like `botmaker-gallery`: no pom, not in the umbrella's reactor, nothing here
is compiled. Read the umbrella `../CLAUDE.md` and `../botmaker-cli/CLAUDE.md` — the gate's code lives there.

## The one structural fact: the entries are the source of truth, the index is derived

`plugins/<plugin-id>.json` is written by a human (well, by `botmaker publish`); `index.json` is written by
`.github/workflows/index.yml` and by nothing else. Two properties follow, and both were bought deliberately
from a single-array layout that did not have them:

- **Two submissions never conflict.** Two authors adding two plugins touch two files.
- **Id uniqueness is git's.** A second `plugins/com.example.discord.json` cannot exist, so the `id` check's
  "already claimed" arm is a property of the layout rather than of a check that could be forgotten. (Value
  type ids needed a scan of every entry until 2026-09-23; a type is its Java class now, and entries no
  longer list types.)

`index.json` must stay at exactly its current path. Studio reads it from
`raw.githubusercontent.com/BotMakerDev/botmaker-plugin-registry/main/index.json`, and a shipped Studio has
that URL compiled into it. A Studio built before the repository moved into the organization on 2026-09-18
spells the owner `LiQiyeDev`; `GitHubConfig.registryIndexRawUrls()` tries both, newest first.

## The gate is not in this repository, and that is not an oversight

`validate.yml` resolves `com.github.LiQiyeDev:botmaker-cli`'s **main** artifact — the library, with no
picocli in it — and calls `com.botmaker.cli.registry.RegistryGate`. The rule from `botmaker-cli/CLAUDE.md`
applies from this side too: **a rule added here is a rule the plugin's author cannot run**, and a submission
that fails for a reason its author could not have seen coming is the experience the gate exists to prevent.
A new check belongs in `PluginValidator`, as a `Check`.

What this repository legitimately owns is the three facts only it holds — the ids every other entry claims,
**which host's bundled plugins these ids are reserved for**, and that `index.json` is generated — and all
three are passed to the gate rather than reimplemented.

**The bundled set is `BOTMAKER_BUNDLED_PLUGINS`, and since 2026-09-05 it is empty.** That is the truthful
value, not a check somebody switched off: `botmaker-studio` has bundled no plugin since 2026-09-02 — every
plugin, the SDK included, is loaded off the open project's own resolved classpath. So no id is reserved
outside this index, and `com.botmaker.sdk` is claimed exactly the way every other id is, by
`plugins/com.botmaker.sdk.json` existing, which git enforces.

**Empty and unset are different, and the gate tells them apart** (`botmaker-cli` v0.0.11 and newer). Unset
warns — nobody said, so a host's own plugins' ids would go unreserved without anyone having decided that,
which is the hole `Bundled` exists to close. Empty is silent. **Do not delete the line believing it means
the same thing.**

**If a host bundles a plugin again, name it as a coordinate, never as a list of ids.** The gate resolves the
coordinate and asks the plugin; a list of ids in this repository would be a second answer to a question the
plugin already answers, and would drift the first time the plugin changed. Name every bundled coordinate
in one comma-separated value: they go on **one** classpath, because a bundled plugin's own dependency may be
`optional` and so not transitive, and a classpath missing it is one that plugin cannot be constructed from.
(The worked example was the SDK's own toolkit dependency, `optional` until SDK v1.1.5.)

**The CLI version and the bundled coordinates are pinned** (`BOTMAKER_CLI_VERSION`,
`BOTMAKER_BUNDLED_PLUGINS` in `validate.yml`), not floating. A verdict must not change under a pull request
that is already open; bump either in a pull request of its own. `BOTMAKER_CLI_VERSION` is a **released tag**
and not `main-SNAPSHOT`, which is what it said until 2026-09-05 and which never resolved: JitPack builds a
tag on demand and serves the artifact under that tag, and this project's poms carry the cosmetic
`0.0.0-SNAPSHOT` JitPack overrides — so a branch build is not the artifact the author's own
`botmaker validate` runs, which is the one property this whole arrangement exists to guarantee.

## Changed paths never reach a shell

A pull request chooses its own filenames, so a path is attacker-controlled text. `validate.yml` writes
`git diff --name-only` to `target/changed.txt` and the gate reads that file (its `@file` argument form).
Interpolating a path into a `run:` line is a command injection; it is also simply broken for a filename
containing a space.

## What this repository never claims

A plugin runs arbitrary code inside Studio's process. Every check asks whether a plugin **works**. Nothing
here is a safety review, and the README says so in its first three lines — keep it that way, and do not add a
badge or a word that implies otherwise.
