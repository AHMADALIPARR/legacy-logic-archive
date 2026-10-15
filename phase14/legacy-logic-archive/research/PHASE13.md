# Phase 13: executable source ingestion

This release retains Phase 11 discovery data and adds a five-repository source ingestion pipeline.

Run `./bin/ingest_phase13.sh list` then `./bin/ingest_phase13.sh fetch Elixir` on a machine with GitHub access. Repeat for SWI-Prolog, Erlang-OTP, GNAT-GCC, UCSD-p-System.

The script clones a complete Git mirror, records its HEAD commit, exports a byte-preserving Git snapshot (tar), hashes it, and logs counts and rights-review status. It does not declare training eligibility. License notices must be reviewed at the file and dependency level.

Full Git mirrors can be very large, especially GCC. Disk space and network bandwidth are the operator's responsibility.

Current build environment lacks external DNS access: no upstream downloads have been performed here.
