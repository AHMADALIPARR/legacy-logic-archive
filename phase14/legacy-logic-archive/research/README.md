# Phase 3 — NATS, Erlang/OTP and Elixir

`bin/git_archive.sh list` lists curated upstreams.

`bin/git_archive.sh fetch nats.ex` mirrors a repository into `git/` and records its exact HEAD SHA in `metadata/git_revisions.tsv`. Requires network access and Git. No remote code is executed. Mirroring can be large (especially OTP). Fetch only repositories whose access and licensing have been reviewed; repository licenses are not necessarily uniform for every file.

The catalog is discovery metadata, not proof that sources were downloaded. Do not train on or redistribute unreviewed sources. `git/` is excluded from this release unless fetched locally. Avoid running build scripts from unknown repositories.
