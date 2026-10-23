#!/usr/bin/env bash
#
# resolve-cli.sh <output-file> — resolve botmaker-cli's MAIN artifact (the library) from JitPack and write its
# runtime classpath to <output-file>.
#
# EVERY RULE THIS CATALOG ENFORCES IS IN THAT ARTIFACT, not here: EntryGate (validate.yml), ListingPolicy
# (automerge.yml) and IndexCommand (index.yml) are com.botmaker.cli.catalog classes. `botmaker bot publish` and
# `botmaker plugin publish` run the same check on the author's machine, so a refusal here is one they could
# already have seen.
#
# THE VERSION IS botmaker-cli's newest GitHub Release, read at each run (2026-10-23, the maintainer's call: no
# version is stored here). github.com/<repo>/releases/latest redirects to it and skips drafts and prereleases; the
# redirect is no API call, so it needs no token and meets no rate limit. A cli release therefore reaches open pull
# requests at their next run, accepted.
#
# validate.yml runs the BASE branch's copy of this script, never the pull request's: a pull request that edits
# tools/ is not one entry file, so it never merges, and it must not choose the code its own check runs either.
set -euo pipefail

out="$1"
latest="$(curl -fsSL --retry 3 -o /dev/null -w '%{url_effective}' https://github.com/BotMakerDev/botmaker-cli/releases/latest)"
version="${latest##*/tag/}"
# A tag git and a URL both carry as is; anything else is not a release page and must not reach the pom.
[[ $latest == */tag/* && $version =~ ^[A-Za-z0-9_][A-Za-z0-9._+-]{0,99}$ ]] || {
    echo "botmaker-cli has no published release ($latest)." >&2
    exit 1
}
work="$(mktemp -d)"

cat > "$work/pom.xml" <<POM
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.botmaker.catalog</groupId>
    <artifactId>gate</artifactId>
    <version>0-SNAPSHOT</version>
    <packaging>pom</packaging>
    <repositories>
        <repository>
            <id>jitpack.io</id>
            <url>https://jitpack.io</url>
        </repository>
    </repositories>
    <dependencies>
        <dependency>
            <groupId>com.github.BotMakerDev</groupId>
            <artifactId>botmaker-cli</artifactId>
            <version>$version</version>
        </dependency>
    </dependencies>
</project>
POM

# An ABSOLUTE outputFile: a relative one resolves against the pom's basedir.
case "$out" in
    /*) ;;
    *) out="$PWD/$out" ;;
esac
mvn -B -q -f "$work/pom.xml" dependency:build-classpath -DincludeScope=runtime -Dmdep.outputFile="$out"
# The check must not be reported as missing when what is missing is its classpath.
test -s "$out"
echo "botmaker-cli $version resolved." >&2
