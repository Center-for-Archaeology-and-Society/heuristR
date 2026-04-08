test_that("live raw and high-level read helpers work", {
  skip_if_no_live_heurist()

  session <- heurist_live_session()
  payload <- heurist_find_records(session, "t:91")
  recs <- payload$records %||% list()

  expect_gte(length(recs), 1)

  rec_id <- recs[[1]]$rec_ID
  fetched <- heurist_get_record(session, rec_id)
  raw <- heurist_raw_record_output(
    session,
    query = list(recID = rec_id, format = "json", restapi = 1)
  )

  expect_equal(fetched$records[[1]]$rec_ID, rec_id)
  expect_equal(raw$records[[1]]$rec_ID, rec_id)
})
