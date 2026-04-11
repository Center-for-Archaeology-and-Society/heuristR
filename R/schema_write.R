#' Call Heurist Entity Edit Directly
#'
#' Low-level wrapper around `entityScrud.php` for write actions. This helper is
#' intentionally explicit because schema edits in Heurist can be destructive if
#' underspecified.
#'
#' @param session A `heurist_session`.
#' @param action Entity action such as `"save"`, `"delete"`, or `"batch"`.
#' @param entity Entity name such as `"defRecTypes"` or `"defTerms"`.
#' @param body Additional form body parameters.
#'
#' @return Parsed JSON response.
#' @export
heurist_raw_entity_edit <- function(session, action, entity, body = list()) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(action), length(action) == 1, nzchar(action))
  stopifnot(is.character(entity), length(entity) == 1, nzchar(entity))
  stopifnot(is.list(body))

  resp <- .heurist_post(
    session,
    "/hserv/controller/entityScrud.php",
    body = c(
      list(
        db = session$database,
        a = action,
        entity = entity
      ),
      body
    )
  )

  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' Create a Heurist Vocabulary Group
#'
#' Safely creates a new `defVocabularyGroups` entry. This helper only permits
#' creation of new rows and will refuse positive existing IDs.
#'
#' @param session A `heurist_session`.
#' @param name Vocabulary group name.
#' @param description Optional description.
#' @param domain Either `"enum"` or `"relation"`.
#' @param order Optional display order.
#'
#' @return Parsed JSON response from Heurist.
#' @export
heurist_create_vocabulary_group <- function(session,
                                            name,
                                            description = NULL,
                                            domain = c("enum", "relation"),
                                            order = NULL) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(name), length(name) == 1, nzchar(name))
  domain <- match.arg(domain)

  fields <- list(
    vcg_ID = "0",
    vcg_Name = name,
    vcg_Domain = domain
  )

  if (!is.null(description)) {
    fields$vcg_Description <- description
  }
  if (!is.null(order)) {
    fields$vcg_Order <- as.character(order)
  }

  heurist_save_entity_create_only(
    session = session,
    entity = "defVocabularyGroups",
    fields = fields
  )
}

#' Create a Heurist Vocabulary
#'
#' Safely creates a new top-level vocabulary as a root `defTerms` record.
#'
#' @param session A `heurist_session`.
#' @param label Vocabulary label.
#' @param domain Either `"enum"` or `"relation"`.
#' @param vocabulary_group_id Optional vocabulary group ID.
#' @param description Optional description.
#' @param code Optional code.
#' @param semantic_reference_url Optional semantic URI.
#' @param status Optional status. Defaults to `"open"`.
#'
#' @return Parsed JSON response from Heurist.
#' @export
heurist_create_vocabulary <- function(session,
                                      label,
                                      domain = c("enum", "relation"),
                                      vocabulary_group_id = NULL,
                                      description = NULL,
                                      code = NULL,
                                      semantic_reference_url = NULL,
                                      status = "open") {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(label), length(label) == 1, nzchar(label))
  domain <- match.arg(domain)

  fields <- list(
    trm_ID = "0",
    trm_Label = label,
    trm_Domain = domain,
    trm_ParentTermID = "0",
    trm_Status = status
  )

  if (!is.null(vocabulary_group_id)) {
    fields$trm_VocabularyGroupID <- as.character(vocabulary_group_id)
  }
  if (!is.null(description)) {
    fields$trm_Description <- description
  }
  if (!is.null(code)) {
    fields$trm_Code <- code
  }
  if (!is.null(semantic_reference_url)) {
    fields$trm_SemanticReferenceURL <- semantic_reference_url
  }

  heurist_save_entity_create_only(
    session = session,
    entity = "defTerms",
    fields = fields
  )
}

#' Create a Heurist Term
#'
#' Safely creates a new term under an existing vocabulary or parent term.
#'
#' @param session A `heurist_session`.
#' @param label Term label.
#' @param parent_term_id Parent term or vocabulary ID.
#' @param description Optional description.
#' @param code Optional code.
#' @param inverse_term_id Optional inverse term ID.
#' @param domain Optional domain override. Use only when creating relation terms.
#' @param status Optional status. Defaults to `"open"`.
#'
#' @return Parsed JSON response from Heurist.
#' @export
heurist_create_term <- function(session,
                                label,
                                parent_term_id,
                                description = NULL,
                                code = NULL,
                                inverse_term_id = NULL,
                                domain = NULL,
                                status = "open") {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(label), length(label) == 1, nzchar(label))
  stopifnot(length(parent_term_id) == 1, !is.na(parent_term_id))

  fields <- list(
    trm_ID = "0",
    trm_Label = label,
    trm_ParentTermID = as.character(parent_term_id),
    trm_Status = status
  )

  if (!is.null(description)) {
    fields$trm_Description <- description
  }
  if (!is.null(code)) {
    fields$trm_Code <- code
  }
  if (!is.null(inverse_term_id)) {
    fields$trm_InverseTermID <- as.character(inverse_term_id)
  }
  if (!is.null(domain)) {
    fields$trm_Domain <- domain
  }

  heurist_save_entity_create_only(
    session = session,
    entity = "defTerms",
    fields = fields
  )
}

