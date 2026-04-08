test_that("live metadata helpers return structure", {
  skip_if_no_live_heurist()

  session <- heurist_live_session()

  rectypes <- heurist_rectypes(session)
  fields <- heurist_fields(session)
  structure_all <- heurist_structure(session)
  raw_entity <- heurist_raw_entity(session, action = "structure", entity = "all")

  expect_gt(length(rectypes), 0)
  expect_gt(length(fields), 0)
  expect_true(!is.null(structure_all$defRecStructure))
  expect_true(!is.null(raw_entity$defRecTypes))
})
