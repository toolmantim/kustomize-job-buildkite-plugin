#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment to enable stub debug output:
# export DOCKER_STUB_DEBUG=/dev/tty
setup() {
  export BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME="k8s-kustom-job"
  export BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY="tests/overlay"
  export BUILDKITE_PLUGIN_KUSTOMIZE_JOB_DEBUG="false"
  export BUILDKITE_JOB_ID=99
  export BUILDKITE_BUILD_ID=99
  export BUILDKITE_REPO=repoman
  export BUILDKITE_COMMIT="committed"
  export BUILDKITE_BRANCH="branched"
  export BUILDKITE_TAG=""
  export BUILDKITE_AGENT_NAME="otto"
  export BUILDKITE_ORGANIZATION_SLUG="evilcorp"
  export BUILDKITE_PIPELINE_SLUG="kustomizer"
  export BUILDKITE_PIPELINE_PROVIDER="github"
  export BUILDKITE_PULL_REQUEST="false"
}

teardown() {
  unset BUILDKITE_JOB_ID
  unset BUILDKITE_REPO
  unset BUILDKITE_COMMIT
  unset BUILDKITE_BRANCH
  unset BUILDKITE_TAG
  unset BUILDKITE_AGENT_NAME
  unset BUILDKITE_ORGANIZATION_SLUG
  unset BUILDKITE_PIPELINE_SLUG
  unset BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME
  unset BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY
  unset BUILDKITE_PLUGIN_KUSTOMIZE_JOB_DEBUG
}

@test "Run command without job name environment var set" {

  unset BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME

  run $PWD/hooks/command

  assert_failure
  assert_output --partial "required property name is not set"

}

@test "Run command without job overlay environment var set" {

  unset BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY

  run $PWD/hooks/command

  assert_failure
  assert_output --partial "required property overlay is not set"

}


@test "Run command without overlay directory" {

  export BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY="/non-existent"

  run $PWD/hooks/command

  assert_failure
  assert_output --partial "required property overlay directory is not found"

}

@test "Run command without overlay kustomization.yaml" {

  export BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY="/tmp"

  run $PWD/hooks/command

  assert_failure
  assert_output --partial "missing kustomization.yaml file in directory ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY}"

}


@test "Run command should succeed" {

  stub kustomize \
    "build ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY} : echo built overlay" \
    "build ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY} : echo built overlay"
  stub kubectl \
    "apply -f - : echo applied to cluster" \
    "get job ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME} -o jsonpath={.status.conditions[].type} : echo ''" \
    "get job ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME} -o jsonpath={.status.conditions[].type} : echo Complete" \
    "logs job/${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME} : echo show me some logs" \
    "delete job ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME} : echo job.batch \"k8s-kustom-job\" deleted"
  stub sleep \
    "10"

  run $PWD/hooks/command

  assert_success
  assert [ -e /kustomize/base/batch.yaml ]
  assert [ -e /kustomize/base/kustomization.yaml ]
  assert_output --partial "applied to cluster"
  assert_output --partial "show me some logs"
  assert_output --partial "deleted"

  unstub kustomize
  unstub kubectl
}

@test "Run command should fail" {

  stub kustomize \
    "build ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY} : echo built overlay" \
    "build ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_OVERLAY} : echo built overlay"
  stub kubectl \
    "apply -f - : echo applied to cluster" \
    "get job ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME} -o jsonpath={.status.conditions[].type} : echo Failed" \
    "logs job/${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME} : echo show me some logs" \
    "delete job ${BUILDKITE_PLUGIN_KUSTOMIZE_JOB_NAME} : echo job.batch \"k8s-kustom-job\" deleted"

  run $PWD/hooks/command

  assert_failure
  assert [ -e /kustomize/base/batch.yaml ]
  assert [ -e /kustomize/base/kustomization.yaml ]
  assert_output --partial "applied to cluster"
  assert_output --partial "show me some logs"
  assert_output --partial "deleted"

  unstub kustomize
  unstub kubectl
}