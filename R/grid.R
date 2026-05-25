#' Create a simulation grid
#'
#' Builds the time, age, and mass discretization used by the PDE solver.
#'
#' @param t_max Final simulation time.
#' @param a_min Minimum age.
#' @param a_max Maximum age.
#' @param m_min Minimum mass.
#' @param m_max Maximum mass.
#' @param h_t Time step.
#' @param h_a Age step.
#' @param h_m Mass step.
#' @param gamma_upper Upper bound used in the CFL-like stability check.
#'
#' @return An object of class `aviculture_grid`.
#' @export
create_grid <- function(
  t_max = 56,
  a_min = 1,
  a_max = 56,
  m_min = 0.054,
  m_max = 3.257,
  h_t = 0.1,
  h_a = 1,
  h_m = 0.05,
  gamma_upper = 0.08
) {
  .assert_positive_scalar(t_max, "t_max")
  .assert_positive_scalar(h_t, "h_t")
  .assert_positive_scalar(h_a, "h_a")
  .assert_positive_scalar(h_m, "h_m")
  .assert_positive_scalar(gamma_upper, "gamma_upper", allow_zero = TRUE)

  if (a_max <= a_min) {
    stop("`a_max` must be larger than `a_min`.", call. = FALSE)
  }
  if (m_max <= m_min) {
    stop("`m_max` must be larger than `m_min`.", call. = FALSE)
  }

  time <- seq(0, t_max, by = h_t)
  if (utils::tail(time, 1L) < t_max) {
    time <- c(time, t_max)
  }

  age <- seq(a_min, a_max, by = h_a)
  if (utils::tail(age, 1L) < a_max) {
    age <- c(age, a_max)
  }

  mass <- seq(m_min, m_max, by = h_m)
  if (utils::tail(mass, 1L) < m_max) {
    mass <- c(mass, m_max)
  }

  structure(
    list(
      time = time,
      age = age,
      mass = mass,
      t_max = t_max,
      a_min = a_min,
      a_max = a_max,
      m_min = m_min,
      m_max = m_max,
      h_t = h_t,
      h_a = h_a,
      h_m = h_m,
      gamma_upper = gamma_upper
    ),
    class = "aviculture_grid"
  )
}

#' @export
print.aviculture_grid <- function(x, ...) {
  cat("<aviculture_grid>\n")
  cat("  Time points :", length(x$time), "\n")
  cat("  Age points  :", length(x$age), "\n")
  cat("  Mass points :", length(x$mass), "\n")
  cat("  Steps       : h_t =", x$h_t, ", h_a =", x$h_a, ", h_m =", x$h_m, "\n")
  invisible(x)
}
