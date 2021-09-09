plan_bookme <- function() { drake::drake_plan(

  # Bookdown #######
  # Bookdown all .Rmd reports into a single book using the M-K default approach
  final_report = flowme::bookme(
    input_dir = "report",
    input_files = knitr_in(!!fs::path_real(fs::dir_ls(
      "report", regexp = "^report/[^_].*[.]Rmd$"
    ))),
    output_dir = "report-output",
    output_format = "bookdown::gitbook" # to override _output.yml
    #output_format = "bookdown::word_document2"
  )

)}
