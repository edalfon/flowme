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
                         output_dir = NULL, output_format = NULL) {

  rmd_files <- fs::dir_ls(
    path = input_dir,
    # TODO: should we let the regexp be modified via fn arg?
    regexp = paste0("^", input_dir, "/[^_].*[.]Rmd$") # exclude _ starting files
    # TODO: recurse = TRUE # to be able to organize reports with subfolders?
  )

  rmd_files_targets <- purrr::map(rmd_files, ~targets::tar_target_raw(
    name = .x,
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
        write(" ", rmd_file, append = TRUE)
        rmd_file
      },
      env = list(rmd_file = .x)
    ),
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



#' Add files and directories for a targets-powered project.
#'
#' Add boilerplate code to the current project for a targets-based project
#' - Copy templates to the current project.
#' - Include entries in .gitignore to prevent some files into version control
#'
#' @export
#' @md
targetsme <- function(install_deps = TRUE) {

  usethis::proj_set(".", force = TRUE)

  use_targets_templates()
  use_targets_description(install_deps)
  use_targets_gitignore()
}

#' @rdname targetsme
#' @export
use_targets <- targetsme



#' Copy `targets` templates to the current project
#'
#' TODO: let the user customize the "report" folder
#' TODO: more convenient overwrite?
#'
#' @export
#' @md
use_targets_templates <- function() {

  # targets file ####
  usethis::use_template(
    template = "targets/_targets.R", save_as = "_targets.R",
    ignore = TRUE, open = TRUE, package = "flowme"
  )
  usethis::use_template(
    template = "targets/_Rprofile", save_as = ".Rprofile",
    ignore = TRUE, open = TRUE, package = "flowme"
  )

  # R files ####
  fs::dir_create("R")
  usethis::use_template(
    template = "targets/R/overrides.R", save_as = "R/overrides.R",
    ignore = FALSE, open = TRUE, package = "flowme"
  )

  # report files ####
  usethis::use_directory("report", ignore = TRUE)
  usethis::use_template(
    template = "targets/report/_bookdown.yml", save_as = "report/_bookdown.yml",
    ignore = TRUE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "targets/report/_output.yml", save_as = "report/_output.yml",
    ignore = TRUE, open = FALSE, package = "flowme"
  )

  # Done differently because usethis::use_template does not handle well weird
  # characters in .docx files (presumably, trying to put data in the template)
  file.copy(
    from = fs::path_package("flowme", "templates/targets/report/_style.docx"),
    to = "report/_style.docx"
  )

  usethis::use_template(
    template = "targets/report/index.Rmd", save_as = "report/index.Rmd",
    ignore = TRUE, open = TRUE, package = "flowme"
  )
  usethis::use_template(
    template = "targets/report/chapter1.Rmd", save_as = "report/chapter1.Rmd",
    ignore = TRUE, open = TRUE, package = "flowme"
  )
  usethis::use_template(
    template = "targets/report/chapter2.Rmd", save_as = "report/chapter2.Rmd",
    ignore = TRUE, open = TRUE, package = "flowme"
  )
}

#' Add entries to .gitignore, to ignore non-version-control-friendly files
#' in this targets-based workflow
#'
#' @export
#' @md
use_targets_gitignore <- function() {

  usethis::use_git_ignore("_targets")
  usethis::use_git_ignore("*.html", "report")
  usethis::use_git_ignore("*.docx", "report")
  usethis::use_git_ignore("*.md", "report")
}

#' Create a description file, including key dependencies to run the workflow
#'
#' TODO: restart rstudio, if available? should we?
#'
#' @param install_deps logical, whether to install dependencies
#'
#' @export
#' @md
use_targets_description <- function(install_deps = TRUE) {

  usethis::use_description(check_name = FALSE)
  desc::desc_set_dep("targets")
  desc::desc_set_dep("tarchetypes")
  desc::desc_set_dep("visNetwork")
  desc::desc_set_dep("bookdown")
  desc::desc_set_dep("conflicted")

  if (isTRUE(install_deps)) {
    remotes::install_deps(upgrade = "never")
  }
}


#' Run a `{targets}` pipeline as a job in RStudio
#'
#' @export
#' @md
tar_make_job <- function () {
  job::job(
    {targets::tar_make()},
    import = NULL,
    packages = NULL,
    title = "{targets} pipeline"
  )
}

#' Visualize `{targets}` dependency graph using custom arguments
#'
#' @export
#' @md
tar_visnetwork_custom <- function () {
  # TODO: read configuration file
  targets::tar_visnetwork(targets_only = TRUE, label = "time")
}
