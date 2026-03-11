# Script to install and load the aviculture package
cat("Installing devtools...\n")
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools", repos = "http://cran.r-project.org")
}

cat("Installing package dependencies...\n")
devtools::install_deps(dependencies = TRUE)

cat("Building and installing the package...\n")
devtools::install(".")

cat("Loading the package...\n")
devtools::load_all(".")

cat("Package installation completed!\n")



