#' Tissue Density Reference Values
#'
#' Returns the reference density values for different broiler chicken tissues.
#'
#' @param model A model object from \code{\link{load_model}}.
#' @param tissue Character. Name of tissue: "bone", "muscle", "fat", "blood", "organs".
#'   If NULL, returns all tissues.
#'
#' @return
#' If tissue is NULL: a named list of tissue densities (kg/L).
#' If tissue is specified: the density value (numeric) for that tissue.
#'
#' @details
#' Tissue densities are biological constants determined from literature:
#' \itemize{
#'   \item bone: 1.85 kg/L (mineralized bone)
#'   \item muscle: 1.06 kg/L (protein + water)
#'   \item fat: 0.90 kg/L (lipids)
#'   \item blood: 1.06 kg/L (similar to water)
#'   \item organs: 1.04 kg/L (viscera)
#' }
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   
#'   # Get all tissue densities
#'   densities <- get_tissue_densities(model)
#'   
#'   # Get specific tissue
#'   bone_density <- get_tissue_densities(model, tissue = "bone")
#' }
#'
#' @export
get_tissue_densities <- function(model, tissue = NULL) {
  
  if (!is.list(model) || !exists("tissue_densities", where = model)) {
    stop("model must be an object returned by load_model()")
  }
  
  densities <- model$tissue_densities
  
  if (is.null(tissue)) {
    return(densities)
  } else {
    if (!(tissue %in% names(densities))) {
      stop("tissue must be one of: ", paste(names(densities), collapse = ", "))
    }
    return(as.numeric(densities[[tissue]]))
  }
}


#' Get Tissue Composition at Given Age
#'
#' Returns the proportion of each tissue (as percentage of body mass)
#' at the specified age using the multi-tissue model.
#'
#' @param age Numeric. Age in days.
#' @param model A model object from \code{\link{load_model}}.
#'
#' @return
#' A named list with proportions (%) of:
#' \item{bone}{Proportion of bone}
#' \item{muscle}{Proportion of muscle}
#' \item{fat}{Proportion of fat}
#' \item{blood}{Proportion of blood}
#' \item{organs}{Proportion of organs}
#'
#' @details
#' Tissue proportions are calculated from sigmoidal functions that
#' capture the biological changes in composition during growth.
#' Sum of proportions is normalized to 100%.
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   
#'   # Composition at day 1
#'   comp_young <- get_tissue_composition(1, model)
#'   
#'   # Composition at day 60 (market weight)
#'   comp_mature <- get_tissue_composition(60, model)
#'   
#'   # Compare
#'   cat("Muscle at day 1:", comp_young$muscle, "%\n")
#'   cat("Muscle at day 60:", comp_mature$muscle, "%\n")
#' }
#'
#' @export
get_tissue_composition <- function(age, model) {
  
  if (!is.list(model)) {
    stop("model must be an object returned by load_model()")
  }
  
  if (!is.numeric(age) || length(age) != 1) {
    stop("age must be a single numeric value")
  }
  
  # Check if tissue composition functions exist in model
  required_funcs <- c("proportion_bone", "proportion_muscle", "proportion_fat",
                      "proportion_blood", "proportion_organs")
  has_funcs <- all(sapply(required_funcs, function(f) exists(f, where = model)))
  
  if (!has_funcs) {
    # Try alternative names (Portuguese or mixed naming)
    alt_names <- c("proportion_os" = "bone",
                   "proportion_muscle" = "muscle",
                   "proportion_graisse" = "fat",
                   "proportion_sang" = "blood",
                   "proportion_visceres" = "organs")
    
    composition <- list()
    for (py_name in names(alt_names)) {
      if (exists(py_name, where = model)) {
        composition[[alt_names[py_name]]] <- as.numeric(model[[py_name]](age))
      }
    }
    
    if (length(composition) == 0) {
      stop("Tissue composition functions not found in model")
    }
    
    return(composition)
  }
  
  # Get proportions from Python functions
  composition <- list(
    bone = as.numeric(model$proportion_bone(age)),
    muscle = as.numeric(model$proportion_muscle(age)),
    fat = as.numeric(model$proportion_fat(age)),
    blood = as.numeric(model$proportion_blood(age)),
    organs = as.numeric(model$proportion_organs(age))
  )
  
  return(composition)
}


#' Model Metadata and Quality Information
#'
#' Returns information about the loaded model including interpolation method,
#' training data, and quality metrics.
#'
#' @param model A model object from \code{\link{load_model}}.
#' @param verbose Logical. If TRUE, print formatted output. Default is FALSE.
#'
#' @return
#' A list containing:
#' \item{model_name}{Interpolation method used}
#' \item{training_ages}{Age range of training data}
#' \item{n_samples}{Number of training samples}
#' \item{parameters}{Model parameters (alpha, beta)}
#' \item{quality_metrics}{RMSE, stability, convergence}
#'
#' @examples
#' \dontrun{
#'   model <- load_model()
#'   info <- get_model_info(model, verbose = TRUE)
#' }
#'
#' @export
get_model_info <- function(model, verbose = FALSE) {
  
  if (!is.list(model) || !exists("model_name", where = model)) {
    stop("model must be an object returned by load_model()")
  }
  
  info <- list(
    model_name = model$model_name,
    training_ages = list(
      min = min(model$age),
      max = max(model$age)
    ),
    n_samples = length(model$age),
    parameters = list(
      alpha = model$alpha,
      beta = model$beta
    ),
    quality_metrics = model$quality_metrics
  )
  
  if (verbose) {
    cat("\n========================================\n")
    cat("    Aviculture Model Information\n")
    cat("========================================\n")
    cat("Interpolation Method:", info$model_name, "\n")
    cat("Training Ages: ", info$training_ages$min, "-", info$training_ages$max, " days\n")
    cat("Training Samples:", info$n_samples, "\n\n")
    cat("Parameters:\n")
    cat("  alpha (mass elasticity):", format(info$parameters$alpha, digits = 3), "\n")
    cat("  beta (volume elasticity):", format(info$parameters$beta, digits = 3), "\n\n")
    cat("Quality Metrics:\n")
    cat("  RMSE:", format(info$quality_metrics$rmse, digits = 6), "\n")
    cat("  Stability:", format(info$quality_metrics$stability, digits = 6), "\n")
    cat("========================================\n\n")
  }
  
  return(info)
}




