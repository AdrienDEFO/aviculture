.resolve_series <- function(indicators, series) {
  missing_series <- setdiff(series, names(indicators))
  if (length(missing_series) > 0L) {
    stop("Unknown series: ", paste(missing_series, collapse = ", "), call. = FALSE)
  }
  indicators[, c("time", series), drop = FALSE]
}

.time_to_index <- function(simulation, time) {
  which.min(abs(simulation$grid$time - time))
}

#' Plot population trajectories
#'
#' Produces two-dimensional population trajectories, either overlaid or one by
#' one, depending on the `overlay` argument.
#'
#' @param simulation An object created by [solve_aviculture()].
#' @param series Character vector of population-related series to display.
#' @param overlay Logical; if `TRUE`, plots the selected series together.
#'
#' @return Invisibly returns the plotted data.
#' @export
plot_population <- function(
  simulation,
  series = c("healthy", "stunted", "total", "marketable"),
  overlay = FALSE
) {
  .check_simulation(simulation)
  data <- .resolve_series(simulation$indicators, series)

  if (overlay) {
    graphics::matplot(data$time, data[, -1L, drop = FALSE], type = "l", lty = 1,
      xlab = "Time", ylab = "Population", main = "Population trajectories")
    graphics::legend("topright", legend = series, col = seq_along(series), lty = 1, bty = "n")
  } else {
    old_par <- graphics::par(mfrow = c(length(series), 1L), mar = c(3, 4, 2, 1))
    on.exit(graphics::par(old_par), add = TRUE)
    for (name in series) {
      graphics::plot(data$time, data[[name]], type = "l",
        xlab = "Time", ylab = name, main = paste("Population:", name))
      graphics::abline(h = 0, lty = 3, col = "grey70")
    }
  }

  invisible(data)
}

#' Plot population profiles
#'
#' Displays age or mass profiles for healthy or stunted chickens at selected
#' time points.
#'
#' @param simulation An object created by [solve_aviculture()].
#' @param variable Either `"healthy"` or `"stunted"`.
#' @param dimension Either `"age"` or `"mass"`.
#' @param times Time points to display.
#' @param overlay Logical; if `TRUE`, overlays all profiles in the same panel.
#'
#' @return Invisibly returns the profile matrix used for plotting.
#' @export
plot_profiles <- function(
  simulation,
  variable = c("healthy", "stunted"),
  dimension = c("age", "mass"),
  times = NULL,
  overlay = FALSE
) {
  .check_simulation(simulation)
  variable <- match.arg(variable)
  dimension <- match.arg(dimension)

  if (is.null(simulation$states)) {
    stop("State arrays were not stored. Re-run `solve_aviculture()` with `store_states = TRUE`.", call. = FALSE)
  }

  if (is.null(times)) {
    times <- unique(round(stats::quantile(simulation$grid$time, probs = c(0.25, 0.5, 0.75)), 4))
  }
  indices <- vapply(times, function(t) .time_to_index(simulation, t), integer(1L))

  state_array <- simulation$states[[variable]]
  if (dimension == "age") {
    x <- simulation$grid$age
    profiles <- sapply(indices, function(idx) rowSums(state_array[idx, , , drop = TRUE]))
    xlab <- "Age"
  } else {
    x <- simulation$grid$mass
    profiles <- sapply(indices, function(idx) colSums(state_array[idx, , , drop = TRUE]))
    xlab <- "Mass"
  }

  if (is.null(dim(profiles))) {
    profiles <- matrix(profiles, ncol = 1L)
  }

  colnames(profiles) <- paste0("t=", simulation$grid$time[indices])

  if (overlay) {
    graphics::matplot(x, profiles, type = "l", lty = 1,
      xlab = xlab, ylab = "Population", main = paste(variable, dimension, "profiles"))
    graphics::legend("topright", legend = colnames(profiles), col = seq_len(ncol(profiles)), lty = 1, bty = "n")
  } else {
    old_par <- graphics::par(mfrow = c(ncol(profiles), 1L), mar = c(3, 4, 2, 1))
    on.exit(graphics::par(old_par), add = TRUE)
    for (i in seq_len(ncol(profiles))) {
      graphics::plot(x, profiles[, i], type = "l",
        xlab = xlab, ylab = "Population", main = paste(variable, colnames(profiles)[i]))
    }
  }

  invisible(profiles)
}

