# Packages
library(tidyverse)
library(WaveletComp)
library(umap)
library(Rtsne)
library(dbscan)
library(MASS)
library(patchwork)

# =============================================================================
# 1. SIMULATE SPIDER SLEEP DATA
# =============================================================================

# Simulate ~30 minutes at 10 fps
set.seed(42)
fps <- 10
duration <- 30 * 60 # seconds
n_frames <- duration * fps
time <- seq(0, duration, length.out = n_frames)

# Define sleep states as blocks
# Each state has different characteristics for area and movement
state_duration <- 300 # 5-minute blocks
n_blocks <- duration / state_duration
true_states <- rep(
  sample(
    c("deep_sleep", "rem", "awake"),
    n_blocks,
    replace = TRUE,
    prob = c(0.5, 0.2, 0.3)
  ),
  each = state_duration * fps
)[1:n_frames]

# Generate metrics based on state
generate_metrics <- function(time, states, fps) {
  n <- length(time)

  # Base area (spider size in pixels)
  base_area <- 5000

  # Initialise
  area <- numeric(n)

  for (i in seq_len(n)) {
    state <- states[i]

    if (state == "deep_sleep") {
      # Very stable, minimal fluctuation
      area[i] <- base_area + rnorm(1, sd = 20)
    } else if (state == "rem") {
      # Occasional twitches: baseline stable but with random bursts
      is_twitch <- runif(1) < 0.03 # 3% chance of twitch per frame
      if (is_twitch) {
        area[i] <- base_area + sample(c(-1, 1), 1) * runif(1, 200, 500)
      } else {
        area[i] <- base_area + rnorm(1, sd = 30)
      }
    } else {
      # Awake: larger, more sustained movements
      # Add slow oscillations + medium noise
      area[i] <- base_area +
        200 * sin(2 * pi * 0.1 * time[i]) + # Slow movement rhythm
        rnorm(1, sd = 80)
    }
  }

  # Smooth slightly to simulate realistic tracking
  area <- stats::filter(area, rep(1 / 3, 3), sides = 2) |> as.numeric()
  area[is.na(area)] <- base_area

  # Compute derived metrics
  centroid_x <- cumsum(c(
    0,
    rnorm(
      n - 1,
      sd = ifelse(
        states[-n] == "deep_sleep",
        0.5,
        ifelse(states[-n] == "rem", 1, 3)
      )
    )
  ))
  centroid_y <- cumsum(c(
    0,
    rnorm(
      n - 1,
      sd = ifelse(
        states[-n] == "deep_sleep",
        0.5,
        ifelse(states[-n] == "rem", 1, 3)
      )
    )
  ))

  tibble(
    time = time,
    true_state = factor(states, levels = c("deep_sleep", "rem", "awake")),
    area = area,
    centroid_x = centroid_x,
    centroid_y = centroid_y,
    velocity = sqrt(c(0, diff(centroid_x))^2 + c(0, diff(centroid_y))^2),
    area_change = abs(c(0, diff(area)))
  )
}

metrics <- generate_metrics(time, true_states, fps)

