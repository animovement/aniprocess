# A frame missing a column its metadata names. anicore's methods no longer
# make one, returning a plain tibble instead (animovement/anicore#178), so
# tests of the guards that catch one build it by hand. The raw attribute is
# deliberate: no accessor will write metadata that contradicts the frame.
drop_column_unchecked <- function(data, col) {
  md <- anicore::get_metadata(data)
  cls <- class(data)
  bare <- dplyr::as_tibble(as.data.frame(data))
  bare[[col]] <- NULL
  base <- c("grouped_df", "rowwise_df", "tbl_df", "tbl", "data.frame")
  class(bare) <- c(setdiff(cls, base), class(bare))
  attr(bare, "metadata") <- md
  bare
}
