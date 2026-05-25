test_that("solver returns a valid simulation object", {
  grid <- create_grid(t_max = 3, a_max = 5, m_max = 1, h_t = 0.1, h_a = 1, h_m = 0.2)
  controls <- create_controls(grid = grid, supply = 5, demand = 0, price = 1)
  simulation <- solve_aviculture(
    grid = grid,
    parameters = create_parameters(),
    controls = controls
  )

  expect_s3_class(simulation, "aviculture_simulation")
  expect_true(all(c("healthy", "stunted", "total") %in% names(simulation$indicators)))
  expect_true(all(is.finite(unlist(simulation$objectives))))
})
