#' a few wrappers of some drake functions

#' r_make, with a couple of tweaks
#'
#' This runs drake::r_make() with two convenience features:
#' - Starts calling rstudioapi::documentSaveAll() to make sure all changes are saved
#' - Shows the total running time, when r_make finishes
#' @return
#' @export
r_make <- function() {
  print("Running custom drake::r_drake()")
  rstudioapi::documentSaveAll()
  tictoc::tic("Total running time for r_make()")
  drake::r_make()
  tictoc::toc()
}


#' Visualize plan graph, excluding external functions
#'
#' @return
#' @export
vizme <- function() {

  rstudioapi::documentSaveAll()
  update_time <- Sys.time()
  output_file <- paste0("./.drake/drake_plan_", as.numeric(update_time),".html")
  plan_info <- r_drake_graph_info(hover = TRUE)

  plan_info$nodes <- plan_info$nodes %>%
   filter(!grepl("::", label)) %>%
   filter(!grepl("base::", label))

  drake::render_drake_graph(
   graph_info = plan_info,
   #file = output_file,
   selfcontained = TRUE,
   main = paste0(plan_info$default_title, " last updated ", update_time)
  )
  #base::shell(output_file, wait = FALSE)
}

#' Visualize plan graph, showing targets only
#'
#' targets_only = TRUE
#'
#' @param targets_only
#'
#' @return
#' @export
#'
#' @examples
vizme2 <- function() {

  rstudioapi::documentSaveAll()
  update_time <- Sys.time()
  output_file <- paste0("./.drake/drake_plan", as.numeric(update_time),".html")
  plan_info <- r_drake_graph_info(hover = TRUE, targets_only = TRUE)

  drake::render_drake_graph(
    graph_info = plan_info,
    #file = output_file,
    selfcontained = TRUE,
    main = paste0(plan_info$default_title, " last updated ", update_time)
  )
  #base::shell(output_file, wait = FALSE)
}

# Controversial trick: override loadd to always avoid replacing items in the env
loadd <- purrr::partial(drake::loadd, replace = FALSE)
