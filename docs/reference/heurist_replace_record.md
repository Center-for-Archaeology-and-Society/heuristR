# Replace a Heurist Record

Replaces a record with the supplied full payload. This is a low-level
full-save helper and should be used carefully.

## Usage

``` r
heurist_replace_record(
  session,
  record_id,
  rectype_id,
  details,
  owner_ugrp_id,
  non_owner_visibility,
  url = NULL,
  scratch_pad = NULL,
  title = NULL
)
```

## Arguments

- session:

  A `heurist_session`.

- record_id:

  Record ID.

- rectype_id:

  Record type ID.

- details:

  Full Heurist details list to save.

- owner_ugrp_id:

  Owner group ID.

- non_owner_visibility:

  Non-owner visibility value.

- url:

  Optional URL value.

- scratch_pad:

  Optional scratch pad value.

- title:

  Optional title override.

## Value

A `heurist_change` object.
