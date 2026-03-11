#!/usr/bin/env Rscript
#
# Plumber API Server for aviculture Package
# 
# Usage:
#   Rscript start_api.R
#   # or in R:
#   # source("start_api.R")
#
# Server will run on http://localhost:8000
#

# Load required packages
library(plumber)
library(aviculture)

# Get the API file path
api_file <- system.file("plumber", "api.R", package = "aviculture")

if (!file.exists(api_file)) {
  stop("API file not found: ", api_file)
}

cat("Starting Aviculture Plumber API...\n")
cat("API file: ", api_file, "\n")
cat("Server: http://localhost:8000\n")
cat("Documentation: http://localhost:8000/__docs__\n\n")

# Create plumber router
pr <- plumb_file(api_file)

# Run the server
pr$run(host = "0.0.0.0", port = 8000)