#' Plot a two-dimensional age-mass heatmap
#'
#' Produces a two-dimensional filled contour plot for healthy or stunted
#' chickens at a selected time point.
#'
#' @param simulation An object created by [solve_aviculture()].
#' @param variable Either `"healthy"` or `"stunted"`.
#' @param time Time point to display.
#' @param palette A color palette function.
#'
#' @return Invisibly returns the plotted matrix.
#' @export
plot_heatmap <- function(
  simulation,
  variable = c("healthy", "stunted"),
  time = NULL,
  palette = grDevices::colorRampPalette(c("#f7fbff", "#6baed6", "#08306b"))
) {
  .check_simulation(simulation)
  variable <- match.arg(variable)

  if (is.null(simulation$states)) {
    stop("State arrays were not stored. Re-run `solve_aviculture()` with `store_states = TRUE`.", call. = FALSE)
  }
  if (is.null(time)) {
    time <- utils::tail(simulation$grid$time, 1L)
  }

  idx <- .time_to_index(simulation, time)
  z <- simulation$states[[variable]][idx, , , drop = TRUE]

  graphics::filled.contour(
    x = simulation$grid$age,
    y = simulation$grid$mass,
    z = z,
    color.palette = palette,
    xlab = "Age",
    ylab = "Mass",
    main = paste("Age-mass heatmap for", variable, "at t =", simulation$grid$time[idx])
  )

  invisible(z)
}

#' Plot economic trajectories
#'
#' Produces two-dimensional economic curves, either overlaid or one by one.
#'
#' @param simulation An object created by [solve_aviculture()].
#' @param series Character vector of economic series to display.
#' @param overlay Logical; if `TRUE`, plots the selected series together.
#'
#' @return Invisibly returns the plotted data.
#' @export
plot_economics <- function(
  simulation,
  series = c("revenue", "purchase_cost", "feed_cost", "death_cost", "profit", "cumulative_profit", "economic_potential"),
  overlay = FALSE
) {
  .check_simulation(simulation)
  data <- .resolve_series(simulation$indicators, series)

  if (overlay) {
    graphics::matplot(data$time, data[, -1L, drop = FALSE], type = "l", lty = 1,
      xlab = "Time", ylab = "Value", main = "Economic trajectories")
    graphics::legend("topright", legend = series, col = seq_along(series), lty = 1, bty = "n")
  } else {
    old_par <- graphics::par(mfrow = c(length(series), 1L), mar = c(3, 4, 2, 1))
    on.exit(graphics::par(old_par), add = TRUE)
    for (name in series) {
      graphics::plot(data$time, data[[name]], type = "l",
        xlab = "Time", ylab = name, main = paste("Economics:", name))
      graphics::abline(h = 0, lty = 3, col = "grey70")
    }
  }

  invisible(data)
}

#' Plot demand and realized supply
#'
#' Compares market demand with realized sales and optionally displays the demand
#' gap on a separate figure.
#'
#' @param simulation An object created by [solve_aviculture()].
#' @param show_gap Logical; if `TRUE`, also plots the demand gap.
#'
#' @return Invisibly returns the plotted data.
#' @export
plot_demand <- function(simulation, show_gap = TRUE) {
  .check_simulation(simulation)
  data <- simulation$indicators[, c("time", "demand", "sold", "demand_gap")]

  old_par <- graphics::par(mfrow = c(if (show_gap) 2L else 1L, 1L), mar = c(3, 4, 2, 1))
  on.exit(graphics::par(old_par), add = TRUE)

  graphics::plot(data$time, data$demand, type = "l", lty = 1,
    xlab = "Time", ylab = "Chickens", main = "Demand versus realized sales")
  graphics::lines(data$time, data$sold, col = 2, lty = 1)
  graphics::legend("topright", legend = c("Demand", "Realized sales"), col = c(1, 2), lty = 1, bty = "n")

  if (show_gap) {
    graphics::plot(data$time, data$demand_gap, type = "l",
      xlab = "Time", ylab = "Gap", main = "Demand gap")
    graphics::abline(h = 0, lty = 3, col = "grey70")
  }

  invisible(data)
}
