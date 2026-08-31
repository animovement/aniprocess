# Reflection padding, and the trim that undoes it.
#
# Filters see a discontinuity at the ends of a signal and ring at the edges;
# mirroring some of the signal outward gives them something continuous to chew
# on, and the padding is discarded afterwards. The pad can only be as long as
# the signal it mirrors, so the width asked for is not always the width applied
# -- and the trim has to use the width applied. Keeping both in one place is
# what stops them disagreeing.

#' Mirror the ends of a signal outward
#'
#' @param x A numeric vector.
#' @param n_pad Desired pad width. Clamped to `length(x)`, since a reflection
#'   cannot be longer than what it reflects.
#' @return `x` with mirrored padding at both ends, carrying the applied pad
#'   width as the integer attribute `pad`.
#' @noRd
pad_reflect <- function(x, n_pad) {
  # An index, so an integer whatever the caller passed in.
  n <- as.integer(min(n_pad, length(x)))

  padded <- c(
    rev(x[seq_len(n)]),
    x,
    rev(x[seq.int(length(x) - n + 1, length.out = n)])
  )

  attr(padded, "pad") <- n
  padded
}

#' Discard reflection padding
#'
#' @param x_padded A filtered signal, the same length as the output of
#'   `pad_reflect()`.
#' @param n_pad The pad width that was applied — the `pad` attribute of the
#'   padded signal, not the width originally asked for.
#' @param n Length of the original signal.
#' @return The middle `n` values.
#' @noRd
trim_reflect <- function(x_padded, n_pad, n) {
  x_padded[seq.int(n_pad + 1, length.out = n)]
}
