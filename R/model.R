#' Aviculture Growth Model for Ross 308 Broilers
#'
#' An R package for simulating and predicting broiler chicken growth curves
#' based on a multi-tissue density model. The package implements interpolation
#' methods (Spline, Lagrange, Gompertz, RBF) to model mass and volume growth
#' dynamics.
#'
#'
#' @import reticulate
#' @import methods
#' @importFrom stats cor
#' @importFrom utils tail
#'
#' @keywords internal
#'
#' @seealso
#'   \code{\link{load_model}}, \code{\link{predict_mass}},
#'   \code{\link{predict_volume}}, \code{\link{predict_growth_rate}}
#'
#' @examples
#' \dontrun{
#'   # Load the pre-trained model
#'   model <- load_model()
#'
#'   # Get mass at age 30 days
#'   mass_30 <- predict_mass(30, model)
#'   print(mass_30)
#'
#'   # Get growth rate
#'   gamma_m <- predict_growth_rate(30, mass_30, model)
#'   print(gamma_m)
#' }
#'
"_PACKAGE"

#' Load the Pre-trained Aviculture Model
#'
#' Loads the pre-trained interpolation model from a pickle file.
#' The model contains interpolation functions, density calculations,
#' and tissue composition data for Ross 308 broilers.
#'
#' @param model_path Character. Path to a model file. If NULL, the package
#'   loads the registered bundled model from \code{inst/extdata}.
#' @param verbose Logical. If TRUE, print loading messages. Default is TRUE.
#'
#' @return
#' A list containing:
#' \item{model_name}{Name of the interpolation method (Spline, Lagrange, etc.)}
#' \item{m_bar}{Function: average mass at age a}
#' \item{gamma_m}{Function: mass growth rate}
#' \item{gamma_v}{Function: volume growth rate}
#' \item{rho}{Function: average density at age a}
#' \item{tissue_densities}{List of tissue densities (kg/L)}
#' \item{alpha}{Numeric: mass elasticity parameter}
#' \item{beta}{Numeric: volume elasticity parameter}
#' \item{age}{Numeric vector: training ages (1:60 days)}
#' \item{mass}{Numeric vector: training mass data (kg)}
#' \item{volume}{Numeric vector: training volume data (L)}
#' \item{quality_metrics}{List of model quality scores}
#'
#' @details
#' The model is a Python object serialized using pickle. It includes:
#' \itemize{
#'   \item Spline, Lagrange, Gompertz, and RBF interpolation methods
#'   \item Multi-tissue density model with 5 tissue types
#'   \item Validation metrics (RMSE, stability scores)
#' }
#'
#' @examples
#' \dontrun{
#'   # Load the default model
#'   model <- load_model()
#'   cat("Model type:", model$model_name, "\n")
#'   cat("RMSE:", model$quality_metrics$rmse, "\n")
#' }
#'
#' @export
load_model <- function(model_path = NULL, verbose = TRUE) {

  # Resolve the single registered model bundled in the package.
  if (is.null(model_path)) {
    candidates <- c(
      system.file("extdata", "avimodel_joblib.pkl", package = "aviculture"),
      system.file("extdata", "avimodel.pkl", package = "aviculture")
    )
    candidates <- candidates[nzchar(candidates)]
    existing <- candidates[file.exists(candidates)]
    if (length(existing) == 0) {
      stop("No registered model found in inst/extdata (expected avimodel_joblib.pkl or avimodel.pkl).")
    }
    # Keep one source of truth: first valid candidate wins.
    model_path <- existing[[1]]
  }

  if (!file.exists(model_path)) {
    stop("Model file not found: ", model_path)
  }
  
  if (verbose) {
    message("[aviculture] Loading model from: ", model_path)
  }
  
  # Load the model
  tryCatch({
    model <- NULL

    # Prefer joblib, fallback to pickle if needed.
    model <- tryCatch({
      joblib <- reticulate::import("joblib")
      joblib$load(model_path)
    }, error = function(e) {
      py_pickle <- reticulate::import("pickle")
      builtins <- reticulate::import_builtins()
      file_conn <- builtins$open(model_path, "rb")
      on.exit(file_conn$close(), add = TRUE)
      py_pickle$load(file_conn)
    })

    # Validate contract used by package functions.
    required_fields <- c("m_bar", "gamma_m", "gamma_v", "rho")
    has_field <- sapply(required_fields, function(f) {
      tryCatch(!is.null(model[[f]]), error = function(e) FALSE)
    })
    if (!all(has_field)) {
      missing_fields <- required_fields[!has_field]
      stop("Loaded model is missing required field(s): ", paste(missing_fields, collapse = ", "))
    }

    if (verbose) {
      message("[aviculture] Model loaded successfully")
      model_name <- tryCatch(as.character(model$model_name), error = function(e) "unknown")
      rmse <- tryCatch(as.numeric(model$quality_metrics$rmse), error = function(e) NA_real_)
      message("[aviculture] Type: ", model_name)
      if (!is.na(rmse)) {
        message("[aviculture] RMSE: ", format(rmse, digits = 6))
      }
      message("[aviculture] Registered source: ", model_path)
    }

    # Attach runtime metadata for traceability.
    attr(model, "aviculture_metadata") <- list(
      package = "aviculture",
      loaded_at = as.character(Sys.time()),
      model_path = model_path,
      model_name = tryCatch(as.character(model$model_name), error = function(e) "unknown")
    )

    return(model)
  }, error = function(e) {
    stop("Failed to load model: ", e$message)
  })
}


