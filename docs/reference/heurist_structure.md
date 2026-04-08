# Get Heurist Structure Definitions

Retrieves database structure definitions through Heurist's metadata
endpoint.

## Usage

``` r
heurist_structure(session, entity = "all")
```

## Arguments

- session:

  A `heurist_session`.

- entity:

  Structure entity name. Defaults to `"all"`.

## Value

A parsed Heurist structure payload.
