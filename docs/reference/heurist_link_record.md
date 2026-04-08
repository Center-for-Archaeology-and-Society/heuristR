# Link a Heurist Record Through a Pointer Field

Safely adds or replaces a pointer field value on an existing record.

## Usage

``` r
heurist_link_record(
  session,
  source_record_id,
  detail_type_id,
  target_record_id,
  append = FALSE
)
```

## Arguments

- session:

  A `heurist_session`.

- source_record_id:

  Source record ID.

- detail_type_id:

  Pointer field detail type ID.

- target_record_id:

  Target record ID.

- append:

  If `TRUE`, append a new value. If `FALSE`, replace the field.

## Value

A `heurist_change` object.
