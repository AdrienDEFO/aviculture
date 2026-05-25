required_packages <- c(
  "devtools", "roxygen2", "testthat", "rcmdcheck",
  "knitr", "rmarkdown", "covr", "remotes"
)

db <- installed.packages()
dependencies <- tools::package_dependencies(
  required_packages,
  db = db,
  which = c("Depends", "Imports", "LinkingTo"),
  recursive = TRUE
)

all_packages <- sort(unique(c(required_packages, unlist(dependencies, use.names = FALSE))))
target_library <- normalizePath("r-lib", winslash = "/", mustWork = FALSE)
dir.create(target_library, recursive = TRUE, showWarnings = FALSE)

package_rows <- intersect(all_packages, rownames(db))
package_info <- db[package_rows, , drop = FALSE]

message("Target library: ", target_library)
message("Copying ", nrow(package_info), " packages into the local project library.")

for (package_name in rownames(package_info)) {
  source_path <- package_info[package_name, "LibPath"]
  source_dir <- file.path(source_path, package_name)
  target_dir <- file.path(target_library, package_name)

  if (dir.exists(target_dir)) {
    unlink(target_dir, recursive = TRUE, force = TRUE)
  }

  success <- file.copy(source_dir, target_library, recursive = TRUE)
  if (!isTRUE(success)) {
    stop("Failed to copy package: ", package_name, call. = FALSE)
  }
}

message("Local test library is ready.")
message("Use one of the following commands from the project root:")
message("  devtools::document()")
message("  devtools::test()")
message("  devtools::check()")
