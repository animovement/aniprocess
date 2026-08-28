# =============================================================================
# HMM VISUALISATION
# =============================================================================

library(patchwork)

# -----------------------------------------------------------------------------
# 1. State-dependent distributions
# -----------------------------------------------------------------------------

# Get fitted parameters
fitted_params <- hmm_full$par()
print(fitted_params)

# Extract shape/scale for each variable and state, then compute densities
variables <- c(
  "power_slow",
  "power_medium",
  "power_fast",
  "area_slow",
  "area_medium",
  "area_fast"
)

# Build density curves for each variable and state
density_curves <- purrr::map_dfr(variables, \(var) {
  # Get the parameter estimates for this variable
  # The structure depends on hmmTMB version, so let's extract from the data

  # Fit gamma to each state's data empirically for visualisation
  purrr::map_dfr(1:3, \(state) {
    state_data <- hmm_data |>
      filter(predicted_full == state) |>
      pull(!!sym(var))

    if (length(state_data) < 10) {
      return(NULL)
    }

    # Fit gamma parameters
    mean_val <- mean(state_data, na.rm = TRUE)
    var_val <- var(state_data, na.rm = TRUE)
    shape <- mean_val^2 / var_val
    scale <- var_val / mean_val

    # Generate density curve
    x_range <- seq(
      0.01,
      quantile(hmm_data[[var]], 0.99, na.rm = TRUE),
      length.out = 200
    )

    tibble(
      variable = var,
      state = factor(state),
      x = x_range,
      density = dgamma(x_range, shape = shape, scale = scale)
    )
  })
})

# Add observed data histograms
p_distributions <- ggplot() +
  geom_histogram(
    data = hmm_data |>
      pivot_longer(
        all_of(variables),
        names_to = "variable",
        values_to = "value"
      ) |>
      mutate(state = predicted_full),
    aes(x = value, y = after_stat(density), fill = state),
    alpha = 0.3,
    position = "identity",
    bins = 30
  ) +
  geom_line(
    data = density_curves,
    aes(x = x, y = density, colour = state),
    linewidth = 1
  ) +
  facet_wrap(~variable, scales = "free", ncol = 3) +
  scale_fill_brewer(palette = "Set2") +
  scale_colour_brewer(palette = "Set2") +
  labs(
    title = "State-dependent distributions",
    subtitle = "Histograms show observed data; lines show fitted gamma distributions",
    x = "Value",
    y = "Density"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

p_distributions

# -----------------------------------------------------------------------------
# 2. Transition probability matrix
# -----------------------------------------------------------------------------

tpm <- hmm_full$tpm()
print(tpm)

tpm_df <- as.data.frame(tpm) |>
  mutate(from_state = factor(row_number())) |>
  pivot_longer(-from_state, names_to = "to_state", values_to = "probability") |>
  mutate(to_state = factor(parse_number(to_state)))

p_tpm <- ggplot(tpm_df, aes(x = to_state, y = from_state, fill = probability)) +
  geom_tile(colour = "white", linewidth = 1) +
  geom_text(
    aes(label = sprintf("%.2f", probability)),
    colour = "white",
    size = 5
  ) +
  scale_fill_viridis_c(option = "magma", limits = c(0, 1)) +
  scale_y_discrete(limits = rev) +
  labs(
    title = "Transition probability matrix",
    x = "To state",
    y = "From state",
    fill = "P(transition)"
  ) +
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    legend.position = "right"
  ) +
  coord_equal()

p_tpm

# -----------------------------------------------------------------------------
# 3. State probabilities over time
# -----------------------------------------------------------------------------

state_probs <- hmm_full$state_probs()

hmm_data <- hmm_data |>
  mutate(
    prob_state1 = state_probs[, 1],
    prob_state2 = state_probs[, 2],
    prob_state3 = state_probs[, 3]
  )

p_state_probs <- hmm_data |>
  select(time, starts_with("prob_state")) |>
  pivot_longer(
    -time,
    names_to = "state",
    values_to = "probability",
    names_prefix = "prob_state"
  ) |>
  mutate(state = factor(state)) |>
  ggplot(aes(x = time / 60, y = probability, fill = state)) +
  geom_area(alpha = 0.8) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "State probabilities over time",
    x = "Time (min)",
    y = "P(state)",
    fill = "State"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

p_state_probs

# -----------------------------------------------------------------------------
# 4. Timeline: true vs predicted states
# -----------------------------------------------------------------------------

p_timeline <- hmm_data |>
  select(time, true_state, predicted_full) |>
  rename(True = true_state, Predicted = predicted_full) |>
  pivot_longer(-time, names_to = "source", values_to = "state") |>
  ggplot(aes(x = time / 60, y = source, fill = state)) +
  geom_tile(height = 0.8) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "True vs HMM-predicted states",
    x = "Time (min)",
    y = NULL,
    fill = "State"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

