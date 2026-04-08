# Log In to Heurist

Authenticates a `heurist_session` using Heurist's login controller and
preserves session cookies for subsequent requests.

## Usage

``` r
heurist_login(session, username, password, session_type = "remember")
```

## Arguments

- session:

  A `heurist_session`.

- username:

  Heurist username.

- password:

  Heurist password.

- session_type:

  Heurist session type. Defaults to `"remember"`.

## Value

An authenticated `heurist_session`.
