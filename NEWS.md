# flowme 0.7.0

* `targetsme()`/`use_targets()` gain a new `renv` argument (default `FALSE`).
  When `TRUE`, calls `renv::init(settings = list(snapshot.type = "explicit"))`
  as the last step, so the scaffolded project starts under `renv`, snapshotting
  only the packages declared in its DESCRIPTION rather than scanning project
  code for dependencies. `renv` lives in Suggests and is only required when
  `renv = TRUE` is actually used.

# flowme 0.6.1

* fix `duck_tar_format()`'s read method: two of the optional-dependency
  checks added in 0.6.0 (`DBI`/`duckdb` and `dplyr`/`dbplyr`) were called
  unqualified. `targets::tar_format()` deparses `read`/`write` to text and
  later reconstructs them outside `flowme`'s namespace, so the bare calls
  failed with `could not find function "check_pkgs_installed"` once the
  package was actually installed (masked under `devtools::load_all()`,
  which exports internals onto the search path). Fixed by qualifying them
  as `flowme:::check_pkgs_installed()`, matching every other reference in
  that closure.

# flowme 0.6.0

Substantially lighter default install: most feature-specific or heavyweight
dependencies moved from Imports to Suggests, only required when the
corresponding functionality is actually used, with an informative error
(naming exactly what's missing, with an `install.packages()` hint) if it
isn't installed. Imports goes from 21 packages down to 11.

* **Breaking change:** drop `magrittr`. `flowme::%>%` is no longer exported
  — flowme's own code already used the native `|>` pipe everywhere. Adds an
  explicit `Depends: R (>= 4.1.0)` to reflect the pipe's actual requirement.

* move `duckdb`, `DBI`, `dplyr`, `dbplyr` and `tictoc` to Suggests.
  `tar_duck_r()`, `tar_duck_rmd()` and `duck_tar_format()`'s read method now
  check upfront that the packages they need are installed, instead of
  requiring them just to load `flowme`.

* move `remotes` to Suggests. `use_targets_description()` and
  `use_drake_description()` only need it when `install_deps = TRUE` (the
  default), and now check for it before calling `remotes::install_deps()`.

* move `rstudioapi` and `job` to Suggests. `tar_make_job()` stays
  RStudio-only by design (it's registered as an RStudio addin and
  hard-requires an active RStudio session via `job::job()` regardless).
  `tar_visnetwork_custom()`, however, no longer requires RStudio at all: it
  now only calls `rstudioapi::documentSaveAll()` when `rstudioapi` is
  installed and RStudio is actually running, silently skipping the save
  otherwise.

* drop the `stringr` (and transitively `stringi`) dependency, replacing its
  two call sites in `tar_duck_rmd()` with base R (`trimws()` and a small
  helper mirroring `stringr::str_extract("^[^#]+")`).

* fix: `tarchetypes` was only listed in Suggests even though
  `tar_bookdown()` calls `tarchetypes::tar_knitr_deps()` unconditionally;
  it's now a proper Imports dependency.

# flowme 0.5.4

* fix to add here as dependency

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
