pca <- function(
  mat,
  metadata = NULL,
  center = TRUE,
  scale = FALSE,
  rank = NULL, 
  removeVar = NULL,
  transposed = FALSE,
  BSPARAM = ExactParam())
{
  # avoid attempting to coerce S4 matrices into full matrices.
  if (is.data.frame(mat)) {
    mat <- as.matrix(mat)
  }
  if (!transposed) {
    mat <- t(mat)
  }

  # if metadata specified, enforce rule that rownames(metadata) is the
  # same as colnames(mat)
  if (!is.null(metadata)) {
    if(!identical(rownames(mat), rownames(metadata))) {
      stop("'colnames(mat)' is not identical to 'rownames(metadata)'")
    }
  }

  # remove lower portion of variables based on variation
  vars <- colVars(DelayedArray(mat))
  if (!is.null(removeVar)) {
    message('-- removing the lower ', removeVar * 100,
      '% of variables based on variance')
    varorder <- order(vars, decreasing = TRUE)
    keep <- head(varorder, max(1, ncol(mat)*(1-removeVar)))
    mat <- mat[,keep,drop=FALSE]
    vars <- vars[keep]
  }

  # Setting the default rank to all values if Exact.
  if (is.null(rank)) {
    if (is(BSPARAM, "ExactParam")) {
      rank <- min(dim(mat))
    } else {
      stop("'rank' must be specified for approximate PCA methods")
    }
  }

  # perform pca via BiocSingular::runPCA().
  pcaobj <- runPCA(mat,
    center = center,
    scale = scale,
    rank = rank,
    BSPARAM = BSPARAM)

  # Determine the proportion of variance of each component
  # Proportion of variance equals (PC stdev^2) / (total variance)
  if (scale) {
    total.var <- length(vars)
  } else {
    total.var <- sum(vars)
  }
  proportionvar <- (pcaobj$sdev ^ 2) / total.var * 100

  # create a new object
  pcaobj <- list(
    rotated = data.frame(pcaobj$x),
    loadings = data.frame(pcaobj$rotation),
    variance = proportionvar,
    sdev = pcaobj$sdev,
    metadata = metadata,
    xvars = colnames(mat),
    yvars = rownames(mat),
    components = colnames(pcaobj$x)
  )

  rownames(pcaobj$rotated) <- pcaobj$yvars
  rownames(pcaobj$loadings) <- pcaobj$xvars
  names(pcaobj$variance) <- pcaobj$components

  # assign class pca to object
  class(pcaobj) <- 'pca'

  return(pcaobj)
}
