# flowme 0.5.3

* fix dependencies in project's DESCRIPTION

# flowme 0.5.2

* fix bug introduced by removing imports.
* tar_duck_r() example calls targets::tar_script() directly, which writes _targets.R into the current working directory — during R CMD check that's the check directory itself, and it was never cleaned up. It's unrelated to the _targets.R template under inst/templates/, which is why you couldn't find it in the repo. Fixed by wrapping the example in targets::tar_dir() — a helper targets ships specifically for this ("Not a user-side function. Just for CRAN.") that runs code in a temp directory and cleans up after.

# flowme 0.5.1

* add `tar_fn()` to the `overrides.R` template: a small convenience for those who like to write
  (part of) the pipeline as plain sequential code inside a function, instead of the usual
  `list()`/plan. It does not call the function; it unfolds its body and evals each statement in
  the caller's environment, one by one. Pairs well with the `tar_target()` override added in
  0.5.0, so running such a function interactively actually executes and assigns each target,
  instead of just returning its (unevaluated) definition.

# flowme 0.5.0

* override `tar_target()` in the generated `.Rprofile`: when running interactively, it evaluates
  the command and assigns it to `name` in `.GlobalEnv`, instead of building a target definition
  (the usual, non-interactive behavior, used e.g. by `tar_make()`). This makes it more convenient
  to write and step through pipelines as normal, sequential code.

* in the `targets` project template, depend on `usethis` instead of `conflicted`, which we no
  longer use (see 0.4.0)

* fix flaky `tar_duck_rmd` tests by ordering query results before comparing them

# flowme 0.4.0

A few changes to reflect our current usage of the flow

* not using {conflicted} anymore. Instead, use the 
  [conflicts.policy option](https://blog.r-project.org/2019/03/19/managing-search-path-conflicts/)
  set to strict and rely on good-old library calls making use of `mask.ok`, `exclude`, 
  `include.only` args to explicitly deal with conflicts.

* keep using load_all for interactive use, and source to make everything available to 
  {targets} (although this will generate warnings when running document or test)

* add by default a .radian_profile file, for our vscode users

# flowme 0.3.1

* Initial version
