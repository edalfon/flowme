
# Load all your R files, which includes 0_packages.R to attach needed packages
# (note leading 0, to get it sourced first. Handy in using devtools::load_all())
lapply(list.files("./R", full.names = TRUE), source, encoding = "UTF-8")

# Your R files should have one or more drake plans. Bind them into the_plan
the_plan <- drake::bind_plans(

  # Add your plans here. A couple of notes about this:
  #
  # - Note the use of drake::bind_plans() to create "the_plan".
  #   This is to keep things modular and avoid defining a huge plan in a single
  #   file. So, unless it is a trivial project, we should not define the actual
  #   plan here. Instead, let's break down the analysis in conceptually relevant
  #   modules (typically a chapter of the final report) and define the plan for
  #   each of them in a separate file.
  #
  # - Plans should be defined in .R files in the R folder. That way they are
  #   loaded/sourced at the beginning (first line in this file) and will be
  #   available here. This is also helpful because the plans will also be
  #   loaded by devtools::load_all().
  #
  # - Plans should not be defined directly into an object using
  #   drake::drake_plan(). Instead, we should define the plans within functions
  #   that return the plan. This is just a convenience  thing that helps
  #   navigation (cursor in the call to the function that defines the plan and
  #   hit F2 would take you to the definition. If the plans are directly defined
  #   as objects that would not work. F2 would open a Viewer on plan data.frame).
  #   The downside of doing this, is either an additional indentation level in
  #   the plan, or somewhat heretical code formatting (as suggested in the
  #   example plans below).

  plan_sessioninfo(), # sample plan to save session info

  plan_bookme() # render Rmd files in the report folder with bookdown
)

# Here just follow dflow, by default changing only format to qs and history=F
## _drake.R must end with a call to drake_config().
## The arguments to drake_config() are basically the same as those to make().
## lock_envir allows functions that alter the random seed to be used. The biggest
## culprits of this seem to be interactive graphics e.g. plotly and mapdeck.
drake_config(the_plan, lock_envir = FALSE, format = "qs", history = FALSE)
