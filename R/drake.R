
#' Add files and directories for a drake-powered project.
#'
#' Add boilerplate code to the current project for a drake-based project
#' - Copy drake templates to the current project.
#' - Create a description file (usethis::use_description), including key
#'   dependencies to run a drake workflow, installing them by default
#'   (opt-out using install_deps = FALSE).
#' - Include entries in .gitignore to prevent some files into version control
#'
#' @inheritParams use_drake_description
#'
#' @export
#' @md
drakeme <- function(install_deps = TRUE) {

  use_drake_templates()
  use_drake_description(install_deps)
  use_drake_gitignore()
}

#' @rdname drakeme
#' @export
use_drake <- drakeme

#' Create a description file, including key dependencies to run a drake workflow
#'
#' TODO: restart rstudio, if available? should we?
#'
#' @param install_deps logical, whether to install drake and other dependencies
#'
#' @export
#' @md
use_drake_description <- function(install_deps = TRUE) {

  usethis::use_description(check_name = FALSE)
  desc::desc_set_dep("drake")
  desc::desc_set_dep("callr")
  desc::desc_set_dep("visNetwork")
  desc::desc_set_dep("lubridate")
  desc::desc_set_dep("bookdown")

  if (isTRUE(install_deps)) {
    remotes::install_deps(upgrade = "never")
  }
}

#' Copy drake templates to the current project
#'
#' Leverage usethis::use_template to use flowme's drake templates
#' TODO: let the user customize the "report" folder
#' TODO: more convenient overwrite?
#'
#' @export
#' @md
use_drake_templates <- function() {

  usethis::proj_set(".", force = TRUE)

  # drake file ####
  usethis::use_template(
    template = "drake/_drake.R", save_as = "_drake.R",
    ignore = TRUE, open = TRUE, package = "flowme"
  )

  # R files ####
  fs::dir_create("R")
  usethis::use_template(
    template = "drake/R/0_packages.R", save_as = "R/0_packages.R",
    ignore = FALSE, open = TRUE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/R/drakeme.R", save_as = "R/drakeme.R",
    ignore = FALSE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/R/plan_bookme.R", save_as = "R/plan_bookme.R",
    ignore = FALSE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/R/plan_sessioninfo.R", save_as = "R/plan_sessioninfo.R",
    ignore = FALSE, open = FALSE, package = "flowme"
  )

  # report files ####
  usethis::use_directory("report", ignore = TRUE)
  usethis::use_template(
    template = "drake/report/_bookdown.yml", save_as = "report/_bookdown.yml",
    ignore = TRUE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/report/_output.yml", save_as = "report/_output.yml",
    ignore = TRUE, open = FALSE, package = "flowme"
  )

  # Done differently because usethis::use_template does not handle well weird
  # characters in .docx files (presumably, trying to put data in the template)
  file.copy(
    from = fs::path_package("flowme", "templates/drake/report/_style.docx"),
    to = "report/_style.docx"
  )

  usethis::use_template(
    template = "drake/report/chapter1.Rmd", save_as = "report/chapter1.Rmd",
    ignore = TRUE, open = TRUE, package = "flowme"
  )
}

#' Add entries to .gitignore, to ignore non-version-control-friendly files
#' in this drake-based workflow
#'
#' @export
#' @md
use_drake_gitignore <- function() {

  usethis::use_git_ignore(".drake")
  usethis::use_git_ignore(".drake_history")
  usethis::use_git_ignore("report/*.html")
  usethis::use_git_ignore("report/report-output/")
  usethis::use_git_ignore("report/_bookdown_files/")
}
