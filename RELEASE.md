# Release checklist

## Before tagging

1. Update `Version` in `DESCRIPTION`.
2. Update `NEWS.md`.
3. Run:

```r
devtools::document()
devtools::test()
devtools::check()
```

4. Review `cran-comments.md`.
5. Ensure examples and vignettes remain lightweight.

## GitHub release

1. Merge to `main`.
2. Confirm GitHub Actions checks are green.
3. Create a tag such as `v0.1.0`.
4. Draft release notes from `NEWS.md`.

## CRAN submission

1. Run `devtools::check_win_devel()`.
2. Run `devtools::check_rhub()`.
3. Submit with:

```r
devtools::submit_cran()
```

4. Respond to CRAN feedback if needed.
