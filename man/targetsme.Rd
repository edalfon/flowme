% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/targets.R
\name{targetsme}
\alias{targetsme}
\alias{use_targets}
\title{Add files and directories for a targets-powered project.}
\usage{
targetsme(install_deps = TRUE)

use_targets(install_deps = TRUE)
}
\arguments{
\item{install_deps}{logical, whether to install dependencies}
}
\description{
Add boilerplate code to the current project for a targets-based project
\itemize{
\item Copy templates to the current project.
\item Include entries in .gitignore to prevent some files into version control
}
}
