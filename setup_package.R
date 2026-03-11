#!/usr/bin/env Rscript

# AUTOMATED SETUP SCRIPT FOR aviculture PACKAGE
# Run this from R: source("setup_package.R")

cat("\n")
cat("=" %*% 60)
cat("\n")
cat("AVICULTURE PACKAGE SETUP - AUTOMATED INSTALLATION\n")
cat("=" %*% 60)
cat("\n\n")

# Check working directory
wd <- getwd()
cat("Working directory:", wd, "\n")

# Step 1: Check if avimodel.pkl exists
cat("\n[Step 1] Checking for Python model file...\n")
model_path <- "inst/extdata/avimodel.pkl"
if (file.exists(model_path)) {
  cat("✓ Found:", model_path, "\n")
  file_size <- file.size(model_path) / (1024^2)  # MB
  cat("  File size:", format(file_size, digits = 3), "MB\n")
} else {
  cat("⚠ NOT FOUND:", model_path, "\n")
  cat("  Please copy avimodel.pkl from d:/projet/Avipro/ first\n")
  cat("  And place it in: inst/extdata/\n")
  stop("Model file missing. Aborting.")
}

# Step 2: Install roxygen2 if needed
cat("\n[Step 2] Checking roxygen2 installation...\n")
if (!require("roxygen2", quietly = TRUE)) {
  cat("Installing roxygen2...\n")
  install.packages("roxygen2")
}
cat("✓ roxygen2 is available\n")

# Step 3: Install devtools if needed
cat("\n[Step 3] Checking devtools installation...\n")
if (!require("devtools", quietly = TRUE)) {
  cat("Installing devtools...\n")
  install.packages("devtools")
}
cat("✓ devtools is available\n")

# Step 4: Generate documentation from Roxygen
cat("\n[Step 4] Generating Roxygen documentation...\n")
tryCatch({
  roxygen2::roxygenise()
  cat("✓ Documentation generated successfully\n")
}, error = function(e) {
  cat("⚠ Error generating documentation:\n")
  print(e)
})

# Step 5: Load all functions
cat("\n[Step 5] Loading package in development mode...\n")
tryCatch({
  devtools::load_all()
  cat("✓ Package loaded successfully\n")
}, error = function(e) {
  cat("⚠ Error loading package:\n")
  print(e)
})

# Step 6: Test basic functionality
cat("\n[Step 6] Testing basic functionality...\n")
tryCatch({
  model <- load_model(verbose = FALSE)
  cat("✓ Model loaded\n")
  
  mass_30 <- predict_mass(30, model)
  cat("  Mass at day 30:", format(mass_30, digits = 4), "kg\n")
  
  volume_30 <- predict_volume(30, model)
  cat("  Volume at day 30:", format(volume_30, digits = 4), "L\n")
  
  gamma_m <- predict_growth_rate(30, mass_30, volume_30, model)
  cat("  Growth rate at day 30:", format(gamma_m, digits = 6), "kg/day\n")
  
  cat("✓ Basic functionality test passed\n")
}, error = function(e) {
  cat("⚠ Error during functionality test:\n")
  print(e)
})

# Step 7: Package check
cat("\n[Step 7] Running package check...\n")
tryCatch({
  check_result <- devtools::check(quiet = TRUE)
  cat("✓ Package check completed\n")
  cat("  Errors:", check_result$errors, "\n")
  cat("  Warnings:", check_result$warnings, "\n")
  cat("  Notes:", check_result$notes, "\n")
}, error = function(e) {
  cat("⚠ Package check failed:\n")
  print(e)
})

# Summary
cat("\n")
cat("=" %*% 60)
cat("\n")
cat("SETUP COMPLETE!\n")
cat("=" %*% 60)
cat("\n\n")

cat("Next steps:\n")
cat("1. Verify package installation: library(aviculture)\n")
cat("2. Try examples: ?predict_mass\n")
cat("3. Build package: devtools::build()\n")
cat("4. For CRAN submission: devtools::check(remote=TRUE)\n\n")

cat("Package location:", getwd(), "\n")
cat("Model file:", model_path, "\n\n")

cat("Documentation available at: README.md\n")
cat("Questions? See: SETUP_INSTRUCTIONS.md\n\n")