#' Predict Average Mass at Given Age
#'
#' Computes the reference mass trajectory at the specified age
#' using the loaded interpolation model.
#'
#' @param age Numeric vector. Age in days (1-60 recommended).
#' @param model A model object from \code{\link{load_model}}.
#' @param simplify Logical. If TRUE, return vector; if FALSE, return list.
#'   Default is TRUE.
#'
#' @return
#' Numeric vector or list of predicted masses (kg) at the given ages.
#'
#' @details
#' The function calls the \code{m_bar} function from the loaded model.
#' Valid range is 1-60 days; extrapolation beyond this range is not recommended.
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   
#'   # Single age
#'   m30 <- predict_mass(30, model)
#'   
#'   # Multiple ages
#'   ages <- c(10, 20, 30, 40, 50)
#'   masses <- sapply(ages, function(a) predict_mass(a, model))
#'   plot(ages, masses, type = 'l', main = "Reference Growth Curve")
#' }
#'
#' @export
predict_mass <- function(age, model, simplify = TRUE) {
  
  if (!is.list(model) || !exists("m_bar", where = model)) {
    stop("model must be an object returned by load_model()")
  }
  
  if (!is.numeric(age)) {
    stop("age must be numeric")
  }
  
  # Call the Python function for each age
  result <- tryCatch({
    if (length(age) == 1) {
      as.numeric(model$m_bar(age))
    } else {
      sapply(age, function(a) as.numeric(model$m_bar(a)))
    }
  }, error = function(e) {
    stop("Error predicting mass: ", e$message)
  })
  
  return(result)
}


#' Predict Average Volume at Given Age
#'
#' Computes the reference volume trajectory at the specified age
#' using the loaded model and density function.
#'
#' @param age Numeric vector. Age in days (1-60 recommended).
#' @param model A model object from \code{\link{load_model}}.
#'
#' @return
#' Numeric vector of predicted volumes (L) at the given ages.
#'
#' @details
#' Volume is computed as: V(age) = M(age) / rho(age),
#' where M is mass and rho is the density function.
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   vol_30 <- predict_volume(30, model)
#'   print(vol_30)
#' }
#'
#' @export
predict_volume <- function(age, model) {
  
  if (!is.list(model) || !exists("rho", where = model)) {
    stop("model must be an object returned by load_model()")
  }
  
  if (!is.numeric(age)) {
    stop("age must be numeric")
  }
  
  tryCatch({
    mass <- predict_mass(age, model)
    density <- if (length(age) == 1) {
      as.numeric(model$rho(age))
    } else {
      sapply(age, function(a) as.numeric(model$rho(a)))
    }
    
    volume <- mass / density
    return(volume)
  }, error = function(e) {
    stop("Error predicting volume: ", e$message)
  })
}


