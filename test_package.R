#!/usr/bin/env Rscript
#' =====================================================
#'  COMPREHENSIVE AVICULTURE PACKAGE TEST SUITE
#' =====================================================
#' Tests all core functionality:
#' - Model loading and validation
#' - Mass & volume predictions
#' - Growth rates & tissue composition
#' - Numerical methods (Euler, Simpson, RK4)
#' - Growth simulation
#' - Economic calculations
#' =====================================================

library(aviculture)

# Color output helpers
cat_pass <- function(text) cat("\033[92m✓\033[0m", text, "\n")
cat_fail <- function(text) cat("\033[91m✗\033[0m", text, "\n")
cat_test <- function(text) cat("\n\033[94m[TEST]\033[0m", text, "\n")
cat_section <- function(text) cat("\n\033[1;96m", strrep("=", 60), "\033[0m\n", text, "\n", strrep("=", 60), "\033[0m\n\n", sep="")

passed <- 0
failed <- 0

cat_section("COMPREHENSIVE AVICULTURE PACKAGE TEST v0.3")

# ============================================================
# TEST 1: Package Information
# ============================================================
cat_test("Package Information")

tryCatch({
  version <- paste(packageVersion("aviculture"))
  cat("  Package: aviculture v", version, "\n")
  cat("  R version: ", paste(R.version$major, R.version$minor, sep="."), "\n")
  cat_pass("Package loaded successfully")
  passed <- passed + 1
}, error = function(e) {
  cat_fail(paste("Package load error:", e$message))
  failed <<- failed + 1
})

# ============================================================
# TEST 2: Validation Functions
# ============================================================
cat_test("Validation Functions")

validations <- list(
  list(func = is_valid_age, args = list(30), expected = TRUE, desc = "is_valid_age(30)"),
  list(func = is_valid_age, args = list(70), expected = FALSE, desc = "is_valid_age(70)"),
  list(func = is_valid_age, args = list(1), expected = TRUE, desc = "is_valid_age(1)"),
  list(func = validate_measurements, args = list(0.5, 5), expected = TRUE, desc = "validate_measurements(0.5, 5)"),
  list(func = validate_measurements, args = list(-0.5, 5), expected = FALSE, desc = "validate_measurements(-0.5, 5)")
)

for (v in validations) {
  tryCatch({
    result <- do.call(v$func, v$args)
    if (result == v$expected) {
      cat_pass(paste(v$desc, "=>", result))
      passed <<- passed + 1
    } else {
      cat_fail(paste(v$desc, "=> Expected", v$expected, "got", result))
      failed <<- failed + 1
    }
  }, error = function(e) {
    cat_fail(paste(v$desc, "=>", e$message))
    failed <<- failed + 1
  })
}

# ============================================================
# TEST 3: Model Loading
# ============================================================
cat_test("Model Loading")

model <- NULL
tryCatch({
  model <- load_model(verbose = FALSE)
  if (!is.null(model) && is.list(model)) {
    cat_pass(paste("Model loaded: type =", model$model_name))
    cat("  - Training data: ages 1-60 days")
    cat("  - Model quality (RMSE):", model$quality_metrics$rmse, "kg\n")
    passed <<- passed + 1
  } else {
    cat_fail("Model object is NULL or invalid structure")
    failed <<- failed + 1
  }
}, error = function(e) {
  cat_fail(paste("Model loading failed:", e$message))
  failed <<- failed + 1
})

