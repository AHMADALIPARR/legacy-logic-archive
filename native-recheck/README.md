# Native recheck (Phase 17)

The native recheck of the nine-snapshot corpus, plus the OpenSSL
1.0.2c collector. Every Phase 16 parser outcome is classified against
a fresh native run — a failure is evidence, not an error to paper over.

## What is inside

- `bin/fetch-corpus.pl` — The nine-target corpus fetcher (OTP 17.5,
  OTP 18.0, SWI-Prolog 7.2.0, GNU Prolog 1.4.4, Elixir 1.0.5,
  Phoenix 1.0.0, GNAT 4.2.0, SPARK 0.3 draft, UCSD OS).
- `bin/fetch.pl` — The separate single-target OpenSSL 1.0.2c collector.
- `bin/normalize.pl`, `bin/report.pl`,
  `bin/verify-native-recheck.pl`, `bin/verify-source.pl` — Normalize,
  report, and verify (gates include
  `strict_jsonl_deliverables`, `baseline_failure_classification`,
  `native_source_and_artifact_hashes`, `parser_aggregate`,
  `offline_source_replay`, `baseline_ledgers_preserved`,
  `runtime_hashes`, `unmodified_openssl_failure_visible`).
- `bin/recheck-parsers.sh` — The recheck pipeline: prepare parser
  inputs, profile operators, build the operator registry, Prolog
  isolated recheck, Erlang 18 recheck, Elixir 1.0.5 recheck, Ada
  recheck, Prolog fixtures, then classify every outcome.
- `bin/recheck-prolog-isolated.pl`, `bin/recheck-erlang18.sh`,
  `bin/recheck-elixir105.sh`, `bin/recheck-ada.pl` — The per-language
  recheckers.
- `bin/convert-erlang18.pl`, `bin/convert-elixir105.pl`,
  `bin/prepare-parser-inputs.pl`, `bin/profile-operators.pl`,
  `bin/classify-parsers.pl`, `bin/cumulative-totals.pl`,
  `bin/apply-source-policy.pl`, `bin/audit-jsonl.pl`,
  `bin/record-builds.pl` — Converters, input prep, classification,
  totals, policy, audit, build records.
- `bin/build-openssl.sh`, `bin/build-otp18.sh`,
  `bin/build-historical-stack.sh`, `bin/runtime-lock.sh`,
  `bin/with-tools.sh`, `bin/package.sh`, `bin/replay.pl` — Historical
  builders, runtime lock, toolchain delegation, packaging, replay.
- `native/` — Prolog operator registry and parser, Erlang/Elixir
  recheck sources, Prolog context.
- `tests/` — Prolog fixtures (`prolog-valid.pl`,
  `prolog-invalid.pl`, `prolog-isolation.pl`) and the fixture generator.
- `patches/openssl-cms-historical-time.patch` — The OpenSSL CMS test
  time patch, kept as a separate derivative. The unmodified failure
  stays visible as evidence.

## Run

```sh
cd native-recheck && sh bin/recheck-parsers.sh && perl bin/report.pl && perl bin/verify-native-recheck.pl
```
