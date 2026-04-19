#' Numerical Utilities for Aviculture Modeling
#'
#' Provides derivatives and integral approximations for growth simulations.
#' These functions are optimized for broiler growth curves and demographic dynamics.
#'
#' @name numerical_utilities
#'
NULL

#' Centered Difference Derivative
#'
#' Approximates the derivative dy/dt using centered differences at node i:
#' \eqn{dy/dt \approx (y_{i+1} - y_{i-1}) / (2 \cdot dt)}
#'
#' This has truncation error O(dt^2), suitable for smooth growth curves.
#'
#' @param y_prev Numeric. Value at t - dt.
#' @param y_next Numeric. Value at t + dt.
#' @param dt Numeric. Time step. Default is 1.
#'
#' @return Numeric. Approximation of dy/dt.
#'
#' @examples
#' # Growth rate between two time points
#' y_prev <- 100
#' y_next <- 110
#' growth_rate <- derivative_central(y_prev, y_next, dt = 1)
#' print(growth_rate)  # [1] 5
#'
#' @export
derivative_central <- function(y_prev, y_next, dt = 1) {
  (y_next - y_prev) / (2 * dt)
}

#' Forward Difference Derivative
#'
#' Approximates the derivative dy/dt using forward differences:
#' \eqn{dy/dt \approx (y_{i+1} - y_i) / dt}
#'
#' This has truncation error O(dt), less accurate than centered but usable at boundaries.
#'
#' @param y0 Numeric. Value at t.
#' @param y1 Numeric. Value at t + dt.
#' @param dt Numeric. Time step. Default is 1.
#'
#' @return Numeric. Approximation of dy/dt.
#'
#' @examples
#' y0 <- 100
#' y1 <- 105
#' rate <- derivative_forward(y0, y1, dt = 1)
#' print(rate)  # [1] 5
#'
#' @export
derivative_forward <- function(y0, y1, dt = 1) {
  (y1 - y0) / dt
}

#' Trapezoidal Rule Integration
#'
#' Approximates the integral of y(t) using the trapezoidal rule:
#' \eqn{\int y \, dt \approx \sum 0.5 \cdot (y_i + y_{i+1}) \cdot dt_i}
#'
#' Error is O(dt^2) for smooth functions. Suitable for cumulative profit/cost calculations.
#'
#' @param ys Numeric vector. Function values at time nodes.
#' @param ts Numeric vector (optional). Time nodes. If NULL, assumes uniform dt = 1.
#'
#' @return Numeric. Approximate integral value.
#'
#' @details
#' If \code{ts} is provided, it must have the same length as \code{ys}.
#' The integration accounts for non-uniform time spacing if \code{ts} is specified.
#'
#' @examples
#' # Integrate a simple linear function
#' t <- 0:10
#' y <- 2 * t + 1
#' integral_value <- integral_trapezoid(y, t)
#' print(integral_value)  # Approximate ∫(2t+1)dt from 0 to 10
#'
#' @export
integral_trapezoid <- function(ys, ts = NULL) {
  if (length(ys) == 0) return(0)
  
  if (is.null(ts) || length(ts) != length(ys)) {
    # Assume uniform dt = 1
    n <- length(ys) - 1
    sum(0.5 * (ys[1:n] + ys[2:(n+1)]))
  } else {
    # Non-uniform spacing
    n <- length(ys) - 1
    dt <- diff(ts)
    sum(0.5 * (ys[1:n] + ys[2:(n+1)]) * dt)
  }
}

#' Simpson's Rule Integration (Composite)
#'
#' Approximates the integral using composite Simpson's rule:
#' \eqn{\int y \, dt \approx (dt/3) \cdot (y_0 + 4 y_1 + 2 y_2 + \ldots + y_n)}
#'
#' Error is O(dt^4), more accurate than trapezoid for smooth functions.
#' Requires even number of intervals (odd number of points).
#'
#' @param ys Numeric vector. Function values at time nodes (must have odd length).
#' @param dt Numeric. Uniform time step. Default is 1.
#'
#' @return Numeric. Approximate integral value.
#'
#' @details
#' If the number of intervals is odd (even number of points), falls back to trapezoidal.
#' Simpson's rule is particularly effective for growth curves with inflection points.
#'
#' @examples
#' # Integrate using Simpson's rule
#' t <- seq(0, 10, by = 0.5)  # 21 points, 20 intervals (even)
#' y <- sin(t)
#' integral_value <- integral_simpson(y, dt = 0.5)
#' print(integral_value)
#'
#' @export
integral_simpson <- function(ys, dt = 1) {
  n <- length(ys) - 1
  
  # Check if even number of intervals (odd number of points)
  if (n %% 2 != 0 || n < 2) {
    # Fall back to trapezoidal
    # integral_trapezoid() assumes unit spacing when ts is NULL
    return(integral_trapezoid(ys) * dt)
  }
  
  # Simpson's rule: dt/3 * (y0 + 4*y1 + 2*y2 + 4*y3 + ... + yn)
  s <- ys[1] + ys[length(ys)]
  for (i in 2:(length(ys)-1)) {
    # R uses 1-based indexing:
    # indices: 1..(n+1) correspond to y0..yn
    # coefficients: 1, 4, 2, 4, 2, ..., 4, 1
    coeff <- if (i %% 2 == 0) 4 else 2
    s <- s + coeff * ys[i]
  }
  
  (dt / 3) * s
}