#' Predict Density at Given Age
#'
#' Computes the average tissue density at the specified age using
#' the multi-tissue density model.
#'
#' @param age Numeric vector. Age in days (1-60 recommended).
#' @param model A model object from \code{\link{load_model}}.
#'
#' @return
#' Numeric vector of densities (kg/L) at the given ages.
#'
#' @details
#' Density is calculated as a weighted average of tissue densities
#' (bone, muscle, fat, blood, organs) with proportions that vary with age.
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   
#'   ages <- 1:60
#'   densities <- sapply(ages, function(a) predict_density(a, model))
#'   plot(ages, densities, type = 'l', 
#'        xlab = "Age (days)", ylab = "Density (kg/L)",
#'        main = "Broiler Density Evolution")
#' }
#'
#' @export
predict_density <- function(age, model) {
  
  if (!is.list(model) || !exists("rho", where = model)) {
    stop("model must be an object returned by load_model()")
  }
  
  if (!is.numeric(age)) {
    stop("age must be numeric")
  }
  
  tryCatch({
    if (length(age) == 1) {
      as.numeric(model$rho(age))
    } else {
      sapply(age, function(a) as.numeric(model$rho(a)))
    }
  }, error = function(e) {
    stop("Error predicting density: ", e$message)
  })
}


#' Run a Single Population Simulation
#'
#' Simulates a flock of broilers over time using explicit Euler or RK4 schemes.
#' Accounts for growth, mortality, and sales dynamics.
#'
#' @param initial_population Numeric. Starting flock size. Default: 100.
#' @param days Numeric. Simulation duration in days. Default: 35.
#' @param feed_price Numeric. Feed cost (currency per kg). Default: 300.
#' @param bird_price Numeric. Sale price (currency per bird). Default: 2500.
#' @param daily_feed Numeric. Feed consumption per bird per day (kg). Default: 0.03.
#' @param daily_deaths Numeric. Baseline mortality rate (daily fraction). Default: 0.01.
#' @param model A model object from \code{\link{load_model}}. If NULL, loads default.
#' @param optav_enabled Logical. If TRUE, use optimized OPTAV parameters. Default: FALSE.
#' @param model_type Character. "standard" or other variants. Default: "standard".
#' @param dt Numeric. Time step in days (small for stability). Default: 0.1.
#' @param demand Numeric. Demand rate (birds per day) or vector. Used if demand_profile is NULL.
#' @param demand_profile Function or numeric vector providing demand at time t.
#' @param objective Character. Objective: "profit", "satisfaction", or "balanced".
#' @param method Character. Numerical scheme: "euler" (default) or "rk4".
#' 
#' @return
#' A data frame with columns:
#' \item{time}{Day (0 to days)}
#' \item{population}{Living birds at time t}
#' \item{average_mass}{Mean mass per bird (kg)}
#' \item{total_mass}{Total flock mass (kg)}
#' \item{marketable_population}{Estimated marketable birds at time t}
#' \item{economic_potential}{Economic potential estimate at time t}
#' \item{cumulative_feed_cost}{Total feed cost to date}
#' \item{cumulative_profit}{Net profit to date}
#' \item{growth_rate}{Population derivative (birds/day)}
#'
#' @details
#' Uses explicit Euler by default with a small time step (default 0.1 day).
#' Optionally uses RK4 if \code{method="rk4"}.
#' Population dynamics:
#' dN/dt = births - deaths - sales
#'
#' OPTAV model adjusts feed efficiency and reduces mortaliy through
#' optimized management practices.
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   sim <- run_aviculture_simulation(
#'     initial_population = 100,
#'     days = 35,
#'     feed_price = 300,
#'     bird_price = 2500,
#'     model = model
#'   )
#'   
#'   plot(sim$time, sim$population, type = 'l',
#'        xlab = "Days", ylab = "Population",
#'        main = "Broiler Flock Size Over Time")
#'   
#'   plot(sim$time, sim$cumulative_profit, type = 'l',
#'        xlab = "Days", ylab = "Profit",
#'        main = "Cumulative Profit")
#' }
#'
#' @export
run_aviculture_simulation <- function(
  initial_population = 100,
  days = 35,
  feed_price = 300,
  bird_price = 2500,
  daily_feed = 0.03,
  daily_deaths = 0.01,
  model = NULL,
  optav_enabled = FALSE,
  model_type = "standard",
  dt = NULL,                       # time step in days (can be fractional for continuous models)
  demand = NULL,                   # scalar demand or vector; used if demand_profile is NULL
  demand_profile = NULL,           # function(t) or numeric vector giving demand at time t
  objective = c("profit", "satisfaction", "balanced"),
  method = c("euler", "rk4")
) {
  
  if (is.null(model)) {
    model <- load_model(verbose = FALSE)
  }
  
  # Adjust parameters for OPTAV
  if (optav_enabled) {
    daily_feed <- daily_feed * 0.95  # 5% feed efficiency gain
    daily_deaths <- daily_deaths * 0.7  # 30% mortality reduction
    bird_price <- bird_price * 1.05  # 5% quality premium
  }
  
  # Determine time step: allow fractional days for continuous models
  if (is.null(dt)) {
    dt <- 0.1
  }
  # create time vector with fractional steps
  times <- seq(0, days, by = dt)
  n_steps <- length(times)
  
  # Initialize output columns
  time <- times
  population <- numeric(n_steps)
  average_mass <- numeric(n_steps)
  total_mass <- numeric(n_steps)
  marketable_population <- numeric(n_steps)
  economic_potential <- numeric(n_steps)
  cumulative_feed_cost <- numeric(n_steps)
  cumulative_profit <- numeric(n_steps)
  growth_rate <- numeric(n_steps)
  profit_rate_prev <- 0
  
  # Initial conditions
  population[1] <- initial_population
  # predict_mass expects ages >= 1; clamp early ages to 1 for reference trajectory
  average_mass[1] <- tryCatch({ predict_mass(max(1, times[1]), model) }, error = function(e) NA_real_)
  total_mass[1] <- population[1] * average_mass[1]
  maturity_ratio_0 <- tryCatch({ as.numeric(model$gamma_ref(max(1, times[1]))) }, error = function(e) 0.5)
  maturity_ratio_0 <- max(0, min(1, maturity_ratio_0))
  marketable_population[1] <- population[1] * maturity_ratio_0
  unit_value_0 <- (maturity_ratio_0 * bird_price) - (daily_feed * feed_price)
  economic_potential[1] <- population[1] * unit_value_0
  cumulative_feed_cost[1] <- 0
  cumulative_profit[1] <- 0
  growth_rate[1] <- 0

  # demand handling helper: demand can be scalar, vector aligned with times, or function(t)
  get_demand_at <- function(t, idx = NULL) {
    if (!is.null(demand_profile)) {
      if (is.function(demand_profile)) return(as.numeric(demand_profile(t)))
      if (is.numeric(demand_profile)) {
        if (!is.null(idx)) {
          if (idx >=1 && idx <= length(demand_profile)) return(as.numeric(demand_profile[idx]))
        }
        # otherwise fallback to nearest time
        nearest <- which.min(abs(times - t))
        return(as.numeric(demand_profile[nearest]))
      }
    }
    if (!is.null(demand)) return(as.numeric(demand))
    return(0)
  }
  
  # Define population ODE: dN/dt
  pop_derivative <- function(N, t, idx = NULL) {
    # allow fractional t; for reference mass use at least age 1
    t_real <- max(1, t)
    # Supply (births) based on approvisionnement e (per day scale)
    # If optav_enabled, apply small efficiency modifier
    supply <- if (optav_enabled) {
      daily_feed * 0 + 0 # placeholder; supply controlled externally in higher-level logic
    } else {
      0
    }
    # Mortality
    deaths <- N * daily_deaths
    # Sales: assume sales happen on mature proportion; here sales will be computed in loop
    # Net change placeholder: supply - deaths - sales
    return(- (deaths))
  }
  
  # Numerical integration scheme
  method <- match.arg(method)
  # Tracking objectives
  total_unmet <- 0
  total_demand <- 0
  # prepare per-step vectors for sales/demand tracking
  sales_vec <- numeric(n_steps)
  demand_vec <- numeric(n_steps)
  sales_rate_vec <- numeric(n_steps)
  for (i in 1:(n_steps - 1)) {
    t_curr <- times[i]
    N_curr <- population[i]

    # compute maturity and marketable population
    maturity_ratio <- tryCatch({ as.numeric(model$gamma_ref(max(1, t_curr))) }, error = function(e) 0.5)
    maturity_ratio <- max(0, min(1, maturity_ratio))
    marketable <- N_curr * maturity_ratio
    marketable_population[i] <- marketable

    # Determine demand at this time (interpreted as rate per day)
    demand_rate <- get_demand_at(t_curr, i)
    # convert to units for this time step
    demand_in_step <- demand_rate * dt
    total_demand <- total_demand + demand_in_step

    # Sales: try to satisfy demand_in_step using marketable birds (units)
    possible_sales <- min(marketable, demand_in_step)
    sales <- possible_sales
    unmet <- max(0, demand_in_step - sales)
    total_unmet <- total_unmet + unmet

    # Costs and revenue for this step (costs scale with dt)
    step_costs <- (feed_price * N_curr * dt) + (daily_feed * N_curr * dt)
    step_revenue <- sales * bird_price

    # Update cumulative trackers
    cumulative_feed_cost[i + 1] <- cumulative_feed_cost[i] + step_costs
    profit_rate <- (step_revenue - step_costs) / max(1e-9, dt)
    # Trapezoidal integration of profit rate
    cumulative_profit[i + 1] <- cumulative_profit[i] + 0.5 * (profit_rate_prev + profit_rate) * dt
    profit_rate_prev <- profit_rate
    unit_value <- (maturity_ratio * bird_price) - (daily_feed * feed_price)
    economic_potential[i] <- N_curr * unit_value

    # Euler or RK4 step for population: include sales as removals (convert sales in step to rate)
    sale_rate <- sales / max(1e-9, dt)
    if (method == "rk4") {
      k1 <- pop_derivative(N_curr, t_curr, i) - sale_rate
      k2 <- pop_derivative(N_curr + 0.5 * dt * k1, t_curr + 0.5 * dt, i) - sale_rate
      k3 <- pop_derivative(N_curr + 0.5 * dt * k2, t_curr + 0.5 * dt, i) - sale_rate
      k4 <- pop_derivative(N_curr + dt * k3, t_curr + dt, i) - sale_rate
      population[i + 1] <- max(0, N_curr + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4))
    } else {
      dN <- pop_derivative(N_curr, t_curr, i) - sale_rate
      population[i + 1] <- max(0, N_curr + dt * dN)
    }

    # update average mass and total mass
    age_for_mass <- max(1, times[i + 1])
    average_mass[i + 1] <- tryCatch({ predict_mass(age_for_mass, model) }, error = function(e) NA_real_)
    total_mass[i + 1] <- population[i + 1] * average_mass[i + 1]
    maturity_next <- tryCatch({ as.numeric(model$gamma_ref(max(1, times[i + 1]))) }, error = function(e) 0.5)
    maturity_next <- max(0, min(1, maturity_next))
    marketable_population[i + 1] <- population[i + 1] * maturity_next
    unit_value_next <- (maturity_next * bird_price) - (daily_feed * feed_price)
    economic_potential[i + 1] <- population[i + 1] * unit_value_next
    growth_rate[i + 1] <- (population[i + 1] - population[i]) / dt
    # store per-step sales/demand ratio in vectors
    sales_vec[i] <- sales
    demand_vec[i] <- demand_in_step
    sales_rate_vec[i] <- if (marketable > 0) sales / marketable else 0
  }

  # Evaluate objectives
  objectives <- list()
  objectives$total_profit <- cumulative_profit[n_steps]
  objectives$total_unmet <- total_unmet
  objectives$satisfaction_rate <- if (total_demand > 0) 1 - (total_unmet / total_demand) else 1
  objectives$objective_selected <- match.arg(objective)
  
  
  # Final growth rate
  if (n_steps > 1) {
    growth_rate[n_steps] <- growth_rate[n_steps - 1]
  }
  
  # Return simulation results and objectives
  sim_df <- data.frame(
    time = time,
    population = population,
    average_mass = average_mass,
    total_mass = total_mass,
    marketable_population = marketable_population,
    economic_potential = economic_potential,
    cumulative_feed_cost = cumulative_feed_cost,
    cumulative_profit = cumulative_profit,
    growth_rate = growth_rate
  )

  # attach sales/demand columns if present
  if (exists("sales_vec")) {
    sim_df$sales <- sales_vec
    sim_df$demand <- demand_vec
    sim_df$sales_rate <- sales_rate_vec
  }

  return(list(simulation = sim_df, objectives = objectives))
}


