source("~/.Rprofile")

# we are putting all env setup now in a project-level .Rprofile
# not convinced about this approach, but let's see how it goes
# don't like that it is not explicitly linked in _targets.R, but ...

if(!requireNamespace("pacman", quietly = TRUE)) {
  utils::install.packages("pacman")
}

pacman::p_load(
  magrittr,
  dplyr,
  tidyr,
  ggplot2,

  targets,
  tarchetypes
)

conflicted::conflict_prefer("filter", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("select", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("expand", "tidyr", quiet = TRUE)

# make all fns available to {targets} (and interactively, via load_all)
if (rlang::is_interactive()) {
  devtools::load_all()
} else {
  invisible(
    lapply(list.files("./R", full.names = TRUE), source, encoding = "UTF-8")
  )
}
