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

## Local Configuration

For local development and live integration tests, create a `.Renviron` file in
the project root. The real `.Renviron` is ignored by git; only
`.Renviron.example` should be committed.

Example:

```bash
cp .Renviron.example .Renviron
```

Then edit `.Renviron` with your own values:

```bash
HEURISTR_TEST_BASE_URL=https://your-heurist-host.example/heurist
HEURISTR_TEST_DB=your_database_name
HEURIST_USERNAME=your_username
HEURIST_PASSWORD=your_password
```

When you run R from the package directory, `heuristR`'s live tests will pick up
that local `.Renviron` automatically.

## Quick Start

```r
library(heuristR)

session <- heurist_session(
  base_url = Sys.getenv("HEURISTR_TEST_BASE_URL"),
  database = Sys.getenv("HEURISTR_TEST_DB")
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
