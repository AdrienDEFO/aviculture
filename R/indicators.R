#' Compute simulation indicators
#'
#' Returns the indicator table stored in a simulation object.
#'
#' @param simulation An object created by [solve_aviculture()].
#'
#' @return A data frame of time-indexed indicators.
#' @export
compute_indicators <- function(simulation) {
  .check_simulation(simulation)
  simulation$indicators
}

#' Compute objective values
#'
#' Returns the objective values corresponding to the simulated trajectory.
#'
#' @param simulation An object created by [solve_aviculture()].
#'
#' @return A named list with `J1` and `J2`.
#' @export
compute_objectives <- function(simulation) {
  .check_simulation(simulation)
  simulation$objectives
}
