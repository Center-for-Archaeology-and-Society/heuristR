`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

.heurist_find_file_upwards <- function(filename, start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = FALSE)

  repeat {
    candidate <- file.path(current, filename)
    if (file.exists(candidate)) {
      return(candidate)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      return(NULL)
    }
    current <- parent
  }
}

.heurist_load_local_renviron <- function() {
  renviron <- .heurist_find_file_upwards(".Renviron")
  if (!is.null(renviron)) {
    readRenviron(renviron)
  }
  invisible(renviron)
}

heurist_test_config <- function() {
  .heurist_load_local_renviron()
  list(
    base_url = Sys.getenv("HEURISTR_TEST_BASE_URL", ""),
    database = Sys.getenv("HEURISTR_TEST_DB", "")
  )
}

heurist_live_credentials <- function() {
  .heurist_load_local_renviron()
  username <- Sys.getenv("HEURIST_USERNAME", "")
  password <- Sys.getenv("HEURIST_PASSWORD", "")

  list(
    username = username,
    password = password,
    available = nzchar(username) && nzchar(password)
  )
}

skip_if_no_live_heurist <- function() {
  cfg <- heurist_test_config()
  creds <- heurist_live_credentials()
  testthat::skip_if_not(
    creds$available && nzchar(cfg$base_url) && nzchar(cfg$database),
    message = paste(
      "Live Heurist integration tests require HEURISTR_TEST_BASE_URL,",
      "HEURISTR_TEST_DB, HEURIST_USERNAME, and HEURIST_PASSWORD."
    )
  )
}

heurist_live_session <- function() {
  skip_if_no_live_heurist()

  cfg <- heurist_test_config()
  creds <- heurist_live_credentials()

  session <- heurist_session(
    base_url = cfg$base_url,
    database = cfg$database,
    timeout = 30
  )

  heurist_login(session, creds$username, creds$password)
}

heurist_stamp <- function(prefix = "heuristR test") {
  paste(prefix, format(Sys.time(), "%Y%m%d%H%M%S", tz = "UTC"))
}

heurist_find_rectype <- function(session, name) {
  hits <- Filter(function(x) identical(x$rty_Name %||% "", name), heurist_rectypes(session))
  if (!length(hits)) {
    stop(sprintf("Rectype '%s' not found", name), call. = FALSE)
  }
  hits[[1]]
}

heurist_find_field <- function(session, name) {
  hits <- Filter(function(x) identical(x$dty_Name %||% "", name), heurist_fields(session))
  if (!length(hits)) {
    stop(sprintf("Field '%s' not found", name), call. = FALSE)
  }
  hits[[1]]
}

heurist_delete_if_exists <- function(session, change) {
  if (is.null(change)) {
    return(invisible(NULL))
  }
  try(heurist_rollback_change(change), silent = TRUE)
  invisible(NULL)
}
