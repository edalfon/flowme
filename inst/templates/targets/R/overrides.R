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
