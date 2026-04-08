#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(heuristR)
})

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

args <- commandArgs(trailingOnly = FALSE)
script_arg <- sub("^--file=", "", args[grep("^--file=", args)][1] %||% "verify_safe_writes.R")
script_dir <- dirname(normalizePath(script_arg))
env_file <- file.path(dirname(dirname(script_dir)), "..", ".heurist.huma.env")

read_env_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  values <- list()
  for (line in lines) {
    trimmed <- trimws(line)
    if (trimmed == "" || startsWith(trimmed, "#") || !grepl("=", trimmed, fixed = TRUE)) {
      next
    }
    parts <- strsplit(trimmed, "=", fixed = TRUE)[[1]]
    values[[trimws(parts[1])]] <- trimws(paste(parts[-1], collapse = "="))
  }
  values
}

env <- read_env_file(env_file)
session <- heurist_session(
  base_url = "https://heurist.huma-num.fr/heurist",
  database = "jalli_coalbed"
)
session <- heurist_login(session, env$USERNAME, env$PASSWORD)

before <- heurist_get_record(session, 3)
change <- heurist_link_record(session, 3, 238, 53501, append = FALSE)
after <- heurist_get_record(session, 3)
rollback <- heurist_rollback(change)
restored <- heurist_get_record(session, 3)

cat("Before details:\n")
str(before$records[[1]]$details)
cat("\nAfter details:\n")
str(after$records[[1]]$details)
cat("\nRestored details:\n")
str(restored$records[[1]]$details)
cat("\nRollback action:", rollback$action, "\n")
