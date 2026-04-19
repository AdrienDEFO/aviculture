test_that("run_aviculture_cycle runs without Python model", {
  params <- list(
    T = 10,
    dt = 1,
    initialPopulation = 50,
    e = 10,
    d = 0.01,
    kappa = 0.0001,
    s = 0.1,
    demand = 20,
    cf = 100,
    cs = 1,
    cn = 0.2,
    cd = 0.5,
    ps = 5,
    growthModel = "logistic",
    integrator = "euler"
  )

  sim <- run_aviculture_cycle(params, model = NULL)
  expect_true(is.data.frame(sim))
  needed <- c(
    "t", "population", "marketable_pop", "births", "deaths", "sales",
    "mass_ref", "volume_ref", "density_ref",
    "total_biomass", "total_volume", "economic_potential",
    "costs_daily", "revenue_daily", "profit_daily",
    "costs_cumulative", "revenue_cumulative", "profit_cumulative"
  )
  expect_true(all(needed %in% names(sim)))
  expect_equal(sim$t[1], 0)
})

test_that("run_aviculture_cycle supports rk4 integrator", {
  params <- list(
    T = 5,
    dt = 1,
    initialPopulation = 0,
    e = 20,
    d = 0.02,
    kappa = 0.0001,
    s = 0.05,
    demand = 100,
    cf = 0,
    cs = 1,
    cn = 0.1,
    cd = 0.5,
    ps = 5,
    growthModel = "gompertz",
    integrator = "rk4"
  )
  sim <- run_aviculture_cycle(params, model = NULL)
  expect_true(is.data.frame(sim))
  expect_true(any(sim$population > 0))
})

