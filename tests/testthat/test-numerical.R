test_that("integral_simpson matches known integrals", {
  # ∫_0^pi sin(x) dx = 2
  x <- seq(0, pi, by = 0.01)
  y <- sin(x)
  res <- integral_simpson(y, dt = 0.01)
  expect_true(is.finite(res))
  expect_lt(abs(res - 2), 1e-3)
})

test_that("integral_simpson falls back with proper scaling", {
  # odd number of intervals triggers trapezoid fallback
  x <- seq(0, 1, by = 0.3) # 0,0.3,0.6,0.9 -> 3 intervals (odd)
  y <- x
  dt <- 0.3
  # ∫_0^0.9 x dx = 0.5 * 0.9^2 = 0.405
  res <- integral_simpson(y, dt = dt)
  expect_lt(abs(res - 0.405), 5e-2)
})

