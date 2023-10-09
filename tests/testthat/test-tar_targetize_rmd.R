targets::tar_test("tar_targetize_rmd() ", {


  # xfun::in_dir(tempdir(), {
  #
  #   targets::tar_script({
  #     library(tarchetypes)
  #     list(
  #       flowme::tar_targetize_rmd(system.file("minimal.Rmd", package = "parsermd"))
  #       #flowme::tar_targetize_rmd("C:/backend/test.Rmd")
  #     )
  #   })
  #   print(targets::tar_visnetwork())
  #
  #   tar_option_set(debug = "pressure")
  #   #targets::tar_meta() |> View()
  #   expect_error(targets::tar_make(callr_function = NULL), NA)
  #   # expect_equal(length(targets::tar_outdated()), expected = 0)
  #
  # })


})
