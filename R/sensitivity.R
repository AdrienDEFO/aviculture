.apply_sensitivity_case <- function(parameters, controls, variable, value, grid) {
  updated_parameters <- parameters
  updated_controls <- controls

  if (variable %in% c("rho", "market_mass", "fixed_cost")) {
    updated_parameters[[variable]] <- value
    if (variable == "rho") {
      base_gamma1 <- parameters$gamma1
      updated_parameters$gamma2 <- function(age, mass) {
        value * base_gamma1(age = age, mass = mass)
      }
    }
    if (variable == "market_mass") {
      updated_parameters$sale_rate <- function(age, mass, time) {
        .default_sale_rate(age = age, mass = mass, time = time, market_mass = value)
      }
    }
  } else if (variable == "gamma_scale") {
    base_gamma1 <- parameters$gamma1
    updated_parameters$gamma1 <- function(age, mass) {
      value * base_gamma1(age = age, mass = mass)
    }
    updated_parameters$gamma2 <- function(age, mass) {
      updated_parameters$rho * updated_parameters$gamma1(age = age, mass = mass)
    }
  } else if (variable == "mortality_scale") {
    base_mortality <- parameters$mortality
    updated_parameters$mortality <- function(age, mass) {
      value * base_mortality(age = age, mass = mass)
    }
  } else if (variable == "competition_scale") {
    base_competition <- parameters$competition
    updated_parameters$competition <- function(age, mass) {
      value * base_competition(age = age, mass = mass)
    }
  } else if (variable == "feed_cost_scale") {
    base_feed_cost <- parameters$feed_cost
    updated_parameters$feed_cost <- function(age, mass) {
      value * base_feed_cost(age = age, mass = mass)
    }
  } else if (variable == "death_cost_scale") {
    base_death_cost <- parameters$death_cost
    updated_parameters$death_cost <- function(age, mass) {
      value * base_death_cost(age = age, mass = mass)
    }
  } else if (variable == "sale_rate_scale") {
    base_sale_rate <- parameters$sale_rate
    updated_parameters$sale_rate <- function(age, mass, time) {
      value * base_sale_rate(age = age, mass = mass, time = time)
    }
  } else if (variable == "supply_scale") {
    updated_controls <- create_controls(
      grid = grid,
      supply = value * controls$supply(grid$time),
      demand = controls$demand(grid$time),
      price = controls$price(grid$time),
      supply_cost = controls$supply_cost(grid$time),
      name = paste0(controls$name, "_supply_scale")
    )
  } else if (variable == "demand_scale") {
    updated_controls <- create_controls(
      grid = grid,
      supply = controls$supply(grid$time),
      demand = value * controls$demand(grid$time),
      price = controls$price(grid$time),
      supply_cost = controls$supply_cost(grid$time),
      name = paste0(controls$name, "_demand_scale")
    )
  } else if (variable == "price_scale") {
    updated_controls <- create_controls(
      grid = grid,
      supply = controls$supply(grid$time),
      demand = controls$demand(grid$time),
      price = value * controls$price(grid$time),
      supply_cost = controls$supply_cost(grid$time),
      name = paste0(controls$name, "_price_scale")
    )
  } else if (variable == "supply_cost_scale") {
    updated_controls <- create_controls(
      grid = grid,
      supply = controls$supply(grid$time),
      demand = controls$demand(grid$time),
      price = controls$price(grid$time),
      supply_cost = value * controls$supply_cost(grid$time),
      name = paste0(controls$name, "_supply_cost_scale")
    )
  } else {
    stop(
      "Unsupported sensitivity variable. Supported values are: ",
      paste(
        c(
          "rho", "market_mass", "fixed_cost", "gamma_scale",
          "mortality_scale", "competition_scale", "feed_cost_scale",
          "death_cost_scale", "sale_rate_scale", "supply_scale",
          "demand_scale", "price_scale", "supply_cost_scale"
        ),
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  list(parameters = updated_parameters, controls = updated_controls)
}

.summarize_sensitivity_run <- function(simulation) {
  indicators <- simulation$indicators
  c(
    final_population = utils::tail(indicators$total, 1L),
    peak_population = max(indicators$total),
    final_cumulative_profit = utils::tail(indicators$cumulative_profit, 1L),
    total_sold = sum(indicators$sold) * simulation$grid$h_t,
    total_deaths = sum(indicators$deaths) * simulation$grid$h_t,
    mean_demand_gap = mean(indicators$demand_gap),
    J1 = simulation$objectives$J1,
    J2 = simulation$objectives$J2
  )
}

#' Run a one-factor sensitivity analysis
#'
#' Repeats the simulation while varying one parameter or one control scaling
#' factor at a time. The result is a tidy data frame that can be used directly
#' for reporting or with [plot_sensitivity()].
#'
#' @param grid An object created with [create_grid()].
#' @param parameters An object created with [create_parameters()].
#' @param controls An object created with [create_controls()].
#' @param variables Character vector of variables to vary.
#' @param values Numeric vector of values or scaling factors to test.
#'
#' @return An object of class `aviculture_sensitivity`.
#' @export
run_sensitivity <- function(
  grid = create_grid(),
  parameters = create_parameters(),
  controls = create_controls(grid = grid),
  variables = c("rho", "market_mass", "gamma_scale", "mortality_scale", "supply_scale"),
  values = c(0.8, 1, 1.2)
) {
  .check_grid_consistency(grid)
  if (!inherits(parameters, "aviculture_parameters")) {
    stop("`parameters` must be created with `create_parameters()`.", call. = FALSE)
  }
  if (!inherits(controls, "aviculture_controls")) {
    stop("`controls` must be created with `create_controls()`.", call. = FALSE)
  }
  if (!is.character(variables) || length(variables) < 1L) {
    stop("`variables` must be a non-empty character vector.", call. = FALSE)
  }
  if (!is.numeric(values) || length(values) < 1L || anyNA(values)) {
    stop("`values` must be a non-empty numeric vector without missing values.", call. = FALSE)
  }

  results <- vector("list", length(variables) * length(values))
  index <- 1L

  for (variable in variables) {
    for (value in values) {
      updated <- .apply_sensitivity_case(
        parameters = parameters,
        controls = controls,
        variable = variable,
        value = value,
        grid = grid
      )
      simulation <- solve_aviculture(
        grid = grid,
        parameters = updated$parameters,
        controls = updated$controls,
        store_states = FALSE
      )
      summary_values <- .summarize_sensitivity_run(simulation)
      results[[index]] <- data.frame(
        variable = variable,
        value = value,
        metric = names(summary_values),
        outcome = as.numeric(summary_values),
        stringsAsFactors = FALSE
      )
      index <- index + 1L
    }
  }

  output <- do.call(rbind, results)
  rownames(output) <- NULL
  structure(
    list(
      results = output,
      variables = variables,
      values = values
    ),
    class = "aviculture_sensitivity"
  )
}

#' Plot sensitivity results
#'
#' Produces two-dimensional sensitivity plots for a selected metric. Curves can
#' be shown together or one by one.
#'
#' @param sensitivity An object created by [run_sensitivity()].
#' @param metric Metric to display.
#' @param overlay Logical; if `TRUE`, plots all variables on the same figure.
#'
#' @return Invisibly returns the plotting data.
#' @export
plot_sensitivity <- function(
  sensitivity,
  metric = "J1",
  overlay = FALSE
) {
  if (!inherits(sensitivity, "aviculture_sensitivity")) {
    stop("`sensitivity` must be an `aviculture_sensitivity` object.", call. = FALSE)
  }

  data <- sensitivity$results[sensitivity$results$metric == metric, , drop = FALSE]
  if (nrow(data) == 0L) {
    stop("Unknown metric for sensitivity plot.", call. = FALSE)
  }

  split_data <- split(data, data$variable)

  if (overlay) {
    variables <- names(split_data)
    x_values <- sort(unique(data$value))
    mat <- sapply(split_data, function(frame) {
      frame <- frame[match(x_values, frame$value), ]
      frame$outcome
    })
    if (is.null(dim(mat))) {
      mat <- matrix(mat, ncol = 1L)
    }
    graphics::matplot(
      x_values,
      mat,
      type = "b",
      lty = 1,
      pch = 16,
      xlab = "Value",
      ylab = metric,
      main = paste("Sensitivity of", metric)
    )
    graphics::legend("topright", legend = variables, col = seq_along(variables), lty = 1, pch = 16, bty = "n")
  } else {
    old_par <- graphics::par(mfrow = c(length(split_data), 1L), mar = c(3, 4, 2, 1))
    on.exit(graphics::par(old_par), add = TRUE)
    for (name in names(split_data)) {
      frame <- split_data[[name]][order(split_data[[name]]$value), ]
      graphics::plot(
        frame$value,
        frame$outcome,
        type = "b",
        pch = 16,
        xlab = "Value",
        ylab = metric,
        main = paste("Sensitivity:", name)
      )
      graphics::abline(h = 0, lty = 3, col = "grey70")
    }
  }

  invisible(data)
}