p_timeline

# -----------------------------------------------------------------------------
# 5. Observations coloured by predicted state
# -----------------------------------------------------------------------------

p_obs <- hmm_data |>
  pivot_longer(all_of(variables), names_to = "band", values_to = "power") |>
  mutate(
    band = factor(band, levels = variables),
    type = if_else(str_starts(band, "power"), "Velocity", "Area")
  ) |>
  ggplot(aes(x = time / 60, y = power, colour = predicted_full)) +
  geom_line(linewidth = 0.3, alpha = 0.7) +
  facet_wrap(~band, ncol = 3, scales = "free_y") +
  scale_colour_brewer(palette = "Set2") +
  labs(
    title = "Band power over time",
    subtitle = "Coloured by HMM-predicted state",
    x = "Time (min)",
    y = "Power (log)",
    colour = "State"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

p_obs

# -----------------------------------------------------------------------------
# 6. State transition diagram (network-style)
# -----------------------------------------------------------------------------

# Requires ggraph and tidygraph
if (
  requireNamespace("ggraph", quietly = TRUE) &&
    requireNamespace("tidygraph", quietly = TRUE)
) {
  library(tidygraph)
  library(ggraph)

  # Create edges from TPM
  edges <- tpm_df |>
    filter(probability > 0.01) |>
    rename(from = from_state, to = to_state, weight = probability)

  # Create nodes
  nodes <- tibble(
    name = factor(1:3),
    stationary = hmm_full$stationary()[1, ]
  )

  # Build graph
  graph <- tbl_graph(nodes = nodes, edges = edges, directed = TRUE)

  p_network <- ggraph(graph, layout = "circle") +
    geom_edge_arc(
      aes(width = weight, alpha = weight),
      arrow = arrow(length = unit(3, "mm"), type = "closed"),
      start_cap = circle(8, "mm"),
      end_cap = circle(8, "mm"),
      colour = "grey40"
    ) +
    geom_node_point(
      aes(size = stationary, fill = name),
      shape = 21,
      colour = "white"
    ) +
    geom_node_text(aes(label = name), colour = "white", fontface = "bold") +
    scale_edge_width(range = c(0.5, 2), guide = "none") +
    scale_edge_alpha(range = c(0.3, 1), guide = "none") +
    scale_size(range = c(15, 25), guide = "none") +
    scale_fill_brewer(palette = "Set2", guide = "none") +
    labs(
      title = "State transition diagram",
      subtitle = "Node size = stationary probability; edge width = transition probability"
    ) +
    theme_void()

  p_network
}

# -----------------------------------------------------------------------------
# 7. Combined summary figure
# -----------------------------------------------------------------------------

# Layout with patchwork
layout <- "
AAAAAA
AAAAAA
BBCCCC
BBCCCC
DDDDDD
"

p_summary <- p_distributions +
  p_tpm +
  p_state_probs +
  p_timeline +
  plot_layout(design = layout) +
  plot_annotation(
    title = "HMM Analysis Summary",
    subtitle = "6-feature model with 3 hidden states",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 12)
    )
  )

p_summary

# -----------------------------------------------------------------------------
# 8. Model diagnostics: pseudo-residuals
# -----------------------------------------------------------------------------

# Pseudo-residuals should be ~N(0,1) if model fits well
pseudo_res <- hmm_full$pseudo_residuals()

if (!is.null(pseudo_res)) {
  pseudo_res_df <- as.data.frame(pseudo_res) |>
    mutate(time = hmm_data$time) |>
    pivot_longer(-time, names_to = "variable", values_to = "residual")

  # QQ plot
  p_qq <- ggplot(pseudo_res_df, aes(sample = residual)) +
    geom_qq(alpha = 0.3, size = 0.5) +
    geom_qq_line(colour = "red") +
    facet_wrap(~variable, ncol = 3) +
    labs(
      title = "Pseudo-residual QQ plots",
      subtitle = "Should follow diagonal line if model fits well"
    ) +
    theme_minimal()

  # Residuals over time
  p_res_time <- ggplot(pseudo_res_df, aes(x = time / 60, y = residual)) +
    geom_point(alpha = 0.2, size = 0.5) +
    geom_hline(yintercept = c(-2, 2), linetype = "dashed", colour = "red") +
    facet_wrap(~variable, ncol = 3) +
    labs(
      title = "Pseudo-residuals over time",
      subtitle = "Should show no pattern; most points within +/- 2",
      x = "Time (min)",
      y = "Pseudo-residual"
    ) +
    theme_minimal()

  p_qq / p_res_time
}
