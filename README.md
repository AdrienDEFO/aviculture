# aviculture

## Overview

**aviculture** is a comprehensive R package for modeling and predicting broiler chicken growth dynamics. It implements a biologically-inspired multi-tissue density model and multiple interpolation methods (Spline, Lagrange, Gompertz, Radial Basis Functions) to accurately predict mass and volume growth trajectories.

The package is based on data from Ross 308 broiler chickens, an industry-standard genetic line, and provides accurate predictions from 1 to 60 days of age.

## Features

- 🐔 **Multi-tissue density modeling**: Accounts for bone, muscle, fat, blood, and organ tissues
- 📈 **Accurate growth prediction**: Mass and volume trajectories with validated interpolation
- ⚡ **Growth rate estimation**: Instantaneous growth rates for individual birds
- 🧾 **Runtime metadata**: Trace model path, load timestamp, and active interpolation model
- 📊 **Tissue composition analysis**: Track changes in tissue proportions with age
- ✅ **Data validation**: Built-in checks for measurement reliability
- 🧪 **Simulation capabilities**: Project growth trajectories from any starting point
- 🔬 **Model diagnostics**: Compare predictions with observed data and calculate fit metrics

## Installation

### From GitHub

```r
# Install remotes if needed
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

remotes::install_github("aviculture/aviculture")
```

### Requirements

- R >= 4.0.0
- reticulate >= 1.25
- Python >= 3.8 (with pickle module)

## Quick Start

```r
library(aviculture)

# Load the pre-trained model
model <- load_model()

# Traceability metadata (runtime)
meta <- attr(model, "aviculture_metadata")
print(meta)

# Predict average mass at 30 days
mass_30 <- predict_mass(30, model)
print(mass_30)  # ~2.2 kg

# Predict volume
volume_30 <- predict_volume(30, model)
print(volume_30)  # ~2.1 L

# Get density at age 30
density_30 <- predict_density(30, model)
print(density_30)  # ~1.05 kg/L

# Predict growth rate for an individual bird
gamma_m <- predict_growth_rate(30, mass = 2.1, volume = 2.0, model)
print(gamma_m)  # ~0.043 kg/day
```

## Examples

### Complete Growth Trajectory

```r
# Simulate growth from day 1 to 60
trajectory <- simulate_growth(start_age = 1, end_age = 60, model = model)

# Visualize
plot(trajectory$age, trajectory$mass_ref, type = 'l', 
     xlab = "Age (days)", ylab = "Mass (kg)",
     main = "Broiler Reference Growth Curve")
grid()

# Add individual growth (starting 10% lighter)
trajectory_light <- simulate_growth(
  start_age = 1, end_age = 60, model = model,
  initial_mass = predict_mass(1, model) * 0.9
)
lines(trajectory_light$age, trajectory_light$mass_obs, col = "red", lty = 2)
legend("topleft", legend = c("Reference", "Light individual"),
       lty = c(1, 2), col = c("black", "red"))
```

### Tissue Composition Analysis

```r
# Get tissue densities
densities <- get_tissue_densities(model)
print(densities)

# Composition at young age
comp_1 <- get_tissue_composition(1, model)
cat("Muscle at day 1:", comp_1$muscle, "%\n")

# Composition at market weight
comp_60 <- get_tissue_composition(60, model)
cat("Muscle at day 60:", comp_60$muscle, "%\n")
cat("Fat at day 60:", comp_60$fat, "%\n")
```

### Model Information and Quality

```r
# Get detailed model information
get_model_info(model, verbose = TRUE)

# Check if ages are in valid range
valid <- is_valid_age(c(10, 45, 75), model)
print(valid)

# Validate measurements for a bird
validation <- validate_measurements(
  age = 30,
  mass = 2.1,
  volume = 2.0,
  model = model,
  threshold = 50  # Warn if deviation > 50%
)
print(validation$messages)
```

### Compare with Observations

