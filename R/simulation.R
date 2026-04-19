#' Population and Economic Simulation for Broiler Production
#'
#' Simulates broiler population dynamics over time with economic calculations,
#' using explicit Euler method with small time steps for stability.
#' Integrates with growth model for realistic tissue composition changes.
#'
#' @name aviculture_simulation
#' 
NULL

#' Get Maturity Factor for Growth Model Selection
#'
#' Returns a sigmoid-based maturity curve that determines when birds
#' become available for market sale.
#'
#' @param t Numeric. Time in days.
#' @param model_type Character. Model type: "logistic", "gompertz", or "optav". Default "logistic".
#'
#' @return Numeric between 0 and 1 representing maturity ratio.
#'
#' @details
#' - **logistic**: S-curve, 50% maturity at day ~20
#' - **gompertz**: Slower initial, steeper middle phase
#' - **optav**: Custom curve optimized for poultry economics
#'
#' @examples
#' t <- 0:60
#' maturity <- sapply(t, function(tt) get_maturity_factor(tt, "logistic"))
#' plot(t, maturity, type='l', main="Maturity Curves", xlab="Age (days)", ylab="Maturity")
#'
#' @export
get_maturity_factor <- function(t, model_type = "logistic") {
  
  if (model_type == "logistic") {
    # Standard logistic: 50% at day 20, steepness 0.2
    return(1 / (1 + exp(-0.2 * (t - 20))))
  }
  
  if (model_type == "gompertz") {
    # Gompertz: exp(-exp(-0.1*(t-25)))
    return(exp(-exp(-0.1 * (t - 25))))
  }
  
  if (model_type == "optav") {
    # Custom OPTAV curve
    return(1 - exp(-0.25 * t) * (1 + 0.15 * t))
  }
  
  # Default: linear approximation
  return(min(1, t / 30))
}

