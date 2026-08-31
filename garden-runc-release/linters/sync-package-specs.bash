#!/bin/bash

set -eu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

function run() {
  local repo_path=${1:?Provide a path to the repository}
  local exit_on_error=${2:-"false"}

  pushd "${repo_path}" > /dev/null

  BUILD_FLAGS="--tags cgo,seccomp" sync_package runc \
    --subtree-module code.cloudfoundry.org/guardian \
    --from-subtree \
    -app github.com/opencontainers/runc &

  BUILD_FLAGS="--tags daemon" sync_package guardian \
    --subtree-module code.cloudfoundry.org/guardian \
    --c-pkg code.cloudfoundry.org/guardian/rundmc/nstar \
    --c-pkg code.cloudfoundry.org/guardian/cmd/init \
    -app code.cloudfoundry.org/guardian/cmd/gdn \
    -app code.cloudfoundry.org/guardian/cmd/dadoo \
    -app code.cloudfoundry.org/guardian/cmd/socket2me \
    -app code.cloudfoundry.org/guardian/cmd/execas &

  BUILD_FLAGS="--tags cloudfoundry" sync_package grootfs \
    --subtree-module code.cloudfoundry.org/guardian \
    -app code.cloudfoundry.org/guardian/grootfs \
    -app code.cloudfoundry.org/guardian/idmapper \
    -app code.cloudfoundry.org/guardian/grootfs/store/filesystems/overlayxfs/tardis &

  BUILD_FLAGS="--tags windows" sync_package guardian-windows \
    --subtree-module code.cloudfoundry.org/guardian \
    -app code.cloudfoundry.org/guardian/cmd/gdn \
    -app code.cloudfoundry.org/guardian/cmd/winit &

  sync_package thresholder \
    -app code.cloudfoundry.org/thresholder &

  sync_package dontpanic \
    -app code.cloudfoundry.org/dontpanic &

  sync_package garden-idmapper \
    --subtree-module code.cloudfoundry.org/guardian \
    -app code.cloudfoundry.org/guardian/idmapper/cmd/newuidmap \
    -app code.cloudfoundry.org/guardian/idmapper/cmd/newgidmap \
    -app code.cloudfoundry.org/guardian/idmapper/cmd/maximus &

  sync_package greenskeeper \
    -app code.cloudfoundry.org/greenskeeper/cmd/greenskeeper &

  sync_package gats \
    --subtree-module code.cloudfoundry.org/guardian \
    -app github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/garden-integration-tests/... \
    -app code.cloudfoundry.org/garden-integration-tests/plugins/consume-mem &

  sync_package gpats \
    -app github.com/onsi/ginkgo/v2/ginkgo \
    -test code.cloudfoundry.org/garden-performance-acceptance-tests/... &

  wait

  git diff --name-only packages/*/spec

  if [[ "$exit_on_error" == "true" ]]; then
    git_error_when_diff
  fi

  popd > /dev/null
}

function sync_package() {
  local bosh_pkg=${1}
  shift

  local subtree_module=""
  local force_from_subtree=false
  local c_pkgs=()
  local gosub_args=()

  while [[ $# -gt 0 ]]; do
    case "${1}" in
      --subtree-module)
        subtree_module="${2}"
        shift 2
        ;;
      --from-subtree)
        force_from_subtree=true
        shift
        ;;
      --c-pkg)
        c_pkgs+=("${2}")
        shift 2
        ;;
      *)
        gosub_args+=("${1}")
        shift
        ;;
    esac
  done

  (
  set -e

  cd "src/code.cloudfoundry.org"

  spec=../../packages/${bosh_pkg}/spec

  {
    cat $spec | grep -v '# gosub'

    if [[ -n "${subtree_module}" ]]; then
      local_mod="${subtree_module#code.cloudfoundry.org/}"
      echo "  - ${subtree_module}/go.mod # gosub"
      echo "  - ${subtree_module}/go.sum # gosub"
    fi

    for c_pkg in "${c_pkgs[@]}"; do
      local_pkg="${c_pkg#code.cloudfoundry.org/}"
      if ls ${local_pkg}/*.c >/dev/null 2>&1; then
        echo "  - ${c_pkg}/*.c # gosub"
      fi
      if ls ${local_pkg}/*.h >/dev/null 2>&1; then
        echo "  - ${c_pkg}/*.h # gosub"
      fi
      if ls ${local_pkg}/Makefile >/dev/null 2>&1; then
        echo "  - ${c_pkg}/Makefile # gosub"
      fi
    done

    # Run gosub from the subtree if forced, or if all -app/-test packages belong to the subtree module
    gosub_from_subtree=false
    if [[ -n "${subtree_module}" ]]; then
      local_mod="${subtree_module#code.cloudfoundry.org/}"
      if [[ "${force_from_subtree}" == "true" ]]; then
        gosub_from_subtree=true
      else
        gosub_from_subtree=true
        for arg in "${gosub_args[@]}"; do
          if [[ "${arg}" == -* ]]; then continue; fi
          if [[ "${arg}" != "${subtree_module}/"* ]]; then
            gosub_from_subtree=false
            break
          fi
        done
      fi
    fi

    if [[ "${gosub_from_subtree}" == "true" ]]; then
      gosub_packages=$(cd "${local_mod}" && BUILD_FLAGS="${BUILD_FLAGS:-}" gosub list "${gosub_args[@]}" 2>/dev/null)
    else
      gosub_packages=$(gosub list "${gosub_args[@]}" 2>/dev/null)
    fi

    for package in ${gosub_packages}; do
      base_pkg="$(echo $package | cut -f2- -d /)"
      if [[ "${gosub_from_subtree}" == "true" ]]; then
        # Resolve paths relative to subtree module compilation context
        # "." means the subtree root package itself; skip if it has no Go files
        if [ "${package}" = "." ]; then
          continue
        fi
        subtree_relative="${package#${subtree_module}/}"
        if [ "${subtree_relative}" != "${package}" ] && [ -d "${local_mod}/${subtree_relative}" ]; then
          # Package is from the subtree module itself (e.g. guardian/gardener)
          package="code.cloudfoundry.org/${local_mod}/${subtree_relative}"
        elif [ -d "${local_mod}/vendor/${package}" ]; then
          # Package is in the subtree's vendor directory
          package="code.cloudfoundry.org/${local_mod}/vendor/${package}"
        else
          package="${base_pkg}"
        fi
      elif [ -d "vendor/${package}" ]; then
        package="code.cloudfoundry.org/vendor/${package}"
      elif [ -d "${base_pkg}" ]; then
        package="code.cloudfoundry.org/${base_pkg}"
      else
        package="${base_pkg}"
      fi
      echo ${package} | sed -e 's/\(.*\)/  - \1\/*.go # gosub/g'
      if ls ../../src/${package}/*.s >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.s # gosub/g'
      fi
      if ls ../../src/${package}/*.h >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.h # gosub/g'
      fi
      if ls ../../src/${package}/*.c >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.c # gosub/g'
      fi
      if ls ../../src/${package}/Makefile >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/Makefile # gosub/g'
      fi
      if ls ../../src/${package}/*.binpb >/dev/null 2>&1; then
        echo ${package} | sed -e 's/\(.*\)/  - \1\/*.binpb # gosub/g'
      fi
    done
  } > $spec.new

  mv $spec.new $spec
)
}


verify_binary gosub
run "$@"
