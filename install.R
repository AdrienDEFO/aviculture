# Installation script for aviculture package
setwd('D:/projet/Avipro/aviculture')

cat('=== AVICULTURE PACKAGE INSTALLATION ===\n')
cat('Working directory:', getwd(), '\n\n')

# Step 1: Check if roxygen2 has generated files
cat('Step 1: Checking generated files...\n')
rd_files <- list.files('man', pattern = '\\\\.Rd$')
cat('  Found', length(rd_files), 'Rd files\n')
cat('  Files:', paste(rd_files[1:min(5, length(rd_files))], collapse=', '), '...\n\n')

# Step 2: Install the package
cat('Step 2: Installing package...\n')
library(devtools)

result <- tryCatch({
  install('.')
  TRUE
}, error = function(e) {
  cat('ERROR during install:', e$message, '\n')
  FALSE
})

if (result) {
  cat('\nStep 3: Verifying installation...\n')
  tryCatch({
    library(aviculture)
    cat('  ✓ Package loaded successfully\n')
    cat('  Version:', paste(packageVersion('aviculture')), '\n')
    cat('  Functions:', length(ls('package:aviculture')), '\n')
  }, error = function(e) {
    cat('  ERROR loading package:', e$message, '\n')
  })
} else {
  cat('\nInstallation FAILED\n')
}

cat('\n=== DONE ===\n')



