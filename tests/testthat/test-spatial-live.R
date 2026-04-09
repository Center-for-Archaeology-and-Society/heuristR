test_that("live site queries can return sf objects", {
  skip_if_no_live_heurist()
  testthat::skip_if_not_installed("sf")

  session <- heurist_live_session()
  rectypes <- heurist_rectypes(session)
  site <- Filter(function(x) identical(x$rty_Name %||% "", "Site"), rectypes)
  expect_true(length(site) >= 1)

  payload <- heurist_find_records(
    session,
    paste0("t:", site[[1]]$rty_ID),
    as_sf = TRUE
  )

  expect_s3_class(payload, "sf")
  expect_gt(nrow(payload), 0)
  expect_true(any(!sf::st_is_empty(payload)))
})
