.as_time_function <- function(x, time, default) {
  if (is.null(x)) {
    return(default)
  }

  if (is.function(x)) {
    return(x)
  }

  if (length(x) == 1L && is.numeric(x)) {
    value <- x
    return(function(t) rep(value, length(t)))
  }

  if (is.numeric(x) && length(x) == length(time)) {
    interpolator <- stats::approxfun(time, x, method = "constant", rule = 2, f = 0)
    return(function(t) interpolator(t))
  }

  stop("Time controls must be NULL, a function, a scalar, or a vector matching the grid time points.", call. = FALSE)
}

#' Create exogenous controls
#'
#' Defines time-dependent supply, selling price, and demand controls. Scalars
#' and vectors are automatically converted to time functions.
#'
#' @param grid A grid created with [create_grid()].
#' @param supply Chicks supply rate. Can be `NULL`, a scalar, a vector defined
#'   on `grid$time`, or a function of time.
#' @param demand Market demand. Can be `NULL`, a scalar, a vector defined on
#'   `grid$time`, or a function of time.
#' @param price Selling price. Can be `NULL`, a scalar, a vector defined on
#'   `grid$time`, or a function of time.
#' @param supply_cost Unit supply cost. Can be `NULL`, a scalar, a vector
#'   defined on `grid$time`, or a function of time.
#' @param name Optional descriptive label.
#'
#' @return An object of class `aviculture_controls`.
#' @export
create_controls <- function(
  grid = create_grid(),
  supply = NULL,
  demand = NULL,
  price = NULL,
  supply_cost = NULL,
  name = "default"
) {
  .check_grid_consistency(grid)

  supply_fn <- .as_time_function(supply, grid$time, .default_supply)
  demand_fn <- .as_time_function(demand, grid$time, .default_demand)
  price_fn <- .as_time_function(price, grid$time, .default_price)
  supply_cost_fn <- .as_time_function(supply_cost, grid$time, .default_supply_cost)

  structure(
    list(
      grid = grid,
      supply = supply_fn,
      demand = demand_fn,
      price = price_fn,
      supply_cost = supply_cost_fn,
      name = name
    ),
    class = "aviculture_controls"
  )
}

#' @export
print.aviculture_controls <- function(x, ...) {
  cat("<aviculture_controls>\n")
  cat("  name :", x$name, "\n")
  cat("  supply, demand, price, and supply_cost are stored as time functions.\n")
  invisible(x)
}
