#' Get a Single Heurist Record
#'
#' Fetches one record by record ID.
#'
#' @param session A `heurist_session`.
#' @param record_id Numeric or character record ID.
#'
#' @return A parsed Heurist record payload.
#' @export
heurist_get_record <- function(session, record_id) {
  stopifnot(inherits(session, "heurist_session"))

  heurist_raw_record_output(
    session,
    query = list(
      recID = as.character(record_id),
      format = "json",
      restapi = 1
    )
  )
}

#' Find Heurist Records
#'
#' Queries records using a raw Heurist query string.
#'
#' @param session A `heurist_session`.
#' @param q Heurist query string, such as `"t:10"` or `"sortby:-m"`.
#' @param format Response format. Defaults to `"json"`.
#'
#' @return A parsed Heurist record payload.
#' @export
heurist_find_records <- function(session, q, format = "json") {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(q), length(q) == 1, nzchar(q))

  heurist_raw_record_output(
    session,
    query = list(
      q = q,
      format = format,
      restapi = 1
    )
  )
}

#' Call Heurist Record Output Directly
#'
#' Low-level wrapper around `record_output.php`.
#'
#' @param session A `heurist_session`.
#' @param query Query parameters passed to the endpoint.
#'
#' @return Parsed JSON response.
#' @export
heurist_raw_record_output <- function(session, query = list()) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.list(query))

  resp <- .heurist_get(
    session,
    "/hserv/controller/record_output.php",
    query = c(list(db = session$database), query)
  )

  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' Call Heurist Record Edit Directly
#'
#' Low-level wrapper around `record_edit.php`.
#'
#' @param session A `heurist_session`.
#' @param body Form body sent to the endpoint.
#'
#' @return Parsed JSON response.
#' @export
heurist_raw_record_edit <- function(session, body = list()) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.list(body))

  req <- do.call(
    httr2::req_body_form,
    c(
      list(.heurist_request(session, "/hserv/controller/record_edit.php")),
      list(db = session$database),
      body
    )
  )

  resp <- httr2::req_perform(req)
  .heurist_check_response(resp)
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' Call Heurist Entity Endpoint Directly
#'
#' Low-level wrapper around `entityScrud.php`.
#'
#' @param session A `heurist_session`.
#' @param action Entity action.
#' @param entity Entity name.
#' @param query Additional query parameters.
#'
#' @return Parsed JSON response.
#' @export
heurist_raw_entity <- function(session, action, entity, query = list()) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(action), length(action) == 1, nzchar(action))
  stopifnot(is.character(entity), length(entity) == 1, nzchar(entity))
  stopifnot(is.list(query))

  resp <- .heurist_get(
    session,
    "/hserv/controller/entityScrud.php",
    query = c(
      list(
        db = session$database,
        a = action,
        entity = entity
      ),
      query
    )
  )

  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' Create a Heurist Record
#'
#' Creates a new record using a Heurist record type ID and a details payload.
#'
#' @param session A `heurist_session`.
#' @param rectype_id Record type ID.
#' @param details Named list of Heurist detail values.
#' @param title Optional title override.
#' @param owner_ugrp_id Optional owner group ID.
#' @param non_owner_visibility Optional non-owner visibility.
#'
#' @return A `heurist_change` object containing the create response.
#' @export
heurist_create_record <- function(session,
                                  rectype_id,
                                  details,
                                  title = NULL,
                                  owner_ugrp_id = NULL,
                                  non_owner_visibility = NULL) {
  stopifnot(inherits(session, "heurist_session"))

  body <- list(
    a = "save",
    ID = "0",
    RecTypeID = as.character(rectype_id),
    details = .heurist_encode_details(details),
    details_encoded = "3"
  )

  if (!is.null(title)) {
    body$Title <- title
  }
  if (!is.null(owner_ugrp_id)) {
    body$OwnerUGrpID <- as.character(owner_ugrp_id)
  }
  if (!is.null(non_owner_visibility)) {
    body$NonOwnerVisibility <- non_owner_visibility
  }

  response <- heurist_raw_record_edit(session, body = body)
  .heurist_assert_ok(response, "Heurist create failed.")

  after_id <- as.character(response$data %||% "")
  after <- if (nzchar(after_id)) heurist_get_record(session, after_id) else NULL

  .heurist_make_change(
    session = session,
    action = "create",
    record_id = after_id,
    before = NULL,
    after = after,
    response = response
  )
}

