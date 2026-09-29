# =============================================================================
# HMM WITH WAVELET FEATURES USING hmmTMB
# =============================================================================

library(hmmTMB)
library(tidyverse)

# -----------------------------------------------------------------------------
# 1. PREPARE WAVELET FEATURES FOR HMM
# -----------------------------------------------------------------------------

# Extract power in frequency bands (from previous wavelet analysis)
# We want smooth-ish time series, not the full spectrogram

bands <- list(
  slow = c(0.03, 0.1), # Periods 10-30s: slow postural shifts
  medium = c(0.1, 0.5), # Periods 2-10s: medium movements
  fast = c(0.5, 3) # Periods 0.3-2s: twitches, quick movements
)

get_band_power <- function(wt, freq_range) {
  freq <- 1 / wt$Period
  in_band <- freq >= freq_range[1] & freq <= freq_range[2]
  if (!any(in_band)) {
    return(rep(NA, ncol(wt$Power)))
  }
  colMeans(wt$Power[in_band, , drop = FALSE])
}

# Build HMM input data
hmm_data <- tibble(
  time = wt_list[[1]]$axis.1,
  ID = 1
) |>
  mutate(
    # Power in each band (from velocity wavelet)
    power_slow = get_band_power(wt_list$velocity, bands$slow),
    power_medium = get_band_power(wt_list$velocity, bands$medium),
    power_fast = get_band_power(wt_list$velocity, bands$fast),

    # Also from area_change wavelet
    area_slow = get_band_power(wt_list$area_change, bands$slow),
    area_medium = get_band_power(wt_list$area_change, bands$medium),
    area_fast = get_band_power(wt_list$area_change, bands$fast)
  )

# Log-transform (power is right-skewed)
hmm_data <- hmm_data |>
  mutate(across(starts_with(c("power_", "area_")), ~ log1p(.x)))

# Get true states for validation
state_idx <- map_int(hmm_data$time, \(t) which.min(abs(metrics$time - t)))
hmm_data$true_state <- metrics$true_state[state_idx]

# Quick look at distributions by state
hmm_data |>
  pivot_longer(
    starts_with(c("power_", "area_")),
    names_to = "band",
    values_to = "value"
  ) |>
  ggplot(aes(x = value, fill = true_state)) +
  geom_density(alpha = 0.5) +
  facet_wrap(~band, scales = "free") +
  theme_minimal() +
  labs(title = "Band power distributions by true state")

# -----------------------------------------------------------------------------
# 2. FIT HMM WITH hmmTMB
# -----------------------------------------------------------------------------

# Start simple: use just the three velocity bands
# Assume Gamma distribution for power (positive, right-skewed)

# Define observation model
# Each band is modeled as Gamma with state-dependent mean and SD

# Gamma distribution: mean = shape * scale, var = shape * scale^2
# Helper to convert from mean/sd to shape/scale
gamma_params <- function(mean, sd) {
  # shape = mean^2 / var = mean^2 / sd^2
  # scale = var / mean = sd^2 / mean
  shape <- mean^2 / sd^2
  scale <- sd^2 / mean
  list(shape = shape, scale = scale)
}

# Convert our intuitive mean/sd to shape/scale
slow_params <- map2(c(0.5, 1, 2), c(0.3, 0.5, 1), \(m, s) gamma_params(m, s))
medium_params <- map2(c(0.3, 1, 2), c(0.2, 0.5, 1), \(m, s) gamma_params(m, s))
fast_params <- map2(c(0.2, 0.8, 1.5), c(0.2, 0.4, 0.8), \(m, s) {
  gamma_params(m, s)
})

obs <- Observation$new(
  data = hmm_data,
  n_states = 3,
  dists = list(
    power_slow = "gamma",
    power_medium = "gamma",
    power_fast = "gamma"
  ),
  par = list(
    power_slow = list(
      shape = map_dbl(slow_params, "shape"),
      scale = map_dbl(slow_params, "scale")
    ),
    power_medium = list(
      shape = map_dbl(medium_params, "shape"),
      scale = map_dbl(medium_params, "scale")
    ),
    power_fast = list(
      shape = map_dbl(fast_params, "shape"),
      scale = map_dbl(fast_params, "scale")
    )
  )
)

# Define hidden state process
hid <- MarkovChain$new(
  data = hmm_data,
  n_states = 3
)

