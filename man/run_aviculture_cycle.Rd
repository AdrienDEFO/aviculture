% Generated manually to match R/simulation.R
\name{run_aviculture_cycle}
\alias{run_aviculture_cycle}
\title{Run Complete Aviculture Cycle Simulation}
\usage{
run_aviculture_cycle(parameters, model = NULL, integrator = c("euler", "rk4"))
}
\arguments{
\item{parameters}{List of scalar parameters (see Details).}

\item{model}{A model object from \code{\link{load_model}}. If \code{NULL}, uses a simple reference growth.}

\item{integrator}{Character. Numerical integrator: \code{"euler"} or \code{"rk4"}.}
}
\value{
A data frame with columns:
\itemize{
  \item \code{t}: time (days)
  \item \code{population}: current bird population
  \item \code{maturity_ratio}: maturity factor (0--1)
  \item \code{marketable_pop}: marketable population
  \item \code{births}, \code{deaths}, \code{sales}: flows over the time step
  \item \code{mass_ref}, \code{volume_ref}, \code{density_ref}: reference growth values
  \item \code{total_biomass}, \code{total_volume}: totals for the flock
  \item \code{economic_potential}: simple economic potential proxy
  \item \code{costs_daily}, \code{revenue_daily}, \code{profit_daily}: step economics
  \item \code{costs_cumulative}, \code{revenue_cumulative}, \code{profit_cumulative}: cumulative economics
}
}
\description{
Discrete-time cycle simulator aligned with the supply--mortality--sales structure used in Mod210126.
It supports explicit Euler and RK4 integration.
}
\details{
Expected fields in \code{parameters}:
\itemize{
  \item \code{T}: final time (days)
  \item \code{dt}: time step (days)
  \item \code{initialPopulation}: initial population at \code{t=0}
  \item \code{e}, \code{d}, \code{kappa}, \code{s}: supply, mortality, competition and sales parameters
  \item \code{demand}: total demand over the horizon
  \item \code{cf}, \code{cs}, \code{cn}, \code{cd}, \code{ps}: fixed/supply/feed/death costs and selling price
  \item \code{growthModel}: \code{"logistic"}, \code{"gompertz"} or \code{"optav"}
}
}
\examples{
\dontrun{
params <- list(T=60, dt=1, initialPopulation=0, e=200, d=0.01, kappa=0.0001, s=0.05,
              demand=2000, cf=5000, cs=1, cn=0.2, cd=0.5, ps=5, growthModel="logistic")
sim <- run_aviculture_cycle(params, model = NULL, integrator = "rk4")
plot(sim$t, sim$population, type="l", xlab="Days", ylab="Population")
}
}

