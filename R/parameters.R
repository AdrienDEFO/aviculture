#' Create model parameters
#'
#' Defines biological, structural, and economic model parameters. Any quantity
#' not supplied by the user receives a default value suitable for examples and
#' initial experimentation.
#'
#' @param rho Stunting transition rate.
#' @param market_mass Minimum marketable mass threshold.
#' @param gamma1 Function of `age` and `mass` returning the healthy growth rate.
#' @param gamma2 Function of `age` and `mass` returning the stunted growth rate.
#'   By default `gamma_2 = rho * gamma_1`.
#' @param mortality Function of `age` and `mass` returning the mortality rate.
#' @param sale_rate Function of `age`, `mass`, and `time` returning the sale
#'   rate.
#' @param competition Function of `age` and `mass` returning the competition
#'   coefficient.
#' @param feed_cost Function of `age` and `mass` returning nutrition cost.
#' @param death_cost Function of `age` and `mass` returning death cost.
#' @param fixed_cost Fixed operating cost.
#'
#' @return An object of class `aviculture_parameters`.
#' @export
create_parameters <- function(
  rho = 0.2,
  market_mass = 2.3,
  gamma1 = .default_gamma1,
  gamma2 = NULL,
  mortality = .default_mortality,
  sale_rate = NULL,
  competition = .default_competition,
  feed_cost = .default_feed_cost,
  death_cost = .default_death_cost,
  fixed_cost = 35
) {
  .assert_positive_scalar(rho, "rho", allow_zero = TRUE)
  .assert_positive_scalar(market_mass, "market_mass")
  .assert_function(gamma1, "gamma1")
  .assert_function(mortality, "mortality")
  .assert_function(competition, "competition")
  .assert_function(feed_cost, "feed_cost")
  .assert_function(death_cost, "death_cost")
  .assert_positive_scalar(fixed_cost, "fixed_cost", allow_zero = TRUE)

  if (is.null(gamma2)) {
    gamma2 <- function(age, mass) {
      rho * gamma1(age = age, mass = mass)
    }
  }
  .assert_function(gamma2, "gamma2")

  if (is.null(sale_rate)) {
    sale_rate <- function(age, mass, time) {
      .default_sale_rate(age = age, mass = mass, time = time, market_mass = market_mass)
    }
  }
  .assert_function(sale_rate, "sale_rate")

  structure(
    list(
      rho = rho,
      market_mass = market_mass,
      gamma1 = gamma1,
      gamma2 = gamma2,
      mortality = mortality,
      sale_rate = sale_rate,
      competition = competition,
      feed_cost = feed_cost,
      death_cost = death_cost,
      fixed_cost = fixed_cost,
      gamma1_coefficients = .aviculture_gamma1_coefficients
    ),
    class = "aviculture_parameters"
  )
}

#' @export
print.aviculture_parameters <- function(x, ...) {
  cat("<aviculture_parameters>\n")
  cat("  rho         :", x$rho, "\n")
  cat("  market_mass :", x$market_mass, "\n")
  cat("  fixed_cost  :", x$fixed_cost, "\n")
  cat("  gamma1(a)   : degree-4 polynomial by default\n")
  cat("  gamma2(a)   : rho * gamma1(a) by default\n")
  invisible(x)
}
