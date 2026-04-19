# Internal helper: NULL-coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

