# Aviculture Plumber API Setup

## Overview

The aviculture R package now includes numerical methods (derivative, trapezoidal integration, Euler ODE solver by default with optional RK4) and exposes them via a Plumber API server. This allows the `avicol-opt` React frontend to call R package functions via HTTP.

## API Server Configuration

### Port Configuration
- **Plumber API:** `http://localhost:8000` (recommended, official)
- **Flask API:** `http://localhost:5000` (legacy, deprecated)

The frontend now defaults to calling the Plumber API on port 8000.

## Starting the API Server

### Option 1: Using Rscript (Recommended)

```bash
cd d:\projet\Avipro\aviculture
Rscript start_api.R
```

The server will launch on `http://localhost:8000`.

### Option 2: In R Console

```r
library(aviculture)
library(plumber)

api_file <- system.file("plumber", "api.R", package = "aviculture")
pr <- plumb_file(api_file)
pr$run(host = "0.0.0.0", port = 8000)
```

### Option 3: Using plumber::plumb()

```r
library(plumber)
pr <- plumb("d:/projet/Avipro/aviculture/inst/plumber/api.R")
pr$run(host = "0.0.0.0", port = 8000)
```

## API Endpoints

### `/simulate` (POST)
Runs a single population simulation using the aviculture model.

**Request:**
```json
{
  "initial_population": 100,
  "days": 35,
  "feed_price": 300,
  "bird_price": 2500,
  "daily_feed": 0.03,
  "daily_deaths": 0.01,
  "optav_enabled": false,
  "model_type": "standard",
  "dt": 0.1,
  "method": "euler",
  "currency": "XOF"
}
```

**Response:**
```json
{
  "time": [0, 1, 2, ...],
  "population": [100, 99.5, 99.1, ...],
  "average_mass": [0.5, 0.7, 0.9, ...],
  "total_mass": [50, 70.3, 89.1, ...],
  "cumulative_feed_cost": [0, 900, 1800, ...],
  "cumulative_profit": [0, -900, -1800, ...],
  "growth_rate": [0, -0.5, -0.4, ...]
}
```

### `/sensitivity` (POST)
Runs sensitivity analysis on a parameter.

**Request:**
```json
{
  "base_params": {
    "initial_population": 100,
    "days": 35,
    "feed_price": 300,
    "bird_price": 2500,
    "daily_feed": 0.03,
    "daily_deaths": 0.01
  },
  "sensitivity_config": {
    "parameter_name": "feed_price",
    "variation": 0.2,
    "steps": 5
  },
  "currency": "XOF"
}
```

**Response:**
```json
{
  "baseline_profit": 50000,
  "results": [
    {"parameter_value": 240, "profit": 55000, "elasticity": -0.5},
    {"parameter_value": 270, "profit": 52500, "elasticity": -0.25},
    ...
  ],
  "parameter": "feed_price",
  "variation_range": [240, 360]
}
```

### `/derivative` (POST)
Computes centered difference derivative.

**Request:**
```json
{
  "y_prev": 100,
  "y_next": 110,
  "dt": 1
}
```

**Response:**
```json
{
  "derivative": 5
}
```

### `/integral-trapezoid` (POST)
Integrates using trapezoidal rule.

**Request:**
```json
{
  "ys": [0, 1, 2, 3, 4, 5],
  "ts": [0, 1, 2, 3, 4, 5]
}
```

**Response:**
```json
{
  "integral": 12.5
}
```

### `/health` (GET)
Health check endpoint.

**Request:**
```bash
curl http://localhost:8000/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "aviculture-api",
  "version": "1.0.0",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Interactive API Documentation

Once the server is running, visit:
```
http://localhost:8000/__docs__/
```

This provides interactive API documentation with Swagger UI.

## Frontend Integration

The `avicol-opt` React frontend automatically detects the API availability:

1. **If API unavailable:** Falls back to local JavaScript simulation (`modelService.ts`)
2. **If API available:** Calls Plumber endpoints on port 8000
3. **Toggle:** Use "Utiliser l'API locale" checkbox in simulation header to enable/disable API calls

## Troubleshooting

### API Not Responding

```r
# Check if plumber is installed
library(plumber)

# Verify aviculture package is loaded
library(aviculture)

# Test API file exists
file.exists(system.file("plumber", "api.R", package = "aviculture"))
```

### Port Already in Use

Change the port in `start_api.R`:

```r
pr$run(host = "0.0.0.0", port = 8001)  # Use 8001 instead
```

Then update frontend to call `http://localhost:8001`.

### Model Loading Error

Ensure `avimodel.pkl` exists:
```r
system.file("extdata", "avimodel.pkl", package = "aviculture")
```

If missing, run package setup:
```r
source("d:/projet/Avipro/aviculture/setup_package.R")
```

## Performance Notes

- **Plumber API:** ~50-100ms per request (includes R model loading)
- **Local JS:** ~5-10ms per request (no network latency)
- For real-time sensitivity analysis with many points, consider pre-computing or caching results

## Dependencies

The Plumber API requires:
- `plumber` (≥ 1.0.0)
- `jsonlite` 
- `aviculture` (with numerical.R functions)

Install missing dependencies:
```r
install.packages(c("plumber", "jsonlite"))
```

## Next Steps

1. Start the API server: `Rscript start_api.R`
2. Open the avicol-opt frontend
3. Check "Utiliser l'API locale" to enable API calls
4. Run simulations—they will call R package functions via Plumber

---

**Note:** The Flask API (`api/app.py`) is now superseded by the Plumber API. You can still use Flask for testing, but Plumber is the official backend.



