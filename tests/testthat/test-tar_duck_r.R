
targets::tar_test("tar_duck_r works", {

  targets::tar_script({

    library(dplyr)

    list(

      # should just create a duckdb file and that file should have a table
      # named band_members_duck. Below it will be tested that after running the
      # pipeline, this holds
      flowme::tar_duck_r(band_members_duck, {
        dplyr::copy_to(db, dplyr::band_members, name = "band_members_duck",
                       overwrite = TRUE, temporary = FALSE)
      }),

      # should just create a duckdb file and that file should have a table
      # named band_instruments_duck. Below it will be tested that after running the
      # pipeline, this holds
      flowme::tar_duck_r(band_instruments_duck, {
        dplyr::copy_to(db, dplyr::band_instruments, name = "band_instruments_duck",
                       overwrite = TRUE, temporary = FALSE)
      }),

      # a target that should depend on both upstream targets band_members_duck
      # and band_instruments_duck. Below it will be tested that the dependencies
      # exist and that after running tar_make, the join was performed and the
      # result stored in the target
      tar_target(join_to_targets, {
        band_members_duck |>
          left_join(band_instruments_duck) |>
          collect() |>
          arrange(name)
      }),

      # similar as the above, but now it's again a tar_duck_r target and
      # the result of the join should be saved in a duckdb file
      flowme::tar_duck_r(join_to_duck, {
        foo <- band_members_duck |>
          left_join(band_instruments_duck) |>
          collect() |>
          arrange(name)
        dplyr::copy_to(db, foo, name = "join_to_duck",
                       overwrite = TRUE, temporary = FALSE)
      }),

      NULL
    )
  })

  # we want to test that the dependencies are correctly induced, so we compare
  # the dependencies of the pipeline above generated by targets and those
  # that should exist
  #print(targets::tar_visnetwork())
  testthat::expect_setequal(
    object = targets::tar_network()$edges |>
      dplyr::mutate(fromto = paste0(from, "->", to)) |>
      dplyr::pull(fromto),
    expected = c(
      "band_instruments_duck->join_to_targets",
      "band_members_duck->join_to_targets",
      "band_instruments_duck->join_to_duck",
      "band_members_duck->join_to_duck"
    )
  )

  testthat::expect_no_error(targets::tar_make())

  # after running tar_make, there should be files created in the duckdb dir
  testthat::expect_true(file.exists("./duckdb/band_members_duck"))
  testthat::expect_true(file.exists("./duckdb/band_instruments_duck"))
  testthat::expect_true(file.exists("./duckdb/join_to_duck"))

  # and the contents of the files, should be a table that match the one copied
  duck_file <- "./duckdb/band_members_duck"
  duck_con <- DBI::dbConnect(duckdb::duckdb(duck_file, read_only = TRUE))
  duck_data <- DBI::dbGetQuery(duck_con, "SELECT * FROM band_members_duck;")
  DBI::dbDisconnect(duck_con, shutdown = TRUE)
  testthat::expect_equal(duck_data, dplyr::band_members |> as.data.frame())
  # TODO: maybe sort?, because sql does not guarantee order

  duck_file <- "./duckdb/band_instruments_duck"
  duck_con <- DBI::dbConnect(duckdb::duckdb(duck_file, read_only = TRUE))
  duck_data <- DBI::dbGetQuery(duck_con, "SELECT * FROM band_instruments_duck;")
  DBI::dbDisconnect(duck_con, shutdown = TRUE)
  testthat::expect_equal(duck_data, dplyr::band_instruments |> as.data.frame())
  # TODO: maybe sort?, because sql does not guarantee order

  duck_file <- "./duckdb/join_to_duck"
  duck_con <- DBI::dbConnect(duckdb::duckdb(duck_file, read_only = TRUE))
  duck_data <- DBI::dbGetQuery(duck_con, "SELECT * FROM join_to_duck;")
  DBI::dbDisconnect(duck_con, shutdown = TRUE)
  testthat::expect_equal(
    duck_data,
    dplyr::band_members |>
      dplyr::left_join(dplyr::band_instruments) |>
      dplyr::arrange(name) |>
      as.data.frame()
  )

  # tar_duck_* has a functionality to automatically return a dplyr handle
  # to a table in the database, if the name of the target exists as a table
  # in the database. Let's test that it works
  duck_data <- targets::tar_read(band_members_duck) |> dplyr::collect()
  DBI::dbDisconnect(db, shutdown = TRUE) # tar_read should have created this con
  testthat::expect_equal(duck_data, dplyr::band_members)

  duck_data <- targets::tar_read(band_instruments_duck) |> dplyr::collect()
  DBI::dbDisconnect(db, shutdown = TRUE) # tar_read should have created this con
  testthat::expect_equal(duck_data, dplyr::band_instruments)

  duck_data <- targets::tar_read(join_to_duck) |> dplyr::collect()
  DBI::dbDisconnect(db, shutdown = TRUE) # tar_read should have created this con
  testthat::expect_equal(
    duck_data,
    dplyr::band_members |>
      dplyr::left_join(dplyr::band_instruments) |>
      dplyr::arrange(name)
  )

  # finally, also check that the normal targets object (join_to_targets) works
  testthat::expect_equal(
    targets::tar_read(join_to_targets),
    duck_data
  )


  # tar_option_set(debug = "pressure")
  # # targets::tar_meta() |> View()
  # # expect_equal(length(targets::tar_outdated()), expected = 0)
})


# foo <- function(x) {
#   deparse(substitute(x)) |> class() |> print()
# }
#
# foo(sdf)

