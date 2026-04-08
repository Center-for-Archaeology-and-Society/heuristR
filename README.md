# heuristR

`heuristR` is an R client for Heurist databases with a session-oriented API.

It provides:

- session and authentication helpers
- metadata access for record types, fields, and structure
- low-level wrappers around core Heurist endpoints
- high-level read helpers
- safe write helpers built around read-modify-write
- rollback helpers for reversible scripted changes

## Install During Development

```r
devtools::load_all("heuristR")
```

## Quick Start

```r
library(heuristR)

session <- heurist_session(
  base_url = "https://heurist.huma-num.fr/h7-alpha",
  database = "rbisc_dissertation"
)

session <- heurist_login(
  session,
  username = Sys.getenv("HEURIST_USERNAME"),
  password = Sys.getenv("HEURIST_PASSWORD")
)

rectypes <- heurist_rectypes(session)
record <- heurist_get_record(session, 3)
```

## Safe Writes

`heuristR` avoids partial destructive saves by default. High-level helpers such
as `heurist_patch_record()` fetch the current record, merge the requested
changes client-side, and send back a full record payload.

Each write returns a `heurist_change` object that can be rolled back with
`heurist_restore_change()` or `heurist_rollback()`.

```r
change <- heurist_patch_record(
  session,
  record_id = 3,
  details = list("1" = list("0" = "Updated title")),
  mode = "replace"
)

heurist_rollback(change)
```

## Status

The package includes permanent unit and live integration tests covering:

- auth/session
- metadata
- raw endpoint wrappers
- reads
- safe create/replace/patch flows
- link helpers
- rollback behavior