# Quick look at the data
p_area <- ggplot(metrics, aes(x = time / 60, y = area, colour = true_state)) +
  geom_line(linewidth = 0.3) +
  labs(
    x = "Time (min)",
    y = "Area (px)",
    title = "Simulated bounding box area"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

p_velocity <- ggplot(
  metrics,
  aes(x = time / 60, y = velocity, colour = true_state)
) +
  geom_line(linewidth = 0.3) +
  labs(
    x = "Time (min)",
    y = "Velocity (px/frame)",
    title = "Centroid velocity"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

p_area / p_velocity

# =============================================================================
# 2. WAVELET TRANSFORM
# =============================================================================

# Variables to analyse
variables <- c("area_change", "velocity")

# Compute wavelet for each variable
compute_wavelet <- function(data, var, dt) {
  analyze.wavelet(
    data,
    var,
    loess.span = 0,
    dt = dt,
    dj = 1 / 12, # Frequency resolution
    lowerPeriod = 0.2, # 0.2 seconds (5 Hz max)
    upperPeriod = 30, # 30 seconds
    make.pval = FALSE,
    verbose = FALSE
  )
}

dt <- median(diff(metrics$time))
cat("Computing wavelet transforms...\n")

wt_list <- map(
  variables,
  \(var) {
    cat("  ", var, "\n")
    compute_wavelet(metrics, var, dt)
  },
  .progress = FALSE
)
names(wt_list) <- variables

# Visualise one of them
wt.image(
  wt_list$velocity,
  color.key = "interval",
  n.levels = 100,
  main = "Velocity spectrogram"
)

# =============================================================================
# 3. BUILD FEATURE MATRIX
# =============================================================================

# Concatenate power spectra from all variables
combined_power <- do.call(rbind, map(wt_list, ~ .x$Power))

cat("Power matrix dimensions:", dim(combined_power), "\n")
cat(
  "  ",
  nrow(combined_power),
  "frequency bands ×",
  ncol(combined_power),
  "time points\n"
)

# Transpose: rows = time points, columns = features
feature_matrix <- t(combined_power)

# Log transform and scale
feature_matrix <- log1p(feature_matrix)
feature_matrix <- scale(feature_matrix)

# Handle any NA/Inf from scaling
feature_matrix[!is.finite(feature_matrix)] <- 0

# Create feature labels for reference
feature_labels <- expand_grid(
  variable = variables,
  period = wt_list[[1]]$Period
) |>
  mutate(
    frequency = 1 / period,
    feature_name = paste0(variable, "_", round(frequency, 3), "Hz")
  )

# =============================================================================
# 4. DIMENSIONALITY REDUCTION - THREE METHODS
# =============================================================================

# Match time points
n_timepoints <- ncol(combined_power)
time_subset <- wt_list[[1]]$axis.1

# Get corresponding true states
state_idx <- map_int(time_subset, \(t) which.min(abs(metrics$time - t)))
true_states_subset <- metrics$true_state[state_idx]

# ---- PCA ----
cat("Running PCA...\n")
pca_result <- prcomp(feature_matrix, center = TRUE, scale. = TRUE)

# Check variance explained
var_explained <- summary(pca_result)$importance[2, 1:10]
cat("Variance explained by first 10 PCs:\n")
print(round(var_explained * 100, 1))

# ---- t-SNE ----
cat("Running t-SNE...\n")
set.seed(123)
tsne_result <- Rtsne(
  feature_matrix,
  dims = 2,
  perplexity = 50,
  max_iter = 1000,
  verbose = FALSE,
  check_duplicates = FALSE
)

# ---- UMAP ----
cat("Running UMAP...\n")
set.seed(123)
umap_config <- umap.defaults
umap_config$n_neighbors <- 30
umap_config$min_dist <- 0.1
umap_result <- umap(feature_matrix, config = umap_config)

# Combine results
embedding <- tibble(
  time = time_subset,
  true_state = true_states_subset,
  pca_1 = pca_result$x[, 1],
  pca_2 = pca_result$x[, 2],
  tsne_1 = tsne_result$Y[, 1],
  tsne_2 = tsne_result$Y[, 2],
  umap_1 = umap_result$layout[, 1],
  umap_2 = umap_result$layout[, 2]
)

# Compare embeddings
p_pca <- ggplot(embedding, aes(x = pca_1, y = pca_2, colour = true_state)) +
  geom_point(size = 0.5, alpha = 0.5) +
  labs(title = "PCA", x = "PC1", y = "PC2", colour = "True state") +
  theme_minimal() +
  theme(legend.position = "none")

p_tsne <- ggplot(embedding, aes(x = tsne_1, y = tsne_2, colour = true_state)) +
  geom_point(size = 0.5, alpha = 0.5) +
  labs(title = "t-SNE", colour = "True state") +
  theme_minimal() +
  theme(legend.position = "none")

p_umap <- ggplot(embedding, aes(x = umap_1, y = umap_2, colour = true_state)) +
  geom_point(size = 0.5, alpha = 0.5) +
  labs(title = "UMAP", colour = "True state") +
  theme_minimal() +
  theme(legend.position = "bottom")

(p_pca | p_tsne | p_umap) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

# =============================================================================
# 5. CLUSTERING - WITH SEPARATE PLOTS
# =============================================================================

# Cluster on UMAP embedding
embedding_matrix <- embedding[, c("pca_1", "pca_2")] |> as.matrix()

# ---- HDBSCAN ----
cat("Running HDBSCAN...\n")
hdb <- hdbscan(embedding_matrix, minPts = 100)
embedding$cluster_hdbscan <- factor(hdb$cluster)

# ---- k-means ----
cat("Running k-means...\n")
set.seed(123)
km <- kmeans(embedding_matrix, centers = 3, nstart = 25)
embedding$cluster_kmeans <- factor(km$cluster)

# ---- GMM ----
cat("Running GMM...\n")
gmm <- Mclust(embedding_matrix, G = 3, verbose = FALSE)
embedding$cluster_gmm <- factor(gmm$classification)

# ---- Watershed ----
cat("Running watershed...\n")
kde <- kde2d(
  embedding$umap_1,
  embedding$umap_2,
  n = 150,
  lims = c(
    range(embedding$umap_1) + c(-1, 1) * diff(range(embedding$umap_1)) * 0.1,
    range(embedding$umap_2) + c(-1, 1) * diff(range(embedding$umap_2)) * 0.1
  )
)

# Smooth density
smooth_density <- function(z, kernel_size = 7) {
  kernel <- outer(
    dnorm(seq(-2, 2, length.out = kernel_size)),
    dnorm(seq(-2, 2, length.out = kernel_size))
  )
  kernel <- kernel / sum(kernel)

  padded <- matrix(0, nrow(z) + kernel_size - 1, ncol(z) + kernel_size - 1)
  offset <- (kernel_size - 1) / 2
  padded[(offset + 1):(offset + nrow(z)), (offset + 1):(offset + ncol(z))] <- z

  result <- matrix(0, nrow(z), ncol(z))
  for (i in seq_len(nrow(z))) {
    for (j in seq_len(ncol(z))) {
      result[i, j] <- sum(
        padded[i:(i + kernel_size - 1), j:(j + kernel_size - 1)] * kernel
      )
    }
  }
  result
}

kde$z <- smooth_density(kde$z, kernel_size = 9)

if (requireNamespace("EBImage", quietly = TRUE)) {
  density_image <- EBImage::as.Image(kde$z / max(kde$z))
  ws <- EBImage::watershed(1 - density_image, tolerance = 0.1) # Increased tolerance

  embedding$cluster_watershed <- map2_int(
    embedding$umap_1,
    embedding$umap_2,
    \(x, y) {
      xi <- which.min(abs(kde$x - x))
      yi <- which.min(abs(kde$y - y))
      ws[xi, yi]
    }
  ) |>
    factor()
} else {
  embedding$cluster_watershed <- factor(NA)
}

# =============================================================================
# 6. PLOT EACH CLUSTERING METHOD SEPARATELY
# =============================================================================

# Helper function for consistent styling
plot_clustering <- function(data, cluster_col, title) {
  n_clusters <- n_distinct(data[[cluster_col]], na.rm = TRUE)

  # Choose appropriate palette based on number of clusters
  if (n_clusters <= 8) {
    colours <- RColorBrewer::brewer.pal(max(3, n_clusters), "Set2")[
      1:n_clusters
    ]
  } else {
    colours <- viridis::viridis(n_clusters)
  }

  ggplot(data, aes(x = pca_1, y = pca_2, colour = .data[[cluster_col]])) +
    geom_point(size = 0.5, alpha = 0.5) +
    scale_colour_manual(values = colours, drop = FALSE) +
    labs(title = title, colour = "Cluster", x = "tSNE 1", y = "tSNE 2") +
    theme_minimal() +
    theme(
      legend.position = "right",
      legend.key.size = unit(0.4, "cm"),
      plot.title = element_text(size = 11, face = "bold")
    ) +
    guides(colour = guide_legend(override.aes = list(size = 2, alpha = 1)))
}

# Also plot true states for reference
p_true <- ggplot(embedding, aes(x = pca_1, y = pca_2, colour = true_state)) +
  geom_point(size = 0.5, alpha = 0.5) +
  scale_colour_brewer(palette = "Set2") +
  labs(title = "True states", colour = "State", x = "UMAP 1", y = "UMAP 2") +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.key.size = unit(0.4, "cm"),
    plot.title = element_text(size = 11, face = "bold")
  ) +
  guides(colour = guide_legend(override.aes = list(size = 2, alpha = 1)))

p_hdbscan <- plot_clustering(embedding, "cluster_hdbscan", "HDBSCAN")
p_kmeans <- plot_clustering(embedding, "cluster_kmeans", "k-means (k=3)")
p_gmm <- plot_clustering(embedding, "cluster_gmm", "GMM (G=3)")
p_watershed <- plot_clustering(embedding, "cluster_watershed", "Watershed")

# Combine with patchwork
(p_true | p_kmeans) /
  (p_gmm | p_hdbscan) /
  (p_watershed | plot_spacer()) +
  plot_annotation(
    title = "Clustering comparison on UMAP embedding",
    theme = theme(plot.title = element_text(size = 14, face = "bold"))
  )

# =============================================================================
# 7. EVALUATE CLUSTERING AGAINST TRUE STATES
# =============================================================================

# Adjusted Rand Index - measures agreement between clusterings
library(fossil) # For adj.rand.index, or use mclust::adjustedRandIndex

evaluate_clustering <- function(true_labels, predicted_labels) {
  # Remove noise points (cluster 0) from HDBSCAN
  valid <- predicted_labels != 0 & !is.na(predicted_labels)
  if (sum(valid) < 10) {
    return(NA)
  }

  mclust::adjustedRandIndex(
    as.numeric(true_labels[valid]),
    as.numeric(predicted_labels[valid])
  )
}

ari_scores <- tibble(
  method = c("hdbscan", "kmeans", "gmm", "watershed"),
  ari = c(
    evaluate_clustering(embedding$true_state, embedding$cluster_hdbscan),
    evaluate_clustering(embedding$true_state, embedding$cluster_kmeans),
    evaluate_clustering(embedding$true_state, embedding$cluster_gmm),
    evaluate_clustering(embedding$true_state, embedding$cluster_watershed)
  )
)

print(ari_scores)

# =============================================================================
# 8. VISUALISE STATE TIMELINE
# =============================================================================

# Pick best clustering method (or just use one)
best_method <- ari_scores |> slice_max(ari, n = 1) |> pull(method)
cat("Best clustering method:", best_method, "\n")

embedding$predicted_state <- embedding[[paste0("cluster_", best_method)]]

# Timeline comparison
timeline_df <- embedding |>
  dplyr::select(time, true_state, predicted_state) |>
  pivot_longer(-time, names_to = "source", values_to = "state")

p_timeline <- ggplot(
  timeline_df,
  aes(x = time / 60, y = source, fill = state)
) +
  geom_tile(height = 0.8) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    x = "Time (min)",
    y = NULL,
    title = "True vs predicted states over time",
    fill = "State"
  ) +
  theme_minimal()

