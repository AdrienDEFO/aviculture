# Minimal pre-integration checks (local)
# Run from package root:
#   Rscript --vanilla test.R

options(warn = 1)
suppressPackageStartupMessages(library(aviculture))

cat("== aviculture test.R ==\n")
cat("Package version:", as.character(packageVersion("aviculture")), "\n\n")

cat("[1] Numerical: Simpson integral\n")
x <- seq(0, pi, by = 0.01)
y <- sin(x)
res <- integral_simpson(y, dt = 0.01)
cat("  integral_simpson(sin, 0..pi) =", format(res, digits = 8), " (expected 2)\n\n")

cat("[2] Cycle simulation (Euler)\n")
params <- list(
  T = 30,
  dt = 1,
  initialPopulation = 100,
  e = 10,
  d = 0.01,
  kappa = 0.0001,
  s = 0.05,
  demand = 200,
  cf = 1000,
  cs = 1,
  cn = 0.2,
  cd = 0.5,
  ps = 5,
  growthModel = "logistic",
  integrator = "euler"
)

sim <- run_aviculture_cycle(params, model = NULL)
cat("  rows:", nrow(sim), "cols:", ncol(sim), "\n")
cat("  final population:", tail(sim$population, 1), "\n")
cat("  final profit:", tail(sim$profit_cumulative, 1), "\n\n")

cat("[3] Cycle simulation (RK4)\n")
params$integrator <- "rk4"
sim2 <- run_aviculture_cycle(params, model = NULL)
cat("  final population:", tail(sim2$population, 1), "\n")
cat("  final profit:", tail(sim2$profit_cumulative, 1), "\n\n")

cat("OK\n")

