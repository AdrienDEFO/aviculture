test_that("grid creation returns expected structure", {
  grid <- create_grid(t_max = 10, h_t = 1, h_a = 1, h_m = 0.5)
  expect_s3_class(grid, "aviculture_grid")
  expect_true(length(grid$time) >= 11)
  expect_true(length(grid$age) > 1)
  expect_true(length(grid$mass) > 1)
})
