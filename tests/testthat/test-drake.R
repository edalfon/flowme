test_that("drakeme works", {
  testthat::expect_error(
    xfun::in_dir(tempdir(TRUE), {
      flowme::drakeme()
      drake::r_make()
    }),
    NA
  )
})
