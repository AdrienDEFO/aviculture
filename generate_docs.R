# Script to generate documentation files for aviculture package
setwd('D:/projet/Avipro/aviculture')

cat('=== ROXYGEN2 DOCUMENTATION GENERATION ===\n\n')

cat('Step 1: Loading roxygen2...\n')
library(roxygen2)

cat('Step 2: Creating man directory if needed...\n')
if (!dir.exists('man')) {
  dir.create('man')
  cat('  ✓ man/ directory created\n')
} else {
  cat('  ✓ man/ directory exists\n')
}

cat('\nStep 3: Generating documentation from source code comments...\n')
roxygen2::roxygenise(roclets = c('rd', 'collate', 'namespace'))

cat('\nStep 4: Verifying generated files...\n')
rd_files <- list.files('man', full.names = FALSE)
cat('  Generated', length(rd_files), 'files\n')
if (length(rd_files) > 0) {
  cat('  Files:\n')
  for (f in sort(rd_files)[1:min(10, length(rd_files))]) {
    cat('    -', f, '\n')
  }
  if (length(rd_files) > 10) {
    cat('    ... and', length(rd_files) - 10, 'more files\n')
  }
}

cat('\n✓ Documentation generation completed!\n')



