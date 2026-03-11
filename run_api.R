#!/usr/bin/env Rscript
# Plumber API Server for aviculture
library(plumber)
library(aviculture)

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║     AVICULTURE PLUMBER API SERVER - STARTING                ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n")
cat("\n")

api_file <- system.file("plumber", "api.R", package = "aviculture")

if (!file.exists(api_file)) {
  stop("API file not found: ", api_file)
}

cat("✓ Package: aviculture loaded\n")
cat("✓ API file: ", api_file, "\n")
cat("✓ Server: http://localhost:8000\n")
cat("✓ Documentation: http://localhost:8000/__docs__\n")
cat("\n")

pr <- plumb_file(api_file)
cat("✓ API ready - listening on port 8000...\n\n")

# Run server
pr$run(host = "0.0.0.0", port = 8000)



