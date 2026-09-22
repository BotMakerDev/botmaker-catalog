# botmaker-plugin-registry

The index of BotMaker plugins. **A curated list with a working gate — never a security claim.**

A BotMaker plugin runs arbitrary code inside Studio's own process. Every check this repository runs asks
whether a plugin *works*: does it resolve, does it load, does it collide with something already here. None of
them asks whether it is *safe*, and none of them could. Install a plugin the way you would run any other
program somebody wrote.

## Submitting a plugin

```bash
botmaker validate                       # the same checks this repository runs
botmaker publish --repo me/my-plugin --description "…" --tags notifications
```

`botmaker publish` forks this repository, writes `plugins/<plugin-id>.json` and opens the pull request. The
entry is composed from what the plugin already says about itself — its id, its display name, the contract
version its pom declares — because a human retyping those is a human putting a typo in the registry's
primary key.

Install the CLI from [botmaker-cli](https://github.com/BotMakerDev/botmaker-cli).

## Layout

```
plugins/<plugin-id>.json    the source of truth — one entry, named by its own id
index.json                  GENERATED. Committed by CI on merge. Do not edit it
tools/build-index.sh        how index.json is generated
```

**The filename is the plugin's id, and that is the layout doing a check's job.** Git refuses a second
`plugins/com.example.discord.json`, so id-uniqueness is a property of this repository rather than of a check
somebody has to remember to run — and two authors submitting on the same day open two pull requests with no
line in common. A single shared array made both of those false.

A pull request that edits `index.json` is refused, naming the entry file to write instead.

## An entry

```json
{
  "id": "com.example.discord",
  "name": "Discord Notifier",
  "coordinate": "com.github.someone:botmaker-discord-plugin",
  "repo": "someone/botmaker-discord-plugin",
  "description": "Sends a message when a bot finishes",
  "tags": ["notifications"],
  "minContractVersion": "1.0.0",
  "verifiedVersion": "v0.1.0",
  "verifiedAt": "2026-08-28"
}
```

`coordinate` carries no version: the index names a plugin, not a release, and Studio resolves the version to
install the same way it resolves the SDK's. `verifiedVersion` is the version the checks last actually ran
against — a date with no artifact beside it would say nothing.

An entry written before 2026-09-23 may still carry `valueTypeIds`. Nothing reads it any more and nothing
rewrites the file; the generated `index.json` simply stops carrying it.

## The gate

`.github/workflows/validate.yml` resolves `com.github.LiQiyeDev:botmaker-cli` — its **main** artifact, the
library — and calls `com.botmaker.cli.registry.RegistryGate`. **The code is not in this repository on
purpose:** it must be the same code the author already ran, because a submission that fails for a reason its
author could not have seen coming is exactly what the gate exists to prevent.

| check | passes when |
|---|---|
| `classpath` | the published coordinate resolves and every entry exists |
| `loads` | `ServiceLoader` finds at least one `StudioPlugin` through the real loader |
| `id` | the id is well formed, and claimed by no other entry and by no plugin Studio itself ships |
| `palette` | `catalog().problems()` is empty and every entry names a real public member |
| `value-types` | every declared type answers a class and a fresh value, no class is declared by two plugins on the classpath, and a component type puts its fresh value back together from its own parts |
| `editors` | `slotEditors()` builds and every predicate answers without throwing |
| `pom-scopes` | `botmaker-studio-api` is `provided` or `compile`; `botmaker-plugin-toolkit` is not `provided` |

One of those — `id` — can only be answered here, because only this repository knows what is already
claimed. That is why a clean local run says so rather than promising the pull request will pass. "Already
claimed" is two sets: every other entry in `plugins/`, and the plugins BotMaker itself ships. **Prefix your
id with something that is yours** and it cannot bite you.

`value-types` used to be the second, over string ids a plugin chose. Since 2026-09-23 a type is its class,
named by its own package, so two plugins can only meet over one when they are loaded together — and a
plugin the submission depends on is loaded beside it here.

## Removing a plugin

Delete `plugins/<plugin-id>.json`. The gate accepts a deletion without resolving anything — an unmaintained
plugin must not become unremovable — and the index regenerates on merge.