#' Create a Heurist Record Type
#'
#' Safely creates a new `defRecTypes` entry. This helper is create-only and does
#' not expose broad update semantics.
#'
#' @param session A `heurist_session`.
#' @param name Record type name.
#' @param description Record type description.
#' @param title_mask Human-readable title mask.
#' @param rectype_group_id Record type group ID.
#' @param plural Optional plural label.
#' @param reference_url Optional semantic/reference URI.
#' @param status Optional status. Defaults to `"open"`.
#' @param show_in_lists Logical or scalar coercible to Heurist boolean.
#' @param show_description_on_edit_form Logical or scalar coercible to Heurist boolean.
#'
#' @return Parsed JSON response from Heurist.
#' @export
heurist_create_rectype <- function(session,
                                   name,
                                   description,
                                   title_mask,
                                   rectype_group_id,
                                   plural = NULL,
                                   reference_url = NULL,
                                   status = "open",
                                   show_in_lists = TRUE,
                                   show_description_on_edit_form = TRUE) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(name), length(name) == 1, nzchar(name))
  stopifnot(is.character(description), length(description) == 1, nzchar(description))
  stopifnot(is.character(title_mask), length(title_mask) == 1, nzchar(title_mask))
  stopifnot(length(rectype_group_id) == 1, !is.na(rectype_group_id))

  fields <- list(
    rty_ID = "0",
    rty_Name = name,
    rty_Description = description,
    rty_TitleMask = title_mask,
    rty_RecTypeGroupID = as.character(rectype_group_id),
    rty_Status = status,
    rty_ShowInLists = .heurist_bool_string(show_in_lists),
    rty_ShowDescriptionOnEditForm = .heurist_bool_string(show_description_on_edit_form)
  )

  if (!is.null(plural)) {
    fields$rty_Plural <- plural
  }
  if (!is.null(reference_url)) {
    fields$rty_ReferenceURL <- reference_url
  }

  heurist_save_entity_create_only(
    session = session,
    entity = "defRecTypes",
    fields = fields
  )
}

#' Create a Heurist Detail Type
#'
#' Safely creates a new `defDetailTypes` entry. This helper is create-only and
#' requires explicit vocabulary or pointer constraints when the field type needs
#' them.
#'
#' @param session A `heurist_session`.
#' @param name Field name.
#' @param help_text Default help text.
#' @param type One of `"enum"`, `"float"`, `"freetext"`, `"blocktext"`,
#'   `"date"`, `"geo"`, `"file"`, `"resource"`, or `"relmarker"`.
#' @param detail_type_group_id Detail type group ID.
#' @param vocabulary_id Required for `"enum"` and `"relmarker"` field types.
#' @param target_rectype_ids Optional target record type IDs for `"resource"` and
#'   `"relmarker"` fields. May be a scalar, vector, or comma-separated string.
#' @param extended_description Optional extended description.
#' @param semantic_reference_url Optional semantic/reference URI.
#' @param status Optional status. Defaults to `"open"`.
#' @param non_owner_visibility Optional visibility. Defaults to `"viewable"`.
#' @param show_in_lists Logical or scalar coercible to Heurist boolean.
#'
#' @return Parsed JSON response from Heurist.
#' @export
heurist_create_detail_type <- function(session,
                                       name,
                                       help_text,
                                       type,
                                       detail_type_group_id,
                                       vocabulary_id = NULL,
                                       target_rectype_ids = NULL,
                                       extended_description = NULL,
                                       semantic_reference_url = NULL,
                                       status = "open",
                                       non_owner_visibility = "viewable",
                                       show_in_lists = TRUE) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(name), length(name) == 1, nzchar(name))
  stopifnot(is.character(help_text), length(help_text) == 1, nzchar(help_text))
  stopifnot(is.character(type), length(type) == 1, nzchar(type))
  stopifnot(length(detail_type_group_id) == 1, !is.na(detail_type_group_id))

  type <- match.arg(
    type,
    choices = c("enum", "float", "freetext", "blocktext", "date", "geo", "file", "resource", "relmarker")
  )

  if (type %in% c("enum", "relmarker") && is.null(vocabulary_id)) {
    cli::cli_abort(c(
      "Vocabulary-backed detail types require an explicit vocabulary ID.",
      "i" = "Supply {.arg vocabulary_id} when creating {.val enum} or {.val relmarker} fields."
    ))
  }

  fields <- list(
    dty_ID = "0",
    dty_Name = name,
    dty_HelpText = help_text,
    dty_Type = type,
    dty_DetailTypeGroupID = as.character(detail_type_group_id),
    dty_Status = status,
    dty_NonOwnerVisibility = non_owner_visibility,
    dty_ShowInLists = .heurist_bool_string(show_in_lists)
  )

  if (!is.null(vocabulary_id)) {
    fields$dty_JsonTermIDTree <- as.character(vocabulary_id)
  }
  if (!is.null(target_rectype_ids)) {
    fields$dty_PtrTargetRectypeIDs <- .heurist_id_csv(target_rectype_ids)
  }
  if (!is.null(extended_description)) {
    fields$dty_ExtendedDescription <- extended_description
  }
  if (!is.null(semantic_reference_url)) {
    fields$dty_SemanticReferenceURL <- semantic_reference_url
  }

  heurist_save_entity_create_only(
    session = session,
    entity = "defDetailTypes",
    fields = fields
  )
}