#' Explicit Euler Integration
#'
#' Solves dy/dt = f(y,t) using the explicit Euler scheme:
#' \eqn{y_{n+1} = y_n + dt \cdot f(y_n, t_n)}
#'
#' This is a first-order method; use a small dt for stability.
#'
#' @param f Function. dy/dt = f(y, t). Must accept (y, t) arguments.
#' @param y0 Numeric. Initial condition at t = t0.
#' @param t0 Numeric. Initial time.
#' @param t_final Numeric. Final time.
#' @param dt Numeric. Time step. Default is 0.1.
#'
#' @return
#' A list with:
#' \item{times}{Numeric vector of time nodes.}
#' \item{values}{Numeric vector of y values at each time node.}
#' \item{steps}{Number of steps taken.}
#'
#' @examples
#' \dontrun{
#'   # Exponential growth: dy/dt = 0.1 * y
#'   f_growth <- function(y, t) 0.1 * y
#'   result <- euler_integrate(f_growth, y0 = 1, t0 = 0, t_final = 10, dt = 0.1)
#'   plot(result$times, result$values, type = 'l')
#' }
#'
#' @export
euler_integrate <- function(f, y0, t0 = 0, t_final, dt = 0.1) {
  times <- seq(t0, t_final, by = dt)
  n_steps <- length(times) - 1
  values <- numeric(length(times))
  values[1] <- y0
  
  for (i in 1:n_steps) {
    t <- times[i]
    y <- values[i]
    values[i + 1] <- y + dt * f(y, t)
  }
  
  list(
    times = times,
    values = values,
    steps = n_steps
  )
}

#' Runge-Kutta 4th Order Integration
#'
#' Solves dy/dt = f(y,t) using the RK4 scheme:
#' \eqn{y_{n+1} = y_n + (dt/6) \cdot (k_1 + 2 k_2 + 2 k_3 + k_4)}
#' where k_i are intermediate slopes.
#'
#' Local truncation error is O(dt^5); global error is O(dt^4).
#' Ideal for population dynamics with density-dependent terms.
#'
#' @param f Function. dy/dt = f(y, t). Must accept (y, t) arguments.
#' @param y0 Numeric. Initial condition at t = t0.
#' @param t0 Numeric. Initial time.
#' @param t_final Numeric. Final time.
#' @param dt Numeric. Time step. Default is 0.1.
#'
#' @return
#' A list with:
#' \item{times}{Numeric vector of time nodes.}
#' \item{values}{Numeric vector of y values at each time node.}
#' \item{steps}{Number of steps taken.}
#'
#' @details
#' The function is typically used internally for population simulations,
#' but can be called directly for custom ODE systems.
#'
#' @examples
#' \dontrun{
#'   # Exponential growth: dy/dt = 0.1 * y
#'   f_growth <- function(y, t) 0.1 * y
#'   result <- rk4_integrate(f_growth, y0 = 1, t0 = 0, t_final = 10, dt = 0.1)
#'   plot(result$times, result$values, type = 'l')
#' }
#'
#' @export
rk4_integrate <- function(f, y0, t0 = 0, t_final, dt = 0.1) {
  times <- seq(t0, t_final, by = dt)
  n_steps <- length(times) - 1
  values <- numeric(length(times))
  values[1] <- y0
  
  for (i in 1:n_steps) {
    t <- times[i]
    y <- values[i]
    
    k1 <- f(y, t)
    k2 <- f(y + 0.5 * dt * k1, t + 0.5 * dt)
    k3 <- f(y + 0.5 * dt * k2, t + 0.5 * dt)
    k4 <- f(y + dt * k3, t + dt)
    
    values[i + 1] <- y + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4)
  }
  
  list(
    times = times,
    values = values,
    steps = n_steps
  )
}

#' Cumulative Profit via Integration
#'
#' Computes total profit using trapezoidal integration over the profit curve.
#' More accurate than simple summation for continuous-time dynamics.
#'
#' @param profit_per_step Numeric vector. Profit at each time node.
#' @param times Numeric vector. Corresponding time nodes.
#'
#' @return Numeric. Total cumulative profit.
#'
#' @examples
#' \dontrun{
#'   times <- 0:30
#'   profit <- 10 + 2 * times  # Linear profit growth
#'   total <- cumulative_profit(profit, times)
#'   print(total)
#' }
#'
#' @export
cumulative_profit <- function(profit_per_step, times) {
  integral_trapezoid(profit_per_step, times)
}




