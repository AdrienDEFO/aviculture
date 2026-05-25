#' Solve the poultry farm PDE system
#'
#' Solves the age-mass structured poultry model with an explicit upwind finite
#' difference scheme. The default configuration uses the degree-4 healthy growth
#' polynomial estimated from the project regression script and the stunted
#' growth rule `gamma_2 = rho * gamma_1`.
#'
#' @param grid An object created with [create_grid()].
#' @param parameters An object created with [create_parameters()].
#' @param controls An object created with [create_controls()].
#' @param initial_healthy Optional initial healthy stock matrix of dimension
#'   `length(grid$age) x length(grid$mass)`.
#' @param initial_stunted Optional initial stunted stock matrix of dimension
#'   `length(grid$age) x length(grid$mass)`.
#' @param store_states Logical; if `TRUE`, keeps the full state arrays.
#'
#' @return An object of class `aviculture_simulation`.
#' @export
solve_aviculture <- function(
  grid = create_grid(),
  parameters = create_parameters(),
  controls = create_controls(grid = grid),
  initial_healthy = NULL,
  initial_stunted = NULL,
  store_states = TRUE
) {
  .check_grid_consistency(grid)
  if (!inherits(parameters, "aviculture_parameters")) {
    stop("`parameters` must be created with `create_parameters()`.", call. = FALSE)
  }
  if (!inherits(controls, "aviculture_controls")) {
    stop("`controls` must be created with `create_controls()`.", call. = FALSE)
  }

  n_t <- length(grid$time)
  n_a <- length(grid$age)
  n_m <- length(grid$mass)

  X <- array(0, dim = c(n_t, n_a, n_m))
  Y <- array(0, dim = c(n_t, n_a, n_m))

  if (!is.null(initial_healthy)) {
    if (!is.matrix(initial_healthy) || !all(dim(initial_healthy) == c(n_a, n_m))) {
      stop("`initial_healthy` must be a matrix with dimensions length(age) x length(mass).", call. = FALSE)
    }
    X[1L, , ] <- initial_healthy
  }
  if (!is.null(initial_stunted)) {
    if (!is.matrix(initial_stunted) || !all(dim(initial_stunted) == c(n_a, n_m))) {
      stop("`initial_stunted` must be a matrix with dimensions length(age) x length(mass).", call. = FALSE)
    }
    Y[1L, , ] <- initial_stunted
  }

  weights <- .space_weights(n_a, n_m)
  gamma1 <- .evaluate_age_mass(parameters$gamma1, grid$age, grid$mass)
  gamma2 <- .evaluate_age_mass(parameters$gamma2, grid$age, grid$mass)
  gamma1[, n_m] <- 0
  gamma2[, n_m] <- 0
  mortality <- .evaluate_age_mass(parameters$mortality, grid$age, grid$mass)
  competition <- .evaluate_age_mass(parameters$competition, grid$age, grid$mass)
  feed_cost <- .evaluate_age_mass(parameters$feed_cost, grid$age, grid$mass)
  death_cost <- .evaluate_age_mass(parameters$death_cost, grid$age, grid$mass)
  marketable_mass <- .market_mask(grid$mass, parameters$market_mass)
  mass_matrix <- matrix(rep(grid$mass, each = n_a), nrow = n_a, ncol = n_m)

  supply_series <- numeric(n_t)
  competition_series <- numeric(n_t)
  sold_series <- numeric(n_t)
  deaths_series <- numeric(n_t)
  transfers_series <- numeric(n_t)
  healthy_total <- numeric(n_t)
  stunted_total <- numeric(n_t)
  biomass_series <- numeric(n_t)
  marketable_series <- numeric(n_t)
  demand_series <- controls$demand(grid$time)
  price_series <- controls$price(grid$time)
  supply_cost_series <- controls$supply_cost(grid$time)
  revenue_series <- numeric(n_t)
  purchase_cost_series <- numeric(n_t)
  feed_cost_series <- numeric(n_t)
  death_cost_series <- numeric(n_t)
  economic_potential <- numeric(n_t)

  for (k in seq_len(n_t)) {
    Xk <- X[k, , ]
    Yk <- Y[k, , ]

    competition_series[k] <- .competition_level(
      X = Xk,
      Y = Yk,
      kappa = competition,
      h_a = grid$h_a,
      h_m = grid$h_m,
      weights = weights
    )

    supplied <- .safe_supply(controls$supply(grid$time[k]) * (1 - competition_series[k]))
    supply_series[k] <- supplied

    healthy_total[k] <- grid$h_a * grid$h_m * sum(weights * Xk)
    stunted_total[k] <- grid$h_a * grid$h_m * sum(weights * Yk)
    biomass_series[k] <- grid$h_a * grid$h_m * sum(weights * (Xk + Yk) * mass_matrix)
    marketable_series[k] <- .aggregate_marketable(Xk, marketable_mass, weights, grid$h_a, grid$h_m)

    sale_rate_matrix <- .evaluate_sale_rate(parameters$sale_rate, grid$age, grid$mass, grid$time[k])
    sold_series[k] <- grid$h_a * grid$h_m * sum(weights * sale_rate_matrix * (Xk + Yk))
    deaths_series[k] <- grid$h_a * grid$h_m * sum(weights * mortality * (Xk + Yk))
    transfers_series[k] <- grid$h_a * grid$h_m * sum(weights * parameters$rho * Xk)
    revenue_series[k] <- price_series[k] * sold_series[k]
    purchase_cost_series[k] <- supply_cost_series[k] * supply_series[k]
    feed_cost_series[k] <- grid$h_a * grid$h_m * sum(weights * feed_cost * (Xk + Yk))
    death_cost_series[k] <- grid$h_a * grid$h_m * sum(weights * death_cost * mortality * (Xk + Yk))
    economic_potential[k] <- grid$h_a * grid$h_m * sum(
      weights * (ifelse(mass_matrix >= parameters$market_mass, price_series[k], 0) - feed_cost) * Xk
    )

    if (k == n_t) {
      next
    }

    next_X <- matrix(0, nrow = n_a, ncol = n_m)
    next_Y <- matrix(0, nrow = n_a, ncol = n_m)

    for (j in seq_len(n_a)) {
      for (l in seq_len(n_m)) {
        gamma1_jl <- gamma1[j, l]
        gamma2_jl <- gamma2[j, l]
        cfl_age <- grid$h_t / grid$h_a
        cfl_mass_1 <- gamma1_jl * grid$h_t / grid$h_m
        cfl_mass_2 <- gamma2_jl * grid$h_t / grid$h_m

        x_self <- Xk[j, l]
        y_self <- Yk[j, l]
        x_age_in <- if (j > 1L) Xk[j - 1L, l] else 0
        y_age_in <- if (j > 1L) Yk[j - 1L, l] else 0
        x_mass_in <- if (l > 1L) Xk[j, l - 1L] else 0
        y_mass_in <- if (l > 1L) Yk[j, l - 1L] else 0

        loss_x <- (mortality[j, l] + sale_rate_matrix[j, l] + parameters$rho) * x_self
        loss_y <- (mortality[j, l] + sale_rate_matrix[j, l]) * y_self

        next_X[j, l] <- x_self -
          cfl_age * (x_self - x_age_in) -
          cfl_mass_1 * (x_self - x_mass_in) -
          grid$h_t * loss_x

        next_Y[j, l] <- y_self -
          cfl_age * (y_self - y_age_in) -
          cfl_mass_2 * (y_self - y_mass_in) -
          grid$h_t * loss_y +
          grid$h_t * parameters$rho * x_self
      }
    }

    next_X[1L, ] <- 0
    next_Y[1L, ] <- 0
    next_X[, 1L] <- 0
    next_Y[, 1L] <- 0
    next_X[1L, 1L] <- grid$h_t * supplied

    X[k + 1L, , ] <- pmax(0, next_X)
    Y[k + 1L, , ] <- pmax(0, next_Y)
  }

  profit_series <- revenue_series - purchase_cost_series - feed_cost_series - death_cost_series
  cumulative_profit <- cumsum(profit_series * grid$h_t) - parameters$fixed_cost * grid$time
  demand_gap <- demand_series - sold_series

  indicators <- data.frame(
    time = grid$time,
    healthy = healthy_total,
    stunted = stunted_total,
    total = healthy_total + stunted_total,
    biomass = biomass_series,
    marketable = marketable_series,
    supplied = supply_series,
    competition = competition_series,
    sold = sold_series,
    deaths = deaths_series,
    transferred = transfers_series,
    demand = demand_series,
    price = price_series,
    supply_cost = supply_cost_series,
    revenue = revenue_series,
    purchase_cost = purchase_cost_series,
    feed_cost = feed_cost_series,
    death_cost = death_cost_series,
    profit = profit_series,
    cumulative_profit = cumulative_profit,
    economic_potential = economic_potential,
    demand_gap = demand_gap
  )

  objective_j1 <- parameters$fixed_cost * grid$t_max +
    sum(grid$h_t * (purchase_cost_series + feed_cost_series + death_cost_series - revenue_series))
  objective_j2 <- sum(grid$h_t * demand_gap^2)

  structure(
    list(
      grid = grid,
      parameters = parameters,
      controls = controls,
      states = if (isTRUE(store_states)) list(healthy = X, stunted = Y) else NULL,
      indicators = indicators,
      objectives = list(J1 = objective_j1, J2 = objective_j2),
      metadata = list(
        solver = "explicit_upwind",
        store_states = isTRUE(store_states),
        gamma1_coefficients = parameters$gamma1_coefficients
      )
    ),
    class = "aviculture_simulation"
  )
}
