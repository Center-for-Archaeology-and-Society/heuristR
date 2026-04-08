`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

heurist_test_config <- function() {
  list(
    base_url = Sys.getenv("HEURISTR_TEST_BASE_URL", "https://heurist.huma-num.fr/h7-alpha"),
    database = Sys.getenv("HEURISTR_TEST_DB", "rbisc_dissertation"),
    env_file = Sys.getenv("HEURISTR_TEST_ENV_FILE", "/mnt/storage/Web/CAS/.heurist.huma.env")
  )
}

heurist_read_env_file <- function(path) {
  if (!file.exists(path)) {
    return(list())
  }

  lines <- readLines(path, warn = FALSE)
  out <- list()
  for (line in lines) {
    line <- trimws(line)
    if (line == "" || startsWith(line, "#") || !grepl("=", line, fixed = TRUE)) {
      next
    }
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    out[[trimws(parts[1])]] <- trimws(paste(parts[-1], collapse = "="))
  }
  out
}

heurist_live_credentials <- function() {
  cfg <- heurist_test_config()
  env <- heurist_read_env_file(cfg$env_file)

  username <- Sys.getenv("HEURIST_USERNAME", env$USERNAME %||% "")
  password <- Sys.getenv("HEURIST_PASSWORD", env$PASSWORD %||% "")

  list(
    username = username,
    password = password,
    available = nzchar(username) && nzchar(password)
  )
}

skip_if_no_live_heurist <- function() {
  creds <- heurist_live_credentials()
  testthat::skip_if_not(
    creds$available,
    message = "Live Heurist credentials not available for integration tests."
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
