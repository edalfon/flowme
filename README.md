
<!-- README.md is generated from README.Rmd. Please edit that file -->

# flowme

<!-- badges: start -->
<!-- badges: end -->

A little package to quickly include templates for our project structures
and workflows. Originally based on McBain’s
[`dflow`](https://github.com/MilesMcBain/dflow) for drake workflows and
tailored to our report-generating projects. But we will be including
other approaches here as well.

## Installation

``` r
# install.packages("remotes") # just in case
remotes::install_github("edalfon/flowme")
```

## Example: setup a drake project

Having `flowme` installed, you would only need to call

``` r
flowme::drakeme()
```

It gets you started to an empty but ready-to-fly drake project
(including key dependencies).

Using `drake::vis_drake_graph()` you can peek at the drake dependency
graph for this boilerplate.

![](man/figures/README-drake-graph.png)<!-- -->

This is already a fully functional project that you can run by calling
`drake::r_make()` and it compiles a sample report.

Now, you only need to do your thing in drake plans, include them as
indicated in `_drake.R`, write your results in `Rmd` files within the
`report` directory and simply call `drake::r_make()` to render them all
into a book.

## [More details](https://edalfon.github.io/flowme/articles/flowme.html)

More details on the proposed workflow in [`flowme`’s web
site](https://edalfon.github.io/flowme/articles/flowme.html)