#' Attach a Detail Type to a Record Type
#'
#' Safely creates a new `defRecStructure` row linking an existing base field to a
#' record type. This helper refuses to overwrite an existing structure row.
#'
#' @param session A `heurist_session`.
#' @param rectype_id Record type ID.
#' @param detail_type_id Detail type ID.
#' @param display_name Optional record-type-specific display name.
#' @param requirement Requirement type. Defaults to `"optional"`.
#' @param max_values Repeatability flag. Defaults to `1`.
#' @param display_width Optional display width.
#' @param display_help_text Optional record-type-specific help text.
#'
#' @return Parsed JSON response from Heurist.
#' @export
heurist_attach_detail_type <- function(session,
                                       rectype_id,
                                       detail_type_id,
                                       display_name = NULL,
                                       requirement = c("required", "recommended", "optional", "forbidden"),
                                       max_values = 1,
                                       display_width = NULL,
                                       display_help_text = NULL) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(length(rectype_id) == 1, !is.na(rectype_id))
  stopifnot(length(detail_type_id) == 1, !is.na(detail_type_id))
  requirement <- match.arg(requirement)

  existing <- heurist_raw_entity(
    session,
    action = "search",
    entity = "defRecStructure",
    query = list(
      rst_RecTypeID = as.character(rectype_id),
      rst_DetailTypeID = as.character(detail_type_id),
      details = "full"
    )
  )

  if (identical(existing$status %||% "", "ok") && isTRUE((existing$data$reccount %||% 0) > 0)) {
    cli::cli_abort(c(
      "A record-structure row already exists for this record type and field.",
      "i" = paste("rectype_id =", rectype_id, "detail_type_id =", detail_type_id),
      "i" = "This helper only creates new structure rows and refuses to overwrite an existing one."
    ))
  }

  fields <- list(
    rst_ID = "0",
    rst_RecTypeID = as.character(rectype_id),
    rst_DetailTypeID = as.character(detail_type_id),
    rst_RequirementType = requirement,
    rst_MaxValues = as.character(max_values)
  )

  if (!is.null(display_name)) {
    fields$rst_DisplayName <- display_name
  }
  if (!is.null(display_width)) {
    fields$rst_DisplayWidth <- as.character(display_width)
  }
  if (!is.null(display_help_text)) {
    fields$rst_DisplayHelpText <- display_help_text
  }

  heurist_save_entity_create_only(
    session = session,
    entity = "defRecStructure",
    fields = fields
  )
}

heurist_save_entity_create_only <- function(session, entity, fields, isfull = TRUE) {
  stopifnot(inherits(session, "heurist_session"))
  stopifnot(is.character(entity), length(entity) == 1, nzchar(entity))
  stopifnot(is.list(fields), length(fields) > 0)

  primary_field <- .heurist_entity_primary_field(entity)
  if (is.null(primary_field)) {
    cli::cli_abort(c(
      "No create-only schema mapping is defined for this entity.",
      "x" = entity
    ))
  }

  fields <- .heurist_assert_create_only_fields(fields, primary_field = primary_field)

  response <- heurist_raw_entity_edit(
    session = session,
    action = "save",
    entity = entity,
    body = list(
      fields = fields,
      isfull = if (isTRUE(isfull)) "1" else "0"
    )
  )

  .heurist_assert_ok(response, sprintf("Heurist schema create failed for entity %s.", entity))
  response
}

.heurist_entity_primary_field <- function(entity) {
  switch(
    entity,
    defVocabularyGroups = "vcg_ID",
    defTerms = "trm_ID",
    defRecTypes = "rty_ID",
    defDetailTypes = "dty_ID",
    defRecStructure = "rst_ID",
    NULL
  )
}

.heurist_assert_create_only_fields <- function(fields, primary_field) {
  out <- fields
  current_id <- out[[primary_field]] %||% NULL

  if (is.null(current_id) || !nzchar(as.character(current_id))) {
    out[[primary_field]] <- "0"
    return(out)
  }

  current_id_num <- suppressWarnings(as.numeric(current_id))
  if (!is.na(current_id_num) && current_id_num > 0) {
    cli::cli_abort(c(
      "Create-only schema helpers refuse to update an existing definition.",
      "x" = paste(primary_field, "=", current_id),
      "i" = "Use the raw entity edit helper only when you intend an explicit low-level schema update."
    ))
  }

  out[[primary_field]] <- "0"
  out
}

.heurist_bool_string <- function(x) {
  if (is.logical(x)) {
    return(if (isTRUE(x)) "1" else "0")
  }
  as.character(x)
}

.heurist_id_csv <- function(x) {
  if (length(x) == 1 && is.character(x) && grepl(",", x, fixed = TRUE)) {
    return(x)
  }
  paste(as.character(x), collapse = ",")
}
