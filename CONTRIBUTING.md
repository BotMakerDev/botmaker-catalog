# Contributing

## Listing a bot or a plugin

A pull request that adds, extends or removes an entry is made by `botmaker bot publish`, `botmaker plugin
publish` or their `unpublish` (see `README.md`). A machine checks it and merges it. It needs no contributor
agreement: an entry names your repository and its releases, and your bot or plugin stays yours, under the license
you chose. `botmaker bot yank` and `botmaker plugin yank` open the same kind of pull request, and an entry's
shape is in `schema/entry.json`.

## Security advisories

Only an admin files an advisory (`botmaker advisory new`), so a pull request adding or changing a file of
`advisories/` from anyone else is refused. To report a problem in a listed bot or plugin, open an issue here
instead; an admin files the advisory.

## Changing the catalog itself

A pull request that changes anything else, such as the tools or `publishers.json`, is reviewed by hand. Its author
signs the BotMaker Contributor License Agreement first, as in every other BotMaker repository: BotMaker is
LiQiyeDev's, published under PolyForm Noncommercial 1.0.0 (`LICENSE`) and also licensed commercially. Ask for the
agreement in the pull request. You keep the copyright of what you write. The agreement lets LiQiyeDev license it
under any terms, commercial ones included.
