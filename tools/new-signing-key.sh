#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 LiQiyeDev
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#
# Makes the catalog's Ed25519 signing key (2026-11-21): stores the private key as the repository secret
# CATALOG_SIGNING_KEY, which index.yml's Sign step reads, and prints the public key, one line of botmaker-core's
# com/botmaker/core/sharing/catalog-keys.txt. The private key is never printed and is deleted on exit; a key that
# is lost is replaced by adding a new public key to the core and releasing it first, then running this again: the next
# index run signs with the new key.
#
# Usage: tools/new-signing-key.sh [owner/repo], by a maintainer whose gh login may set the repository's secrets.
set -euo pipefail

repo=${1:-BotMakerDev/botmaker-catalog}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
umask 077

openssl genpkey -algorithm ed25519 -out "$work/key.pem"
gh secret set CATALOG_SIGNING_KEY --repo "$repo" <"$work/key.pem"
echo "CATALOG_SIGNING_KEY is set on $repo. Public key, for botmaker-core's catalog-keys.txt:"
openssl pkey -in "$work/key.pem" -pubout -outform DER | base64 -w0
echo
