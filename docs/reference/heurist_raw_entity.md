# Call Heurist Entity Endpoint Directly

Low-level wrapper around `entityScrud.php`.

## Usage

``` r
heurist_raw_entity(session, action, entity, query = list())
```

## Arguments

- session:

  A `heurist_session`.

- action:

  Entity action.

- entity:

  Entity name.

- query:

  Additional query parameters.

## Value

Parsed JSON response.
