library(dplyr)
library(ggplot2)

# Simulate movement-like data: slow postural sway + faster movement + noise
set.seed(42)
n <- 512
t <- seq(0, 4, length.out = n)
slow_component <- sin(2 * pi * 0.5 * t) # 0.5 Hz - slow sway
fast_component <- 0.5 * sin(2 * pi * 4 * t) # 4 Hz - faster movement
burst <- ifelse(t > 1.5 & t < 2, sin(2 * pi * 10 * t), 0) # Brief 10 Hz burst
noise <- rnorm(n, sd = 0.2)

signal <- slow_component + fast_component + burst + noise

# Quick look at the signal
plot(
  t,
  signal,
  type = "l",
  main = "Simulated movement signal",
  xlab = "Time (s)",
  ylab = "Position"
)


library(wavelets)

dwt_result <- dwt(signal, filter = "la8", n.levels = 5)

# Visualise each level
par(mfrow = c(7, 1), mar = c(2, 4, 1, 1))

plot(t, signal, type = "l", ylab = "Original", xaxt = "n")

for (i in 1:5) {
  # Access by name, not index
  detail <- dwt_result@W[[paste0("W", i)]]
  detail_upsampled <- rep(detail, each = 2^i)
  detail_upsampled <- detail_upsampled[1:n]
  plot(
    t,
    detail_upsampled,
    type = "l",
    ylab = paste0("D", i, " (", 2^i, "x)"),
    xaxt = if (i < 5) "n" else "s"
  )
}

# Same fix for the approximation
approx <- dwt_result@V[[paste0("V", 5)]]
approx_upsampled <- rep(approx, each = 2^5)[1:n]
plot(t, approx_upsampled, type = "l", ylab = "A5 (smooth)")


library(WaveletComp)

# Create data frame (WaveletComp expects this format)
dat <- data.frame(time = t, signal = signal)

# Continuous wavelet transform with Morlet wavelet
wt <- analyze.wavelet(
  dat,
  "signal",
  loess.span = 0, # No detrending
  dt = t[2] - t[1], # Time step
  dj = 1 / 20, # Frequency resolution
  lowerPeriod = 0.05, # Shortest period to analyse
  upperPeriod = 2, # Longest period
  make.pval = FALSE, # Skip significance testing for speed
  verbose = FALSE
)

# Plot the spectrogram
wt.image(
  wt,
  color.key = "interval",
  n.levels = 250,
  legend.params = list(lab = "Power"),
  timelab = "Time (s)",
  periodlab = "Period (s)",
  main = "Wavelet Power Spectrum"
)


# Check the actual structure
str(wt$Power)
str(wt$axis.1) # Time axis
str(wt$axis.2) # Period axis

power_df <- tidyr::expand_grid(
  time_idx = seq_along(wt$axis.1),
  period_idx = seq_along(wt$Period)
) |>
  mutate(
    time = wt$axis.1[time_idx],
    period = wt$Period[period_idx],
    power = as.vector(power_matrix)
  ) |>
  filter(power > 0)

ggplot(power_df, aes(x = time, y = period, fill = log10(power))) +
  geom_tile() +
  scale_fill_viridis_c(name = "log10(Power)") +
  scale_y_log10() +
  labs(
    x = "Time (s)",
    y = "Period (s)",
    title = "Continuous Wavelet Transform",
    subtitle = "Morlet wavelet spectrogram"
  ) +
  theme_minimal()


# Average power at each period (across all time points)
global_power <- rowMeans(wt$Power)

global_spectrum <- tibble(
  period = wt$Period,
  frequency = 1 / wt$Period,
  power = global_power
)

# Plot it
ggplot(global_spectrum, aes(x = frequency, y = power)) +
  geom_line() +
  scale_x_log10() +
  labs(
    x = "Frequency (Hz)",
    y = "Mean power",
    title = "Global Wavelet Spectrum"
  ) +
  theme_minimal()


# Simple peak detection: find local maxima
find_peaks <- function(x, threshold = 0.1) {
  # A point is a peak if it's greater than both neighbours
  # and above threshold * max
  n <- length(x)
  is_peak <- x[2:(n - 1)] > x[1:(n - 2)] &
    x[2:(n - 1)] > x[3:n] &
    x[2:(n - 1)] > threshold * max(x)
  which(is_peak) + 1 # Offset because we started at index 2
}

peak_idx <- find_peaks(global_power, threshold = 0.2)

dominant_timescales <- tibble(
  period = wt$Period[peak_idx],
  frequency = 1 / wt$Period[peak_idx],
  power = global_power[peak_idx]
) |>
  arrange(desc(power))

dominant_timescales
# Expected output (approximately):
#   period frequency power
#    0.25       4.0   ...   <- fast component
#    2.0        0.5   ...   <- slow component
#    0.1       10.0   ...   <- burst (weaker because it's brief)

# Find the row index closest to 10 Hz (period = 0.1s)
target_period <- 0.1
period_idx <- which.min(abs(wt$Period - target_period))

power_at_10hz <- tibble(
  time = wt$axis.1,
  power = wt$Power[period_idx, ]
)

ggplot(power_at_10hz, aes(x = time, y = power)) +
  geom_line() +
  labs(
    x = "Time (s)",
    y = "Power",
    title = paste0(
      "Power at ~",
      round(1 / wt$Period[period_idx], 1),
      " Hz over time"
    )
  ) +
  theme_minimal()
