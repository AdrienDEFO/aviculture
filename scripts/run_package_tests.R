options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

devtools::test()
