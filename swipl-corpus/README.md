# SWI-Prolog corpus (Phase 16)

The SWI-Prolog submodule corpus: all 34 first-level gitlinks of
SWI-Prolog 7.2.0, locked at the commits pinned by the parent
superproject (parent `6442d29038b0e1ed413e2f1dfe8086b812777e7d`),
fetched, and assembled into a buildable SWI-Prolog 7.2.0 — plus the
native parsers and the locked toolchain that read the corpus.

Nested gitlinks below the 34 are not fetched. This is a verified
first-level corpus, not a complete dependency closure.

## What is inside

- `bin/lock-submodules.pl`, `bin/fetch.pl` — Lock the 34 gitlinks from
  the parent superproject, then fetch each at its pinned commit.
- `bin/assemble-swi.pl`, `bin/build-swi.sh`, `bin/rebuild-swi.sh` —
  Assemble the superproject plus submodules and build SWI-Prolog 7.2.0.
- `bin/build-otp18.sh` — Build OTP 18.0.
- `bin/normalize.pl`, `bin/report.pl`, `bin/verify.pl` — Normalize,
  report, and independently verify (gates include
  `exact_pinned_swi_dependency_closure`,
  `phase15_manifests_preserved`,
  `native_toolchain_package_hashes`,
  `native_parser_source_and_artifact_links`,
  `historical_swi_executable_examples`).
- `bin/attach-native.pl` — Attach native parser overlays to inventory
  records.
- `bin/apply-license-review.pl` — Manual license-review overrides
  (including the two Groupe Bull name-use-clause files).
- `bin/package.sh`, `bin/replay.pl`, `bin/export-training.pl` —
  Package, offline replay, guarded training export.
- `bin/apt-local.sh`, `bin/check-debian-index.pl`,
  `bin/toolchain-lock.pl`, `bin/with-tools.sh`, `bin/native/` —
  Toolchain wrappers and the signed Debian package-index lock. Every
  build tool must match the signed index SHA-256.
- `native/` — Native parsers: SWI `read_term` (Prolog), `epp_dodger`
  (Erlang), `Code.string_to_quoted` (Elixir), GNAT syntax-only (Ada).
- `tests/` — Fixtures, adversarial cases, `native-fixtures.t`.

Three files in `bin/` are assistant-reconstructed, not user-supplied
originals, and say so in-file and in their commit: `normalize.pl`,
`report.pl`, `structure.pm`.

## Run

```sh
cd swipl-corpus && perl bin/normalize.pl && perl bin/report.pl && perl bin/verify.pl
```

The verifier expects `../historical-corpus/` to be present.
