# Internal helper: single entry point for gamma interpolation calls.
.predict_gamma <- function(field_name, age, mass, volume, model) {
  if (!is.list(model)) {
    stop("model must be an object returned by load_model()")
  }

  gamma_fn <- tryCatch(model[[field_name]], error = function(e) NULL)
  if (is.null(gamma_fn)) {
    stop("model must provide '", field_name, "' from the registered interpolation model")
  }

  if (!is.numeric(age) || !is.numeric(mass) || !is.numeric(volume)) {
    stop("age, mass, and volume must be numeric")
  }

  tryCatch({
    as.numeric(gamma_fn(age, mass, volume))
  }, error = function(e) {
    stop("Error predicting ", field_name, ": ", e$message)
  })
}

#' Predict Mass Growth Rate (Gamma_m)
#'
#' Computes the instantaneous mass growth rate for an individual bird
#' based on its current age, mass, and volume.
#'
#' @param age Numeric. Current age in days.
#' @param mass Numeric. Current mass in kg.
#' @param volume Numeric. Current volume in L.
#' @param model A model object from \code{\link{load_model}}.
#'
#' @return
#' Numeric vector of mass growth rates (kg/day).
#'
#' @details
#' The growth rate is calculated as:
#' \deqn{\gamma_m(a, m, v) = \gamma_{ref}(a) \cdot \psi(a, m, v)}
#' where \eqn{\psi} is a dimensionless growth multiplier depending on the bird's
#' deviation from the average trajectory.
#'
#' The multiplier combines mass and volume deviations:
#' \deqn{\psi = \left(\frac{m}{m_{ref}}\right)^\alpha \left(\frac{v}{v_{ref}}\right)^\beta}
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   
#'   # Bird at age 30, slightly heavier than average
#'   age <- 30
#'   m_ref <- predict_mass(age, model)
#'   v_ref <- predict_volume(age, model)
#'   m_obs <- m_ref * 1.05  # 5% heavier
#'   v_obs <- v_ref * 1.03  # 3% larger volume
#'   
#'   gamma_m <- predict_growth_rate(age, m_obs, v_obs, model)
#'   cat("Mass growth rate:", gamma_m, "kg/day\n")
#' }
#'
#' @export
predict_growth_rate <- function(age, mass, volume, model) {
  .predict_gamma("gamma_m", age, mass, volume, model)
}


#' Predict Volume Growth Rate (Gamma_v)
#'
#' Computes the instantaneous volume growth rate for an individual bird
#' based on its current age, mass, and volume.
#'
#' @param age Numeric. Current age in days.
#' @param mass Numeric. Current mass in kg.
#' @param volume Numeric. Current volume in L.
#' @param model A model object from \code{\link{load_model}}.
#'
#' @return
#' Numeric vector of volume growth rates (L/day).
#'
#' @details
#' The volume growth rate is derived from the mass growth rate
#' adjusted for density:
#' \deqn{\gamma_v(a, m, v) = \frac{1000}{\rho(a)} \cdot \gamma_m(a, m, v)}
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   
#'   age <- 30
#'   m_ref <- predict_mass(age, model)
#'   v_ref <- predict_volume(age, model)
#'   
#'   gamma_v <- predict_volume_growth_rate(age, m_ref, v_ref, model)
#'   cat("Volume growth rate:", gamma_v, "L/day\n")
#' }
#'
#' @export
predict_volume_growth_rate <- function(age, mass, volume, model) {
  .predict_gamma("gamma_v", age, mass, volume, model)
}


#' Simulate Broiler Growth Trajectory
#'
#' Simulates the complete growth trajectory (mass and volume) from
#' age start_age to end_age.
#'
#' @param start_age Numeric. Starting age in days. Default is 1.
#' @param end_age Numeric. Ending age in days. Default is 60.
#' @param model A model object from \code{\link{load_model}}.
#' @param initial_mass Numeric. Initial mass in kg. If NULL, uses model reference.
#' @param initial_volume Numeric. Initial volume in L. If NULL, computed from density.
#' @param time_step Numeric. Time step in days for simulation. Default is 1.
#'
#' @return
#' A data frame with columns:
#' \item{age}{Age in days}
#' \item{mass_ref}{Reference mass (kg)}
#' \item{volume_ref}{Reference volume (L)}
#' \item{density}{Tissue density (kg/L)}
#' \item{mass_obs}{Observed/simulated mass (kg)}
#' \item{volume_obs}{Observed/simulated volume (L)}
#' \item{gamma_m}{Mass growth rate (kg/day)}
#' \item{gamma_v}{Volume growth rate (L/day)}
#'
#' @details
#' If initial mass/volume are provided, the simulation tracks deviations
#' from the reference trajectory. Otherwise, it replicates the reference
#' curve exactly.
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   
#'   # Simulate reference trajectory
#'   trajectory <- simulate_growth(start_age = 1, end_age = 60, model = model)
#'   
#'   # Visualize
#'   plot(trajectory$age, trajectory$mass_ref, type = 'l',
#'        xlab = "Age (days)", ylab = "Mass (kg)",
#'        main = "Reference Growth Trajectory")
#'   
#'   # Simulate with initial deviation
#'   trajectory_light <- simulate_growth(
#'     start_age = 1, end_age = 60, model = model,
#'     initial_mass = 0.044 * 0.9  # 10% lighter at age 1
#'   )
#'   lines(trajectory_light$age, trajectory_light$mass_obs, col = "red", lty = 2)
#' }
#'
#' @export
simulate_growth <- function(start_age = 1, end_age = 60, model,
                            initial_mass = NULL, initial_volume = NULL,
                            time_step = 0.1) {
  
  if (!is.list(model) || !exists("m_bar", where = model)) {
    stop("model must be an object returned by load_model()")
  }
  
  if (start_age < 1 || end_age > 80) {
    warning("Ages outside 1-60 days range may produce unreliable predictions")
  }
  
  # Generate age sequence
  ages <- seq(start_age, end_age, by = time_step)
  n <- length(ages)
  
  # Initialize trajectories
  result <- data.frame(
    age = ages,
    mass_ref = numeric(n),
    volume_ref = numeric(n),
    density = numeric(n),
    mass_obs = numeric(n),
    volume_obs = numeric(n),
    gamma_m = numeric(n),
    gamma_v = numeric(n),
    stringsAsFactors = FALSE
  )
  
  # Get reference values
  result$mass_ref <- sapply(ages, function(a) predict_mass(a, model))
  result$volume_ref <- sapply(ages, function(a) predict_volume(a, model))
  result$density <- sapply(ages, function(a) predict_density(a, model))
  
  # Initialize observed trajectory
  if (is.null(initial_mass)) {
    result$mass_obs <- result$mass_ref
  } else {
    result$mass_obs[1] <- initial_mass
  }
  
  if (is.null(initial_volume)) {
    result$volume_obs <- result$volume_ref
  } else {
    result$volume_obs[1] <- initial_volume
  }
  
  # Calculate growth rates
  for (i in seq_along(ages)) {
    a <- ages[i]
    m <- result$mass_obs[i]
    v <- result$volume_obs[i]
    
    result$gamma_m[i] <- predict_growth_rate(a, m, v, model)
    result$gamma_v[i] <- predict_volume_growth_rate(a, m, v, model)
    
    # Project to next day if not at the end
    if (i < n) {
      result$mass_obs[i + 1] <- m + result$gamma_m[i] * time_step
      result$volume_obs[i + 1] <- v + result$gamma_v[i] * time_step
    }
  }
  
  return(result)
}
