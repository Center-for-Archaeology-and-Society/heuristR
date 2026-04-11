test_that("form body encoder flattens nested schema fields", {
  encoded <- .heurist_encode_form_body(
    list(
      a = "save",
      entity = "defRecTypes",
      fields = list(
        rty_ID = "0",
        rty_Name = "Example Type"
      ),
      isfull = "1"
    )
  )

  expect_equal(encoded$a, "save")
  expect_equal(encoded$entity, "defRecTypes")
  expect_equal(encoded[["fields[rty_ID]"]], "0")
  expect_equal(encoded[["fields[rty_Name]"]], "Example Type")
  expect_equal(encoded$isfull, "1")
})

test_that("create-only guard forces zero IDs and blocks positive IDs", {
  expect_equal(
    .heurist_assert_create_only_fields(list(rty_Name = "Example"), "rty_ID")$rty_ID,
    "0"
  )

  expect_equal(
    .heurist_assert_create_only_fields(list(rty_ID = "", rty_Name = "Example"), "rty_ID")$rty_ID,
    "0"
  )

  expect_error(
    .heurist_assert_create_only_fields(list(rty_ID = "12", rty_Name = "Example"), "rty_ID"),
    "refuse"
  )
})
