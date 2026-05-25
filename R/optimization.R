#' Optimize the supply schedule
#'
#' Optimizes a piecewise-constant supply schedule over user-defined blocks using
#' the selected objective functional.
#'
#' @param grid An object created with [create_grid()].
#' @param parameters An object created with [create_parameters()].
#' @param controls An object created with [create_controls()].
#' @param objective Objective to minimize, either `"J1"` or `"J2"`.
#' @param blocks Number of supply blocks over the time horizon.
#' @param lower Lower bound for supply.
#' @param upper Upper bound for supply.
#' @param initial Initial supply level used for optimization.
#'
#' @return A list containing the optimized simulation and optimizer output.
#' @export
optimize_supply <- function(
  grid = create_grid(),
  parameters = create_parameters(),
  controls = create_controls(grid = grid),
  objective = c("J1", "J2"),
  blocks = 7,
  lower = 0,
  upper = 100,
  initial = 40
) {
  objective <- match.arg(objective)
  .check_grid_consistency(grid)
  .assert_positive_scalar(blocks, "blocks")
  .assert_positive_scalar(upper, "upper", allow_zero = TRUE)
  .assert_positive_scalar(initial, "initial", allow_zero = TRUE)

  block_id <- cut(seq_along(grid$time), breaks = blocks, labels = FALSE, include.lowest = TRUE)
  objective_function <- function(levels) {
    schedule <- levels[block_id]
    local_controls <- create_controls(
      grid = grid,
      supply = schedule,
      demand = controls$demand(grid$time),
      price = controls$price(grid$time),
      supply_cost = controls$supply_cost(grid$time),
      name = sprintf("optimized_%s", objective)
    )
    simulation <- solve_aviculture(grid = grid, parameters = parameters, controls = local_controls)
    simulation$objectives[[objective]]
  }

  fit <- stats::optim(
    par = rep(initial, blocks),
    fn = objective_function,
    method = "L-BFGS-B",
    lower = rep(lower, blocks),
    upper = rep(upper, blocks)
  )

  best_schedule <- fit$par[block_id]
  optimized_controls <- create_controls(
    grid = grid,
    supply = best_schedule,
    demand = controls$demand(grid$time),
    price = controls$price(grid$time),
    supply_cost = controls$supply_cost(grid$time),
    name = sprintf("optimized_%s", objective)
  )
  optimized_simulation <- solve_aviculture(
    grid = grid,
    parameters = parameters,
    controls = optimized_controls
  )

  list(
    simulation = optimized_simulation,
    controls = optimized_controls,
    optimizer = fit,
    block_schedule = fit$par
  )
}