#' Run Complete Aviculture Cycle Simulation
#'
#' Simulates broiler farm production cycle with:
#' - Population dynamics (births, deaths, sales)
#' - Growth tracking (mass & volume using model)
#' - Economic calculations (costs, revenue, profit)
#' - Numerical integration (explicit Euler by default)
#'
#' @param parameters List with elements:
#'   \item{T}{Numeric. Total simulation duration in days.}
#'   \item{e}{Numeric. Daily chick supply (chicks/day).}
#'   \item{d}{Numeric. Daily mortality rate (0-1 fraction).}
#'   \item{kappa}{Numeric. Density-dependent mortality parameter (1/bird).}
#'   \item{s}{Numeric. Fraction of marketable birds sold per day (0-1).}
#'   \item{demand}{Numeric. Total demand (birds to sell).}
#'   \item{cf}{Numeric. Fixed costs (€ per cycle).}
#'   \item{cs}{Numeric. Cost per chick (€/chick).}
#'   \item{cn}{Numeric. Daily feed cost per bird (€/bird/day).}
#'   \item{cd}{Numeric. Cost per mortality (€/bird).}
#'   \item{ps}{Numeric. Selling price per bird (€/bird).}
#'   \item{ms}{Numeric. Minimum marketable mass (kg). Optional.}
#'   \item{vs}{Numeric. Minimum marketable volume (L). Optional.}
#'   \item{growthModel}{Character. "logistic", "gompertz", or "optav". Default "logistic".}
#'   \item{dt}{Numeric. Time step (days). Default 1. Smaller = more accurate.}
#'   \item{integrator}{Character. "euler" or "rk4". Default "euler".}
#'   \item{initialPopulation}{Numeric. Initial flock size at t=0. Default 0.}
#'
#' @param model A model object from \code{\link{load_model}}. If NULL, uses reference growth only.
#'
#' @return
#' A data frame with columns:
#'   \item{t}{Time (days)}
#'   \item{population}{Current bird population}
#'   \item{maturity_ratio}{Fraction of birds at market age}
#'   \item{marketable_pop}{Population ready for sale}
#'   \item{births}{Chicks added this day}
#'   \item{deaths}{Birds lost this day}
#'   \item{sales}{Birds sold this day}
#'   \item{mass_ref}{Reference average mass (kg)}
#'   \item{volume_ref}{Reference average volume (L)}
#'   \item{density_ref}{Reference average density (kg/L)}
#'   \item{total_biomass}{Total flock biomass (kg)}
#'   \item{total_volume}{Total flock volume (L)}
#'   \item{economic_potential}{Instant economic potential proxy}
#'   \item{costs_daily}{Daily operational costs}
#'   \item{revenue_daily}{Daily revenue from sales}
#'   \item{profit_daily}{Daily profit}
#'   \item{costs_cumulative}{Total costs to date}
#'   \item{revenue_cumulative}{Total revenue to date}
#'   \item{profit_cumulative}{Total profit to date}
#'
#' @details
#' ## Population Dynamics ODE:
#' \deqn{\frac{dN}{dt} = e \cdot (1 - \kappa N) - d \cdot N - s \cdot m(t) \cdot N}
#'
#' where:
#' - e = daily supply (chicks/day)
#' - κ = density dependence
#' - d = baseline mortality
#' - m(t) = maturity factor
#' - s = sales fraction
#'
#' ## Cost Structure:
#' - Fixed costs: cf / T (spread over T days)
#' - Supply costs: births * cs
#' - Feed costs: population * cn
#' - Mortality costs: deaths * cd
#'
#' ## Revenue:
#' - Revenue per day: sales * ps
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   
#'   params <- list(
#'     T = 90,
#'     e = 500,
#'     d = 0.015,
#'     kappa = 0.0001,
#'     s = 0.05,
#'     demand = 1500,
#'     cf = 5000,
#'     cs = 1,
#'     cn = 0.2,
#'     cd = 0.5,
#'     ps = 5,
#'     growthModel = "logistic",
#'     dt = 1
#'   )
#'   
#'   sim <- run_aviculture_cycle(params, model)
#'   
#'   # Plot profit evolution
#'   plot(sim$t, sim$profit_cumulative, type='l',
#'        xlab="Days", ylab="Profit (€)", main="Cumulative Profit")
#'   grid()
#' }
#'
#' @export
run_aviculture_cycle <- function(parameters, model = NULL, integrator = c("euler", "rk4")) {
  
  # Validate parameters
  required_params <- c("T", "e", "d", "kappa", "s", "demand", "cf", "cs", "cn", "cd", "ps")
  for (param in required_params) {
    if (!(param %in% names(parameters))) {
      stop("Missing required parameter: ", param)
    }
  }
  
  # Extract parameters
  T <- parameters$T
  e <- parameters$e
  d <- parameters$d
  kappa <- parameters$kappa
  s <- parameters$s
  demand <- parameters$demand
  cf <- parameters$cf
  cs <- parameters$cs
  cn <- parameters$cn
  cd <- parameters$cd
  ps <- parameters$ps
  
  growth_model <- parameters$growthModel %||% "logistic"
  dt <- parameters$dt %||% 1
  initial_pop <- parameters$initialPopulation %||% 0
  integrator <- parameters$integrator %||% integrator[[1]]
  integrator <- match.arg(integrator, c("euler", "rk4"))
  
  # Initialize state
  times <- seq(0, T, by = dt)
  n_steps <- length(times)
  
  # Pre-allocate data frame
  result <- data.frame(
    t = times,
    population = numeric(n_steps),
    maturity_ratio = numeric(n_steps),
    marketable_pop = numeric(n_steps),
    births = numeric(n_steps),
    deaths = numeric(n_steps),
    sales = numeric(n_steps),
    mass_ref = numeric(n_steps),
    volume_ref = numeric(n_steps),
    density_ref = numeric(n_steps),
    total_biomass = numeric(n_steps),
    total_volume = numeric(n_steps),
    economic_potential = numeric(n_steps),
    costs_daily = numeric(n_steps),
    revenue_daily = numeric(n_steps),
    profit_daily = numeric(n_steps),
    costs_cumulative = numeric(n_steps),
    revenue_cumulative = numeric(n_steps),
    profit_cumulative = numeric(n_steps),
    stringsAsFactors = FALSE
  )
  
  # Initialize accumulators
  current_pop <- initial_pop
  cum_costs <- 0
  cum_revenue <- 0
  cum_sales <- 0
  
  # ODE for population: dN/dt
  population_derivative <- function(N, t, sales_rate) {
    supply_rate <- e * (1 - kappa * N)
    mortality_rate <- d * N
    supply_rate - mortality_rate - sales_rate
  }
  
  # RK4 integration step
  rk4_step <- function(y, t, dt, sales_rate) {
    k1 <- population_derivative(y, t, sales_rate)
    k2 <- population_derivative(y + 0.5 * dt * k1, t + 0.5 * dt, sales_rate)
    k3 <- population_derivative(y + 0.5 * dt * k2, t + 0.5 * dt, sales_rate)
    k4 <- population_derivative(y + dt * k3, t + dt, sales_rate)
    
    return(y + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4))
  }
  
  # Main simulation loop
  for (i in 1:n_steps) {
    t <- times[i]
    
    # Get maturity and reference growth
    maturity <- get_maturity_factor(t, growth_model)
    
    if (!is.null(model)) {
      age_for_growth <- max(1, t)
      result$mass_ref[i] <- predict_mass(age_for_growth, model)
      result$volume_ref[i] <- predict_volume(age_for_growth, model)
      result$density_ref[i] <- predict_density(age_for_growth, model)
    } else {
      # Simple reference if no model
      result$mass_ref[i] <- 0.04 + 0.06 * t
      result$volume_ref[i] <- result$mass_ref[i] / 1.05
      result$density_ref[i] <- 1.05
    }
    
    # Calculate population flows
    supply_rate <- e * (1 - kappa * current_pop)
    mortality_rate <- current_pop * d
    marketable <- current_pop * maturity
    demand_remaining <- max(0, demand - cum_sales)
    actual_sales <- min(marketable * s * dt, demand_remaining)
    actual_sales <- max(0, actual_sales)
    sales_rate <- if (dt > 0) actual_sales / dt else 0
    
    births <- supply_rate * dt
    deaths <- mortality_rate * dt
    
    # Store flows
    result$population[i] <- max(0, current_pop)
    result$maturity_ratio[i] <- maturity
    result$marketable_pop[i] <- marketable
    result$births[i] <- births
    result$deaths[i] <- deaths
    result$sales[i] <- actual_sales
    result$total_biomass[i] <- result$population[i] * result$mass_ref[i]
    result$total_volume[i] <- result$population[i] * result$volume_ref[i]
    result$economic_potential[i] <- (ps * marketable) - (cn * result$population[i])
    
    # Economic calculations for this day
    fixed_per_day <- cf / max(1, T)
    daily_fixed <- fixed_per_day * dt
    daily_supply_cost <- births * cs
    daily_feed_cost <- current_pop * cn * dt
    daily_mortality_cost <- deaths * cd
    
    daily_costs <- daily_fixed + daily_supply_cost + daily_feed_cost + daily_mortality_cost
    daily_revenue <- actual_sales * ps
    daily_profit <- daily_revenue - daily_costs
    
    result$costs_daily[i] <- daily_costs
    result$revenue_daily[i] <- daily_revenue
    result$profit_daily[i] <- daily_profit
    
    # Cumulative
    cum_costs <- cum_costs + daily_costs
    cum_revenue <- cum_revenue + daily_revenue
    
    result$costs_cumulative[i] <- cum_costs
    result$revenue_cumulative[i] <- cum_revenue
    result$profit_cumulative[i] <- cum_revenue - cum_costs
    
    # Advance population
    if (i < n_steps) {
      if (integrator == "rk4") {
        current_pop <- rk4_step(current_pop, t, dt, sales_rate)
      } else {
        current_pop <- current_pop + dt * population_derivative(current_pop, t, sales_rate)
      }
      current_pop <- max(0, current_pop)
      cum_sales <- cum_sales + actual_sales
    }
  }
  
  return(result)
}

