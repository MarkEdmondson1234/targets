# script to generate cloudbuild.yaml and build the Docker
library(googleCloudRunner)

# my fork for now - allow access to github repo via 
# https://console.cloud.google.com/cloud-build/triggers/connect
repo <- cr_buildtrigger_repo("MarkEdmondson1234/targets")

# creates gcr.io/gcer-public/targets docker image with renv and targets
cr_deploy_docker_trigger(
  repo = repo,
  image = "targets",
  projectId_target = "gcer-public",
  dir = "inst/templates/cloudbuild/"
)

# create cloudbuild.yaml for deploying target pipelines to Cloud build
# assumes you have saved git credentials to Secret Manager at github-ssh
bs <- c(
  cr_buildstep_gitsetup("github-ssh"),
  cr_buildstep_git(c("clone","${_PUSH_NAME}", "repo"), id = "clone to repo dir"),
  cr_buildstep_r("renv::restore()", 
                 name = "gcr.io/gcer-public/targets", 
                 id = "Restore packages",
                 dir = "repo"),
  cr_buildstep_r("targets::tar_make()", name = "gcr.io/gcer-public/targets", 
                 id = "target pipeline", dir = "repo"),
  cr_buildstep_git(c("add", "--all"), dir = "repo"),
  cr_buildstep_git(c("commit", "-a", "-m",
                     "Add target run from ${COMMIT_SHA}: $(date +\"%Y%m%dT%H:%M:%S\")"), 
                   dir = "repo"),
  cr_buildstep_git("push", dir = "repo")
  )

yaml <- cr_build_yaml(
  bs,
  substitutions = list(
    `_PUSH_NAME` = "$(push.repository.name)"
  )
)

cr_build_write(yaml, file = "inst/templates/cloudbuild/cloudbuild.yaml")


# set up a build trigger for cloudbuild.yaml
