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
