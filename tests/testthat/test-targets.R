test_that("use_targets works", {
  testthat::expect_error(
    xfun::in_dir(tempdir(TRUE), {
      flowme::use_targets()
      targets::tar_make()
    }),
    NA
  )
})

