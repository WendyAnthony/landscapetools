#' util_classify
#'
#' @description Classify a raster into proportions based upon a vector of class
#' weightings.
#'
#' @details  The number of elements in the weighting vector determines the number of classes
#' in the resulting matrix. The classes start with the value 0.
#' If non-numerical levels are required, the user can specify a vector to turn the
#' numerical factors into other data types, for example into character strings (i.e. class labels).
#' If the numerical vector of weightings does not sum up to 1, the sum of the
#' weightings is divided by the number of elements in the weightings vector and this is then used for the classification.
#'
#' For a given 'real' landscape the number of classes and the weightings are
#' extracted and used to classify the given nlm landscape (any given weighting parameter is
#' overwritten in this case!). If an optional mask value is given the corresponding
#' class from the 'real' landscape is cut from the nlm landscape beforehand.
#'
#' @param x 2D matrix
#' @param weighting Vector of numeric values.
#' @param level_names Vector of names for the factor levels.
#' @param real_land Raster with real landscape
#' @param mask_val Value to mask (refers to real_land)
#'
#' @return RasterLayer
#'
#' @examples
#' weight <- c(0.5, 0.25, 0.25)
#' util_classify(fbmmap, weight,
#'               level_names = c("Land Use 1", "Land Use 2", "Land Use 3"))
#'
#' \dontrun{
#' rland <- util_classify(NLMR::nlm_planargradient(200,200),
#'                          c(.4,.2,.4),
#'                          c("Land use 1", "Water", "Land use 2"))
#'
#' resu <- util_classify(fbmmap, real_land = rland)
#' resu_mask <- util_classify(fbmmap, real_land = rland, mask_val = 1)
#'
#' visu <- list(
#' '1 nlm' = fbmmap,
#' '2 real' = rland,
#' '3 result' = resu,
#' '4 result with mask' = resu_mask
#' )
#' util_facetplot(visu)
#' }
#'
#' @aliases util_classify
#' @rdname util_classify
#'
#' @export
#'

util_classify <- function(x, weighting, level_names = NULL,
                          real_land = NULL, mask_val = NULL) {

  # Check function arguments ----
  checkmate::assert_class(x, "RasterLayer")
  if (is.null(real_land)) {
      checkmate::assert_numeric(weighting)
  }else{
      checkmate::assert_class(real_land, "RasterLayer")
      frq <- tibble::as_tibble(raster::freq(real_land))
      if (!is.null(mask_val)) {
          frq <- dplyr::filter(frq, value != mask_val)
          x <- raster::mask(x, real_land, maskvalue = mask_val)
      }
      weighting <- frq$count / sum(frq$count)
  }

  # Calculate cum. proportions and boundary values ----
  cumulative_proportions <- util_w2cp(weighting)
  boundary_values <- util_calc_boundaries(raster::values(x),
                                          cumulative_proportions)

  # Classify the matrix based on the boundary values ----
  raster::values(x) <- findInterval(raster::values(x),
                                    boundary_values,
                                    rightmost.closed = TRUE)

  # If level_names are not NULL, add them as specified ----
  if (!is.null(level_names)) {

    # Turn raster values into factors ----
    x <- raster::as.factor(x)

    c_r_levels <- raster::levels(x)[[1]]
    c_r_levels[["Categories"]] <- level_names
    levels(x) <- c_r_levels
  }

  return(x)
}
