
#' Use drake boilerplate
#'
#' Create files and directories for a drake-powered project
#'
#' @export
#' @md
drakeme <- function() {

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
    template = "drake/R/bookme.R", save_as = "R/bookme.R",
    ignore = FALSE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/R/drakeme.R", save_as = "R/drakeme.R",
    ignore = FALSE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/R/plan_bookme.R", save_as = "R/plan_bookme.R",
    ignore = FALSE, open = FALSE, package = "flowme"
  )

  # report files ####
  fs::dir_create("report")
  usethis::use_template(
    template = "drake/report/_bookdown.yml", save_as = "report/_bookdown.yml",
    ignore = TRUE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/report/_output.yml", save_as = "report/_output.yml",
    ignore = TRUE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/report/_style.docx", save_as = "report/_style.docx",
    ignore = TRUE, open = FALSE, package = "flowme"
  )
  usethis::use_template(
    template = "drake/report/chapter1.Rmd", save_as = "report/chapter1.Rmd",
    ignore = TRUE, open = TRUE, package = "flowme"
  )

  # description file ####
  usethis::use_description(check_name = FALSE)
  # if (requireNamespace("projthis", quietly = TRUE)) {
  #   projthis::proj_update_deps()
  # }
}
