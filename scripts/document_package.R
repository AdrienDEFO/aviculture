.libPaths(c(normalizePath("r-lib", winslash = "/", mustWork = TRUE), .libPaths()))

devtools::document()