#' Summary Statistics for Simulation
#'
#' Computes key performance indicators from simulation results.
#'
#' @param simulation Data frame from \code{\link{run_aviculture_cycle}}.
#' @param parameters List with simulation parameters.
#'
#' @return
#' A list with:
#'   \item{total_profit}{Final cumulative profit (€)}
#'   \item{total_revenue}{Total revenue (€)}
#'   \item{total_costs}{Total costs (€)}
#'   \item{birds_sold}{Total birds sold}
#'   \item{birds_died}{Total birds that died}
#'   \item{final_population}{Population at end}
#'   \item{avg_daily_profit}{Average profit per day}
#'   \item{mortality_rate}{Overall mortality rate}
#'   \item{sales_efficiency}{Fraction of demand met}
#'
#' @export
summarize_simulation <- function(simulation, parameters = NULL) {
  
  total_revenue <- tail(simulation$revenue_cumulative, 1)
  total_costs <- tail(simulation$costs_cumulative, 1)
  total_profit <- total_revenue - total_costs
  
  birds_sold <- sum(simulation$sales, na.rm = TRUE)
  birds_died <- sum(simulation$deaths, na.rm = TRUE)
  final_pop <- tail(simulation$population, 1)
  
  n_days <- nrow(simulation)
  avg_profit <- total_profit / n_days
  
  demand <- if (!is.null(parameters)) parameters$demand else birds_sold
  sales_efficiency <- if (demand > 0) birds_sold / demand else 0
  
  mortality_rate <- birds_died / (birds_sold + birds_died + 1e-10)
  
  list(
    total_profit = total_profit,
    total_revenue = total_revenue,
    total_costs = total_costs,
    birds_sold = birds_sold,
    birds_died = birds_died,
    final_population = final_pop,
    avg_daily_profit = avg_profit,
    mortality_rate = mortality_rate,
    sales_efficiency = sales_efficiency
  )
}
