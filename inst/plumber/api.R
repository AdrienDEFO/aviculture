#* Aviculture Plumber API
#* 
#* Exposes aviculture R package functions for broiler growth simulations.
#* Backend for avicol-opt React frontend.
#*
#* @apiTitle Aviculture Simulation API
#* @apiVersion 1.0.0

# Load the package to ensure all functions are available
library(aviculture)

#* @post /simulate
#* Run a single population simulation
#* 
#* @param params List of model parameters (JSON body)
#* @return Simulation results with time series data
function(req) {
  params <- jsonlite::fromJSON(jsonlite::toJSON(req$body))
  
  # Extract parameters with defaults
  initial_population <- params$initial_population %||% 100
  days <- params$days %||% 35
  feed_price <- params$feed_price %||% 300
  bird_price <- params$bird_price %||% 2500
  daily_feed <- params$daily_feed %||% 0.03
  daily_deaths <- params$daily_deaths %||% 0.01
  optav_enabled <- params$optav_enabled %||% FALSE
  model_type <- params$model_type %||% "standard"
  dt <- params$dt %||% NULL
  method <- params$method %||% "euler"
  
  # Run simulation using package functions
  results <- run_aviculture_simulation(
    initial_population = initial_population,
    days = days,
    feed_price = feed_price,
    bird_price = bird_price,
    daily_feed = daily_feed,
    daily_deaths = daily_deaths,
    optav_enabled = optav_enabled,
    model_type = model_type,
    dt = dt,
    method = method
  )
  
  return(results)
}

#* @post /sensitivity
#* Run sensitivity analysis on model parameters
#*
#* @param params List with base_params and sensitivity_config (JSON body)
#* @return Sensitivity analysis results
function(req) {
  params <- jsonlite::fromJSON(jsonlite::toJSON(req$body))
  
  base_params <- params$base_params
  sensitivity_config <- params$sensitivity_config
  
  results <- run_sensitivity_analysis(
    base_params = base_params,
    sensitivity_config = sensitivity_config
  )
  
  return(results)
}

#* @post /derivative
#* Compute centered difference derivative
#*
#* @param y_prev Numeric. Value at t - dt
#* @param y_next Numeric. Value at t + dt
#* @param dt Numeric. Time step (default: 1)
#* @return Derivative value
function(y_prev, y_next, dt = 1) {
  list(
    derivative = derivative_central(y_prev = as.numeric(y_prev), 
                                   y_next = as.numeric(y_next), 
                                   dt = as.numeric(dt))
  )
}

#* @post /integral-trapezoid
#* Integrate using trapezoidal rule
#*
#* @param ys Numeric vector. Function values
#* @param ts Numeric vector. Time nodes (optional)
#* @return Integral value
function(req) {
  body <- jsonlite::fromJSON(jsonlite::toJSON(req$body))
  
  ys <- as.numeric(body$ys)
  ts <- if (!is.null(body$ts)) as.numeric(body$ts) else NULL
  
  list(
    integral = integral_trapezoid(ys = ys, ts = ts)
  )
}

#* @post /rk4-integrate
#* Solve ODE using RK4 method
#*
#* @param params List with: f_string (function body), y0, t0, t_final, dt
#* @return Time series solution
function(req) {
  body <- jsonlite::fromJSON(jsonlite::toJSON(req$body))
  
  # For security/simplicity, accept pre-computed function or use predefined ones
  y0 <- as.numeric(body$y0)
  t0 <- as.numeric(body$t0 %||% 0)
  t_final <- as.numeric(body$t_final)
  dt <- as.numeric(body$dt %||% 0.1)
  
  # This would require dynamic function evaluation; 
  # for now, we skip and use simulation directly
  # In production, use more robust approach
  
  list(
    message = "Use /simulate endpoint for full ODE solutions",
    note = "Use method='euler' (default) or method='rk4' in /simulate"
  )
}

#* Health check
#* @get /health
function() {
  list(
    status = "healthy",
    service = "aviculture-api",
    version = "1.0.0",
    timestamp = Sys.time()
  )
}



