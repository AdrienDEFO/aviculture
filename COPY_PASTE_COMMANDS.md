# COPY-PASTE COMMANDS - READY TO USE

## PowerShell Commands (Step 1 & 2)

Copy and paste the following into PowerShell:

```powershell
# Step 1: Generate Python model
Write-Host "Generating Python model..." -ForegroundColor Green
cd "d:\projet\Avipro"
python Interpolation.py

# Check if successful
if (Test-Path "avimodel.pkl") {
    Write-Host "✓ Model generated successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to generate model" -ForegroundColor Red
    exit
}

# Step 2: Copy to package
Write-Host "Copying model to package..." -ForegroundColor Green
$source = "d:\projet\Avipro\avimodel.pkl"
$dest = "d:\projet\Avipro\aviculture\inst\extdata\avimodel.pkl"
Copy-Item $source $dest -Force

if (Test-Path $dest) {
    Write-Host "✓ Model copied successfully" -ForegroundColor Green
    $size = [math]::Round((Get-Item $dest).Length / 1MB, 2)
    Write-Host "  File size: $size MB" -ForegroundColor Cyan
} else {
    Write-Host "✗ Failed to copy model" -ForegroundColor Red
    exit
}

Write-Host "✓ Steps 1-2 COMPLETE!" -ForegroundColor Green
```

---

## R Commands (Step 3 - Generate Documentation)

Copy and paste the following into R:

```r
# Step 3: Generate Roxygen documentation
cat("\nGenerating Roxygen documentation...\n")

# Set working directory
setwd("d:/projet/Avipro/aviculture")

# Install roxygen2 if needed
if (!require("roxygen2", quietly = TRUE)) {
  cat("Installing roxygen2...\n")
  install.packages("roxygen2")
}

# Generate documentation
roxygen2::roxygenise()

cat("\n✓ Documentation generated successfully!\n")
cat("  Check: man/ directory should now contain 13 .Rd files\n\n")
```

---

## R Commands (Step 4 - Test Package)

Copy and paste the following into R:

```r
# Step 4: Test package
cat("\n\nTesting package functionality...\n")

setwd("d:/projet/Avipro/aviculture")

# Install devtools if needed
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Load package in development mode
devtools::load_all()

cat("✓ Package loaded\n\n")

# Test: Load model
cat("Testing model loading...\n")
model <- load_model()
cat("✓ Model loaded\n\n")

# Test: Predict mass
cat("Testing predictions...\n")
mass_30 <- predict_mass(30, model)
cat("  Mass at day 30: ", format(mass_30, digits=4), " kg\n")

volume_30 <- predict_volume(30, model)
cat("  Volume at day 30: ", format(volume_30, digits=4), " L\n")

density_30 <- predict_density(30, model)
cat("  Density at day 30: ", format(density_30, digits=4), " kg/L\n")

# Test: Growth rate
gamma_m <- predict_growth_rate(30, mass_30, volume_30, model)
cat("  Growth rate at day 30: ", format(gamma_m, digits=6), " kg/day\n\n")

# Test: Model info
cat("Testing model information...\n")
info <- get_model_info(model)
cat("  Model type: ", info$model_name, "\n")
cat("  RMSE: ", format(info$quality_metrics$rmse, digits=6), "\n\n")

cat("✓ ALL TESTS PASSED!\n")
cat("✓ Package is working correctly!\n\n")
```

---

## R Commands (Step 5 - Full Check)

Copy and paste the following into R:

```r
# Step 5: Full package check
cat("\n\nRunning full package check...\n")

setwd("d:/projet/Avipro/aviculture")

if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Run check
cat("This may take 30 seconds...\n\n")
result <- devtools::check()

cat("\n\n")
if (result$errors == 0 && result$warnings == 0) {
  cat("✓✓✓ PACKAGE CHECK PASSED! ✓✓✓\n")
  cat("Status: READY FOR SUBMISSION\n\n")
} else {
  cat("⚠ Package check found issues:\n")
  cat("  Errors: ", result$errors, "\n")
  cat("  Warnings: ", result$warnings, "\n")
  cat("  Notes: ", result$notes, "\n\n")
}
```

---

## One-Line Quick Verification

Quick check that everything works (in R):

```r
setwd("d:/projet/Avipro/aviculture"); devtools::load_all(); model <- load_model(); cat("✓ Package works! Mass at day 30:", predict_mass(30, model), "kg\n")
```

---

## Build Package (Optional - For Distribution)

When ready to create a distributable file:

