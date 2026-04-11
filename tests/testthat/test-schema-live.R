test_that("live schema create helpers work and remain scoped", {
  skip_if_no_live_heurist()

  session <- heurist_live_session()
  stamp <- heurist_stamp("heuristR schema")

  first_id <- function(resp) {
    out <- resp$data %||% NULL
    if (is.null(out) || length(out) < 1) {
      return(NULL)
    }
    as.character(out[[1]])
  }

  safe_entity_delete <- function(entity, body) {
    try(
      heurist_raw_entity_edit(
        session,
        action = "delete",
        entity = entity,
        body = body
      ),
      silent = TRUE
    )
    invisible(NULL)
  }

  rtg <- heurist_raw_entity(session, "search", "defRecTypeGroups", list(details = "list"))
  dtg <- heurist_raw_entity(session, "search", "defDetailTypeGroups", list(details = "list"))

  rtg_id <- as.character(rtg$data$records[[1]][[1]])
  dtg_id <- as.character(dtg$data$records[[1]][[1]])

  vcg_id <- NULL
  vocab_id <- NULL
  term_id <- NULL
  rty_id <- NULL
  dty_id <- NULL

  on.exit({
    if (!is.null(rty_id) && !is.null(dty_id)) {
      safe_entity_delete("defRecStructure", list(recID = paste(rty_id, dty_id, sep = ".")))
    }
    if (!is.null(dty_id)) {
      safe_entity_delete("defDetailTypes", list(dty_ID = dty_id))
    }
    if (!is.null(rty_id)) {
      safe_entity_delete("defRecTypes", list(rty_ID = rty_id))
    }
    if (!is.null(term_id)) {
      safe_entity_delete("defTerms", list(trm_ID = term_id))
    }
    if (!is.null(vocab_id)) {
      safe_entity_delete("defTerms", list(trm_ID = vocab_id))
    }
    if (!is.null(vcg_id)) {
      safe_entity_delete("defVocabularyGroups", list(vcg_ID = vcg_id))
    }
  }, add = TRUE)

  created_group <- heurist_create_vocabulary_group(
    session,
    name = paste(stamp, "group"),
    description = "Temporary heuristR live schema test group."
  )
  expect_equal(created_group$status, "ok")
  vcg_id <- first_id(created_group)
  expect_true(nzchar(vcg_id))

  created_vocab <- heurist_create_vocabulary(
    session,
    label = paste(stamp, "vocab"),
    vocabulary_group_id = vcg_id,
    description = "Temporary heuristR live schema test vocabulary."
  )
  expect_equal(created_vocab$status, "ok")
  vocab_id <- first_id(created_vocab)
  expect_true(nzchar(vocab_id))

  created_term <- heurist_create_term(
    session,
    label = paste(stamp, "term"),
    parent_term_id = vocab_id,
    description = "Temporary heuristR live schema test term."
  )
  expect_equal(created_term$status, "ok")
  term_id <- first_id(created_term)
  expect_true(nzchar(term_id))

  created_rectype <- heurist_create_rectype(
    session,
    name = paste(stamp, "type"),
    description = "Temporary heuristR live schema test record type.",
    title_mask = "[ID]",
    rectype_group_id = rtg_id
  )
  expect_equal(created_rectype$status, "ok")
  rty_id <- first_id(created_rectype)
  expect_true(nzchar(rty_id))

  created_detail_type <- heurist_create_detail_type(
    session,
    name = paste(stamp, "field"),
    help_text = "Temporary heuristR live schema test field.",
    type = "enum",
    detail_type_group_id = dtg_id,
    vocabulary_id = vocab_id
  )
  expect_equal(created_detail_type$status, "ok")
  dty_id <- first_id(created_detail_type)
  expect_true(nzchar(dty_id))

  attached <- heurist_attach_detail_type(
    session,
    rectype_id = rty_id,
    detail_type_id = dty_id,
    display_name = "Temporary Field"
  )
  expect_equal(attached$status, "ok")

  duplicate_attach <- tryCatch(
    heurist_attach_detail_type(
      session,
      rectype_id = rty_id,
      detail_type_id = dty_id,
      display_name = "Temporary Field"
    ),
    error = function(e) e
  )
  expect_s3_class(duplicate_attach, "error")
  expect_match(conditionMessage(duplicate_attach), "already exists")
})
