list(

  tar_target(toy_data, mtcars),
  tar_target(fake_data, data.frame(x = runif(100))),

  flowme::tar_bookdown("report")
)
