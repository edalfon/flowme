options(conflicts.policy = "strict")
if (file.exists("~/.Rprofile")) source("~/.Rprofile")

library(stats) # package 'stats' in options("defaultPackages") was not found
library(utils)
library(dplyr, mask.ok = c("filter", "lag", "intersect", "setdiff", "setequal", "union"))
library(tidyr)
library(ggplot2)
library(targets)
library(tarchetypes)

# make all fns available to {targets} (and interactively, via load_all)
if (rlang::is_interactive()) {
  devtools::load_all()
} else {
  invisible(
    lapply(list.files("./R", full.names = TRUE), source, encoding = "UTF-8")
  )
}
