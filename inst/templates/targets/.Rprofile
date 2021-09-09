# we are putting all env setup now in a project-level .Rprofile
# not convinced about this approach, but let's see how it goes
# don't like that it is not explicitly linked in _targets.R, but ...

if(!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}

pacman::p_load(
  magrittr,
  dplyr,
  tidyr,
  ggplot2,

  targets,
  tarchetypes
)

# let's also use xfun::pkg_load
if(!requireNamespace("xfun", quietly = TRUE)) {
  install.packages("xfun")
}
xfun::pkg_load(
  c(
    "conflicted",
    "callr",
    "visNetwork",
    "arrow",
    "assertr",
    "waldo",
    "qs",
    "sessioninfo",
    "tictoc",
    "fs",
    "here",
    "purrr",
    "bookdown"
  ),
  install = TRUE
)

conflicted::conflict_prefer("filter", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("select", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("expand", "tidyr", quiet = TRUE)

# make all fns available
invisible(
  lapply(list.files("./R", full.names = TRUE), source, encoding = "UTF-8")
)

