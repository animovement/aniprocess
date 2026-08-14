#' Filter coordinates outside a region of interest (ROI)
#'
#' @description
#' Filters out coordinates that fall outside a specified region of interest by
#' setting them to NA. The ROI can be either rectangular/cuboid (defined by
#' min/max coordinates) or circular/spherical (defined by center and radius).
#' Automatically handles 2D or 3D data based on the spatial variables in the
#' aniframe metadata.
#'
#' @param data An aniframe containing spatial coordinates.
#' @param x_min,x_max Bounds for x-coordinate (rectangular/cuboid ROI).
#' @param y_min,y_max Bounds for y-coordinate (rectangular/cuboid ROI).
#' @param z_min,z_max Bounds for z-coordinate (cuboid ROI, 3D only).
#' @param x_center,y_center,z_center Center coordinates for circular/spherical
#'   ROI. For 3D data, provide all three; for 2D data, only x and y.
#' @param radius Radius of circular (2D) or spherical (3D) ROI.
#'
#' @return An aniframe with coordinates outside ROI set to NA.
#' @export
#'
#' @examples
#' # Create sample 2D data
#' sample_data <- aniframe::aniframe(
#'   time = 1:9,
#'   x = rep(c(25, 50, 75), 3),
#'   y = rep(c(25, 50, 75), each = 3)
#' )
#'
#' # Rectangular ROI example
#' sample_data |>
#'   filter_na_roi(x_min = 20, x_max = 60, y_min = 20, y_max = 60)
#'
#' # Circular ROI example
#' sample_data |>
#'   filter_na_roi(x_center = 50, y_center = 50, radius = 30)
#'
#' # 3D cuboid ROI example
#' sample_3d <- aniframe::aniframe(
#'   time = 1:8,
#'   x = rep(c(25, 75), 4),
#'   y = rep(c(25, 75), each = 2, times = 2),
#'   z = rep(c(25, 75), each = 4),
#'   variables_where = c("x", "y", "z")
#' )
#'
#' sample_3d |>
#'   filter_na_roi(x_min = 20, x_max = 60, y_min = 20, y_max = 60, z_min = 20, z_max = 60)
filter_na_roi <- function(
  data,
  x_min = NULL,
  x_max = NULL,
  y_min = NULL,
  y_max = NULL,
  z_min = NULL,
  z_max = NULL,
  x_center = NULL,
  y_center = NULL,
  z_center = NULL,
  radius = NULL
) {
  is_frame <- aniframe::is_aniframe(data)
  if (is_frame) {
    ensure_aniframe_spatial(data)
    variables_where <- aniframe::get_metadata(data, "variables_where")
  } else {
    ensure_coords(data)
    variables_where <- names(data)
  }
  missing_axes <- setdiff(c("x", "y"), variables_where)
  if (length(missing_axes) > 0L) {
    cli::cli_abort(c(
      "ROI filtering needs coordinate{?s} {.val {missing_axes}}.",
      "i" = "Got {.val {variables_where}}."
    ))
  }
  has_z <- "z" %in% variables_where

  # Check for rectangular vs circular ROI
  rect_params <- c(x_min, x_max, y_min, y_max, z_min, z_max)
  circ_params_2d <- c(x_center, y_center)

  is_rectangular <- !all(is.null(rect_params))
  is_circular <- !is.null(radius) || !all(is.null(circ_params_2d))

  if (!is_rectangular && !is_circular) {
    if (has_z) {
      cli::cli_abort(
        c(
          "No ROI parameters provided.",
          "i" = "For cuboid ROI: Provide at least one of {.arg x_min}, {.arg x_max}, {.arg y_min}, {.arg y_max}, {.arg z_min}, {.arg z_max}.",
          "i" = "For spherical ROI: Provide {.arg x_center}, {.arg y_center}, {.arg z_center}, and {.arg radius}."
        )
      )
    } else {
      cli::cli_abort(
        c(
          "No ROI parameters provided.",
          "i" = "For rectangular ROI: Provide at least one of {.arg x_min}, {.arg x_max}, {.arg y_min}, {.arg y_max}.",
          "i" = "For circular ROI: Provide {.arg x_center}, {.arg y_center}, and {.arg radius}."
        )
      )
    }
  }

  # Check for mixing rectangular and circular parameters
  if (is_rectangular && is_circular) {
    cli::cli_abort(
      c(
        "Cannot mix rectangular and circular ROI parameters.",
        "i" = "Provide either rectangular bounds or circular center/radius, not both."
      )
    )
  }

  if (is_rectangular) {
    # Validate z params only used with 3D data
    if (!has_z && (!is.null(z_min) || !is.null(z_max))) {
      cli::cli_abort(
        c(
          "Cannot use {.arg z_min}/{.arg z_max} with 2D data.",
          "i" = "Data has spatial variables: {.val {variables_where}}."
        )
      )
    }
    data <- filter_na_roi_rect(
      data,
      x_min,
      x_max,
      y_min,
      y_max,
      z_min,
      z_max,
      has_z
    )
  } else {
    # Circular/spherical ROI
    if (is.null(radius)) {
      cli::cli_abort(
        c(
          "Incomplete circular/spherical ROI parameters.",
          "x" = "{.arg radius} must be provided."
        )
      )
    }
    if (is.null(x_center) || is.null(y_center)) {
      cli::cli_abort(
        c(
          "Incomplete circular/spherical ROI parameters.",
          "x" = "{.arg x_center} and {.arg y_center} must be provided."
        )
      )
    }
    if (has_z && is.null(z_center)) {
      cli::cli_abort(
        c(
          "Incomplete spherical ROI parameters for 3D data.",
          "x" = "{.arg z_center} must be provided for 3D data."
        )
      )
    }
    if (!has_z && !is.null(z_center)) {
      cli::cli_abort(
        c(
          "Cannot use {.arg z_center} with 2D data.",
          "i" = "Data has spatial variables: {.val {variables_where}}."
        )
      )
    }
    data <- filter_na_roi_sphere(
      data,
      x_center,
      y_center,
      z_center,
      radius,
      has_z
    )
  }

  data
}