```r
# Simulate some observed data
ages_obs <- c(10, 20, 30, 40, 50)
masses_obs <- sapply(ages_obs, predict_mass, model = model) * 
             rnorm(5, mean = 1, sd = 0.03)
volumes_obs <- sapply(ages_obs, predict_volume, model = model) * 
              rnorm(5, mean = 1, sd = 0.03)

# Compare with model predictions
comparison <- compare_with_observations(ages_obs, masses_obs, volumes_obs, model)
print(comparison)

# Get quality metrics
mass_metrics <- attr(comparison, "mass_metrics")
cat("Mass RMSE:", mass_metrics$RMSE, "kg\n")
cat("Mass R2:", mass_metrics$R2, "\n")
```

## Mathematical Background

### Multi-Tissue Density Model

The package uses a biologically-grounded approach where broiler density is modeled as a weighted average of tissue densities:

$$\rho(a) = \sum_i p_i(a) \cdot \rho_i$$

where:
- $p_i(a)$ = proportion of tissue $i$ at age $a$ (calculated from sigmoidal functions)
- $\rho_i$ = intrinsic density of tissue $i$ (constant)

Tissue types:
- **Bone** (1.85 kg/L): Decreases as proportion, increases in absolute terms
- **Muscle** (1.06 kg/L): Increases with age
- **Fat** (0.90 kg/L): Increases rapidly with age
- **Blood** (1.06 kg/L): Relatively stable
- **Organs** (1.04 kg/L): Decreases as proportion

### Growth Rate Model

The instantaneous growth rate combines a reference trajectory with a dimensionless multiplier:

$$\gamma_m(a, m, v) = \gamma_{ref}(a) \cdot \psi(a, m, v)$$

where:

$$\psi = \left(\frac{m}{m_{ref}}\right)^\alpha \left(\frac{v}{v_{ref}}\right)^\beta$$

Parameters:
- $\alpha$ = 0.4 (mass elasticity)
- $\beta$ = 0.6 (volume elasticity)

This formulation ensures:
1. Birds on the reference trajectory have $\psi = 1$
2. Heavier birds grow faster
3. Larger-volume birds grow faster
4. Growth rates remain positive for realistic deviations

## Data and Model Selection

The package uses data from the [Ross 308 Broiler Performance Objectives](https://eu.aviagen.com/assets/Tech_Center/Ross_Broiler/Ross308-308FF-BroilerPO2019-EN.pdf) as reference. The best-performing interpolation method (evaluated by RMSE and stability) is automatically selected and serialized.

Current model: **Spline interpolation** with optimized smoothing parameters.

## Metadata and Traceability

`load_model()` now attaches runtime metadata to the loaded object:

- `package`: package name
- `loaded_at`: model load timestamp
- `model_path`: exact model file used
- `model_name`: active interpolation model name

Access it with:

```r
meta <- attr(model, "aviculture_metadata")
str(meta)
```

## Functions Reference

### Core Predictions

- `predict_mass(age, model)` - Reference mass at age
- `predict_volume(age, model)` - Reference volume at age
- `predict_density(age, model)` - Tissue density at age
- `predict_growth_rate(age, mass, volume, model)` - Mass growth rate
- `predict_volume_growth_rate(age, mass, volume, model)` - Volume growth rate

### Simulation

- `simulate_growth(start_age, end_age, model, ...)` - Full growth trajectory

### Tissue Analysis

- `get_tissue_densities(model)` - Tissue density constants
- `get_tissue_composition(age, model)` - Tissue proportions at age

### Utilities

- `load_model()` - Load pre-trained model
- `get_model_info(model, verbose)` - Model metadata
- `is_valid_age(age, model)` - Validate age range
- `validate_measurements(age, mass, volume, model)` - Validate bird data
- `compare_with_observations(age_obs, mass_obs, volume_obs, model)` - Compare predictions

## Citation

If you use aviculture in your research, please cite:

```
@software{aviculture2024,
  title={aviculture: Broiler Growth Model and Interpolation for Ross 308 Chickens},
  author={Aviculture Team},
  year={2024},
  url={https://github.com/aviculture/aviculture}
}
```

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

## References

1. Aviagen (2019). Ross 308 Broiler Performance Objectives.
   https://eu.aviagen.com/assets/Tech_Center/Ross_Broiler/

2. Sveegaard, S., & Lauridsen, C. (2005). Broiler welfare. 
   In Handbook of Farm Animal Breeding (pp. 215-234).

3. Hermans, D., & Matthijs, S. (2016). Chicken biology and health.
   In Poultry Meat Processing (pp. 1-15).




