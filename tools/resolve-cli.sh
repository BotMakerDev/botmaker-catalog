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
# THE VERSION IS tools/botmaker-cli.version, one line, and it is pinned rather than floating: a verdict must
# not change under a pull request that is already open. An admin bumps it in a commit of its own.
#
# validate.yml runs the BASE branch's copy of this script, never the pull request's: a pull request that edits
# tools/ is not one entry file, so it never merges, and it must not choose the code its own check runs either.
set -euo pipefail

out="$1"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(tr -d '[:space:]' < "$root/tools/botmaker-cli.version")"
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
