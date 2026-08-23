# using flowme::tar_bookdown means we have to deal with changing working
# directory and help targets find the store in tar_read/tar_load calls within
# .Rmd files. There are a number of alternatives and they can be verbose. So we
# override tar_read and tar_load changing the default store, and using {here} to
# help finding it note here heuristics to find it
# see ?flowme::tar_bookdown

tar_read <- purrr::partial(
  .f = targets::tar_read,
  store = here::here(targets::tar_config_get("store"))
)

tar_load <- purrr::partial(
  .f = targets::tar_load,
  store = here::here(targets::tar_config_get("store"))
)

# Small convenience for those who like writing (part of) the pipeline as
# plain sequential code inside a function -- e.g. a series of tar_target()
# calls -- instead of the usual list()/plan. tar_fn(fn) does NOT call fn();
# it unfolds fn's body and evals each top-level statement in the *caller's*
# environment (the console/.GlobalEnv), as if you had pasted the lines in
# one by one. Combined with the tar_target override in .RProfile (which, when
# interactive, evaluates the command and assigns it to `name` in .GlobalEnv
# instead of building a target definition), this lets you run such a
# function interactively and actually execute and assign each target -- not
# just get back its (unevaluated) target definition -- while still keeping
# the code organized in a function for non-interactive sourcing.
# Note: fn's arguments are not bound, so the body must not reference them
# (or you must define them yourself beforehand in the caller's environment).
tar_fn <- function(fn) {
  lapply(as.list(body(fn))[-1], eval)
}
