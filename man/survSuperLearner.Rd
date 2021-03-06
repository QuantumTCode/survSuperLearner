% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SL_functions.R
\name{survSuperLearner}
\alias{survSuperLearner}
\title{Super Learner for conditional survival functions}
\usage{
survSuperLearner(
  time,
  event,
  X,
  newX,
  new.times,
  event.SL.library,
  cens.SL.library,
  id = NULL,
  verbose = FALSE,
  control = list(),
  cvControl = list(),
  obsWeights = NULL
)
}
\arguments{
\item{time}{\code{n x 1} numeric vector of observed right-censored follow-up times; i.e. the minimum of the event and censoring times.}

\item{event}{\code{n x 1} numeric vector of status indicators of whether an event was observed.}

\item{X}{\code{n x p} data.frame of observed covariate values on which to train the SuperLearner.}

\item{newX}{\code{m x p} data.frame of new observed covariate values at which to obtain predictions for the estimated algorithm. Must have the same names and structure as \code{X}.}

\item{new.times}{\code{k x 1} numeric vector of times at which to obtain predicted conditional survivals.}

\item{event.SL.library}{Library of candidate learners to use to estimate the conditional survival of the event. Should have the same structure as the \code{SL.library} argument to the \code{SuperLearner} function in the \code{SuperLearner} package; see details below. Run \code{\link{survlistWrappers()}} to see a list of currently available prediction and screening algorithms.
#' @param cens.SL.library Library of candidate learners to use to estimate the conditional survival of censoring.}

\item{id}{Optional \code{n x 1} vector of observation clusters. If provided, cross-validation folds will respect clustering and \code{id} will be passed to every learner, though some learners may not make use of it. Default is every observation in its own cluster; i.e. iid observations.}

\item{verbose}{\code{TRUE/FALSE} indicating whether to print progress in the fitting process to the console.}

\item{control}{Named list of parameters controlling the fitting process. See \code{\link{survSuperLearner.control}} for details.}

\item{cvControl}{Named list of parameters controlling the cross-validation process. See \code{\link{survSuperLearner.cvControl}} for details.}

\item{obsWeights}{Optional \code{n x 1} vector of observation weights. If provided, these weights will be passed to each learner, which may or may not make use of them (or make use of them correctly), and will be used in the ensemble step to weight the empirical risk function.}
}
\value{
\code{survSuperLearner} returns a named list with the following elements:
\item{call}{The matched call.}
\item{event.libraryNames, cens.libraryNames}{Parsed learner names.}
\item{event.SL.library, cens.SL.library}{Libraries used for fitting.}
\item{event.SL.predict, cens.SL.predict}{\code{m x k} matrices of SuperLearner predicted survival values. Rows index observations in \code{newX}; columns index times in \code{new.times.}}
\item{event.coef, cens.coef}{Fitted SuperLearner coefficients for the model for the conditional survival functions for the event and censoring times, respectively.}
\item{event.library.predict, cens.library.predict}{\code{m x k x p} predicted event and censoring survivals on \code{newX} and \code{new.times} from the candidate learners, where \code{p} is the number of candidated learners.}
\item{event.Z, cens.Z}{\code{n x l x p} cross-validated event and censoring survivals on the training data, where \code{l} is the number of elements in \code{control$event.t.grid} and \code{control$cens.t.grid}, respectively, and \code{p} is the number of candidate learners.}
\item{event.cvRisk, cens.cvRisk}{Cross-validated risks for the candidate conditional event and censoring survival functions.}
\item{event.fitLibrary, cens.fitLibrary}{Fitted conditional survival functions for all learners in the library on the full data.}
\item{varNames}{Variable names of the training data.}
\item{validRows}{Length \code{V} list containing the indices contained in each fold used for cross-validation.}
\item{event.whichScreen, cens.whichScreen}{Matrix indicating which variables were included in each screening algorithm in the full training data.}
\item{control, cvControl}{Parameters used for controlling the fitting and cross-validation processes, respectively.}
\item{event.errorsInCVLibrary, cens.errorsInCVLibrary}{Logical matrices indicating whether each learning algorithm encountered any errors in each cross-validation fold.}
\item{event.errorsInLibrary, cens.errorsInLibrary}{Logical vectors indicating whether each learning algorithm encountered any errors on the full data.}
\item{times}{Timing data.}
}
\description{
This function estimates conditional survival functions for the event and censoring times from right-censored data.
}
\details{
The conditional survival function of the event at time \code{t} given covariates \code{X} is defined as the probability that the event occurs after time \code{t} given covariate values \code{x}. The conditional survival function of censoring is the probability that the censoring time occurs after \code{t} given covariates \code{x}. This function finds the optimal weighted combination, i.e. the Super Learner, of candidate learners for both of these functions simultaneously.
}
\examples{
n <- 100
X <- data.frame(X1 = rnorm(n), X2 = rbinom(n, size = 1, prob = 0.5))

S0 <- function(t, x) pexp(t, rate = exp(-2 + x[,1] - x[,2] + .5 * x[,1] * x[,2]), lower.tail = FALSE)
T <- rexp(n, rate = exp(-2 + X[,1] - X[,2] + .5 *  X[,1] * X[,2]))

G0 <- function(t, x) {
  as.numeric(t < 15) * .9 * pexp(t, rate = exp(-2 -.5 * x[,1] - .25 * x[,2] + .5 * x[,1] * x[,2]), lower.tail=FALSE)
}
C0 <- rbinom(n, 1, .1)
C <- rexp(n, exp(-2 -.5 * X[,1] - .25 * X[,2] + .5 * X[,1] * X[,2]))
C[C0 == 1] <- 0
C[C > 15] <- 15

time <- pmin(T, C)
event <- as.numeric(T <= C)

event.SL.library <- cens.SL.library <- lapply(c("survSL.km", "survSL.coxph", "survSL.expreg", "survSL.weibreg", "survSL.loglogreg", "survSL.gam", "survSL.rfsrc"), function(alg) {
  c(alg, "survscreen.glmnet", "survscreen.marg", "All")
})

fit <- survSuperLearner(time = time, event = event, X = X, newX = X, new.times = seq(0, 15, .1), event.SL.library = event.SL.library, cens.SL.library = cens.SL.library, verbose = TRUE)

fit$event.coef[which(fit$event.coef > 0)]
fit$cens.coef[which(fit$cens.coef > 0)]

plot(fit$event.SL.predict[1,], S0(t =  seq(0, 15, .1), X[1,]))
abline(0,1,col='red')
plot(fit$cens.SL.predict[1,], G0(t =  seq(0, 15, .1), X[1,]))
abline(0,1,col='red')
}
\references{
van der Laan, M. J., Polley, E. C., & Hubbard, A. E. (2007). Super learner. \emph{Statistical Applications in Genetics and Molecular Biology}, 6(1).

van der Laan, M. J., and Rose, S. (2011). \emph{Targeted Learning: Causal inference for observational and experimental data}. Springer-Verlag New York.
}
