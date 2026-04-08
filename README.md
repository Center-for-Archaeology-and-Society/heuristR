# heuristR

`heuristR` is an R client for Heurist databases with a session-oriented API.

## What Is Heurist?

[Heurist](https://heuristnetwork.org/) is a web-based database platform built
for research projects that need flexible, relational data structures without a
custom application build. The public Heurist startup page describes it as a
system designed by researchers for collecting, managing, analysing,
visualising, exporting, publishing, and archiving information.

For hosted use, the public Huma-Num server currently provides a database
creation flow at [heurist.huma-num.fr/heurist/startup/](https://heurist.huma-num.fr/heurist/startup/).
Based on that page, new users can register there and create their first
database on the server, while existing users can create additional databases
through the administration interface after logging in.

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

## Create Your Own Heurist Database

The easiest public starting point appears to be the Huma-Num hosted service:

1. Visit [heurist.huma-num.fr/heurist/startup/](https://heurist.huma-num.fr/heurist/startup/).
2. Register as a new user, or log in if you already have an account on that server.
3. Create a database name through the startup form.
4. Open the new database and begin defining record types and fields in the Design menu.

This README is based on the public startup flow available on April 8, 2026. If
that hosted registration path changes, check the main
[Heurist Network website](https://heuristnetwork.org/) for the current guidance.

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
