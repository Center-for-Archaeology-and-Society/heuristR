test_that("live link and rollback helpers work", {
  skip_if_no_live_heurist()

  session <- heurist_live_session()
  place_change <- NULL
  ethnic_change <- NULL
  on.exit(heurist_delete_if_exists(session, ethnic_change), add = TRUE)
  on.exit(heurist_delete_if_exists(session, place_change), add = TRUE)

  place_rty <- heurist_find_rectype(session, "Place")
  ethnic_rty <- heurist_find_rectype(session, "Ethnic Group")
  place_ptr_field <- heurist_find_field(session, "Place")

  place_change <- heurist_create_record(
    session,
    rectype_id = as.character(place_rty$rty_ID),
    details = list("1" = list("0" = heurist_stamp("heuristR link place")))
  )
  ethnic_change <- heurist_create_record(
    session,
    rectype_id = as.character(ethnic_rty$rty_ID),
    details = list("1" = list("0" = heurist_stamp("heuristR link ethnic")))
  )

  place_id <- as.character(place_change$record_id)
  ethnic_id <- as.character(ethnic_change$record_id)

  link_change <- heurist_link_record(
    session,
    source_record_id = ethnic_id,
    detail_type_id = as.character(place_ptr_field$dty_ID),
    target_record_id = place_id,
    append = FALSE
  )

  linked <- heurist_get_record(session, ethnic_id)
  expect_equal(linked$records[[1]]$details[["238"]][[1]]$id, place_id)

  rollback <- heurist_rollback_change(link_change)
  unlinked <- heurist_get_record(session, ethnic_id)
  expect_true(is.null(unlinked$records[[1]]$details[["238"]]))
  expect_equal(rollback$action, "replace")

  heurist_rollback_change(ethnic_change)
  heurist_rollback_change(place_change)
  ethnic_change <- NULL
  place_change <- NULL
})
