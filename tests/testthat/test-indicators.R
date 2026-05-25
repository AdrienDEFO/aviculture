test_that("indicator and objective accessors return expected types", {
  grid <- create_grid(t_max = 2, a_max = 4, m_max = 0.5, h_t = 0.1, h_a = 1, h_m = 0.1)
  simulation <- solve_aviculture(
    grid = grid,
    parameters = create_parameters(),
    controls = create_controls(grid = grid)
  )

  indicators <- compute_indicators(simulation)
  objectives <- compute_objectives(simulation)

  expect_s3_class(indicators, "data.frame")
  expect_type(objectives, "list")
  expect_true(all(c("J1", "J2") %in% names(objectives)))
})