#' Replace a Heurist Record
#'
#' Replaces a record with the supplied full payload. This is a low-level
#' full-save helper and should be used carefully.
#'
#' @param session A `heurist_session`.
#' @param record_id Record ID.
#' @param rectype_id Record type ID.
#' @param details Full Heurist details list to save.
#' @param owner_ugrp_id Owner group ID.
#' @param non_owner_visibility Non-owner visibility value.
#' @param url Optional URL value.
#' @param scratch_pad Optional scratch pad value.
#' @param title Optional title override.
#'
#' @return A `heurist_change` object.
#' @export
heurist_replace_record <- function(session,
                                   record_id,
                                   rectype_id,
                                   details,
                                   owner_ugrp_id,
                                   non_owner_visibility,
                                   url = NULL,
                                   scratch_pad = NULL,
                                   title = NULL) {
  stopifnot(inherits(session, "heurist_session"))

  before <- heurist_get_record(session, record_id)
  body <- list(
    a = "save",
    ID = as.character(record_id),
    RecTypeID = as.character(rectype_id),
    OwnerUGrpID = as.character(owner_ugrp_id),
    NonOwnerVisibility = as.character(non_owner_visibility),
    details = .heurist_encode_details(details),
    details_encoded = "3"
  )

  if (!is.null(url)) {
    body$URL <- url
  }
  if (!is.null(scratch_pad)) {
    body$ScratchPad <- scratch_pad
  }
  if (!is.null(title)) {
    body$Title <- title
  }

  response <- heurist_raw_record_edit(session, body = body)
  .heurist_assert_ok(response, "Heurist replace failed.")
  after <- heurist_get_record(session, record_id)

  .heurist_make_change(
    session = session,
    action = "replace",
    record_id = as.character(record_id),
    before = before,
    after = after,
    response = response
  )
}

#' Patch a Heurist Record Safely
#'
#' Performs a safe read-modify-write update. Existing details are fetched,
#' normalized, merged with the supplied changes, and then written back as a full
#' record payload to avoid accidental data loss.
#'
#' @param session A `heurist_session`.
#' @param record_id Record ID.
#' @param details Named list of detail changes.
#' @param mode Merge mode: `"replace"` or `"append"`.
#'
#' @return A `heurist_change` object.
#' @export
heurist_patch_record <- function(session, record_id, details, mode = c("replace", "append")) {
  stopifnot(inherits(session, "heurist_session"))
  mode <- match.arg(mode)

  current <- .heurist_require_record(heurist_get_record(session, record_id), record_id)
  normalized <- .heurist_normalize_record(current)
  merged_details <- .heurist_merge_details(normalized$details, details, mode = mode)

  heurist_replace_record(
    session = session,
    record_id = record_id,
    rectype_id = normalized$rectype_id,
    details = merged_details,
    owner_ugrp_id = normalized$owner_ugrp_id,
    non_owner_visibility = normalized$non_owner_visibility,
    url = normalized$url,
    scratch_pad = normalized$scratch_pad
  )
}

#' Link a Heurist Record Through a Pointer Field
#'
#' Safely adds or replaces a pointer field value on an existing record.
#'
#' @param session A `heurist_session`.
#' @param source_record_id Source record ID.
#' @param detail_type_id Pointer field detail type ID.
#' @param target_record_id Target record ID.
#' @param append If `TRUE`, append a new value. If `FALSE`, replace the field.
#'
#' @return A `heurist_change` object.
#' @export
heurist_link_record <- function(session,
                                source_record_id,
                                detail_type_id,
                                target_record_id,
                                append = FALSE) {
  stopifnot(inherits(session, "heurist_session"))

  change_details <- list()
  change_details[[as.character(detail_type_id)]] <- list("0" = as.character(target_record_id))

  heurist_patch_record(
    session = session,
    record_id = source_record_id,
    details = change_details,
    mode = if (append) "append" else "replace"
  )
}

#' Restore a Prior Heurist Change
#'
#' Restores the previous state captured by a `heurist_change` object.
#'
#' @param change A `heurist_change` object.
#'
#' @return A `heurist_change` object representing the restore operation.
#' @export
heurist_restore_change <- function(change) {
  stopifnot(inherits(change, "heurist_change"))

  if (identical(change$action, "create")) {
    response <- heurist_raw_record_edit(
      change$session,
      body = list(
        a = "delete",
        ids = as.character(change$record_id)
      )
    )
    .heurist_assert_status(response, c("ok", "deleted"), "Heurist rollback delete failed.")

    return(.heurist_make_change(
      session = change$session,
      action = "rollback_delete",
      record_id = change$record_id,
      before = change$after,
      after = NULL,
      response = response
    ))
  }

  before_record <- .heurist_require_record(change$before, change$record_id)
  normalized <- .heurist_normalize_record(before_record)

  heurist_replace_record(
    session = change$session,
    record_id = change$record_id,
    rectype_id = normalized$rectype_id,
    details = normalized$details,
    owner_ugrp_id = normalized$owner_ugrp_id,
    non_owner_visibility = normalized$non_owner_visibility,
    url = normalized$url,
    scratch_pad = normalized$scratch_pad
  )
}

#' Roll Back a Heurist Change
#'
#' Alias for `heurist_restore_change()` for a more explicit workflow name.
#'
#' @param change A `heurist_change` object.
#'
#' @return A `heurist_change` object.
#' @export
heurist_rollback <- function(change) {
  heurist_restore_change(change)
}

#' Roll Back a Heurist Change
#'
#' Alias for `heurist_restore_change()`.
#'
#' @param change A `heurist_change` object.
#'
#' @return A `heurist_change` object.
#' @export
heurist_rollback_change <- function(change) {
  heurist_restore_change(change)
}
