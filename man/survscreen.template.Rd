% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SL_wrappers.R
\name{survscreen.template}
\alias{survscreen.template}
\title{Wrapper functions for screening algorithms in survSuperLearner}
\usage{
survscreen.template(time, event, X, obsWeights, id, ...)
}
\arguments{
\item{time}{Observed follow-up time; i.e. minimum of the event and censoring times.}

\item{event}{Observed event indicator; i.e, whether the follow-up time corresponds to an event or censoring.}

\item{X}{Training covariate data.frame.}

\item{obsWeights}{Observation weights.}

\item{id}{Observation clusters.}

\item{...}{Additional ignored arguments.}
}
\value{
Logical vector of the same length as the number of columns as \code{X} indicating which variables should be included.
}
\description{
This is a template function for a \code{survSuperLearner} screening algorithm. You can use this to write your own screening algorithms.
}
