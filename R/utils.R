`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) {
    return(y)
  }
  x
}

.heurist_make_change <- function(session, action, record_id, before, after, response) {
  change <- list(
    session = session,
    action = action,
    record_id = as.character(record_id),
    before = before,
    after = after,
    response = response
  )
  class(change) <- "heurist_change"
  change
}

.heurist_request <- function(session, path) {
  httr2::request(paste0(session$base_url, path)) |>
    httr2::req_cookie_preserve(path = session$cookie_path) |>
    httr2::req_timeout(session$timeout) |>
    httr2::req_retry(max_tries = 2) |>
    httr2::req_error(is_error = function(resp) FALSE)
}

.heurist_get <- function(session, path, query = list()) {
  req <- .heurist_request(session, path)

  if (length(query) > 0) {
    req <- do.call(httr2::req_url_query, c(list(req), query))
  }

  resp <- httr2::req_perform(req)
  .heurist_check_response(resp)
}

.heurist_check_response <- function(resp) {
  status <- httr2::resp_status(resp)

  if (status >= 400) {
    body <- tryCatch(httr2::resp_body_string(resp), error = function(e) "")
    cli::cli_abort(c(
      "Heurist request failed.",
      "x" = paste("HTTP", status),
      "i" = .heurist_cli_safe(substr(body, 1, 500))
    ))
  }

  resp
}

.heurist_message <- function(payload) {
  .heurist_cli_safe(payload$message %||% payload$msg %||% "Unknown Heurist error.")
}

.heurist_cli_safe <- function(text) {
  text <- as.character(text %||% "")
  text <- gsub("\\{", "{{", text, perl = TRUE)
  text <- gsub("\\}", "}}", text, perl = TRUE)
  text
}

.heurist_assert_ok <- function(payload, message = "Heurist request failed.") {
  .heurist_assert_status(payload, "ok", message)
}

.heurist_assert_status <- function(payload, statuses, message) {
  status <- payload$status %||% ""
  if (!(status %in% statuses)) {
    cli::cli_abort(c(
      message,
      "x" = .heurist_message(payload)
    ))
  }
}

.heurist_require_record <- function(payload, record_id) {
  records <- payload$records %||% list()
  if (length(records) < 1) {
    cli::cli_abort(paste("No record found for record ID", record_id))
  }
  records[[1]]
}

.heurist_normalize_record <- function(record) {
  details <- .heurist_normalize_existing_details(record$details %||% list())

  list(
    record_id = as.character(record$rec_ID),
    rectype_id = as.character(record$rec_RecTypeID),
    owner_ugrp_id = as.character(record$rec_OwnerUGrpID),
    non_owner_visibility = as.character(record$rec_NonOwnerVisibility),
    url = .heurist_nullable_scalar(record$rec_URL),
    scratch_pad = .heurist_nullable_scalar(record$rec_ScratchPad),
    details = details
  )
}

.heurist_nullable_scalar <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NULL)
  }
  if (is.list(x) && length(x) == 0) {
    return(NULL)
  }
  as.character(x)
}

.heurist_normalize_existing_details <- function(details) {
  if (is.null(details) || length(details) == 0) {
    return(list())
  }

  normalized <- list()
  for (dty_id in names(details)) {
    normalized[[dty_id]] <- .heurist_normalize_detail_entries(details[[dty_id]], dty_id)
  }
  normalized
}

.heurist_normalize_detail_entries <- function(entries, dty_id) {
  if (is.null(entries) || length(entries) == 0) {
    return(list())
  }

  if (!is.list(entries)) {
    cli::cli_abort(paste("Unsupported Heurist detail payload for field", dty_id))
  }

  normalized <- list()
  for (entry_name in names(entries)) {
    value <- entries[[entry_name]]

    if (is.list(value) && !is.null(value$id)) {
      normalized[[entry_name]] <- as.character(value$id)
    } else if (is.atomic(value) && length(value) == 1) {
      normalized[[entry_name]] <- as.character(value)
    } else if (is.list(value) && length(value) == 0) {
      normalized[[entry_name]] <- NULL
    } else {
      cli::cli_abort(c(
        "Unsupported Heurist detail shape during safe update.",
        "x" = paste("Field", dty_id, "contains a value shape heuristR does not yet know how to preserve safely.")
      ))
    }
  }

  normalized
}

.heurist_merge_details <- function(existing, changes, mode = c("replace", "append")) {
  mode <- match.arg(mode)
  stopifnot(is.list(existing), is.list(changes))

  merged <- existing

  for (dty_id in names(changes)) {
    new_entries <- .heurist_normalize_new_detail_entries(changes[[dty_id]])

    if (identical(mode, "replace")) {
      merged[[dty_id]] <- new_entries
    } else {
      current <- merged[[dty_id]] %||% list()
      next_idx <- .heurist_next_detail_index(current)
      for (value in new_entries) {
        current[[as.character(next_idx)]] <- value
        next_idx <- next_idx + 1
      }
      merged[[dty_id]] <- current
    }
  }

  merged
}

.heurist_next_detail_index <- function(entries) {
  if (length(entries) == 0) {
    return(0L)
  }

  names_num <- suppressWarnings(as.integer(names(entries)))
  names_num <- names_num[!is.na(names_num)]
  if (length(names_num) == 0) {
    return(0L)
  }
  max(names_num) + 1L
}

.heurist_normalize_new_detail_entries <- function(entries) {
  if (is.null(entries)) {
    return(list())
  }

  if (!is.list(entries)) {
    return(list("0" = as.character(entries)))
  }

  normalized <- list()
  if (length(entries) == 0) {
    return(normalized)
  }

  if (is.null(names(entries))) {
    for (idx in seq_along(entries)) {
      normalized[[as.character(idx - 1L)]] <- as.character(entries[[idx]])
    }
    return(normalized)
  }

  for (entry_name in names(entries)) {
    value <- entries[[entry_name]]
    if (is.null(value)) {
      next
    }
    if (is.list(value) && !is.null(value$id)) {
      normalized[[entry_name]] <- as.character(value$id)
    } else if (length(value) == 1) {
      normalized[[entry_name]] <- as.character(value)
    } else {
      cli::cli_abort("New detail entries must be scalar values or pointer objects with an `id` element.")
    }
  }

  normalized
}

.heurist_encode_details <- function(details) {
  stopifnot(is.list(details))
  jsonlite::toJSON(details, auto_unbox = TRUE)
}
