#' Count Marketable Birds at Time t
#'
#' Counts how many birds are marketable based on mass and volume thresholds.
#'
#' @param population Data frame with at least \code{mass}, \code{volume}, and \code{count} columns.
#' @param ms Numeric. Minimum marketable mass (kg).
#' @param vs Numeric. Minimum marketable volume (L).
#' @param mass_col Character. Column name for mass. Default "mass".
#' @param volume_col Character. Column name for volume. Default "volume".
#' @param count_col Character. Column name for counts. Default "count".
#'
#' @return
#' A list with:
#' \item{marketable}{Total marketable birds}
#' \item{total}{Total birds}
#' \item{ratio}{Marketable ratio}
#' \item{rows}{Logical vector of marketable rows}
#'
#' @examples
#' \dontrun{
#' pop <- data.frame(mass = c(1.8, 2.3), volume = c(1.6, 2.2), count = c(50, 80))
#' count_marketable(pop, ms = 2.0, vs = 2.0)
#' }
#'
#' @export
count_marketable <- function(population, ms, vs,
                             mass_col = "mass",
                             volume_col = "volume",
                             count_col = "count") {
  if (!is.data.frame(population)) {
    stop("population must be a data frame")
  }
  for (col in c(mass_col, volume_col, count_col)) {
    if (!col %in% names(population)) {
      stop("population is missing column: ", col)
    }
  }
  if (!is.numeric(ms) || !is.numeric(vs)) {
    stop("ms and vs must be numeric")
  }
  mass <- population[[mass_col]]
  volume <- population[[volume_col]]
  count <- population[[count_col]]
  if (!is.numeric(mass) || !is.numeric(volume) || !is.numeric(count)) {
    stop("mass, volume, and count columns must be numeric")
  }
  rows <- (mass >= ms) & (volume >= vs)
  marketable <- sum(count[rows])
  total <- sum(count)
  ratio <- if (total > 0) marketable / total else 0
  list(marketable = marketable, total = total, ratio = ratio, rows = rows)
}

#' Identify Birds (or Cohorts) with Stagnant Growth
#'
#'
#' Flags birds or cohorts that are no longer growing based on recent
#' mass and volume changes.
#'
#' @param history Data frame with columns for time, mass, volume, and id.
#' @param id_col Character. Column name for bird or cohort id. Default "id".
#' @param time_col Character. Column name for time. Default "time".
#' @param mass_col Character. Column name for mass. Default "mass".
#' @param volume_col Character. Column name for volume. Default "volume".
#' @param window Integer. Number of last time steps to evaluate. Default 3.
#' @param min_mass_growth Numeric. Minimum average mass growth per time step. Default 0.002.
#' @param min_volume_growth Numeric. Minimum average volume growth per time step. Default 0.002.
#'
#' @return
#' Data frame with one row per id and columns:
#' \item{id}{Bird or cohort id}
#' \item{stagnant}{TRUE if growth is below thresholds}
#' \item{mass_growth}{Average mass growth per step}
#' \item{volume_growth}{Average volume growth per step}
#'
#' @examples
#' \dontrun{
#' hist <- data.frame(id = c(1,1,1,2,2,2),
#'                    time = c(1,2,3,1,2,3),
#'                    mass = c(1.0,1.01,1.01,1.0,1.05,1.10),
#'                    volume = c(0.9,0.91,0.91,0.9,0.96,1.02))
#' identify_stagnant(hist, window = 2, min_mass_growth = 0.005, min_volume_growth = 0.005)
#' }
#'
#' @export
identify_stagnant <- function(history,
                              id_col = "id",
                              time_col = "time",
                              mass_col = "mass",
                              volume_col = "volume",
                              window = 3,
                              min_mass_growth = 0.002,
                              min_volume_growth = 0.002) {
  if (!is.data.frame(history)) {
    stop("history must be a data frame")
  }
  for (col in c(id_col, time_col, mass_col, volume_col)) {
    if (!col %in% names(history)) {
      stop("history is missing column: ", col)
    }
  }
  if (!is.numeric(window) || window < 2) {
    stop("window must be an integer >= 2")
  }
  ids <- unique(history[[id_col]])
  out <- lapply(ids, function(id) {
    rows <- history[[id_col]] == id
    h <- history[rows, , drop = FALSE]
    h <- h[order(h[[time_col]]), , drop = FALSE]
    if (nrow(h) < window) {
      return(data.frame(
        id = id, stagnant = FALSE,
        mass_growth = NA_real_, volume_growth = NA_real_
      ))
    }
    tail_h <- tail(h, window)
    dm <- diff(tail_h[[mass_col]])
    dv <- diff(tail_h[[volume_col]])
    mass_growth <- mean(dm)
    volume_growth <- mean(dv)
    stagnant <- (mass_growth < min_mass_growth) && (volume_growth < min_volume_growth)
    data.frame(id = id, stagnant = stagnant,
               mass_growth = mass_growth, volume_growth = volume_growth)
  })
  do.call(rbind, out)
}