# Create and fit HMM
hmm <- HMM$new(obs = obs, hid = hid)

# Fit the model
hmm$fit(silent = FALSE)

# -----------------------------------------------------------------------------
# 3. INSPECT RESULTS
# -----------------------------------------------------------------------------

# Parameter estimates
hmm$par()

# State-dependent distributions
hmm$obs$par()

# Transition probability matrix
hmm$hid$par()

# Decode most likely state sequence (Viterbi)
hmm_data$predicted_state <- factor(hmm$viterbi())

# State probabilities over time
state_probs <- hmm$state_probs()
hmm_data <- hmm_data |>
  mutate(
    prob_state1 = state_probs[, 1],
    prob_state2 = state_probs[, 2],
    prob_state3 = state_probs[, 3]
  )

# -----------------------------------------------------------------------------
# 4. VISUALISE HMM RESULTS
# -----------------------------------------------------------------------------

# Timeline: true vs predicted
p_timeline <- hmm_data |>
  dplyr::select(time, true_state, predicted_state) |>
  pivot_longer(-time, names_to = "source", values_to = "state") |>
  ggplot(aes(x = time / 60, y = source, fill = state)) +
  geom_tile(height = 0.8) +
  scale_fill_brewer(palette = "Set2") +
  labs(x = "Time (min)", y = NULL, title = "True vs HMM-predicted states") +
  theme_minimal()

# State probabilities over time
p_probs <- hmm_data |>
  dplyr::select(time, starts_with("prob_")) |>
  pivot_longer(
    -time,
    names_to = "state",
    values_to = "probability",
    names_prefix = "prob_"
  ) |>
  ggplot(aes(x = time / 60, y = probability, colour = state)) +
  geom_line(alpha = 0.7) +
  labs(x = "Time (min)", y = "P(state)", title = "State probabilities") +
  theme_minimal()

# Observations coloured by predicted state
p_obs <- hmm_data |>
  pivot_longer(starts_with("power_"), names_to = "band", values_to = "power") |>
  ggplot(aes(x = time / 60, y = power, colour = predicted_state)) +
  geom_line(linewidth = 0.3) +
  facet_wrap(~band, ncol = 1, scales = "free_y") +
  labs(x = "Time (min)", title = "Band power with HMM states") +
  theme_minimal()

p_timeline / p_probs / p_obs

# -----------------------------------------------------------------------------
# 5. EVALUATE FIT
# -----------------------------------------------------------------------------

# Confusion matrix (need to align state labels first)
# HMM states are arbitrary - find best mapping to true states
library(mclust)

ari <- adjustedRandIndex(
  as.numeric(hmm_data$true_state),
  as.numeric(hmm_data$predicted_state)
)
cat("Adjusted Rand Index:", round(ari, 3), "\n")

# Cross-tabulation
table(true = hmm_data$true_state, predicted = hmm_data$predicted_state)

# -----------------------------------------------------------------------------
# 6. MODEL SELECTION - HOW MANY STATES?
# -----------------------------------------------------------------------------

fit_hmm_nstates <- function(data, n_states) {
  # Helper to convert mean/sd to shape/scale for gamma
  gamma_params <- function(mean, sd) {
    shape <- mean^2 / sd^2
    scale <- sd^2 / mean
    list(shape = shape, scale = scale)
  }

  # Initial parameters scaled by number of states
  means <- seq(0.5, 2.5, length.out = n_states)
  sds <- seq(0.3, 1, length.out = n_states)

  # Convert to shape/scale
  params <- purrr::map2(means, sds, gamma_params)
  shapes <- purrr::map_dbl(params, "shape")
  scales <- purrr::map_dbl(params, "scale")

  obs <- Observation$new(
    data = data,
    n_states = n_states,
    dists = list(
      power_slow = "gamma",
      power_medium = "gamma",
      power_fast = "gamma"
    ),
    par = list(
      power_slow = list(shape = shapes, scale = scales),
      power_medium = list(shape = shapes * 0.8, scale = scales * 0.8),
      power_fast = list(shape = shapes * 0.6, scale = scales * 0.6)
    )
  )

  hid <- MarkovChain$new(data = data, n_states = n_states)
  hmm <- HMM$new(obs = obs, hid = hid)

  tryCatch(
    {
      hmm$fit(silent = TRUE)
      list(
        hmm = hmm,
        AIC = AIC(hmm),
        BIC = BIC(hmm),
        n_states = n_states
      )
    },
    error = function(e) {
      list(
        hmm = NULL,
        AIC = NA,
        BIC = NA,
        n_states = n_states,
        error = e$message
      )
    }
  )
}

