#!/usr/bin/env bash
#
# entry-facts.sh <pr-number> — print, as JSON, the facts com.botmaker.cli.catalog.ListingPolicy decides one open
# pull request on. Run by automerge.yml, from this repository's own main branch.
#
# EVERY FACT IS READ THROUGH THE API, AS DATA. Nothing from the pull request is checked out or executed, which is
# what makes it safe for the job running this to hold a token that can merge. A path is only ever a quoted
# variable; the policy reads paths itself and holds anything that is not one entry file.
#
# Output, beside what the policy reads, carries headSha: the merge is made with --match-head-commit, so a push
# after the check ran can never be merged on the strength of it.
set -euo pipefail

repo="${GITHUB_REPOSITORY:?}"
pr="$1"
case "$pr" in
    ''|*[!0-9]*) echo "not a pull request number: $pr" >&2; exit 2 ;;
esac

pr_json="$(gh api "repos/$repo/pulls/$pr")"
author="$(jq -r '.user.login' <<<"$pr_json")"
sha="$(jq -r '.head.sha' <<<"$pr_json")"

# Every completed `validate` run on the head commit must have succeeded, and there must be at least one. "All"
# rather than "the newest": a second job of that name can only come from a pull request that edits a workflow,
# and the policy holds that one anyway — but a verdict should not depend on that being noticed.
checks="$(gh api "repos/$repo/commits/$sha/check-runs?check_name=validate&per_page=100" --jq '
    [.check_runs[] | select(.status == "completed")] as $runs
    | ($runs | length) > 0 and ($runs | all(.conclusion == "success"))')"

changes="$(gh api --paginate "repos/$repo/pulls/$pr/files?per_page=100" \
    --jq '.[] | {path: .filename, status: .status}' | jq -s -c '.')"

# One timestamp per NEW entry the author had merged in the last 24 hours, bots and plugins alike. Pull requests
# rather than commits, because a pull request's author is a login and a commit's is only an email.
since="$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)"
recent='[]'
while read -r number merged_at; do
    [ -n "$number" ] || continue
    [ "$number" = "$pr" ] && continue
    added="$(gh api --paginate "repos/$repo/pulls/$number/files?per_page=100" --jq \
        '[.[] | select(.status == "added" and (.filename | test("^(bots|plugins)/[^/]+\\.json$")))] | length' \
        | awk '{ sum += $1 } END { print sum + 0 }')"
    for _ in $(seq 1 "$added"); do
        recent="$(jq -c --arg t "$merged_at" '. + [$t]' <<<"$recent")"
    done
done < <(gh pr list --repo "$repo" --state merged --author "$author" --search "merged:>=$since" \
    --limit 100 --json number,mergedAt --jq '.[] | "\(.number) \(.mergedAt)"')

jq -n \
    --arg author "$author" \
    --argjson checksPassed "$checks" \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg headSha "$sha" \
    --argjson changes "$changes" \
    --argjson recent "$recent" \
    '{author: $author, checksPassed: $checksPassed, now: $now, headSha: $headSha, changes: $changes,
      recentNewEntries: $recent}'
