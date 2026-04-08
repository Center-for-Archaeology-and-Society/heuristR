#' Create a Heurist Session
#'
#' Creates a lightweight session object for a Heurist database.
#'
#' @param base_url Base Heurist URL, such as
#'   `"https://heurist.huma-num.fr/heurist"`.
#' @param database Heurist database name.
#' @param timeout Request timeout in seconds.
#'
#' @return A `heurist_session` object.
#' @export
heurist_session <- function(base_url, database, timeout = 30) {
  stopifnot(is.character(base_url), length(base_url) == 1, nzchar(base_url))
  stopifnot(is.character(database), length(database) == 1, nzchar(database))
  stopifnot(is.numeric(timeout), length(timeout) == 1, timeout > 0)

  session <- list(
    base_url = sub("/+$", "", base_url),
    database = database,
    timeout = timeout,
    cookie_path = tempfile("heuristR-cookies-"),
    authenticated = FALSE,
    current_user = NULL
  )

  class(session) <- "heurist_session"
  session
}

#' Log In to Heurist
#'
#' Authenticates a `heurist_session` using Heurist's login controller and
#' preserves session cookies for subsequent requests.
#'
#' @param session A `heurist_session`.
#' @param username Heurist username.
#' @param password Heurist password.
#' @param session_type Heurist session type. Defaults to `"remember"`.
#'
#' @return An authenticated `heurist_session`.
#' @export
heurist_login <- function(session, username, password, session_type = "remember") {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(username), length(username) == 1, nzchar(username))
  stopifnot(is.character(password), length(password) == 1, nzchar(password))

  req <- .heurist_request(session, "/hserv/controller/usr_info.php") |>
    httr2::req_body_form(
      db = session$database,
      a = "login",
      username = username,
      password = password,
      session_type = session_type
    )

  resp <- httr2::req_perform(req)
  payload <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  if (!identical(payload$status, "ok")) {
    cli::cli_abort(c(
      "Heurist login failed.",
      "x" = .heurist_message(payload)
    ))
  }

  verify <- .heurist_get(
    session,
    "/hserv/controller/usr_info.php",
    query = list(db = session$database, a = "verify_credentials")
  )

  verified <- httr2::resp_body_json(verify, simplifyVector = FALSE)
  if (!identical(verified$status, "ok") || !identical(verified$data, TRUE)) {
    cli::cli_abort("Heurist login did not establish an authenticated session.")
  }

  session$authenticated <- TRUE
  session$current_user <- payload$data$currentUser %||% NULL

  cli::cli_inform(c(
    "Authenticated with Heurist.",
    "i" = paste("Database:", session$database)
  ))

  session
}

#' Log Out of Heurist
#'
#' Logs out an authenticated `heurist_session`.
#'
#' @param session A `heurist_session`.
#'
#' @return The updated `heurist_session`.
#' @export
heurist_logout <- function(session) {
  stopifnot(inherits(session, "heurist_session"))

  req <- .heurist_request(session, "/hserv/controller/usr_info.php") |>
    httr2::req_body_form(
      db = session$database,
      a = "logout"
    )

  httr2::req_perform(req)
  session$authenticated <- FALSE
  session$current_user <- NULL
  session
}
