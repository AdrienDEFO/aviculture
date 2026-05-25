# Contributing to aviculture

Thank you for contributing to `aviculture`.

## Development workflow

1. Fork the repository and create a feature branch.
2. Keep changes focused and documented.
3. Add or update tests in `tests/testthat` whenever behavior changes.
4. Run local checks before opening a pull request:

```r
Rscript scripts/setup_test_library.R
Rscript scripts/document_package.R
Rscript scripts/test_package.R
Rscript scripts/check_package.R
```

## Style guidelines

- Use clear English names and comments.
- Keep exported functions documented.
- Prefer two-dimensional graphics for model outputs.
- Avoid adding heavy dependencies without a strong reason.

## Reporting issues

When opening an issue, include:

- a minimal reproducible example,
- the package version,
- the output of `sessionInfo()`,
- and, if relevant, the mathematical assumption being discussed.
