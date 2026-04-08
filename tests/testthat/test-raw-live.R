test_that("live raw record edit create and delete work", {
  skip_if_no_live_heurist()

  session <- heurist_live_session()
  raw_id <- NULL
  on.exit({
    if (!is.null(raw_id)) {
      try(heurist_raw_record_edit(session, body = list(a = "delete", ids = raw_id)), silent = TRUE)
    }
  }, add = TRUE)

  place_rty <- heurist_find_rectype(session, "Place")
  title <- heurist_stamp("heuristR raw")

  created <- heurist_raw_record_edit(
    session,
    body = list(
      a = "save",
      ID = "0",
      RecTypeID = as.character(place_rty$rty_ID),
      details = jsonlite::toJSON(list("1" = list("0" = title)), auto_unbox = TRUE),
      details_encoded = "3"
    )
  )

  expect_equal(created$status, "ok")
  raw_id <- as.character(created$data)

  fetched <- heurist_raw_record_output(
    session,
    query = list(recID = raw_id, format = "json", restapi = 1)
  )
  expect_equal(fetched$records[[1]]$rec_Title, title)

  deleted <- heurist_raw_record_edit(session, body = list(a = "delete", ids = raw_id))
  expect_true((deleted$status %||% "") %in% c("ok", "deleted"))
  raw_id <- NULL
})
