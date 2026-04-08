# heuristR

`heuristR` is an R client for Heurist databases with a session-oriented
API.

Documentation website:
<https://center-for-archaeology-and-society.github.io/heuristR/>

## Overview

`heuristR` provides a practical R interface for working with Heurist
databases from scripts, analysis workflows, and repeatable
data-management tasks. It is designed to make authentication, metadata
inspection, record retrieval, and safe scripted updates easier to manage
from R.

## What Is Heurist?

[Heurist](https://heuristnetwork.org/) is a web-based database platform
built for research projects that need flexible, relational data
structures without a custom application build. The public Heurist
startup page describes it as a system designed by researchers for
collecting, managing, analysing, visualising, exporting, publishing, and
archiving information.

For hosted use, the public Huma-Num server currently provides a database
creation flow at
[heurist.huma-num.fr/heurist/startup/](https://heurist.huma-num.fr/heurist/startup/).
New users can register there and create a first database on the server,
while existing users can create additional databases through the
administration interface after logging in.

## What heuristR Provides

The package includes:

- session and authentication helpers
- metadata access for record types, fields, and structure
- low-level wrappers around core Heurist endpoints
- high-level read helpers
- safe write helpers built around read-modify-write
- rollback helpers for reversible scripted changes

## Installation

Install the development version from GitHub with `remotes` or `pak`, or
load it locally when working from a checkout.

From GitHub:

``` r
remotes::install_github("Center-for-Archaeology-and-Society/heuristR")
```

During development from a local checkout:

``` r
devtools::load_all("heuristR")
```

## Create Your Own Heurist Database

The easiest public starting point appears to be the Huma-Num hosted
service:

1.  Visit
    [heurist.huma-num.fr/heurist/startup/](https://heurist.huma-num.fr/heurist/startup/).
2.  Register as a new user, or log in if you already have an account on
    that server.
3.  Create a database name through the startup form.
4.  Open the new database and begin defining record types and fields in
    the Design menu.

The hosted registration workflow referenced here was verified against
the public startup page on April 8, 2026. If that path changes, consult
the main [Heurist Network website](https://heuristnetwork.org/) for
current guidance.

## Local Configuration

For local development and live integration tests, create a `.Renviron`
file in the project root. The real `.Renviron` is ignored by git; only
`.Renviron.example` should be committed.

Example:

``` bash
cp .Renviron.example .Renviron
```

Then edit `.Renviron` with your own values:

``` bash
HEURISTR_TEST_BASE_URL=https://your-heurist-host.example/heurist
HEURISTR_TEST_DB=your_database_name
HEURIST_USERNAME=your_username
HEURIST_PASSWORD=your_password
```

When you run R from the package directory, `heuristR`’s live tests will
pick up that local `.Renviron` automatically.

## Basic Workflow

A typical `heuristR` session looks like this:

``` r
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

From there you can inspect structure with
[`heurist_fields()`](https://center-for-archaeology-and-society.github.io/heuristR/reference/heurist_fields.md)
and
[`heurist_structure()`](https://center-for-archaeology-and-society.github.io/heuristR/reference/heurist_structure.md),
search records with
[`heurist_find_records()`](https://center-for-archaeology-and-society.github.io/heuristR/reference/heurist_find_records.md),
and use the higher-level write helpers when you need controlled updates.

## Safe Writes

`heuristR` avoids partial destructive saves by default. High-level
helpers such as
[`heurist_patch_record()`](https://center-for-archaeology-and-society.github.io/heuristR/reference/heurist_patch_record.md)
fetch the current record, merge the requested changes client-side, and
send back a full record payload.

Each write returns a `heurist_change` object that can be rolled back
with
[`heurist_restore_change()`](https://center-for-archaeology-and-society.github.io/heuristR/reference/heurist_restore_change.md)
or
[`heurist_rollback()`](https://center-for-archaeology-and-society.github.io/heuristR/reference/heurist_rollback.md).

``` r
change <- heurist_patch_record(
  session,
  record_id = 3,
  details = list("1" = list("0" = "Updated title")),
  mode = "replace"
)

heurist_rollback(change)
```

## Documentation

Additional package documentation is available here:

- GitHub Pages site:
  <https://center-for-archaeology-and-society.github.io/heuristR/>
- Function reference:
  <https://center-for-archaeology-and-society.github.io/heuristR/reference/>
- Workflow vignette:
  <https://center-for-archaeology-and-society.github.io/heuristR/articles/archaeology-workflow.html>

## Project Status

The package includes permanent unit and live integration tests covering:

- auth/session
- metadata
- raw endpoint wrappers
- reads
- safe create/replace/patch flows
- link helpers
- rollback behavior
