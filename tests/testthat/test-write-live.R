test_that("live create, replace, patch, restore, and rollback work", {
  skip_if_no_live_heurist()

  session <- heurist_live_session()
  place_change <- NULL
  on.exit(heurist_delete_if_exists(session, place_change), add = TRUE)

  place_rty <- heurist_find_rectype(session, "Place")
  title_original <- heurist_stamp("heuristR write test")

  place_change <- heurist_create_record(
    session,
    rectype_id = as.character(place_rty$rty_ID),
    details = list("1" = list("0" = title_original))
  )

  place_id <- as.character(place_change$record_id)
  expect_true(nzchar(place_id))

  place_record <- heurist_get_record(session, place_id)
  expect_equal(place_record$records[[1]]$rec_Title, title_original)

  title_replaced <- paste(title_original, "replaced")
  replace_change <- heurist_replace_record(
    session,
    record_id = place_id,
    rectype_id = as.character(place_rty$rty_ID),
    details = list("1" = list("0" = title_replaced)),
    owner_ugrp_id = place_record$records[[1]]$rec_OwnerUGrpID,
    non_owner_visibility = place_record$records[[1]]$rec_NonOwnerVisibility
  )

  replaced <- heurist_get_record(session, place_id)
  expect_equal(replaced$records[[1]]$rec_Title, title_replaced)

  restored_change <- heurist_restore_change(replace_change)
  restored <- heurist_get_record(session, place_id)
  expect_equal(restored$records[[1]]$rec_Title, title_original)
  expect_equal(restored_change$action, "replace")

  title_patched <- paste(title_original, "patched")
  patch_change <- heurist_patch_record(
    session,
    place_id,
    details = list("1" = list("0" = title_patched)),
    mode = "replace"
  )

  patched <- heurist_get_record(session, place_id)
  expect_equal(patched$records[[1]]$rec_Title, title_patched)

  rollback_change <- heurist_rollback(patch_change)
  rolled_back <- heurist_get_record(session, place_id)
  expect_equal(rolled_back$records[[1]]$rec_Title, title_original)
  expect_equal(rollback_change$action, "replace")

  delete_change <- heurist_rollback_change(place_change)
  expect_equal(delete_change$action, "rollback_delete")
  place_change <- NULL
})
