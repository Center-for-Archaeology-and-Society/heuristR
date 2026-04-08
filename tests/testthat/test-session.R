test_that("heurist_session creates expected structure", {
  session <- heurist_session("https://heurist.huma-num.fr/heurist", "jalli_coalbed")

  expect_s3_class(session, "heurist_session")
  expect_equal(session$database, "jalli_coalbed")
  expect_false(session$authenticated)
})
