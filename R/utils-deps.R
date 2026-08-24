#' Check that the given packages are installed, stopping with an informative
#' message (and install hint) naming exactly the missing ones.
#' @noRd
check_pkgs_installed <- function(pkgs, fn_name) {
  installed <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
  missing <- pkgs[!installed]
  if (length(missing) > 0) {
    stop(
      "Package(s) ", paste(missing, collapse = ", "),
      " required for ", fn_name, "(). Install with:\n",
      "  install.packages(c(",
      paste0('"', missing, '"', collapse = ", "),
      "))",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
