#' @export
print.aviculture_simulation <- function(x, ...) {
  cat("<aviculture_simulation>\n")
  cat("  Time horizon  :", x$grid$t_max, "\n")
  cat("  Healthy final :", utils::tail(x$indicators$healthy, 1L), "\n")
  cat("  Stunted final :", utils::tail(x$indicators$stunted, 1L), "\n")
  cat("  J1            :", x$objectives$J1, "\n")
  cat("  J2            :", x$objectives$J2, "\n")
  invisible(x)
}

#' @export
summary.aviculture_simulation <- function(object, ...) {
  out <- list(
    horizon = object$grid$t_max,
    final_population = utils::tail(object$indicators$total, 1L),
    peak_population = max(object$indicators$total),
    total_sold = sum(object$indicators$sold) * object$grid$h_t,
    total_deaths = sum(object$indicators$deaths) * object$grid$h_t,
    final_cumulative_profit = utils::tail(object$indicators$cumulative_profit, 1L),
    objectives = object$objectives
  )
  class(out) <- "summary.aviculture_simulation"
  out
}

#' @export
plot.aviculture_simulation <- function(x, y, ...) {
  plot_population(x, ...)
}
