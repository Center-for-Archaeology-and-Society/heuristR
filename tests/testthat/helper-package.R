if (!exists("heurist_session", mode = "function")) {
  pkg_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
  pkgload::load_all(pkg_root, helpers = FALSE, quiet = TRUE, export_all = FALSE)
}
