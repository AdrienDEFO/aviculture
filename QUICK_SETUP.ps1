# QUICK SETUP COMMANDS FOR aviculture PACKAGE
# Copy and paste these commands in PowerShell

# ==================== STEP 1: Run Python to generate model ====================
Write-Host "Step 1: Generate Python model" -ForegroundColor Green
cd "d:\projet\Avipro"
python Interpolation.py

# Check if avimodel.pkl was created
if (Test-Path "avimodel.pkl") {
    Write-Host "✓ avimodel.pkl created successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to create avimodel.pkl" -ForegroundColor Red
    exit
}

# ==================== STEP 2: Copy model to package ====================
Write-Host "`nStep 2: Copy model to package" -ForegroundColor Green
$source = "d:\projet\Avipro\avimodel.pkl"
$destination = "d:\projet\Avipro\aviculture\inst\extdata\avimodel.pkl"

if (!(Test-Path "d:\projet\Avipro\aviculture\inst\extdata")) {
    New-Item -ItemType Directory -Path "d:\projet\Avipro\aviculture\inst\extdata" -Force
}

Copy-Item $source $destination -Force
Write-Host "✓ Model copied to package" -ForegroundColor Green

# ==================== STEP 3: Generate documentation in R ====================
Write-Host "`nStep 3: Generate Roxygen documentation" -ForegroundColor Green
cd "d:\projet\Avipro\aviculture"

$r_code = @"
setwd('d:/projet/Avipro/aviculture')
if (!require('roxygen2')) install.packages('roxygen2')
roxygen2::roxygenise()
cat('\n✓ Documentation generated\n')
"@

Rscript -e $r_code

# ==================== STEP 4: Test the package ====================
Write-Host "`nStep 4: Test package installation" -ForegroundColor Green

$r_test = @"
setwd('d:/projet/Avipro/aviculture')
if (!require('devtools')) install.packages('devtools')
devtools::load_all()
model <- load_model()
mass_30 <- predict_mass(30, model)
cat('Test: Mass at day 30 =', mass_30, 'kg\n')
cat('✓ Package test successful\n')
"@

Rscript -e $r_test

# ==================== STEP 5: Build package ====================
Write-Host "`nStep 5: Build package tarball" -ForegroundColor Green
cd "d:\projet\Avipro"
$r_build = @"
system('R CMD build aviculture')
cat('✓ Package built successfully\n')
"@

Rscript -e $r_build

Write-Host "`n✓ SETUP COMPLETE!" -ForegroundColor Green
Write-Host "Package location: d:\projet\Avipro\aviculture" -ForegroundColor Cyan
Write-Host "To install: install.packages('aviculture_0.2.0.tar.gz', repos=NULL, type='source')" -ForegroundColor Cyan