#' Filter coordinates outside a rectangular/cuboid ROI
#'
#' @description
#' Helper function for filter_na_roi() that handles rectangular (2D) or
#' cuboid (3D) ROIs. Sets coordinates to NA if they fall outside the
#' specified bounds.
#'
#' @param data An aniframe containing spatial coordinates.
#' @param x_min,x_max,y_min,y_max,z_min,z_max Bounds of the ROI.
#' @param has_z Logical indicating whether data has z coordinate.
#'
#' @return An aniframe with coordinates outside ROI set to NA.
#' @keywords internal
filter_na_roi_rect <- function(
  data,
  x_min,
  x_max,
  y_min,
  y_max,
  z_min,
  z_max,
  has_z
) {
  if (!is.null(x_min)) {
    outside_x <- data$x < x_min
    data$x <- dplyr::if_else(outside_x, NA_real_, data$x)
    data$y <- dplyr::if_else(outside_x, NA_real_, data$y)
    if (has_z) data$z <- dplyr::if_else(outside_x, NA_real_, data$z)
  }

  if (!is.null(x_max)) {
    outside_x <- data$x > x_max
    data$x <- dplyr::if_else(outside_x, NA_real_, data$x)
    data$y <- dplyr::if_else(outside_x, NA_real_, data$y)
    if (has_z) data$z <- dplyr::if_else(outside_x, NA_real_, data$z)
  }

  if (!is.null(y_min)) {
    outside_y <- data$y < y_min
    data$x <- dplyr::if_else(outside_y, NA_real_, data$x)
    data$y <- dplyr::if_else(outside_y, NA_real_, data$y)
    if (has_z) data$z <- dplyr::if_else(outside_y, NA_real_, data$z)
  }

  if (!is.null(y_max)) {
    outside_y <- data$y > y_max
    data$x <- dplyr::if_else(outside_y, NA_real_, data$x)
    data$y <- dplyr::if_else(outside_y, NA_real_, data$y)
    if (has_z) data$z <- dplyr::if_else(outside_y, NA_real_, data$z)
  }

  if (has_z && !is.null(z_min)) {
    outside_z <- data$z < z_min
    data$x <- dplyr::if_else(outside_z, NA_real_, data$x)
    data$y <- dplyr::if_else(outside_z, NA_real_, data$y)
    data$z <- dplyr::if_else(outside_z, NA_real_, data$z)
  }

  if (has_z && !is.null(z_max)) {
    outside_z <- data$z > z_max
    data$x <- dplyr::if_else(outside_z, NA_real_, data$x)
    data$y <- dplyr::if_else(outside_z, NA_real_, data$y)
    data$z <- dplyr::if_else(outside_z, NA_real_, data$z)
  }

  data
}

#' Filter coordinates outside a circular/spherical ROI
#'
#' @description
#' Helper function for filter_na_roi() that handles circular (2D) or
#' spherical (3D) ROIs. Sets coordinates to NA if they fall outside the
#' specified circle/sphere.
#'
#' @param data An aniframe containing spatial coordinates.
#' @param x_center,y_center,z_center Center coordinates of the ROI.
#' @param radius Radius of the ROI.
#' @param has_z Logical indicating whether data has z coordinate.
#'
#' @return An aniframe with coordinates outside ROI set to NA.
#' @keywords internal
filter_na_roi_sphere <- function(
  data,
  x_center,
  y_center,
  z_center,
  radius,
  has_z
) {
  if (has_z) {
    is_outside <- ((data$x - x_center)^2 +
      (data$y - y_center)^2 +
      (data$z - z_center)^2) >
      radius^2
  } else {
    is_outside <- ((data$x - x_center)^2 +
      (data$y - y_center)^2) >
      radius^2
  }

  data$x <- dplyr::if_else(is_outside, NA_real_, data$x)
  data$y <- dplyr::if_else(is_outside, NA_real_, data$y)
  if (has_z) {
    data$z <- dplyr::if_else(is_outside, NA_real_, data$z)
  }

  data
}
