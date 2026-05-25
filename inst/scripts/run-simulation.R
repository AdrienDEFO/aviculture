#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(aviculture))

input_json <- readLines(file("stdin"), warn = FALSE)
if (length(input_json) == 0L) {
  stop("No JSON payload received on stdin.", call. = FALSE)
}

input_data <- jsonlite::fromJSON(paste(input_json, collapse = "\n"))

grid <- create_grid(
  t_max = as.numeric(input_data$grid$t_max),
  a_min = as.numeric(input_data$grid$a_min),
  a_max = as.numeric(input_data$grid$a_max),
  m_min = as.numeric(input_data$grid$m_min),
  m_max = as.numeric(input_data$grid$m_max),
  h_t = as.numeric(input_data$grid$h_t),
  h_a = as.numeric(input_data$grid$h_a),
  h_m = as.numeric(input_data$grid$h_m)
)

parameters <- create_parameters(
  rho = as.numeric(input_data$parameters$rho),
  market_mass = as.numeric(input_data$parameters$market_mass),
  fixed_cost = as.numeric(input_data$parameters$fixed_cost)
)

make_control <- function(config, fallback) {
  if (is.null(config$type) || identical(config$type, "constant")) {
    return(as.numeric(config$value %||% fallback))
  }

  if (identical(config$type, "series")) {
    times <- as.numeric(config$times)
    values <- as.numeric(config$values)
    return(function(time) stats::approxfun(times, values, method = "constant", rule = 2, f = 0)(time))
  }

  fallback
}

`%||%` <- function(x, y) if (is.null(x)) y else x

controls <- create_controls(
  grid = grid,
  supply = make_control(input_data$controls$supply, 40),
  demand = make_control(input_data$controls$demand, 25),
  price = make_control(input_data$controls$price, 5.5),
  supply_cost = make_control(input_data$controls$supply_cost, 1.25)
)

simulation <- solve_aviculture(
  grid = grid,
  parameters = parameters,
  controls = controls,
  store_states = TRUE
)

output <- list(
  indicators = as.data.frame(compute_indicators(simulation)),
  objectives = compute_objectives(simulation),
  success = TRUE
)

cat(jsonlite::toJSON(output, pretty = TRUE, auto_unbox = TRUE))
