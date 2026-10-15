# Phase 14 — Erlang/OTP historical license boundaries

The 2015-06-24 OTP 18.0 release changed the project-level license from EPL to Apache-2.0.
Never infer historical file-level rights from the current main branch. Retain license files,
release tarballs, commit IDs, author notices, and third-party component licenses.

`bin/audit_otp_epoch.sh PATH TAG_OR_COMMIT` produces a provisional epoch classification.
Its classification is NOT a legal determination or a training authorization.

Evidence: https://www.erlang.org/news/86 and https://www.erlang.org/downloads.html

Next: ingest verified release tags and generate per-file SPDX reports when network access is available.
