#' Plan to store session info in a target that can be used in the report
#' as reproducibility information.
#'
#' But this is mostly an example plan that you can get rid off
#' You can always call drake::drake_get_session_info() to get the session info
#' of the last r_make run. And this sample plan adds little value to that.
#' Perhaps only:
#' - If you include it in the report it is, sort of, self-contained and you do
#'   not need to rely on the .drake cache
#' - It adds sessioninfo::session_info() that includes info of the source of the
#'   package (CRAN, github, etc.) and the actual lines of code that setup the
#'   environment (0_packages.R)
#'
#' @return drake::drake_plan
#' @md
plan_sessioninfo <- function() { drake::drake_plan(

  sessioninfo = drake::target(
    command = list(
      sessionInfo(), # standard session info
      sessioninfo::session_info(), # session info including source of packages
      readLines(file_in("R/0_packages.R"))
    )
  )

)}
