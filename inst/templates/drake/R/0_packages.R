# Load required packages with pacman::p_load() to install them when missing
# TODO: Consider using xfun::pkg_attach(..., install = TRUE)
#       I don't like that it uses character vectors, though.
if(!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(
  magrittr,
  dplyr,
  tidyr,
  ggplot2,
  patchwork,

  assertr,

  conflicted,
  dotenv,
  drake
)

conflicted::conflict_prefer("filter", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("select", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("expand", "tidyr", quiet = TRUE)

# TODO: how to deal with dependencies (packages that need to be available)
#       but do not need to be attached/loaded (e.g. we use only one of its fns).
#       In a package that would go in the DESCRIPTION. Let's see how to do it.
#       Perhaps just renv::hydrate() once and not here 'cause this runs every
#       time r_make() and other r_* drake functions run.
#       Also, renv::hydrate() seems like a heavyweight, so perhaps better
#       only use DESCRIPTION and remotes::install_deps().
#       And set the lock file from renv, ja, but without forking library

# Meanwhile, let's use xfun::pkg_load
deps_pkgs <- c(
  "waldo",
  "qs",
  "bookdown"
)
xfun::pkg_load(deps_pkgs, install = TRUE)


# TODO: for projects where we do not want to use renv, let's how to deal
#       with dependencies
#       Perhaps pacman::p_install_version()
#
# TODO: and let's see how better integrate renv

# Check all packages used in this code
# renv::dependencies()$Package %>% unique()