# Now run the comparison
model_comparison <- purrr::map(2:5, \(n) {
  cat("  n_states =", n, "\n")
  fit_hmm_nstates(hmm_data, n)
})

# Compare
comparison_df <- tibble(
  n_states = map_int(model_comparison, "n_states"),
  AIC = map_dbl(model_comparison, "AIC"),
  BIC = map_dbl(model_comparison, "BIC")
)
print(comparison_df)

# Plot
comparison_df |>
  pivot_longer(c(AIC, BIC), names_to = "criterion", values_to = "value") |>
  ggplot(aes(x = n_states, y = value, colour = criterion)) +
  geom_line() +
  geom_point(size = 3) +
  labs(
    x = "Number of states",
    y = "Information criterion",
    title = "Model selection"
  ) +
  theme_minimal()

# -----------------------------------------------------------------------------
# 7. MORE COMPLEX MODEL: INCLUDING AREA FEATURES
# -----------------------------------------------------------------------------

# Helper function
gamma_params <- function(mean, sd) {
  shape <- mean^2 / sd^2
  scale <- sd^2 / mean
  list(shape = shape, scale = scale)
}

# Convert parameters for each variable
convert_params <- function(means, sds) {
  params <- purrr::map2(means, sds, gamma_params)
  list(
    shape = purrr::map_dbl(params, "shape"),
    scale = purrr::map_dbl(params, "scale")
  )
}

obs_full <- Observation$new(
  data = hmm_data,
  n_states = 3,
  dists = list(
    power_slow = "gamma",
    power_medium = "gamma",
    power_fast = "gamma",
    area_slow = "gamma",
    area_medium = "gamma",
    area_fast = "gamma"
  ),
  par = list(
    power_slow = convert_params(c(0.5, 1, 2), c(0.3, 0.5, 1)),
    power_medium = convert_params(c(0.3, 1, 2), c(0.2, 0.5, 1)),
    power_fast = convert_params(c(0.2, 0.8, 1.5), c(0.2, 0.4, 0.8)),
    area_slow = convert_params(c(0.5, 1, 2), c(0.3, 0.5, 1)),
    area_medium = convert_params(c(0.3, 1, 2), c(0.2, 0.5, 1)),
    area_fast = convert_params(c(0.2, 0.8, 1.5), c(0.2, 0.4, 0.8))
  )
)

hid_full <- MarkovChain$new(data = hmm_data, n_states = 3)
hmm_full <- HMM$new(obs = obs_full, hid = hid_full)
hmm_full$fit(silent = FALSE)

hmm_data$predicted_full <- factor(hmm_full$viterbi())

# Compare simple vs full model
cat("\nSimple model (3 features):\n")
cat("  AIC:", AIC(hmm), "\n")
cat(
  "  ARI:",
  adjustedRandIndex(
    as.numeric(hmm_data$true_state),
    as.numeric(hmm_data$predicted_state)
  ),
  "\n"
)

cat(
  "\nFull model (6 features):\n
"
)
cat("  AIC:", AIC(hmm_full), "\n")
cat(
  "  ARI:",
  adjustedRandIndex(
    as.numeric(hmm_data$true_state),
    as.numeric(hmm_data$predicted_full)
  ),
  "\n"
)

# -----------------------------------------------------------------------------
# 8. COVARIATE-DEPENDENT TRANSITIONS (ADVANCED)
# -----------------------------------------------------------------------------

# You can also model transition probabilities as functions of covariates
# e.g., time of day might affect transition rates

hmm_data <- hmm_data |>
  mutate(
    time_of_day = (time %% (24 * 60)) / (24 * 60), # Normalised 0-1
    is_night = time_of_day > 0.75 | time_of_day < 0.25
  )

# Transition probabilities depend on time of day
hid_covar <- MarkovChain$new(
  data = hmm_data,
  n_states = 3,
  formula = ~ cos(2 * pi * time_of_day) + sin(2 * pi * time_of_day)
)

hmm_covar <- HMM$new(obs = obs, hid = hid_covar)
hmm_covar$fit(silent = FALSE)

cat("\nModel with time-varying transitions:\n")
cat("  AIC:", AIC(hmm_covar), "\n")
