#' Target factory to run SQL code on a DuckDB database backend, keeping one
#' DuckDB file per target
#'
#' Creates a target that keeps a `DBI` connection to a DuckDB database, creating
#' one DuckDB file per target. With `tar_duck_r()` the user writes R code
#' and can interact with DuckDB's database directly via `DBI` (e.g.
#' `dbGetQuery`, `dbExecute`) or `dbplyr`-backed operations (so either write SQL
#' as strings or let `dbplyr` write the SQL for you). With `tar_duck_rmd()` the
#' user writes the code in a Rmd Notebook, basically to take advantage of sql
#' chunks to write pure SQL.
#' **Watch out:** this target factory does very unorthodox things! It does not
#' have much guardrails, it can be fragile and could probably break in
#' unexpected ways. We do ugly things here. There are side-effects all over the
#' place. It is still experimental and tailored to very specific use cases. See
#' details for a description of what it does, how it does it and why we decided
#' to do it that way. So, use it only if you can stomach all that -or if you are
#' part of the team and kind of have to ;)-
#'
#' This target factory aims to support the following workflow / use case:
#'
#' - Write SQL code in a Rmd file
#' - Render the Rmd file, running the SQL code on a DuckDB database
#' - Each Rmd file run against a single DuckDB file (persistent DB)
#'   So typically each Rmd file creates one table in the DB, as part of some
#'   data wrangling
#'
#' Let's keep here a list of the idiosyncrasies of this target factory:
#'
#' - This is perhaps the most controversial: We are keeping the DBI connection
#'   in the global environment. There might be a better way and we would need to
#'   take a closer look at {targets}'s environment management to find it. But
#'   for now, this is working as we intended and you just have to be aware of
#'   this, and of course, make sure you do not create conflicts by creating in
#'   your code variables with the same name as the one given to the connection
#'   (conn_name)
#' - To keep it as flexible as possible, we do not want to use {targets} storage
#'   for the DuckDB files. Instead, we decided to keep the files somewhere else
#'   (duh, in the duckdb folder, or wherever you want, since you can simply pass
#'   the full path to the target factory). In the {targets} storage we will keep
#'   only some metadata to re-create the DBI connection.
#' - So, what about the DBI connection? Well, connections are one of those
#'   non-exportable objects that are tied to a given R session and cannot be
#'   easily saved and simply read on another session. So that cannot be the
#'   return value of the target. Typical workarounds for that in {targets}
#'   include the use of custom functions to create and close the connection
#'   after the job is done, and the use of hooks with similar purpose.
#'   (https://books.ropensci.org/targets/targets.html#return-value).
#'   `tar_duck_*` will create the DBI connection and close the connection behind
#'   the scenes and make it available in the target's command environment, so
#'   that the user's code can use it, just refering the object with the name
#'   passed to `tar_duck_*` via `conn_name` argument.
#' - So what does it mean to read/load a target that has already been built?
#'   In other words, what is the return object of a `tar_duck_*` target?
#'   We use a custom format, in which the read method does the heavy lifting.
#'   Write method is simply a writeRDS, just like in any tar_target. But the
#'   read method makes sure a DBI connection pointing to the duckdb file is
#'   available. So the users should access the data they are interested in via
#'   the DBI connection. Yet, the most common use case we have is one table per
#'   target. Thus, if in the database of the target exists a table matching
#'   the target's name, we also return a dplyr/dbplyr handle to the table.
#' - But what about dependencies?, if you keep the data from each target in
#'   separate duckdb files, how can I write a new target that uses data from
#'   one or more upstream targets? Here `tar_duck_*` makes use of the ATTACH
#'   functionality from duckdb. It makes sure to attach all duckdb files that
#'   the current target depends on, to the current connection.
#' - We are currently hashing the duckdb file when the target's command
#'   finishes, and keep that data in the target's storage. We do this to make
#'   sure changes will propagate downstream and potentially could be used to
#'   detect changes in the data, made outside from the pipeline. Check TODOs.
#' - to keep the target's scripts as concise as possible, for tar_duck_rmd,
#'   we will use the filename of the Rmd as the name of the target (it's just a
#'   default, you can override that by giving it explicitly other name)
#'
#' Why this?
#' Transitioning from a Postgres-backed data pipeline to use DuckDB, we hit a
#' couple of issues issue with the size of the file:
#' i) connecting/disconnecting to large files can be slow (EDIT: there have been
#'    improvements recently and now DuckDB has "Lazy-loading of storage metadata
#'    for faster startup times") and
#' ii) the files can get pretty big real quick,
#'     which can cause storage issues (how big?, currently, one pipeline hit
#'     almost 2TB).
#' To deal with this, we want to experiment with the also recently introduced
#' feature of DuckDB: ATTACH, which basically let's you connect to another
#' DuckDB database, that can be read from and written to, from within the
#' currently running DB/connection. So, the plan is to try and keep one table
#' per duckdb file, which should limit the individual file size to a typical
#' table size (i.e. around 25GB), thereby helping to solve or cirmcunvent the
#' issues above. So, instad of haven a monolitic DuckDB file with all the data,
#' we would have one file per table, and we can ATTACH other tables as needed
#' on-the-fly. Now, this can be cumbersome, because you need to handle each
#' connection and manually attach each DB you need, and then manually edit
#' DuckDB's search path to emulate one single database (or you would have to use
#' fully qualified names to refer to the tables, becasue ATTACH puts each file
#' in its own catalog). And here's where {targets} can be handy, because it is
#' super smart in handling dependencies and loading them on the fly. So the idea
#' is to leverage that power in a bunch of targets that handle the DBI
#' connection to each duckdb file, opening it and attaching dependencies on the
#' fly. Let's see how it goes ...
#'
#' @param target_name target name, ala name in `targets::tar_target`.
#' @param command R code to run the target, just like targets::tar_target, but
#' this code can (and should) take advantage of the connection to a DuckDB
#' database whose name is given by `conn_name`.
#' @param duckdb_path path of the duckdb file. The default is to use the target
#' name as filename (without extension) and save it in a duckdb folder in the
#' current directory. It can be set to any relative or absolute path.
#' @param conn_name name to give to the DBI connection to the DuckDB db.
#'
#' @return a custom target
#' @export
#' @md
#'
#' @examples
#'   targets::tar_script({
#'
#'     suppressMessages(library(dplyr))
#'
#'     list(
#'       # a couple of targets to ingest the data
#'       # (note the use of the DBI connection, named `db`)
#'       flowme::tar_duck_r(band_members_duck, {
#'         dplyr::copy_to(db, dplyr::band_members, name = "band_members_duck",
#'                        overwrite = TRUE, temporary = FALSE)
#'       }),
#'
#'       flowme::tar_duck_r(band_instruments_duck, {
#'         dplyr::copy_to(db, dplyr::band_instruments, name = "band_instruments_duck",
#'                        overwrite = TRUE, temporary = FALSE)
#'       }),
#'
#'       # a "normal" target that depends on both upstream targets
#'       # band_members_duck and band_instruments_duck. `tar_duck_r`'S
#'       # custom load mechanism makes sure you get a valid
#'       # dplyr/dbplyr handle to the table, stored in a DuckDB database.
#'       # None of the data have been fed into R, but everything operated
#'       # seamlessly on DuckDB. But since this is a normal target, to
#'       # save the results you need to collect and return them.
#'       # Notice here that although band_members_duck and
#'       # band_instruments_duck are stored in a separated DuckDB databases,
#'       # you can operate seamlessly on both of them simultaneously.
#'       tar_target(join_to_targets, {
#'         band_members_duck |>
#'           left_join(band_instruments_duck) |>
#'           collect() |> # to collect the data from DuckDB into R
#'           arrange(name)
#'       }),
#'
#'       # Now, if you want to keep operating on DuckDB (e.g. because the
#'       # output will also be larger than memory), you would keep using
#'       # `tar_duck_r`. So, similar as the above, but now it's again a
#'       # `tar_duck_r` target and the result of the join should be saved
#'       # in a duckdb file
#'       flowme::tar_duck_r(join_to_duck, {
#'         foo <- band_members_duck |>
#'           left_join(band_instruments_duck) |>
#'           collect() |>
#'           arrange(name)
#'         dplyr::copy_to(db, foo, name = "join_to_duck",
#'                        overwrite = TRUE, temporary = FALSE)
#'       }),
#'
#'       NULL
#'     )
#'   })
#'   targets::tar_visnetwork()
#'   # After running tar_make() you will find a duckdb file for each of
#'   # the `tar_duck_r` targets above. Go check that.
#'   # See the testthat files for examples of `tar_duck_rmd`
tar_duck_r <- function(target_name,
                       command = NULL,
                       duckdb_path = paste0(
                         "./duckdb/",
                         targets::tar_deparse_language(substitute(target_name))
                       ),
                       conn_name = "db") {

  target_name <- targets::tar_deparse_language(substitute(target_name))

  duck_target <- targets::tar_target_raw(
    name = target_name,
    command = base::substitute(
      expr = {

        # given that {targets} loads the upstream targets beforehand, a
        # connection may be there already. So, create a new one only if there is
        # no connection, or it is invalid, if the connection exists and it is
        # valid, we want rather to attach the database
        conn_obj <- base::get0(conn_name, envir = .GlobalEnv)
        if (is.null(conn_obj) || !DBI::dbIsValid(conn_obj)) {
          tictoc::tic("Connecting to DuckDB")
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

        eval(command)

        # We want to hash the duckdb file, to make sure changes here
        # propagate to downstream targets. Otherwise, in case a tar_duck_*
        # need to be re-built, but the duckdb_path, target_name and conn_name do
        # not change, {targets} would think
        # TODO: two improvements to make:
        #       1. make it part of the target's update/outdate rules, so that
        #          changes to the db made outside of the pipeline are catched
        #       2. find someway faster to do it. Hashing can be slow (that's
        #          why we currently are not doing the 1. above), an although
        #          it's not that critical now (e.g. rlang::hash_file takes
        #          about 5 seconds to hash our typical 25GB duckdb file), if we
        #          keep down this road, it may be a good idea to find a faster
        #          way to do it.
        tictoc::tic("Disconnecting DuckDB")
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
        target_name = target_name,
        command = base::substitute(command),
        duckdb_path = duckdb_path,
        conn_name = conn_name
      )
    ),
    format = duck_tar_format,
    memory = "transient" # this is important here, because the default
                         # ("persistent") keeps the target in memory until the
                         # end of the pipeline. This means it will not load it
                         # again for downstream targets once it is loaded or
                         # built. That does not work in our case, because our
                         # target is attached to a connection that could
                         # (and will) be closed or invalidated. That's why we
                         # need to use "transient", with which:
                         # > the target gets unloaded after every new target
                         # > completes. Either way, the target gets
                         # > automatically loaded into memory whenever another
                         # > target needs the value.
                         # This is exactly what we need, so that every time a
                         # tar_duck_* is needed, it will be loaded, which in
                         # our case means either a new connection to the db is
                         # created, or the db will be attached to the currently
                         # valid connection
  )

  duck_target
}



#' A custom format. The write function is standard, as we only want to store
#' in the target the info that allows us to create the connection. The read
#' function would do the heavy-lifting.
#' @export
duck_tar_format <- targets::tar_format(
  read = function(path) {

    duckdb_target_object <- readRDS(path)
    duckdb_path <- duckdb_target_object$duckdb_path
    target_name <- duckdb_target_object$target_name
    duckdb_hash <- duckdb_target_object$duckdb_hash
    conn_name <- duckdb_target_object$conn_name

    # What do we want to achieve when we load/read a target?
    # We want to make the target's data available to the calling environment.
    # Calling environment could be:
    # i) a downstream target that needs to use the data, or,
    # ii) the global environment, when the user loads the target interactively
    #     using tar_read/tar_load
    #
    # Now, tar_duck_* are ultimately a DuckDB file (stored at duckdb_path). So,
    # making that available to the calling environment means either to create a
    # connection to the file, or to attach the file to the currently available
    # connection. Thus, we want to check if there is already a valid connection
    # to attach the target's duckdb file to, and if there is no valid
    # connection, just create a new one.

    # TODO: well, here's a bummer. this function cannot access the environment
    # in which the downstream target is running, because {targets} loads the
    # dependencies before start building the downstream target and not within it
    # (I think, not 100% sure about it). So, hack it (mit f) and use the global
    # environment. It's ugly and bad practice, but I think it works. And to be
    # honest, it does not bother me that much. But anyway, keep it as a to-do to
    # better investigate how environments work in {targets} and find a cleaner
    # approach.

    conn_obj <- base::get0(conn_name, envir = .GlobalEnv)
    if (is.null(conn_obj) || !DBI::dbIsValid(conn_obj)) {
      conn_obj <- base::assign(
        x = conn_name,
        value = DBI::dbConnect(duckdb::duckdb(":memory:", FALSE)),
        envir = .GlobalEnv,
        inherits = TRUE # recycle
      )
      # Whenever you open a connection, you usually should prepare to close it
      # (e.g. via on.exit() or whatever). Yet, here we DO NOT WANT TO CLOSE IT
      # because, on.exit(), would close it when it finished loading the target
      # (i.e. when it finishes executing this read fn from the custom format)
      # and therefore, the connection would not be available for the downstream
      # targets, which is precisely what we want to achieve. So let's keep this
      # note here just as a reminder
      # on.exit({
      #   tictoc::tic("DISCONNECTING DuckDB")
      #   DBI::dbDisconnect(conn_obj, shutdown = TRUE)
      #   tictoc::toc()
      # })

      #DBI::dbExecute(conn_obj, "SET search_path = 'memory';")
    }

    # At this point we have ensured there is a valid connection (conn_obj) to
    # DuckDB. This can either be a connection to an in-memory database created
    # here by this read fn, or an already available connection. In either case
    # we want to attach the loading target's duckdb file (duckdb_path) to the
    # connection. And we do this in read_only mode, because if we are
    # loading/reading the target, it is already built and we do not want to
    # modify it (i.e. do not write to that duckdb file. That should only happen
    # when you are building the target, so, only in the tar_duck_* command)
    flowme::attach_db(conn_obj, duckdb_path, read_only = TRUE)
    #flowme::update_search_path(conn_obj, append = target_name)

    # the most common use case, is to have a target that creates a table in the
    # database using the target name. So let's just check if a table with that
    # name exists and return a dplyr handle to it. If that's not the case just
    # return null, and anyway the side effect we were looking for is already in
    # place (a connection with the db attache to it)
    if (DBI::dbExistsTable(conn_obj, target_name)) {
      dplyr::tbl(conn_obj, target_name)
    } else {
      NULL
    }
  },
  write = function(object, path) {
    saveRDS(object, path)
  },
  marshal = function(object) {
    identity(object)
  },
  unmarshal = function(object) {
    identity(object)
  },
  convert = function(object) {
    identity(object)
  }
)

#' Query  DuckDB's `search_path`
#'
#' @param conn_obj DBI connection to DuckDB
#'
#' @export
get_search_path <- function(conn_obj) {
  DBI::dbGetQuery(conn_obj, "SELECT current_setting('search_path') AS sp;")$sp
}

#' Set DuckDB's `search_path`
#'
#' @param conn_obj DBI connection to DuckDB
#' @param new_search_path character with the new search path (comma-separated
#' list of catalogs)
#'
#' @export
set_search_path <- function(conn_obj, new_search_path) {
  DBI::dbExecute(conn_obj, paste0("SET search_path = '", new_search_path, "';"))
}

#' Update DuckDB's `search_path` by prepending and/or appending values
#'
#' @param conn_obj DBI connection to DuckDB
#' @param prepend character with value to prepend
#' @param append character with value to append
#'
#' @export
update_search_path <- function(conn_obj, prepend = NULL, append = NULL) {

  current_search_path <- get_search_path(conn_obj)
  if (current_search_path == "") current_search_path <- NULL

  new_search_path <- paste(c(prepend, current_search_path, append),
                           collapse = ",") # Collapse will ignore NULLs

  set_search_path(conn_obj, new_search_path)
}

#' Attach a database to the currently running DuckDB and update the search_path
#' to make the objects in the new database available without using fully
#' qualified names
#'
#' @param conn_obj DBI connection to DuckDB
#' @param duckdb_path path to the DuckDB file to attach
#' @param duckdb_alias alias to use fir the newly attached database
#' @param read_only whether it should be attached in read only mode
#'
#' @export
attach_db <- function(conn_obj, duckdb_path, duckdb_alias = duckdb_path |>
                        fs::path_file() |>
                        fs::path_ext_remove() |>
                        make.names(), read_only = TRUE) {

  already_attached <- DBI::dbGetQuery(conn_obj, "SHOW databases;")$database_name
  read_only_str <- ""
  if (isTRUE(read_only)) read_only_str <- " (READ_ONLY)"

  if (!(duckdb_alias %in% already_attached)) {
    DBI::dbExecute(
      conn_obj,
      paste0("ATTACH '", duckdb_path, "' AS ", duckdb_alias, read_only_str, ";")
    )
  }

  # when you attach a db, DuckDB will put it under a catalog
  # corresponding to the file name or alias you provide, and not in the default
  # catalog. Therefore, yo would need to use fully qualified names to refer to
  # tables and other objects in the db being attached. To avoid so much typing,
  # you can edit the `search_path` config and include in there the catalog of
  # the recently attached db. But watch out, do not simply replace the
  # search_path with the new catalog, because then you would need fully
  # qualified names to access objects in the current database. Thus, you need to
  # append to it and therefore, we need to first query the current search_path,
  # because we do not know which database is currently running. And then append
  # to it, the database being attached.

  # if it is read_only, append, if not, prepend
  if (isTRUE(read_only)) {
    flowme::update_search_path(conn_obj, append = duckdb_alias)
  } else {
    flowme::update_search_path(conn_obj, prepend = duckdb_alias)
  }
}


