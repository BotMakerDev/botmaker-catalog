# botmaker-plugin-registry

The index of BotMaker plugins. **A curated list with a working gate — never a security claim.**

A BotMaker plugin runs arbitrary code inside Studio's own process. Every check this repository runs asks
whether a plugin *works*: does it resolve, does it load, does it collide with something already here. None of
them asks whether it is *safe*, and none of them could. Install a plugin the way you would run any other
program somebody wrote.

## Submitting a plugin

```bash
botmaker plugin validate                # the same checks this repository runs
botmaker plugin publish --repo me/my-plugin --description "…" --tags notifications
```

`botmaker plugin publish` forks this repository, writes `plugins/<plugin-id>.json` and opens the pull request. The
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

An example:

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

An older entry may still carry `valueTypeIds`. Nothing reads it any more and nothing rewrites the file; the
generated `index.json` simply stops carrying it.

## The gate

`.github/workflows/validate.yml` resolves `com.github.BotMakerDev:botmaker-cli` — its **main** artifact, the
library — at the release the workflow names, and calls `com.botmaker.cli.registry.RegistryGate`. **The code
is not in this repository on purpose:** it must be the same code the author already ran, because a
submission that fails for a reason its author could not have seen coming is exactly what the gate exists to
prevent. The checks are that release's: `BOTMAKER_CLI_VERSION` in the workflow pins it, so a verdict does
not change under an open pull request, and the pin moves in a pull request of its own.
[botmaker-cli's README](https://github.com/BotMakerDev/botmaker-cli#readme) lists the checks on its `main`
under `botmaker plugin validate`; the pinned release may run fewer.

One of them — `id` — can only be answered here, because only this repository knows what is already claimed:
every other entry in `plugins/`, plus any plugin a host bundles (`BOTMAKER_BUNDLED_PLUGINS` in the workflow;
Studio bundles none, so it is empty). That is why a clean local run says so rather than promising the pull
request will pass. **Prefix your id with something that is yours** and it cannot bite you.

## Removing a plugin

Delete `plugins/<plugin-id>.json`. The gate accepts a deletion without resolving anything — an unmaintained
plugin must not become unremovable — and the index regenerates on merge.
