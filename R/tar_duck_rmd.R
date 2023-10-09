#' @describeIn tar_duck_r write the sql code in a Rmd Notebook
#' @param sql_rmd path to the Rmd file
#' @export
tar_duck_rmd <- function(sql_rmd,
                         duckdb_path = paste0("./duckdb/", target_name),
                         target_name = sql_rmd |>
                           fs::path_file() |>
                           fs::path_ext_remove() |>
                           make.names(),
                         conn_name = "db") {

  # We want to induce a dependency on the Rmd file. But we will use a custom
  # format for this target, so we cannot simply set it to format = 'file'. We
  # could create a separate tar_file just to track changes in the Rmd and keep
  # the execution in other target that depends on the file (ala
  # tarchetypes::tar_file_read). But we do not really want to do that. Our data
  # pipelines are already long and complex enough, and having two targets in
  # each step (one for the file and other for the actual work) would be just too
  # much. So we use this trick to induce the dependency, by reading the content
  # of the files into a variable (sql_rmd_txt) and making it part of the command
  # of the target, so that everytime it's checked by {targets}, it would be
  # marked as outdated if the contents of the file have changed.
  # TODO: find the way to ignore modifications that do not lead to changes in
  #       the processing (e.g. only changes in the markdown, but not any r or
  #       sql chunks.). That's actually kind of trivial, but what would be nice
  #       at some point, is to be able to render the Rmd again without running
  #       the code (ideas: leverage targets again?, or knitr caching mechanism?)
  sql_rmd_txt <- base::readLines(sql_rmd, warn = FALSE)

  # To circumvent recent ban on using tar_read / tar_load let's just include a
  # chunk dedicated to load targets (before we used tar_read / tar_load within
  # the Rmd) where you can just reference the targets and they will become part
  # of the command of the target, inducing the dependencies via standard targets
  # detection mechanism and effectively loading them (which triggers the custom
  # read method of the custom format)
  sql_rmd_ast <- parsermd::parse_rmd(sql_rmd_txt)
  tar_loads <-
    parsermd::rmd_select(sql_rmd_ast, parsermd::has_label("load-targets")) |>
    purrr::map(~.x$code) |>
    purrr::list_c() |>
    stringr::str_trim() |>
    # TODO: handle here edge cases, like commented lines and others
    #      (both, whole line commented, or comment at the end of the line)
    #      here's a way to do it, but very basic perhaps
    stringr::str_extract("^[^#]+") |> # extract everything before the first #
    (\(x) x[x != ""])() |>
    paste0(collapse = ", ") |>
    paste0("list(", x = _, ")") # pipe placeholder can only be used with named arg

  duck_target <- targets::tar_target_raw(
    name = target_name,
    command = base::substitute(
      expr = {

        induce_upstream_tar_loads <- tar_loads
        induce_rmd_dependency <- sql_rmd_txt

        # given that {targets} loads the upstream targets beforehand, a
        # connection may be there already. So, create a new one only if there is
        # no connection, or it is invalid, if the connection exists and it is
        # valid, we want rather to attach the database
        conn_obj <- base::get0(conn_name, envir = .GlobalEnv)
        if (is.null(conn_obj) || !DBI::dbIsValid(conn_obj)) {
          tictoc::tic("CONNECTING DuckDB")
          fs::dir_create(fs::path_dir(duckdb_path))
          conn_obj <- base::assign(
            x = conn_name,
            value = DBI::dbConnect(duckdb::duckdb(duckdb_path, FALSE)),
            envir = .GlobalEnv
          )
          tictoc::toc()
        } else {
          # here we do want to write to this database, so attach write-mode
          flowme::attach_db(conn_obj, duckdb_path, read_only = FALSE)
        }

        # I wanted to do this. I thought it was cleaner. But anyway we keep
        # getting the warning saying the connection was recycled. Not sure why.
        # And meanwhile, to be able to get the hash of the duckdb file after
        # rendering the rmd, we need to close it. So let's just remove this
        # from here
        # on.exit({
        #   tictoc::tic("DISCONNECTING DuckDB")
        #   DBI::dbDisconnect(conn_obj, shutdown = TRUE)
        #   tictoc::toc()
        # })

        # need to set the knit_root_dir to the current working directory
        # (i.e. the directory in which targets is running), otherwise,
        # it will knit using the default, which is the folder in which the
        # rmd file lives, messing everything up (e.g. duckdb will run on
        # that directory as well, and will not be able to find other databases
        # because the path is relative to the main project diretory)
        rmarkdown::render(sql_rmd, knit_root_dir = getwd())

        tictoc::tic("DISCONNECTING DuckDB within the target's command")
        DBI::dbDisconnect(conn_obj, shutdown = TRUE)
        tictoc::toc()
        tictoc::tic("Hashing DuckDB's file")
        duckdb_hash <- rlang::hash_file(duckdb_path)
        tictoc::toc()

        list(
          duckdb_path = duckdb_path,
          target_name = target_name,
          duckdb_hash = duckdb_hash,
          conn_name = conn_name
        )
      },
      env = list(
        sql_rmd = sql_rmd,
        target_name = target_name,
        duckdb_path = duckdb_path,
        conn_name = conn_name,
        sql_rmd_txt = sql_rmd_txt,
        tar_loads = base::str2lang(tar_loads)
      )
    ),
    format = duck_tar_format,
    memory = "transient"
  )

  duck_target
}