p_timeline

# =============================================================================
# 9. SUMMARY VISUALISATION
# =============================================================================

# Power in different frequency bands over time
get_band_power <- function(wt, freq_range) {
  freq <- 1 / wt$Period
  in_band <- freq >= freq_range[1] & freq <= freq_range[2]
  if (!any(in_band)) {
    return(rep(NA, ncol(wt$Power)))
  }
  colMeans(wt$Power[in_band, , drop = FALSE])
}

band_power <- tibble(
  time = time_subset,
  true_state = true_states_subset,
  slow = get_band_power(wt_list$velocity, c(0.03, 0.1)),
  medium = get_band_power(wt_list$velocity, c(0.1, 0.5)),
  fast = get_band_power(wt_list$velocity, c(0.5, 3))
) |>
  pivot_longer(c(slow, medium, fast), names_to = "band", values_to = "power") |>
  mutate(band = factor(band, levels = c("slow", "medium", "fast")))

p_bands <- ggplot(
  band_power,
  aes(x = time / 60, y = power, colour = true_state)
) +
  geom_line(linewidth = 0.3, alpha = 0.7) +
  facet_wrap(~band, ncol = 1, scales = "free_y") +
  labs(
    x = "Time (min)",
    y = "Power",
    title = "Power in frequency bands",
    colour = "True state"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

p_bands

# =============================================================================
# 10. FULL SUMMARY FIGURE
# =============================================================================

(p_area / p_velocity) | (p_umap / p_timeline)
