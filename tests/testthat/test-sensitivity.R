test_that("sensitivity analysis returns a structured result", {
  grid <- create_grid(t_max = 2, a_max = 4, m_max = 0.5, h_t = 0.1, h_a = 1, h_m = 0.1)
  parameters <- create_parameters()
  controls <- create_controls(grid = grid, supply = 5, demand = 2, price = 1)

  result <- run_sensitivity(
    grid = grid,
    parameters = parameters,
    controls = controls,
    variables = c("rho", "supply_scale"),
    values = c(0.8, 1.0)
  )

  expect_s3_class(result, "aviculture_sensitivity")
  expect_true(all(c("variable", "value", "metric", "outcome") %in% names(result$results)))
  expect_true(all(c("J1", "J2") %in% result$results$metric))
})
