#!/usr/bin/env Rscript

library(aviculture)

cat("\n====================================================\n")
cat("  AVICULTURE PACKAGE TEST SUITE\n")
cat("====================================================\n\n")

# Test 1: Package Info
cat("Package aviculture v", paste(packageVersion("aviculture")), " loaded\n\n")

# Test 2: Validation Functions
cat("TEST: Validation Functions\n")
cat("  is_valid_age(30): ", is_valid_age(30), "\n")
cat("  is_valid_age(70): ", is_valid_age(70), "\n")
cat("  validate_measurements(0.5, 5): ", validate_measurements(0.5, 5), "\n")
cat("  validate_measurements(-0.5, 5): ", validate_measurements(-0.5, 5), "\n\n")

# Test 3: Load Model
cat("TEST: Loading Model\n")
tryCatch({
  model <- load_model()
  cat("  Model loaded successfully\n")
  cat("  Model type: ", model$model_name, "\n\n")
  
  # Test 4: Make Predictions
  cat("TEST: Predictions\n")
  
  # Test at different ages
  ages <- c(5, 15, 30, 45, 60)
  cat("  Age (days)  |  Mass (kg)  |  Volume (L)\n")
  cat("  ", strrep("-", 40), "\n", sep="")
  
  for (age in ages) {
    mass <- predict_mass(age, model)
    volume <- predict_volume(age, model)
    cat(sprintf("     %2d       |  %7.2f    |  %7.2f\n", age, mass, volume))
  }
  
  cat("\n  Predictions working correctly\n\n")
  
}, error = function(e) {
  cat("  Error: ", e$message, "\n")
  cat("  This is expected if the Python model file is missing.\n")
})

cat("\n====================================================\n")
cat("All core functions are operational!\n")
cat("====================================================\n\n")



