#' Validate Age Parameter
#'
#' Check if age is within the valid range for the model (1-60 days)
#'
#' @param age Numeric. Age in days to validate.
#'
#' @return
#' Logical. TRUE if age is valid (1-60), FALSE otherwise.
#'
#' @examples
#' is_valid_age(30)
#' is_valid_age(70)
#'
#' @export
is_valid_age <- function(age) {
  if (!is.numeric(age) || length(age) == 0) {
    return(FALSE)
  }
  return(all(age >= 1 & age <= 60))
}

#' Validate Measurement Inputs
#'
#' Validates that measurement inputs are in the correct format and range
#'
#' @param mass Numeric vector. Body mass in kg.
#' @param volume Numeric vector (optional). Body volume in liters.
#' @param age Numeric vector. Age in days.
#'
#' @return
#' Logical. TRUE if all measurements are valid, FALSE otherwise.
#'
#' @details
#' Checks that:
#' \itemize{
#'   \item All inputs are numeric
#'   \item Ages are between 1 and 60 days
#'   \item Mass values are positive
#'   \item Volume values (if provided) are positive
#'   \item Input vectors have compatible lengths
#' }
#'
#' @examples
#' validate_measurements(mass = 0.5, age = 5)
#' validate_measurements(mass = c(0.5, 1.0), age = c(5, 10))
#'
#' @export
validate_measurements <- function(mass, age, volume = NULL) {
  # Check if mass and age are numeric
  if (!is.numeric(mass) || !is.numeric(age)) {
    return(FALSE)
  }
  
  # Check if vectors have compatible lengths
  if (length(mass) != length(age)) {
    return(FALSE)
  }
  
  # Check if ages are valid
  if (!all(age >= 1 & age <= 60)) {
    return(FALSE)
  }
  
  # Check if mass values are positive
  if (!all(mass > 0)) {
    return(FALSE)
  }
  
  # If volume provided, check it
  if (!is.null(volume)) {
    if (!is.numeric(volume)) {
      return(FALSE)
    }
    if (length(volume) != length(mass)) {
      return(FALSE)
    }
    if (!all(volume > 0)) {
      return(FALSE)
    }
  }
  
  return(TRUE)
}

#' Compare Model Predictions with Observed Data
#'
#'
#' Calculate goodness-of-fit metrics between model predictions and observations
#'
#' @param predicted Numeric vector. Model predicted values.
#' @param observed Numeric vector. Observed values from data.
#'
#' @return
#' A list containing:
#' \item{rmse}{Root Mean Squared Error}
#' \item{mae}{Mean Absolute Error}
#' \item{mape}{Mean Absolute Percentage Error}
#' \item{r_squared}{R-squared coefficient of determination}
#' \item{pearson_r}{Pearson correlation coefficient}
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   predicted <- sapply(1:60, function(age) predict_mass(age, model))
#'   # compare_with_observations(predicted, observed_mass_data)
#' }
#'
#' @export
compare_with_observations <- function(predicted, observed) {
  if (!is.numeric(predicted) || !is.numeric(observed)) {
    stop("Both predicted and observed must be numeric vectors")
  }
  
  if (length(predicted) != length(observed)) {
    stop("predicted and observed must have the same length")
  }
  
  # Calculate errors
  errors <- predicted - observed
  
  # RMSE
  rmse <- sqrt(mean(errors^2))
  
  # MAE
  mae <- mean(abs(errors))
  
  # MAPE
  mape <- mean(abs(errors / observed)) * 100
  
  # R-squared
  ss_res <- sum(errors^2)
  ss_tot <- sum((observed - mean(observed))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  # Pearson correlation
  pearson_r <- cor(predicted, observed, method = "pearson")
  
  return(list(
    rmse = rmse,
    mae = mae,
    mape = mape,
    r_squared = r_squared,
    pearson_r = pearson_r
  ))
}
