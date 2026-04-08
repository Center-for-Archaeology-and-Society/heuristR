# Create a Heurist Session

Creates a lightweight session object for a Heurist database.

## Usage

``` r
heurist_session(base_url, database, timeout = 30)
```

## Arguments

- base_url:

  Base Heurist URL, such as `"https://heurist.huma-num.fr/heurist"`.

- database:

  Heurist database name.

- timeout:

  Request timeout in seconds.

## Value

A `heurist_session` object.
