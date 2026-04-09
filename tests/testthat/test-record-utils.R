test_that("existing Heurist details normalize safely", {
  details <- list(
    "1" = list("3" = "42SA920"),
    "238" = list("834266" = list(id = "53501", type = "12", title = "Montezuma Canyon"))
  )

  normalized <- heuristR:::.heurist_normalize_existing_details(details)

  expect_equal(normalized[["1"]][["3"]], "42SA920")
  expect_equal(normalized[["238"]][["834266"]], "53501")
})

test_that("existing geospatial details normalize to WKT safely", {
  details <- list(
    "28" = list(
      "1576558" = list(
        geo = list(
          type = "p",
          wkt = "POINT(-107.9618 36.06054)"
        )
      )
    )
  )

  normalized <- heuristR:::.heurist_normalize_existing_details(details)

  expect_equal(normalized[["28"]][["1576558"]], "POINT(-107.9618 36.06054)")
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

test_that("WKT is extracted from Heurist geo detail payloads", {
  record <- list(
    rec_ID = "1",
    details = list(
      "1096" = list(
        "0" = list(
          geo = list(
            type = "p",
            wkt = "POINT(-110.1 35.2)"
          )
        )
      )
    )
  )

  expect_equal(
    heuristR:::.heurist_extract_wkt(record),
    "POINT(-110.1 35.2)"
  )
})

test_that("payloads can be converted to sf objects when sf is available", {
  testthat::skip_if_not_installed("sf")

  payload <- list(
    records = list(
      list(
        rec_ID = "1",
        rec_RecTypeID = "91",
        rec_Title = "Example Site",
        rec_Modified = "2026-04-08 00:00:00",
        rec_Added = "2026-04-08 00:00:00",
        rec_URL = NULL,
        details = list(
          "1096" = list(
            "0" = list(
              geo = list(
                type = "p",
                wkt = "POINT(-110.1 35.2)"
              )
            )
          )
        )
      )
    )
  )

  spatial <- heuristR:::.heurist_payload_to_sf(payload)

  expect_s3_class(spatial, "sf")
  expect_equal(nrow(spatial), 1)
  expect_equal(as.character(sf::st_geometry_type(spatial)[1]), "POINT")
  expect_equal(spatial$rec_Title[[1]], "Example Site")
})

test_that("spatial payloads warn when sf is unavailable", {
  payload <- list(
    records = list(
      list(
        rec_ID = "1",
        details = list(
          "1096" = list(
            "0" = list(
              geo = list(
                type = "p",
                wkt = "POINT(-110.1 35.2)"
              )
            )
          )
        )
      )
    )
  )

  testthat::local_mocked_bindings(
    .heurist_has_sf = function() FALSE,
    .package = "heuristR"
  )

  expect_warning(
    heuristR:::.heurist_warn_missing_sf(payload),
    "Spatial data were returned by Heurist"
  )
})
