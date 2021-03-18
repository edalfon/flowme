# Load required packages with pacman::p_load() to install them when missing
if(!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(
  magrittr,
  dplyr,
  tidyr,
  ggplot2,

  assertr,

  conflicted,
  drake
)

conflicted::conflict_prefer("filter", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("select", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("expand", "tidyr", quiet = TRUE)

# Meanwhile, let's use xfun::pkg_load
deps_pkgs <- c(
  "waldo",
  "qs",
  "sessioninfo",
  "tictoc",
  "fs",
  "bookdown"
)
xfun::pkg_load(deps_pkgs, install = TRUE)

# TODO: better articulate with DESCRIPTION and renv
#       use DESCRIPTION and remotes::install_deps()
