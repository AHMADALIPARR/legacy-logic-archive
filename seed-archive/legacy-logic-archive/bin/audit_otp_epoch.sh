#!/bin/sh
set -eu
if [ "$#" -ne 2 ]; then echo 'Usage: audit_otp_epoch.sh REPOSITORY_PATH TAG_OR_COMMIT' >&2; exit 2; fi
repo=$1; revision=$2
sha=$(git -C "$repo" rev-parse --verify "${revision}^{commit}") || exit 1
version=$(git -C "$repo" show "$sha:OTP_VERSION" 2>/dev/null | head -n 1 || true)
case "$version" in
  '') case "$revision" in OTP-*) version=${revision#OTP-};; esac;;
esac
major=$(printf '%s' "$version" | sed -n 's/^\([0-9][0-9]*\).*/\1/p')
case "$major" in
  '') epoch=unknown; license=review_required;;
  *) if [ "$major" -lt 18 ]; then epoch=pre_18; license=Erlang-Public-License; else epoch=otp_18_plus; license=Apache-2.0; fi;;
esac
printf 'commit\tversion\tepoch\tdefault_license\tcomponent_review\n'
printf '%s\t%s\t%s\t%s\t%s\n' "$sha" "${version:-unknown}" "$epoch" "$license" required
