# Default polynomial coefficients estimated from `regression_analysis.py`.
.aviculture_gamma1_coefficients <- c(
  2.47585141e-08,
  -3.07710266e-06,
  8.11711240e-05,
  1.76493561e-03,
  9.53163333e-03
)

.default_gamma1 <- function(age, mass = NULL) {
  value <- (((.aviculture_gamma1_coefficients[1] * age +
    .aviculture_gamma1_coefficients[2]) * age +
    .aviculture_gamma1_coefficients[3]) * age +
    .aviculture_gamma1_coefficients[4]) * age +
    .aviculture_gamma1_coefficients[5]
  pmax(0, value)
}

.default_gamma2 <- function(age, mass = NULL, rho = 0.2) {
  rho * .default_gamma1(age = age, mass = mass)
}

.default_supply <- function(time) {
  rep(40, length(time))
}

.default_sale_rate <- function(age, mass, time, market_mass = 2.3) {
  ifelse(mass >= market_mass, 0.06, 0)
}

.default_mortality <- function(age, mass) {
  base <- 0.004 + 0.002 * (age <= 7)
  pmax(0, base)
}

.default_competition <- function(age, mass) {
  rep(0, length(age))
}

.default_demand <- function(time) {
  ifelse(time < 35, 0, 25)
}

.default_price <- function(time) {
  rep(5.5, length(time))
}

.default_supply_cost <- function(time) {
  rep(1.25, length(time))
}

.default_feed_cost <- function(age, mass) {
  0.03 + 0.01 * pmax(mass, 0)
}

.default_death_cost <- function(age, mass) {
  rep(0.5, length(age))
}

.default_unit_value <- function(age, mass, time, market_mass, price) {
  ifelse(mass >= market_mass, price(time), 0) - .default_feed_cost(age, mass)
}
