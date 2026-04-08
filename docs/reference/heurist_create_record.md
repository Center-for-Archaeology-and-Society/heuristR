# Create a Heurist Record

Creates a new record using a Heurist record type ID and a details
payload.

## Usage

``` r
heurist_create_record(
  session,
  rectype_id,
  details,
  title = NULL,
  owner_ugrp_id = NULL,
  non_owner_visibility = NULL
)
```

## Arguments

- session:

  A `heurist_session`.

- rectype_id:

  Record type ID.

- details:

  Named list of Heurist detail values.

- title:

  Optional title override.

- owner_ugrp_id:

  Optional owner group ID.

- non_owner_visibility:

  Optional non-owner visibility.

## Value

A `heurist_change` object containing the create response.
