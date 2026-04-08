# Patch a Heurist Record Safely

Performs a safe read-modify-write update. Existing details are fetched,
normalized, merged with the supplied changes, and then written back as a
full record payload to avoid accidental data loss.

## Usage

``` r
heurist_patch_record(
  session,
  record_id,
  details,
  mode = c("replace", "append")
)
```

## Arguments

- session:

  A `heurist_session`.

- record_id:

  Record ID.

- details:

  Named list of detail changes.

- mode:

  Merge mode: `"replace"` or `"append"`.

## Value

A `heurist_change` object.
