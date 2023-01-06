#' Target factory for bookdown
#'
#' `{targets}` and `{tarchetypes}` make it straightforward to include individual
#' ["dependency-aware R Markdown reports inside the individual targets of a
#' pipeline"](https://books.ropensci.org/targets/files.html#literate-programming)
#' But a `{bookdown}`-based approach can be tricky. This function creates
#' targets to let you concisely (e.g. `tar_bookdown("report")`) include a
#' `bookdown` report in your pipeline, letting targets do its magic handling
#' dependencies.
#'
#' So, this function
#' - receives `input_dir`, typically a subfolder in your project that includes
#'   all .Rmd files and `{bookdown}` config files
#' - creates one target per .Rmd file in `input_dir`, making sure to include its
#'   dependencies (e.g. tar_read, tar_load calls within .Rmd files, detected via
#'   `tarchetypes::tar_knitr_deps`)
#' - includes also a single target for the `{bookdown}` report, that depends on
#'   all the individual targets corresponding to .Rmd files
#' - returns all the targets above as a list to be included in your pipeline
#'   (please note all targets are format = "file")
#'
#' Note that when running your pipeline, the bookdown target renders the book
#' using `flowme::bookme` which is simply a wrapper around
#' `bookdown::render_book` to deal with `{bookdown}`'s restrictions and  be able
#' to render in subdirectories. This collides with the stricter (compared to
#' .drake) policy of `{targets}` to find the data store (_targets/) at the
#' project root.
#'
#' EDIT: now it seems `{targets}` is more flexible and you can
#' configure the location using `tar_config_set()`. Yet, the discussion below
#' still applies because we need to deal with temporarily changing working
#' directory to make bookdown work).
#'
#' `flowme::bookme` changes working directory to `input_dir` to render the book.
#' Thus, when you call `tar_read` in an .Rmd, `{targets}` will look for the data
#' store in `input_dir` and not in your project root where it probably lies,
#' leading your pipeline to fail. To circumvent this issue, there are a few
#' alternatives you can use when retrieving targets in your .Rmd.
#'
#' - change the store directly to a hard-coded value, which is probably the less
#'   verbose alternative, but it is not robust or portable (e.g. if you nest
#'   the bookdown folder into other directories)
#'   + `tar_read(data, store = "..")`
#' - also change the store, but using `here` to help you find the data store
#'   + `tar_read(data, store = here::here(targets::tar_config_get("store")))`
#' - change the working directory again, temporarily
#'   + `xfun::in_dir(here::here(), tar_read(data))` # or withr::with_dir
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
                         output_dir = NULL, output_format = NULL,
                         preview = FALSE) {

  rmd_files <- fs::dir_ls(
    path = input_dir,
    # TODO: should we let the regexp be modified via fn arg?
    regexp = paste0("^", input_dir, "/[^_].*[.]Rmd$") # exclude _ starting files
    # TODO: recurse = TRUE # to be able to organize reports with subfolders?
  )

  rmd_files_targets <- purrr::map(rmd_files, .f = ~targets::tar_target_raw(
    name = make.names(.x),
    command = substitute(
      expr = {
        # this is hacky, ugly, fragile and error-prone, ..., but ...
        # it's the only trick I quickly came up with to convince targets to
        # build the report when there is a change in an upstream target
        # (e.g. data) that an .Rmd file depends on. In such cases, targets
        # correctly identifies and shows as outdated the upstream target,
        # the .Rmd file target and the report target. But in running the
        # pipeline, it builds the upstream target, the .Rmd file but skips
        # the report. The problem must be that after building the .Rmd target,
        # targets finds that it did not change and therefore there it no need
        # to build the report. Touching the .Rmd file does not work either,
        # I guess, because targets compare the hash of the file and not only
        # the modification date. So this trick is just to try and write
        # something to the end of the file to force a change in the file's
        # hash and induce targets to build it. There must be a better way.
        # Meanwhile, this works. TODO: find a better way.
        #write(" ", rmd_file, append = TRUE)
        # Now we are doing this a bit different, to also enable preview = TRUE
        # Here's the deal. We want to target that builds the report to be aware
        # of the .Rmd files that changed so that it can pass only those files
        # with preview = TRUE to bookdown.
        # We could not use {targets} fns for that. tar_outdated for example,
        # would not work. So we are hacking our way here, by using a small file
        # that the report depends on (see below, now it returns the book file
        # and the preview_file), and this file will be modified when the
        # target for an .Rmd need to run. That way we can know downstream
        # which .Rmds were modified (and also triggers the report build as well
        # effectively circumventing the issue discussed above).
        preview_file <- paste0(input_dir, "/_preview")
        fs::file_create(preview_file) # can happen it does not exist
        write(
          x = fs::path_rel(rmd_file, input_dir),
          file = preview_file,
          append = TRUE,
          sep = "\n"
        )
        rmd_file
      },
      env = list(rmd_file = .x, input_dir = input_dir)
    ),
    deps = tarchetypes::tar_knitr_deps(.x),
    format = "file"
  ))

  report_target <- targets::tar_target_raw(
    name = input_dir,
    command = base::substitute(
      expr = {

        # Now we can access the preview files, modified by the .Rmd targets
        preview_file <- paste0(input_dir, "/_preview")
        fs::file_create(preview_file) # can happen it does not exist
        rmd_to_preview <- readLines(preview_file)
        if (isTRUE(preview)) {
          input_files_to_pass <- rmd_to_preview[rmd_to_preview != ""]
        } else {
          input_files_to_pass <- input_files
        }
        # and we want to keep it empty once the report is built
        write(x = "", file = preview_file, append = FALSE)

        book_files <- flowme::bookme(
          input_dir = input_dir,
          input_files = input_files_to_pass,
          output_dir = output_dir,
          output_format = output_format,
          preview = preview
        )

        c(book_files, preview_file)
      },
      env = list(input_dir = input_dir,
                 input_files = input_files,
                 output_dir = output_dir,
                 output_format = output_format,
                 preview = preview)
    ),
    format = "file",
    deps = make.names(rmd_files)
  )

  list(rmd_files_targets, report_target)
}
