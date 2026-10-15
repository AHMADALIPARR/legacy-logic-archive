# NASA Prolog discovery extension

NASA's public GitHub organization lists Prolog among languages, but no original NASA legacy Prolog source has yet been verified for inclusion. The NASA Open-Source-Catalog is a verified source of project metadata; its contents are not necessarily Prolog programs.

1. Review the NASA catalog metadata and candidate repository licenses.
2. Fetch the public catalog using `bin/git_archive.sh fetch NASA-Open-Source-Catalog` only after review.
3. Inspect a local mirror with `bin/nasa_prolog_scan.sh` (catalog metadata is not executable Prolog).
4. Identify actual `.pl`, `.pro`, and `.prolog` files in candidate repos and confirm authorship and era.
5. Preserve SHA-256 hashes, source revisions, and explicit rights decisions before ingestion.

NASA code is not automatically public domain; some releases have access limitations. No restricted sources should be fetched.