#' Run Sensitivity Analysis
#'
#' Performs sensitivity analysis by varying parameters around baseline values.
#' Computes output elasticity and impact on final profit.
#'
#' @param base_params List. Base parameter values (initial_population, days, feed_price, bird_price, etc.)
#' @param sensitivity_config List. Configuration with:
#'   \itemize{
#'     \item \code{parameter_name}: Name of parameter to vary ("feed_price", "bird_price", etc.)
#'     \item \code{variation}: Fraction to vary by (e.g., 0.1 for +/-10%)
#'     \item \code{steps}: Number of variation steps (default: 5)
#'     \item \code{model}: Model object (optional, loads default if NULL)
#'   }
#'
#' @return
#' A list with:
#' \item{baseline_profit}{Profit at base parameters}
#' \item{results}{Data frame with varied parameter, profit, and elasticity}
#' \item{parameter}{Name of varied parameter}
#' \item{variation_range}{Min and max values tested}
#'
#' @examples
#' \dontrun{
#'   base <- list(initial_population = 100, days = 35, 
#'                feed_price = 300, bird_price = 2500)
#'   config <- list(parameter_name = "feed_price", variation = 0.2, steps = 5)
#'   sens <- run_sensitivity_analysis(base, config)
#'   print(sens$results)
#' }
#'
#' @export
run_sensitivity_analysis <- function(base_params, sensitivity_config) {
  
  param_name <- sensitivity_config$parameter_name
  variation <- sensitivity_config$variation %||% 0.1
  steps <- sensitivity_config$steps %||% 5
  model <- sensitivity_config$model
  
  if (is.null(model)) {
    model <- load_model(verbose = FALSE)
  }
  
  # Run baseline
  baseline_sim <- do.call(run_aviculture_simulation,
                          c(base_params, list(model = model)))
  baseline_profit <- baseline_sim$objectives$total_profit
  
  # Create variation range
  base_value <- base_params[[param_name]]
  variation_factors <- seq(1 - variation, 1 + variation, length.out = steps)
  varied_values <- base_value * variation_factors
  
  # Run simulations for each variation
  results_list <- lapply(varied_values, function(val) {
    params <- base_params
    params[[param_name]] <- val
    sim <- do.call(run_aviculture_simulation, c(params, list(model = model)))
    final_profit <- sim$objectives$total_profit
    
    # Elasticity: (% change in output) / (% change in input)
    if (baseline_profit != 0 && base_value != 0) {
      pct_change_output <- (final_profit - baseline_profit) / baseline_profit
      pct_change_input <- (val - base_value) / base_value
      elasticity <- if (pct_change_input != 0) pct_change_output / pct_change_input else 0
    } else {
      elasticity <- 0
    }
    
    list(
      parameter_value = val,
      profit = final_profit,
      elasticity = elasticity
    )
  })
  
  results_df <- data.frame(
    parameter_value = sapply(results_list, `[[`, "parameter_value"),
    profit = sapply(results_list, `[[`, "profit"),
    elasticity = sapply(results_list, `[[`, "elasticity")
  )
  
  list(
    baseline_profit = baseline_profit,
    results = results_df,
    parameter = param_name,
    variation_range = range(varied_values)
  )
}




