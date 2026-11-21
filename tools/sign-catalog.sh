#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 LiQiyeDev
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
#
# Writes catalog.signed.json, the file Studio reads (2026-11-21):
#
#   {"payload": base64(catalog.json), "key": <key id>, "signature": base64(Ed25519 over catalog.json's bytes)}
#
# One file holds the payload and its signature, so the raw CDN never serves a catalog with another commit's
# signature. The key id is the first 16 hex digits of the SHA-256 of the public key's DER form; botmaker-core keeps
# the public keys it trusts in com/botmaker/core/sharing/catalog-keys.txt.
#
# Usage: tools/sign-catalog.sh [catalog.json] [catalog.signed.json], the private key (PEM) in $CATALOG_SIGNING_KEY
# (tools/new-signing-key.sh makes it). Nothing is written when the signed file already holds this catalog under this
# key, so the nightly run commits nothing new, and a new key signs again at the next run.
set -euo pipefail

catalog=${1:-catalog.json}
signed=${2:-catalog.signed.json}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if [[ -z ${CATALOG_SIGNING_KEY:-} ]]; then
  echo "CATALOG_SIGNING_KEY is not set: run tools/new-signing-key.sh once." >&2
  exit 1
fi
(umask 077 && printf '%s\n' "$CATALOG_SIGNING_KEY" >"$work/key.pem")
openssl pkey -in "$work/key.pem" -pubout -out "$work/public.pem"
key=$(openssl pkey -pubin -in "$work/public.pem" -outform DER | sha256sum | cut -c1-16)

base64 -w0 "$catalog" >"$work/payload"
if [[ -f $signed ]] && [[ "$(jq -r .key "$signed")" == "$key" ]] \
    && [[ "$(jq -r .payload "$signed")" == "$(cat "$work/payload")" ]]; then
  echo "$signed already signs $catalog with key $key."
  exit 0
fi

openssl pkeyutl -sign -inkey "$work/key.pem" -rawin -in "$catalog" -out "$work/signature.bin"
# Checked before it is written: a key that cannot sign fails here, not in every Studio.
openssl pkeyutl -verify -pubin -inkey "$work/public.pem" -rawin -in "$catalog" -sigfile "$work/signature.bin" >/dev/null
base64 -w0 "$work/signature.bin" >"$work/signature"
# --rawfile, not --arg: a catalog's base64 outgrows one command-line argument.
jq -n --rawfile payload "$work/payload" --arg key "$key" --rawfile signature "$work/signature" \
  '{payload: $payload, key: $key, signature: $signature}' >"$signed"
echo "Signed $catalog with key $key."