#' Estimate Marketable Age Threshold
#'
#' Computes the earliest age where both mass and volume exceed thresholds.
#'
#' @param ms Numeric. Minimum marketable mass (kg).
#' @param vs Numeric. Minimum marketable volume (L).
#' @param model A model object from \code{\link{load_model}}.
#' @param start_age Numeric. Starting age. Default 1.
#' @param end_age Numeric. Ending age. Default 80.
#' @param step Numeric. Step in days. Default 0.1.
#'
#' @return
#' Numeric age in days, or NA if thresholds are not reached.
#'
#' @export
estimate_marketable_age <- function(ms, vs, model,
                                    start_age = 1,
                                    end_age = 80,
                                    step = 0.1) {
  if (!is.numeric(ms) || !is.numeric(vs)) {
    stop("ms and vs must be numeric")
  }
  ages <- seq(start_age, end_age, by = step)
  masses <- sapply(ages, function(a) predict_mass(a, model))
  volumes <- sapply(ages, function(a) predict_volume(a, model))
  idx <- which(masses >= ms & volumes >= vs)
  if (length(idx) == 0) return(NA_real_)
  ages[min(idx)]
}

#' Build Decision Table for Entry Recommendations
#'
#' Creates a decision table with marketable, stagnant, and recommended entry
#' based on future demand and lead time to marketable status.
#'
#' @param sim A list returned by \code{\link{simulate_market_flow}} or a summary data frame.
#' @param demand Numeric, vector, or function. If NULL, uses summary$demand when available.
#' @param lead_time_days Numeric. Days needed for a chick to become marketable.
#'   If NULL, it is estimated from \code{ms}, \code{vs}, and \code{model}.
#' @param time_step Numeric. Time step in days. If NULL, tries to read from attributes.
#' @param ms Numeric. Minimum marketable mass (kg). Required if lead_time_days is NULL.
#' @param vs Numeric. Minimum marketable volume (L). Required if lead_time_days is NULL.
#' @param model Model object. Required if lead_time_days is NULL.
#' @param entry_cap Numeric. Optional max entry per step.
#'
#' @return
#' Data frame with decision columns per time step.
#'
#' @export
build_decision_table <- function(sim,
                                 demand = NULL,
                                 lead_time_days = NULL,
                                 time_step = NULL,
                                 ms = NULL,
                                 vs = NULL,
                                 model = NULL,
                                 entry_cap = NULL) {
  summary <- if (is.list(sim)) sim$summary else sim
  if (!is.data.frame(summary)) {
    stop("sim must be a list from simulate_market_flow or a data frame")
  }
  if (is.null(time_step)) {
    time_step <- attr(summary, "time_step")
    if (is.null(time_step)) time_step <- 1
  }
  if (is.null(lead_time_days)) {
    if (is.null(ms) || is.null(vs) || is.null(model)) {
      stop("lead_time_days is NULL; provide ms, vs, and model")
    }
    lead_time_days <- estimate_marketable_age(ms, vs, model) - 1
  }
  if (is.na(lead_time_days) || lead_time_days < 0) {
    stop("lead_time_days could not be estimated")
  }
  lead_steps <- ceiling(lead_time_days / time_step)
  n <- nrow(summary)

  get_value_at <- function(x, idx) {
    if (is.null(x)) return(0)
    if (is.function(x)) return(as.numeric(x(summary$time[idx])))
    if (is.numeric(x) && length(x) == 1) return(as.numeric(x))
    if (is.numeric(x)) {
      if (idx <= length(x)) return(as.numeric(x[idx]))
      return(as.numeric(x[length(x)]))
    }
    stop("demand must be numeric, vector, or function")
  }

  demand_vec <- numeric(n)
  for (i in seq_len(n)) {
    if (!is.null(demand)) {
      demand_vec[i] <- get_value_at(demand, i)
    } else if ("demand" %in% names(summary)) {
      demand_vec[i] <- summary$demand[i]
    } else {
      demand_vec[i] <- 0
    }
  }

  recommended <- numeric(n)
  shortage <- numeric(n)
  for (i in seq_len(n)) {
    future_idx <- min(n, i + lead_steps)
    need <- demand_vec[future_idx]
    available <- summary$marketable[future_idx]
    shortage[i] <- max(0, need - available)
    recommended[i] <- shortage[i]
    if (!is.null(entry_cap)) recommended[i] <- min(recommended[i], entry_cap)
  }

  data.frame(
    time = summary$time,
    marketable = summary$marketable,
    stagnant = summary$stagnant,
    demand = demand_vec,
    shortage_future = shortage,
    recommended_entry = recommended,
    stringsAsFactors = FALSE
  )
}

