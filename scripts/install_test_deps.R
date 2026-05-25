options(repos = c(CRAN = "https://cloud.r-project.org"))

pkgs <- c(
  # Testing / checks
  "testthat",
  "devtools",
  "roxygen2",
  "pkgload",
  "withr",
  # Vignettes / docs
  "knitr",
  "rmarkdown"
)

installed <- rownames(installed.packages())
missing <- setdiff(pkgs, installed)

if (length(missing) == 0) {
  message("All test dependencies are already installed.")
  quit(status = 0)
}

message("Installing missing packages: ", paste(missing, collapse = ", "))
install.packages(missing)
