test_that("live auth flow works", {
  skip_if_no_live_heurist()

  session <- heurist_live_session()
  expect_true(session$authenticated)
  expect_true(nzchar(session$current_user$ugr_Name %||% ""))

  session <- heurist_logout(session)
  expect_false(session$authenticated)
})
