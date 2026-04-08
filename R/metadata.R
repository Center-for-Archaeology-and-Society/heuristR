#' List Heurist Record Types
#'
#' Retrieves record type metadata for the current database.
#'
#' @param session A `heurist_session`.
#'
#' @return A list of Heurist record type objects.
#' @export
heurist_rectypes <- function(session) {
  stopifnot(inherits(session, "heurist_session"))
  resp <- .heurist_get(session, sprintf("/api/%s/rectypes", session$database))
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' List Heurist Fields
#'
#' Retrieves field metadata for the current database.
#'
#' @param session A `heurist_session`.
#'
#' @return A list of Heurist field objects.
#' @export
heurist_fields <- function(session) {
  stopifnot(inherits(session, "heurist_session"))
  resp <- .heurist_get(session, sprintf("/api/%s/fields", session$database))
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' Get Heurist Structure Definitions
#'
#' Retrieves database structure definitions through Heurist's metadata endpoint.
#'
#' @param session A `heurist_session`.
#' @param entity Structure entity name. Defaults to `"all"`.
#'
#' @return A parsed Heurist structure payload.
#' @export
heurist_structure <- function(session, entity = "all") {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(entity), length(entity) == 1, nzchar(entity))

  heurist_raw_entity(
    session,
    action = "structure",
    entity = entity
  )
}
