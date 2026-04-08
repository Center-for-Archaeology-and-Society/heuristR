# heuristR

`heuristR` is an R client for Heurist databases with a session-oriented API.

Documentation website: <https://center-for-archaeology-and-society.github.io/heuristR/>

## Overview

`heuristR` provides a practical R interface for working with Heurist databases
from scripts, analysis workflows, and repeatable data-management tasks. It is
designed to make authentication, metadata inspection, record retrieval, and
safe scripted updates easier to manage from R.

The package is especially useful when you want to move beyond manual work in
the Heurist web interface and begin building reproducible R workflows for:

- metadata inspection and schema exploration
- record retrieval for analysis or reporting
- controlled creation of new records
- safer scripted updates that avoid destructive partial saves
- reversible data maintenance with rollback support

## What Is Heurist?

[Heurist](https://heuristnetwork.org/) is a web-based database platform built
for research projects that need flexible, relational data structures without a
custom application build. The public Heurist startup page describes it as a
system designed by researchers for collecting, managing, analysing,
visualising, exporting, publishing, and archiving information.

For hosted use, the public Huma-Num server currently provides a database
creation flow at [heurist.huma-num.fr/heurist/startup/](https://heurist.huma-num.fr/heurist/startup/).
New users can register there and create a first database on the server, while
existing users can create additional databases through the administration
interface after logging in.

## What heuristR Provides

The package includes:

- session and authentication helpers
- metadata access for record types, fields, and structure
- low-level wrappers around core Heurist endpoints
- high-level read helpers
- safe write helpers built around read-modify-write
- rollback helpers for reversible scripted changes

Most users will spend most of their time with the higher-level helpers such as
`heurist_login()`, `heurist_rectypes()`, `heurist_find_records()`,
`heurist_get_record()`, `heurist_create_record()`, and
`heurist_patch_record()`. The low-level wrappers are still available when you
need to inspect or debug the raw Heurist payloads.

## Installation

Install the development version from GitHub with `remotes` or `pak`, or load it
locally when working from a checkout.

From GitHub:

```r
remotes::install_github("Center-for-Archaeology-and-Society/heuristR")
```

During development from a local checkout:

```r
devtools::load_all("heuristR")
```

After installation, load the package as usual:

```r
library(heuristR)
```

## Create Your Own Heurist Database

The easiest public starting point is the Huma-Num hosted service:

1. Visit [heurist.huma-num.fr/heurist/startup/](https://heurist.huma-num.fr/heurist/startup/).
2. Register as a new user, or log in if you already have an account on that server.
3. Create a database name through the startup form.
4. Open the new database and begin defining record types and fields in the Design menu.

The hosted registration workflow referenced here was verified against the
public startup page on April 8, 2026. If that path changes, consult the main
[Heurist Network website](https://heuristnetwork.org/) for current guidance.

## Local Configuration

For local development and live integration tests, create a `.Renviron` file in
the project root. Do not commit your own `.Renviron` file or any file that
contains live credentials to a git repository.

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

## Authentication and Sessions

`heuristR` separates session creation from login:

1. `heurist_session()` creates a client object with the base URL, database
   name, timeout, and cookie storage.
2. `heurist_login()` uses that client to authenticate and retain the returned
   session cookies.

That separation keeps configuration distinct from authentication and makes it
possible to construct a session object before logging in.

A typical setup looks like this:

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
```

If you prefer a more compact mental model, you can think of this as “create the
client, then authenticate the client.”

## Basic Workflow

A typical `heuristR` session looks like this:

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

From there you can inspect structure with `heurist_fields()` and
`heurist_structure()`, search records with `heurist_find_records()`, and use
the higher-level write helpers when you need controlled updates.

The examples below are illustrative and may need to be adapted to your own
Heurist database structure, record types, field IDs, and permissions.

## Inspect Database Structure

Before writing automation against a Heurist database, it is usually helpful to
inspect the available record types and field definitions.

```r
rectypes <- heurist_rectypes(session)
fields <- heurist_fields(session)
structure <- heurist_structure(session)
```

Typical use cases include:

- finding the exact name of a record type such as `Place` or `Site`
- locating the numeric field ID for a pointer field or title field
- understanding how a project database models people, places, objects, or events

If you need direct access to the underlying structure response, use the
lower-level metadata wrapper:

```r
raw_structure <- heurist_raw_entity(
  session,
  list(a = "structure", entity = "all")
)
```

## Read Records

There are two common read patterns: fetch a known record by ID, or search for a
set of records.

Fetch a single record:

```r
record <- heurist_get_record(session, 3)
```

Search for records using Heurist query syntax:

```r
sites <- heurist_find_records(
  session,
  q = "t:Site sortby:-m"
)
```

Another example using a fictional thematic query:

```r
late_sites <- heurist_find_records(
  session,
  q = 't:Site "Late Archaic" sortby:-m'
)
```

If you want the raw endpoint response rather than the higher-level parsed helper:

```r
raw_records <- heurist_raw_record_output(
  session,
  list(q = "t:Site", format = "json")
)
```

## Create Records

New records can be created with `heurist_create_record()`. For example, the
following illustrative example creates a fictional `Place` record:

```r
change_create <- heurist_create_record(
  session,
  rectype = "Place",
  details = list(
    "1" = list("0" = "North Ridge Wash")
  )
)
```

The returned object is a `heurist_change`, which includes enough information to
support rollback later if needed.

```r
new_record_id <- change_create$record_id
```

## Update Records Safely

Direct Heurist save operations can be destructive if you send incomplete
payloads. `heuristR` avoids that by using a read-modify-write approach in
`heurist_patch_record()`.

Example:

```r
change_patch <- heurist_patch_record(
  session,
  record_id = 42,
  details = list(
    "1" = list("0" = "Updated Site Title")
  ),
  mode = "replace"
)
```

This helper first fetches the existing record, merges your requested change in
R, and then submits a full replacement payload back to Heurist.

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

If you need a full explicit replacement rather than a merge-style patch, use
`heurist_replace_record()`.

```r
change_replace <- heurist_replace_record(
  session,
  record_id = 42,
  details = list(
    "1" = list("0" = "Replacement title")
  )
)
```

## Link Related Records

Heurist databases often use resource pointer fields to connect records. For
that case, `heurist_link_record()` provides a clearer workflow than manually
constructing all the detail payloads yourself.

```r
change_link <- heurist_link_record(
  session,
  record_id = 108,
  field_id = 1108,
  target_record_id = 42
)
```

That pattern is useful for examples such as:

- linking an object to a place
- linking a person to an organization
- linking a site to a locality or region record

## Rollback and Reversible Workflows

One of the most useful features of `heuristR` is that the high-level write
helpers return change objects that can be undone.

```r
heurist_rollback(change_create)
heurist_rollback(change_patch)
heurist_rollback(change_link)
```

This is especially helpful when you are:

- testing a script against a staging database
- validating field mappings
- prototyping a cleanup or migration workflow
- making scripted edits you may need to reverse quickly

## Low-Level Endpoint Access

If you need raw access to the underlying Heurist controllers, the package also
provides low-level wrappers.

```r
raw_read <- heurist_raw_record_output(session, list(q = "t:Site"))
raw_edit <- heurist_raw_record_edit(session, list(a = "delete", ids = "9999"))
raw_meta <- heurist_raw_entity(session, list(a = "structure", entity = "all"))
```

These are helpful for:

- debugging request payloads
- inspecting server responses directly
- prototyping new higher-level helpers

## Documentation

Additional package documentation is available here:

- GitHub Pages site: <https://center-for-archaeology-and-society.github.io/heuristR/>
- Function reference: <https://center-for-archaeology-and-society.github.io/heuristR/reference/>
- Workflow vignette: <https://center-for-archaeology-and-society.github.io/heuristR/articles/archaeology-workflow.html>

## Project Status

The package includes permanent unit and live integration tests covering:

- auth/session
- metadata
- raw endpoint wrappers
- reads
- safe create/replace/patch flows
- link helpers
- rollback behavior
