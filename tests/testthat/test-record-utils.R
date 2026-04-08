test_that("existing Heurist details normalize safely", {
  details <- list(
    "1" = list("3" = "42SA920"),
    "238" = list("834266" = list(id = "53501", type = "12", title = "Montezuma Canyon"))
  )

  normalized <- heuristR:::.heurist_normalize_existing_details(details)

  expect_equal(normalized[["1"]][["3"]], "42SA920")
  expect_equal(normalized[["238"]][["834266"]], "53501")
})

test_that("detail merge replaces or appends as expected", {
  existing <- list(
    "1" = list("3" = "42SA920"),
    "238" = list("834266" = "53501")
  )

  replaced <- heuristR:::.heurist_merge_details(
    existing,
    list("238" = list("0" = "777")),
    mode = "replace"
  )

  appended <- heuristR:::.heurist_merge_details(
    existing,
    list("238" = list("0" = "777")),
    mode = "append"
  )

  expect_equal(replaced[["238"]][["0"]], "777")
  expect_equal(appended[["238"]][["834266"]], "53501")
  expect_equal(appended[["238"]][["834267"]], "777")
})

test_that("record normalization keeps header values and details", {
  record <- list(
    rec_ID = "3",
    rec_RecTypeID = "91",
    rec_OwnerUGrpID = "0",
    rec_NonOwnerVisibility = "viewable",
    rec_URL = NULL,
    rec_ScratchPad = "",
    details = list("1" = list("3" = "42SA920"))
  )

  normalized <- heuristR:::.heurist_normalize_record(record)

  expect_equal(normalized$record_id, "3")
  expect_equal(normalized$rectype_id, "91")
  expect_equal(normalized$details[["1"]][["3"]], "42SA920")
})