#' Simulate Discrete Poultry Flow with Mass and Volume
#'
#' Discrete-time simulation aligned with Mod210126: tracks cohorts by age,
#' mass, and volume; controls entry flow; counts marketable birds; flags stagnation.
#'
#' @param start_time Numeric. Start time (days). Default 0.
#' @param end_time Numeric. End time (days). Default 60.
#' @param time_step Numeric. Time step in days. Default 1.
#' @param model A model object from \code{\link{load_model}}. If NULL, loads default.
#' @param entry Numeric, vector, or function. Entry flow of chicks. If vector, aligned with time steps.
#' @param entry_is_rate Logical. If TRUE, entry is per-day rate and will be multiplied by time_step.
#' @param mortality_rate Numeric or function(age, mass, volume, time) giving per-day mortality rate.
#' @param ms Numeric. Minimum marketable mass (kg).
#' @param vs Numeric. Minimum marketable volume (L).
#' @param demand Numeric, vector, or function. Market demand (birds per day).
#' @param demand_is_rate Logical. If TRUE, demand is per-day rate and will be multiplied by time_step.
#' @param feed_price Numeric. Feed price per kg.
#' @param bird_price Numeric. Sale price per bird.
#' @param daily_feed Numeric. Feed consumption per bird per day (kg).
#' @param fixed_cost_per_day Numeric. Fixed cost per day.
#' @param stagnation_window Integer. Window size for stagnation detection. Default 3.
#' @param min_mass_growth Numeric. Minimum average mass growth per step. Default 0.002.
#' @param min_volume_growth Numeric. Minimum average volume growth per step. Default 0.002.
#' @param return_history Logical. If TRUE, returns cohort history.
#'
#' @return
#' A list with:
#' \item{summary}{Data frame by time: population, marketable, stagnant, sold, entered, deaths}
#' \item{cohorts}{Final cohort table}
#' \item{history}{Cohort history if return_history=TRUE}
#'
#' @examples
#' \dontrun{
#' model <- load_model()
#' sim <- simulate_market_flow(
#'   end_time = 60, time_step = 1,
#'   entry = 100, entry_is_rate = FALSE,
#'   ms = 2.0, vs = 2.0,
#'   demand = 80, demand_is_rate = FALSE,
#'   model = model
#' )
#' head(sim$summary)
#' }
#'
#' @export
simulate_market_flow <- function(
  start_time = 0,
  end_time = 60,
  time_step = 1,
  model = NULL,
  entry = 0,
  entry_is_rate = TRUE,
  mortality_rate = 0.01,
  ms,
  vs,
  demand = NULL,
  demand_is_rate = TRUE,
  feed_price = 0,
  bird_price = 0,
  daily_feed = 0,
  fixed_cost_per_day = 0,
  stagnation_window = 3,
  min_mass_growth = 0.002,
  min_volume_growth = 0.002,
  return_history = FALSE
) {
  if (is.null(model)) {
    model <- load_model(verbose = FALSE)
  }
  if (!is.numeric(time_step) || time_step <= 0) {
    stop("time_step must be a positive number")
  }
  if (!is.numeric(ms) || !is.numeric(vs)) {
    stop("ms and vs must be numeric")
  }

  times <- seq(start_time, end_time, by = time_step)
  n_steps <- length(times)

  get_value_at <- function(x, t, idx, is_rate) {
    if (is.null(x)) return(0)
    if (is.function(x)) {
      val <- as.numeric(x(t))
    } else if (is.numeric(x) && length(x) == 1) {
      val <- as.numeric(x)
    } else if (is.numeric(x)) {
      if (idx <= length(x)) {
        val <- as.numeric(x[idx])
      } else {
        val <- as.numeric(x[length(x)])
      }
    } else {
      stop("entry/demand must be numeric, vector, or function")
    }
    if (is_rate) val <- val * time_step
    max(0, val)
  }

  next_id <- 1
  cohorts <- data.frame(
    id = integer(0),
    age = numeric(0),
    mass = numeric(0),
    volume = numeric(0),
    count = numeric(0),
    stringsAsFactors = FALSE
  )

  history <- NULL
  if (return_history) {
    history <- data.frame(
      time = numeric(0), id = integer(0), age = numeric(0),
      mass = numeric(0), volume = numeric(0), count = numeric(0),
      stringsAsFactors = FALSE
    )
  }

  summary <- data.frame(
    time = times,
    population = numeric(n_steps),
    marketable = numeric(n_steps),
    stagnant = numeric(n_steps),
    sold = numeric(n_steps),
    entered = numeric(n_steps),
    deaths = numeric(n_steps),
    demand = numeric(n_steps),
    revenue = numeric(n_steps),
    feed_cost = numeric(n_steps),
    fixed_cost = numeric(n_steps),
    profit = numeric(n_steps),
    cumulative_profit = numeric(n_steps),
    stringsAsFactors = FALSE
  )

  # store per-cohort recent growth for stagnation detection
  growth_hist <- list()

  for (i in seq_along(times)) {
    t <- times[i]

    # Entry flow
    entry_now <- get_value_at(entry, t, i, entry_is_rate)
    if (entry_now > 0) {
      age0 <- 1
      mass0 <- predict_mass(age0, model)
      vol0 <- predict_volume(age0, model)
      cohorts <- rbind(
        cohorts,
        data.frame(
          id = next_id, age = age0, mass = mass0, volume = vol0,
          count = entry_now, stringsAsFactors = FALSE
        )
      )
      next_id <- next_id + 1
    }

    # Update growth for existing cohorts
    if (nrow(cohorts) > 0) {
      for (r in seq_len(nrow(cohorts))) {
        a <- cohorts$age[r]
        m <- cohorts$mass[r]
        v <- cohorts$volume[r]
        gm <- predict_growth_rate(a, m, v, model)
        gv <- predict_volume_growth_rate(a, m, v, model)
        cohorts$age[r] <- a + time_step
        cohorts$mass[r] <- m + gm * time_step
        cohorts$volume[r] <- v + gv * time_step

        # Mortality
        d_rate <- if (is.function(mortality_rate)) {
          as.numeric(mortality_rate(a, m, v, t))
        } else {
          as.numeric(mortality_rate)
        }
        d_rate <- max(0, d_rate)
        deaths <- cohorts$count[r] * d_rate * time_step
        cohorts$count[r] <- max(0, cohorts$count[r] - deaths)
        summary$deaths[i] <- summary$deaths[i] + deaths

        # Track growth for stagnation
        gid <- cohorts$id[r]
        if (is.null(growth_hist[[as.character(gid)]])) {
          growth_hist[[as.character(gid)]] <- list(m = numeric(0), v = numeric(0))
        }
        growth_hist[[as.character(gid)]]$m <- c(growth_hist[[as.character(gid)]]$m, gm)
        growth_hist[[as.character(gid)]]$v <- c(growth_hist[[as.character(gid)]]$v, gv)
      }
    }

    # Marketable count
    if (nrow(cohorts) > 0) {
      mk <- count_marketable(cohorts, ms = ms, vs = vs,
                             mass_col = "mass", volume_col = "volume", count_col = "count")
      summary$marketable[i] <- mk$marketable
    } else {
      summary$marketable[i] <- 0
    }

    # Demand and sales
    demand_now <- get_value_at(demand, t, i, demand_is_rate)
    summary$demand[i] <- demand_now
    sold_now <- min(summary$marketable[i], demand_now)
    summary$sold[i] <- sold_now

    # Remove sold birds proportionally from marketable cohorts
    if (sold_now > 0 && nrow(cohorts) > 0) {
      mk_rows <- (cohorts$mass >= ms) & (cohorts$volume >= vs) & (cohorts$count > 0)
      total_mk <- sum(cohorts$count[mk_rows])
      if (total_mk > 0) {
        share <- cohorts$count[mk_rows] / total_mk
        cohorts$count[mk_rows] <- pmax(0, cohorts$count[mk_rows] - sold_now * share)
      }
    }

    # Stagnant detection (per cohort)
    stagnant_now <- 0
    if (nrow(cohorts) > 0) {
      for (r in seq_len(nrow(cohorts))) {
        gid <- cohorts$id[r]
        gh <- growth_hist[[as.character(gid)]]
        if (!is.null(gh) && length(gh$m) >= stagnation_window) {
          m_mean <- mean(tail(gh$m, stagnation_window))
          v_mean <- mean(tail(gh$v, stagnation_window))
          if (m_mean < min_mass_growth && v_mean < min_volume_growth) {
            stagnant_now <- stagnant_now + cohorts$count[r]
          }
        }
      }
    }
    summary$stagnant[i] <- stagnant_now

    # Summary population and entry
    population_now <- if (nrow(cohorts) > 0) sum(cohorts$count) else 0
    summary$population[i] <- population_now
    summary$entered[i] <- entry_now

    # Economics
    revenue <- sold_now * bird_price
    feed_cost <- population_now * daily_feed * feed_price * time_step
    fixed_cost <- fixed_cost_per_day * time_step
    profit <- revenue - feed_cost - fixed_cost
    summary$revenue[i] <- revenue
    summary$feed_cost[i] <- feed_cost
    summary$fixed_cost[i] <- fixed_cost
    summary$profit[i] <- profit
    summary$cumulative_profit[i] <- if (i == 1) profit else summary$cumulative_profit[i - 1] + profit

    # Record history if requested
    if (return_history && nrow(cohorts) > 0) {
      history <- rbind(
        history,
        data.frame(
          time = t,
          id = cohorts$id,
          age = cohorts$age,
          mass = cohorts$mass,
          volume = cohorts$volume,
          count = cohorts$count,
          stringsAsFactors = FALSE
        )
      )
    }
  }

  attr(summary, "time_step") <- time_step
  attr(summary, "ms") <- ms
  attr(summary, "vs") <- vs

  list(summary = summary, cohorts = cohorts, history = history)
}
