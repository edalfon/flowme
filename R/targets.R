#' Target factory for bookdown
#'
#' `targets` and `tarchetypes` make it straightforward to include individual
#' ["dependency-aware R Markdown reports inside the individual targets of a
#' pipeline"](https://books.ropensci.org/targets/files.html#literate-programming)
#' But a `bookdown`-based approach can be tricky. This function creates targets
#' to let you concisely (e.g. tar_bookdown("report")) include a `bookdown`
#' report in your pipeline, letting targets do its magic handling dependencies.
#'
#' So, this function
#' - receives `input_dir`, typically a subfolder in your project that includes
#'   all .Rmd files and `bookdown` config files
#' - creates one target per .Rmd file in `input_dir`, making sure to include its
#'   dependencies (e.g. tar_read, tar_load calls within .Rmd files, detected via
#'   `tarchetypes::tar_knitr_deps`)
#' - includes also a single target for the `bookdown` report, that depends on
#'   all the individual targets corresponding to .Rmd files
#' - returns all the targets above as a list to be included in your pipeline
#'   (please note all targets are format = "file")
#'
#' Note that when running your pipeline, the bookdown target renders the book
#' using `flowme::bookme` which is simply a wrapper around
#' `bookdown::render_book` to deal with `bookdown`'s restrictions and  be able
#' to render in subdirectories. This collides with the stricter (compared to
#' .drake) policy of `targets` to find the data store (_targets/) at the
#' project root.
#'
#' EDIT: now it seems `targets` is more flexible and you can
#' configure the location using `tar_config_set()`. Yet, the discussion below
#' still applies because we need to deal with temporarily changing working
#' directory to make bookdown work).
#'
#' `flowme::bookme` changes working directory to `input_dir` to render the book.
#' Thus, when you call `tar_read` in an .Rmd, `targets` will look for the data
#' store in `input_dir` and not in your project root where it probably lies,
#' leading your pipeline to fail. To circumvent this issue, there are a few
#' alternatives you can use when retrieving targets in your .Rmd.
#'
#' - change the store directly to a hard-coded value, which is probably the less
#'   verbose alternative, but it is not robust or portable (e.g. if you nest
#'   the bookdown folder into other directories)
#'   + `tar_read(data, store = "..")`
#' - also change the store, but using `here` to help you find the data store
#'   + tar_read(data, store = here::here(targets::tar_config_get("store")))
#' - change the working directory again, temporarily
#'   + xfun::in_dir(here::here(), tar_read(data)) # equivalently withr::with_dir
#' - TODO: there might be a better way to do it. Try and find it. Meanwhile,
#'   this works.
#'
#' @inheritParams bookme
#'
#' @return a list of targets, including one target for each .Rmd file in
#' input_dir and one target for the bookdown output, that depends on all
#' .Rmd files
#' @export
#' @md
#'
#' @examples
#' \dontrun{
#' tar_bookdown("report")
#' }
tar_bookdown <- function(input_dir = "report", input_files = ".",
                         output_dir = NULL, output_format = NULL) {

  rmd_files <- fs::dir_ls(
    path = input_dir,
    # TODO: should we let the regexp be modified via fn arg?
    regexp = paste0("^", input_dir, "/[^_].*[.]Rmd$") # exclude _ starting files
    # TODO: recurse = TRUE # to be able to organize reports with subfolders?
  )

  rmd_files_targets <- purrr::map(rmd_files, ~targets::tar_target_raw(
    name = .x,
    command = .x,
    deps = tarchetypes::tar_knitr_deps(.x),
    format = "file"
  ))

  report_target <- targets::tar_target_raw(
    name = input_dir,
    command = base::substitute({
      flowme::bookme(
        input_dir = input_dir,
        input_files = input_files,
        output_dir = output_dir,
        output_format = output_format
      )
    }),
    format = "file",
    deps = rmd_files
  )

  list(rmd_files_targets, report_target)
}
