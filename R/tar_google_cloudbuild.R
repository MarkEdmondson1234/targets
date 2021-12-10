#' @title Set up Google Cloud Build to run a targets pipeline
#' @export
#' @family scripts
#' @description Writes a Google Cloud Build workflow file so the pipeline
#'   runs on every push to GitHub, or via a PubSub trigger (that could be scheduled). Historical runs accumulate in the
#'   `targets-runs` branch, and the latest output is restored before
#'   [tar_make()] so up-to-date targets do not rerun.
#' @details Steps to set up continuous deployment:
#'   1. Ensure your pipeline stays within the resource limitations of
#'     GitHub Actions and repositories, both for storage and compute.
#'     For storage, you may wish to reduce the burden with
#'     AWS-backed storage formats like `"aws_qs"`.
#'   2. Setup Cloud Build via `googleCloudRunner::cr_setup()`.
#'   2. Call `targets::tar_renv(extras = character(0))`
#'     to expose hidden package dependencies.
#'   3. Set up `renv` for your project (with `renv::init()`
#'     or `renv::snapshot()`). Details at
#'     <https://rstudio.github.io/renv/articles/ci.html>.
#'   4. Commit the `renv.lock` file to the `main` (recommended)
#'     or `master` Git branch.
#'   5. Run `tar_google_cloudbuild()` to create the workflow file.
#'     Commit this file to `main` (recommended) or `master` in Git.
#'   6. Push your project to GitHub. Verify that a Google Cloud Build trigger
#'     runs and pushes results to `targets-runs`.
#'     Subsequent runs will only recompute the outdated targets.
#' @return Nothing (invisibly). This function writes a Google Cloud Build yaml and sets up a Cloud Build trigger as a side effect.
#' @param path Character of length 1, file path to write the Google Cloud Build yaml
#'   workflow file.
#' @param ask Logical, whether to ask before writing if the workflow file
#'   already exists. If `NULL`, defaults to `Sys.getenv("TAR_ASK")`.
#'   (Set to `"true"` or `"false"` with `Sys.setenv()`).
#'   If `ask` and the `TAR_ASK` environment variable are both
#'   indeterminate, defaults to `interactive()`.
#' @examples
#' tar_github_actions(tempfile())
tar_google_cloudbuild <- function(
  path = file.path("cloud_builds", "cloudbuild.yaml"),
  ask = NULL
) {
  tar_assert_chr(path, "path must be a character")
  tar_assert_scalar(path, "path must have length 1")
  if (!tar_should_overwrite(path = path, ask = ask)) {
    # covered in tests/interactive/test-tar_github_actions.R # nolint
    return(invisible()) # nocov
  }
  dir_create(dirname(path))
  source <- system.file(
    file.path("templates", "cloudbuild", "cloudbuild.yaml"),
    package = "targets",
    mustWork = TRUE
  )
  file.copy(source, path, overwrite = TRUE)
  invisible()
}