if (is.null(model)) {
  cat("\n⚠️  Cannot continue tests without model. Check Python file avimodel.pkl\n")
} else {
  
  # ============================================================
  # TEST 4: Basic Predictions (Mass & Volume)
  # ============================================================
  cat_test("Mass and Volume Predictions")
  
  test_ages <- c(1, 5, 15, 30, 45, 60)
  cat("  Age(d) | Mass(kg) | Volume(L) | Density(kg/L) | Comment\n")
  cat("  ", strrep("-", 60), "\n", sep="")
  
  all_pass <- TRUE
  for (age in test_ages) {
    tryCatch({
      mass <- predict_mass(age, model)
      volume <- predict_volume(age, model)
      density <- predict_density(age, model)
      
      # Sanity checks
      checks_pass <- (mass > 0 && mass < 5 &&
                      volume > 0 && volume < 4 &&
                      density > 0.8 && density < 1.2)
      
      comment <- if (checks_pass) "✓" else "⚠️ Abnormal"
      cat(sprintf("    %2d  | %7.3f  | %7.3f   | %11.4f   | %s\n", 
                  age, mass, volume, density, comment))
      
      if (checks_pass) passed <<- passed + 1
      else { failed <<- failed + 1; all_pass <<- FALSE }
      
    }, error = function(e) {
      cat_fail(paste("  Age", age, "error:", e$message))
      failed <<- failed + 1
      all_pass <<- FALSE
    })
  }
  
  if (all_pass) {
    cat_pass("All mass/volume predictions within acceptable ranges")
  } else {
    cat_fail("Some predictions outside acceptable ranges")
  }
  
  # ============================================================
  # TEST 5: Growth Rates
  # ============================================================
  cat_test("Growth Rates (gamma_m, gamma_v)")
  
  test_points <- list(
    list(age = 10, mass_ratio = 1.0, vol_ratio = 1.0, desc = "Average bird at day 10"),
    list(age = 30, mass_ratio = 1.05, vol_ratio = 1.03, desc = "5% heavier bird at day 30"),
    list(age = 45, mass_ratio = 0.95, vol_ratio = 0.97, desc = "5% lighter bird at day 45")
  )
  
  for (pt in test_points) {
    tryCatch({
      m_ref <- predict_mass(pt$age, model)
      v_ref <- predict_volume(pt$age, model)
      m_obs <- m_ref * pt$mass_ratio
      v_obs <- v_ref * pt$vol_ratio
      
      gamma_m <- predict_growth_rate(pt$age, m_obs, v_obs, model)
      gamma_v <- predict_volume_growth_rate(pt$age, m_obs, v_obs, model)
      
      if (gamma_m > 0 && gamma_v > 0 && gamma_m < 0.3 && gamma_v < 0.3) {
        cat_pass(paste(pt$desc, "=> γ_m =", format(gamma_m, digits=4), "kg/d, γ_v =", format(gamma_v, digits=4), "L/d"))
        passed <<- passed + 1
      } else {
        cat_fail(paste(pt$desc, "=> Abnormal rates", gamma_m, gamma_v))
        failed <<- failed + 1
      }
    }, error = function(e) {
      cat_fail(paste(pt$desc, "=>", e$message))
      failed <<- failed + 1
    })
  }
  
  # ============================================================
  # TEST 6: Tissue Composition
  # ============================================================
  cat_test("Tissue Composition")
  
  tissue_ages <- c(1, 30, 60)
  for (age in tissue_ages) {
    tryCatch({
      comp <- get_tissue_composition(age, model)
      total <- sum(unlist(comp))
      
      cat(sprintf("  Day %2d: Bone=%.1f%% Muscle=%.1f%% Fat=%.1f%% Blood=%.1f%% Organs=%.1f%% (total=%.1f%%)\n",
                  age, comp$bone, comp$muscle, comp$fat, comp$blood, comp$organs, total))
      
      # Tissue proportions should sum to ~100%
      if (abs(total - 100) < 2) {
        cat_pass(paste("Composition valid for day", age))
        passed <<- passed + 1
      } else {
        cat_fail(paste("Composition sum != 100% for day", age))
        failed <<- failed + 1
      }
    }, error = function(e) {
      cat_fail(paste("Day", age, "error:", e$message))
      failed <<- failed + 1
    })
  }
  
  # ============================================================
  # TEST 7: Numerical Methods - Euler Integration
  # ============================================================
  cat_test("Numerical Methods - Explicit Euler")
  
  tryCatch({
    # Simple exponential: dy/dt = 0.1 * y, y(0) = 1, exact: y(t) = e^(0.1*t)
    f_exp <- function(y, t) 0.1 * y
    result <- euler_integrate(f_exp, y0 = 1, t0 = 0, t_final = 10, dt = 0.01)
    
    y_final <- tail(result$values, 1)
    y_expected <- exp(0.1 * 10)  # e^1 ≈ 2.718
    error_pct <- abs(y_final - y_expected) / y_expected * 100
    
    cat(sprintf("  Exponential growth test (dt=0.01)\n"))
    cat(sprintf("  - Computed: y(10) = %.4f\n", y_final))
    cat(sprintf("  - Expected: y(10) = %.4f\n", y_expected))
    cat(sprintf("  - Error: %.2f%%\n", error_pct))
    
    if (error_pct < 2) {
      cat_pass("Euler integration accurate")
      passed <<- passed + 1
    } else {
      cat_fail(paste("Euler error > 2%:", error_pct, "%"))
      failed <<- failed + 1
    }
  }, error = function(e) {
    cat_fail(paste("Euler test error:", e$message))
    failed <<- failed + 1
  })
  
  # ============================================================
  # TEST 8: Numerical Methods - Simpson's Rule
  # ============================================================
  cat_test("Numerical Methods - Simpson's Rule Integration")
  
  tryCatch({
    # Integrate sin(x) from 0 to π => should give 2.0
    x <- seq(0, pi, length.out = 101)  # 100 intervals (even)
    y <- sin(x)
    dt <- pi / 100
    
    result <- integral_simpson(y, dt = dt)
    expected <- 2.0
    error <- abs(result - expected)
    
    cat(sprintf("  Simpson integration test: ∫sin(x)dx from 0 to π\n"))
    cat(sprintf("  - Computed: %.6f\n", result))
    cat(sprintf("  - Expected: %.6f\n", expected))
    cat(sprintf("  - Error: %.2e\n", error))
    
    if (error < 0.01) {
      cat_pass("Simpson's rule accurate")
      passed <<- passed + 1
    } else {
      cat_fail(paste("Simpson error > 0.01:", error))
      failed <<- failed + 1
    }
  }, error = function(e) {
    cat_fail(paste("Simpson test error:", e$message))
    failed <<- failed + 1
  })
  
  # ============================================================
  # TEST 9: Numerical Methods - RK4 Integration
  # ============================================================
  cat_test("Numerical Methods - Runge-Kutta 4th Order")
  
  tryCatch({
    # Same exponential test with RK4 (should be more accurate)
    f_exp <- function(y, t) 0.1 * y
    result <- rk4_integrate(f_exp, y0 = 1, t0 = 0, t_final = 10, dt = 0.01)
    
    y_final <- tail(result$values, 1)
    y_expected <- exp(0.1 * 10)
    error_pct <- abs(y_final - y_expected) / y_expected * 100
    
    cat(sprintf("  Exponential growth test (dt=0.01)\n"))
    cat(sprintf("  - Computed: y(10) = %.6f\n", y_final))
    cat(sprintf("  - Expected: y(10) = %.6f\n", y_expected))
    cat(sprintf("  - Error: %.4f%%\n", error_pct))
    
    if (error_pct < 0.1) {
      cat_pass("RK4 integration very accurate")
      passed <<- passed + 1
    } else {
      cat_fail(paste("RK4 error > 0.1%:", error_pct, "%"))
      failed <<- failed + 1
    }
  }, error = function(e) {
    cat_fail(paste("RK4 test error:", e$message))
    failed <<- failed + 1
  })
  
  # ============================================================
  # TEST 10: Growth Simulation
  # ============================================================
  cat_test("Growth Simulation (Reference Trajectory)")
  
  tryCatch({
    trajectory <- simulate_growth(start_age = 1, end_age = 60, model = model, time_step = 1)
    
    cat(sprintf("  Simulated %d days, %d time points\n", nrow(trajectory)-1, nrow(trajectory)))
    cat("  Age(d) | Mass_Ref(kg) | Volume_Ref(L) | Gamma_m(kg/d) | Gamma_v(L/d)\n")
    cat("  ", strrep("-", 70), "\n", sep="")
    
    selected_indices <- c(1, 10, 20, 30, 40, 50, 60)
    all_valid <- TRUE
    for (idx in selected_indices) {
      if (idx <= nrow(trajectory)) {
        row <- trajectory[idx, ]
        cat(sprintf("     %2d  | %12.4f | %13.4f | %13.6f | %13.6f\n",
                    row$age, row$mass_ref, row$volume_ref, row$gamma_m, row$gamma_v))
        
        if (row$gamma_m <= 0 || row$gamma_v <= 0 || is.na(row$gamma_m)) {
          all_valid <- FALSE
        }
      }
    }
    
    if (all_valid && nrow(trajectory) > 50) {
      cat_pass("Growth trajectory simulated successfully")
      passed <<- passed + 1
    } else {
      cat_fail("Trajectory has invalid values or insufficient data")
      failed <<- failed + 1
    }
  }, error = function(e) {
    cat_fail(paste("Growth simulation error:", e$message))
    failed <<- failed + 1
  })
  
  # ============================================================
  # TEST 11: Cumulative Profit Integration
  # ============================================================
  cat_test("Cumulative Profit Calculation")
  
  tryCatch({
    times <- 0:60
    profit_per_day <- 10 + 0.5 * times  # Linear profit growth
    total_profit <- cumulative_profit(profit_per_day, times)
    expected <- 10 * 61 + 0.5 * (sum(times))  # Approximate sum
    
    cat(sprintf("  60-day simulation with linear profit growth\n"))
    cat(sprintf("  - Total cumulative profit: %.2f\n", total_profit))
    cat(sprintf("  - Expected (approx): %.2f\n", expected))
    
    if (!is.na(total_profit) && total_profit > 0) {
      cat_pass("Profit calculation successful")
      passed <<- passed + 1
    } else {
      cat_fail("Profit calculation failed or returned invalid value")
      failed <<- failed + 1
    }
  }, error = function(e) {
    cat_fail(paste("Profit calculation error:", e$message))
    failed <<- failed + 1
  })
  
} # end if model loaded

# ============================================================
# FINAL SUMMARY
# ============================================================
cat_section(paste("TEST SUMMARY"))

total_tests <- passed + failed
pass_rate <- if (total_tests > 0) (passed / total_tests * 100) else 0

cat(sprintf("  Passed: %3d tests  ✓\n", passed))
cat(sprintf("  Failed: %3d tests  ✗\n", failed))
cat(sprintf("  Total:  %3d tests\n", total_tests))
cat(sprintf("  Pass Rate: %.1f%%\n\n", pass_rate))

if (failed == 0) {
  cat("  \033[92m✓ ALL TESTS PASSED - Package is ready for production\033[0m\n")
} else {
  cat("  \033[91m✗ SOME TESTS FAILED - Review errors above\033[0m\n")
}

cat("\n\033[94m[INFO]\033[0m Ready to integrate with frontend via API\n")



