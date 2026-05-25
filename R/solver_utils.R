.trapz_weights <- function(n) {
  weights <- rep(1, n)
  if (n > 1L) {
    weights[c(1L, n)] <- 0.5
  }
  weights
}

.space_weights <- function(n_age, n_mass) {
  outer(.trapz_weights(n_age), .trapz_weights(n_mass))
}

.evaluate_age_mass <- function(fun, age, mass, extra = list()) {
  grid <- expand.grid(age = age, mass = mass, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  values <- do.call(fun, c(list(age = grid$age, mass = grid$mass), extra))
  matrix(values, nrow = length(age), ncol = length(mass), byrow = FALSE)
}

.evaluate_sale_rate <- function(fun, age, mass, time) {
  grid <- expand.grid(age = age, mass = mass, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  values <- fun(age = grid$age, mass = grid$mass, time = time)
  matrix(values, nrow = length(age), ncol = length(mass), byrow = FALSE)
}

.competition_level <- function(X, Y, kappa, h_a, h_m, weights) {
  h_a * h_m * sum(weights * kappa * (X + Y))
}

.market_mask <- function(mass, market_mass) {
  mass >= market_mass
}

.safe_supply <- function(value) {
  pmax(0, value)
}

.aggregate_marketable <- function(stock, mask, weights, h_a, h_m) {
  h_a * h_m * sum(weights[, mask, drop = FALSE] * stock[, mask, drop = FALSE])
}

.compute_population_totals <- function(state_array, h_a, h_m, weights) {
  apply(
    state_array,
    1L,
    function(slice) h_a * h_m * sum(weights * matrix(slice, nrow = dim(state_array)[2L]))
  )
}

.reshape_time_slice <- function(array3d, time_index) {
  array3d[time_index, , , drop = TRUE]
}