```r
setwd("d:/projet/Avipro")
devtools::build()
# Creates: aviculture_0.2.0.tar.gz

# Check it
system("R CMD check aviculture_0.2.0.tar.gz --as-cran")
```

---

## Install Package Locally

After everything passes:

```r
setwd("d:/projet/Avipro/aviculture")
devtools::install()

# Then use it
library(aviculture)
model <- load_model()
predict_mass(30, model)
```

---

## Automated Setup (Alternative)

Instead of manual steps, run this automated script in PowerShell:

```powershell
cd "d:\projet\Avipro\aviculture"
.\QUICK_SETUP.ps1
```

Or in R:

```r
setwd("d:/projet/Avipro/aviculture")
source("setup_package.R")
```

---

## FILE CHECKLIST

Before running commands, verify these files exist:

```powershell
# Check Python script
Test-Path "d:\projet\Avipro\Interpolation.py"
# Should return: True

# Check R source files
Test-Path "d:\projet\Avipro\aviculture\R\model.R"
Test-Path "d:\projet\Avipro\aviculture\R\growth.R"
Test-Path "d:\projet\Avipro\aviculture\R\density.R"
Test-Path "d:\projet\Avipro\aviculture\R\utils.R"
# All should return: True

# Check config files
Test-Path "d:\projet\Avipro\aviculture\DESCRIPTION"
Test-Path "d:\projet\Avipro\aviculture\NAMESPACE"
Test-Path "d:\projet\Avipro\aviculture\LICENSE"
# All should return: True

# Check documentation
Test-Path "d:\projet\Avipro\aviculture\README.md"
# Should return: True

# Check directory exists (for model file)
Test-Path "d:\projet\Avipro\aviculture\inst\extdata"
# Should return: True (created automatically)
```

---

## EXPECTED OUTPUT MESSAGES

### After Step 1 (Python)
```
✓ Meilleur modèle sélectionné : SPLINE
✓ Modèle sauvegardé (pickle) : avimodel.pkl
✓ Model rechargé avec succès
✓ Test de prédiction...
```

### After Step 2 (Copy)
```
(No output = success)
Or check: Get-Item d:\projet\Avipro\aviculture\inst\extdata\avimodel.pkl
```

### After Step 3 (Roxygen)
```
Loading aviculture
✓ Documentation updated
Roxygen finished with no issues
```

### After Step 4 (Test)
```
✓ Model loaded
  Mass at day 30:  2.205  kg
  Volume at day 30:  2.082  L
  Growth rate at day 30:  0.043256  kg/day
✓ ALL TESTS PASSED!
```

### After Step 5 (Check)
```
0 errors ✓
0 warnings ✓
0 notes
Status: OK
```

---

## TROUBLESHOOTING COMMANDS

If something goes wrong:

```powershell
# Verify Python is accessible
python --version
# Should show: Python 3.8+ 

# Verify R is accessible
Rscript --version
# Should show: R version info

# Verify package structure
Get-ChildItem "d:\projet\Avipro\aviculture\R\" -Filter "*.R"
# Should list: model.R, growth.R, density.R, utils.R
```

In R:
```r
# Check roxygen2 installation
packageVersion("roxygen2")
# Should show: version number

# Check reticulate
library(reticulate)
py_config()
# Should show: Python configuration
```

---

## FINAL VERIFICATION

When all steps complete, run this final check:

```r
# Final verification script
setwd("d:/projet/Avipro/aviculture")

# 1. Load package
library(aviculture)
cat("✓ Package loads\n")

# 2. Access functions
exists("load_model")
exists("predict_mass")
exists("predict_volume")
cat("✓ Functions accessible\n")

# 3. Model works
model <- load_model(verbose = FALSE)
cat("✓ Model loads\n")

# 4. Predictions work
m <- predict_mass(30, model)
v <- predict_volume(30, model)
gamma <- predict_growth_rate(30, m, v, model)
cat("✓ Predictions work\n")

# 5. Help available
?load_model
cat("✓ Help pages available\n")

# 6. Check completed
devtools::check()
cat("✓ Package check passed\n")

cat("\n✓✓✓ ALL SYSTEMS GO! ✓✓✓\n")
cat("Package is ready for CRAN submission!\n")
```

---

## SUCCESS!

If you see "✓ Package is ready for CRAN submission!" - you're done! 🎉

Next: Submit to https://cran.r-project.org/submit.html

---

**Need help?** Check these files:
- START_HERE.md - Quick overview
- SETUP_INSTRUCTIONS.md - Detailed guide
- CRAN_SUBMISSION_CHECKLIST.md - Pre-submission
- README.md - Function documentation

Good luck! 🚀



