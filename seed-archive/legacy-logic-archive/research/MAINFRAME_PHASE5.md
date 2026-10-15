# Phase 5 — Mainframe and statistical computing

Scope: IBM MVS JCL, COBOL and COBOL II dialect evidence, DFSORT/ICEGENER/ICETOOL, Modula-2, SAS.

## Provenance caveats
- MVS 3.8 examples are not automatically IBM COBOL II. Record dialect from compiler headers, manuals, and program syntax; do not mislabel.
- IBM DFSORT ICE utilities are proprietary product features; archive public documentation links and rights-cleared examples, not copyrighted product binaries.
- GNU Modula-2 in GCC is a modern open-source implementation, not an original 1980s compiler. ADW Modula-2 is freeware but some RTL sources were removed for copyright reasons.
- SAS examples and macros are not the proprietary SAS runtime.
- No actual external repository has been downloaded in this package.

## Discovery and metadata fields
Family, source URL, commit SHA, retrieval UTC, file SHA-256, declared license, rights review, dialect, encoding, record format (FB/VB), EBCDIC code page, JCL DD names, dataset names (redacted), PROC and EXEC references, COBOL divisions, COPYBOOK imports, CICS/IMS/DB2 references, SAS DATA/PROC/macro dependencies, Modula-2 DEFINITION/IMPLEMENTATION imports, and execution validation status.

## Archive workflow
1. Review license and security of each repository.
2. `bin/git_archive.sh fetch MVS3.8` (requires internet).
3. Save immutable commit revision and calculate per-file checksums.
4. Parse only inert text, never execute untrusted JCL or shell payloads.
5. Use an isolated Hercules environment only with properly licensed system images.

## Official references
- https://www.ibm.com/support/pages/dfsort
- https://www.modula2.org/adwm2/
- https://github.com/sassoftware/sas-code-examples
