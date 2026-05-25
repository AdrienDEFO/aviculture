test_that("default parameters use the regression-based polynomial", {
  parameters <- create_parameters(rho = 0.3)
  age <- c(1, 10, 20)
  gamma1 <- parameters$gamma1(age, mass = rep(1, length(age)))
  gamma2 <- parameters$gamma2(age, mass = rep(1, length(age)))

  expect_true(all(gamma1 >= 0))
  expect_equal(gamma2, 0.3 * gamma1)
})
