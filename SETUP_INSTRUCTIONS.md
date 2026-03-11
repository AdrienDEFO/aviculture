# SETUP INSTRUCTIONS FOR aviculture PACKAGE

## Step 1: Generate the Python Model (avimodel.pkl)

First, you need to run your Python script to generate the trained model:

```powershell
cd d:\projet\Avipro
python Interpolation.py
```

This will create `avimodel.pkl` in `d:\projet\Avipro\` directory.

**Expected output:**
- ✓ Model sauvegardé (pickle) : avimodel.pkl
- ✓ Model rechargé avec succès

---

## Step 2: Copy the Model to the Package

Copy the generated `avimodel.pkl` to the package data directory:

```powershell
copy d:\projet\Avipro\avimodel.pkl d:\projet\Avipro\aviculture\inst\extdata\avimodel.pkl
```

Or use Python:
```powershell
cd d:\projet\Avipro\aviculture\inst
python copy_model.py
```

---

## Step 3: Generate R Documentation from Roxygen

Open R and run:

```r
setwd("d:/projet/Avipro/aviculture")

# Install roxygen2 if needed
if (!require("roxygen2")) install.packages("roxygen2")

# Generate documentation from Roxygen comments
roxygen2::roxygenise()
```

This will:
- Create `.Rd` files in `man/` directory (help pages)
- Update `NAMESPACE` file
- Create `DESCRIPTION` (already done, will be updated)

**Files created:**
- `man/load_model.Rd`
- `man/predict_mass.Rd`
- `man/predict_volume.Rd`
- `man/predict_density.Rd`
- `man/predict_growth_rate.Rd`
- `man/predict_volume_growth_rate.Rd`
- `man/simulate_growth.Rd`
- `man/get_tissue_densities.Rd`
- `man/get_tissue_composition.Rd`
- `man/get_model_info.Rd`
- `man/is_valid_age.Rd`
- `man/validate_measurements.Rd`
- `man/compare_with_observations.Rd`

---

## Step 4: Check the Package Integrity

```r
# Set working directory
setwd("d:/projet/Avipro/aviculture")

# Load the package in development mode
devtools::load_all()

# Check package structure
devtools::check()

# or with base R
system("R CMD check aviculture")
```

Expected result: **Status: OK**

---

## Step 5: Install the Package Locally

```r
setwd("d:/projet/Avipro")

# Install from local source
install.packages("aviculture", repos = NULL, type = "source")

# Or using devtools
devtools::install("aviculture")
```

---

## Step 6: Test the Package

```r
library(aviculture)

# Load the model
model <- load_model()

# Test predictions
mass_30 <- predict_mass(30, model)
print(mass_30)  # Should be ~2.2 kg

# Test growth rate
gamma <- predict_growth_rate(30, mass_30, predict_volume(30, model), model)
print(gamma)

# Test simulation
trajectory <- simulate_growth(1, 60, model)
plot(trajectory$age, trajectory$mass_ref, type='l')
```

---

## Step 7: Build and Check for CRAN Submission

Before submitting to CRAN, run comprehensive checks:

```r
setwd("d:/projet/Avipro/aviculture")

# Full package check
devtools::check(remote = TRUE, run_dont_test = TRUE)

# Check with additional strictness
rcmdcheck::rcmdcheck()

# Run spell check
devtools::spell_check()

# Check URLs
urlchecker::url_check()
```

Expected: All checks pass with Status: **OK**

---

## Step 8: Build the Package Tarball

```r
setwd("d:/projet/Avipro")

# Create the source package
system("R CMD build aviculture")

# This creates: aviculture_0.2.0.tar.gz
```

---

## File Structure Verification

After all steps, your package should have this structure:

```
aviculture/
├── R/
│   ├── model.R          (core model functions)
│   ├── growth.R         (growth prediction functions)
│   ├── density.R        (density and tissue functions)
│   ├── utils.R          (utility functions)
│   └── zzz.R           (optional: .onLoad, .onAttach)
├── man/
│   ├── aviculture.Rd     (package documentation)
│   ├── load_model.Rd
│   ├── predict_mass.Rd
│   ├── predict_volume.Rd
│   ├── predict_density.Rd
│   ├── predict_growth_rate.Rd
│   ├── predict_volume_growth_rate.Rd
│   ├── simulate_growth.Rd
│   ├── get_tissue_densities.Rd
│   ├── get_tissue_composition.Rd
│   ├── get_model_info.Rd
│   ├── is_valid_age.Rd
│   ├── validate_measurements.Rd
│   └── compare_with_observations.Rd
├── inst/
│   ├── extdata/
│   │   └── avimodel.pkl    (THE TRAINED MODEL - CRITICAL)
│   └── copy_model.py
├── DESCRIPTION           (package metadata)
├── NAMESPACE            (function exports)
├── LICENSE              (MIT license)
├── README.md            (user documentation)
└── .Rbuildignore        (files to exclude from build)
```

---

## Troubleshooting

### Problem: "avimodel.pkl not found"
**Solution**: Make sure you've run `Interpolation.py` and copied the file to `inst/extdata/`.

### Problem: Roxygen comments not generating documentation
**Solution**: Make sure `RoxygenNote` in DESCRIPTION matches your roxygen2 version:
```r
packageVersion("roxygen2")
```
Update DESCRIPTION accordingly.

### Problem: reticulate cannot find Python
**Solution**: Configure Python in R:
```r
reticulate::use_python("C:/Users/YourUsername/AppData/Local/Programs/Python/Python39/python.exe")
# or use conda:
reticulate::use_condaenv("base")
```

### Problem: Package check fails with "Hidden objects"
**Solution**: This is normal for S3 methods. Add to `.Rbuildignore`:
```
^.*/\.[^/]*$
```

---

## CRAN Submission Checklist

Before submitting to CRAN:

- [ ] Run `devtools::check()` - Status OK
- [ ] Run `rcmdcheck::rcmdcheck()` - No errors/warnings
- [ ] Version number updated in DESCRIPTION
- [ ] All Roxygen documentation generated
- [ ] README.md complete with examples
- [ ] LICENSE file present and correct
- [ ] No external URLs without DOI or active validation
- [ ] Package description clear and concise
- [ ] Author/Maintainer information correct
- [ ] All Suggests and Imports listed correctly
- [ ] Package tested locally with `library(aviculture)`
- [ ] CRAN policy compliance checked

---

## Contact

For questions, open an issue on GitHub or email: contact@aviculture.dev

Good luck with your CRAN submission! 🚀



