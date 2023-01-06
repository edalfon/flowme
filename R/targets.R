#' Add files and directories for a targets-powered project.
#'
#' Add boilerplate code to the current project for a targets-based project
#' - Copy templates to the current project.
#' - Include entries in .gitignore to prevent some files into version control
#'
#' @inheritParams use_targets_description
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
  usethis::use_template(
    template = "targets/tar_visnetwork.yml", save_as = "tar_visnetwork.yml",
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

  rstudioapi::documentSaveAll()

  if (file.exists("pre_tar_make.R")) source("pre_tar_make.R")

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
  rstudioapi::documentSaveAll()

  if (file.exists("tar_visnetwork.yml")) {
    custom_params <- yaml::read_yaml("tar_visnetwork.yml")
    if (is.null(custom_params)) custom_params <- list()
  } else {
    custom_params <- list(targets_only = TRUE, label = "time")
  }

  custom_visnetwork <- do.call(targets::tar_visnetwork, custom_params)

  # TODO: let also customize options below and find a not-so-hacky way
  #       currently doing it like this, because calling visNetwork fns
  #       would override all options and legend configuration, forcing me
  #       to recreate them all
  # visNetwork::visOptions(nodesIdSelection = TRUE)
  # visNetwork::visLegend(width = 0.1) would override all legend config
  custom_visnetwork$x$idselection$enabled <- TRUE
  custom_visnetwork$x$legend$width <- 0.1

  custom_visnetwork
}

