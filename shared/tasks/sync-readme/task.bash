#!/bin/bash

set -eEu
set -o pipefail

THIS_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TASK_NAME="$(basename $THIS_FILE_DIR)"
source "$THIS_FILE_DIR/../../../shared/helpers/helpers.bash"
source "$THIS_FILE_DIR/../../../shared/helpers/git-helpers.bash"
unset THIS_FILE_DIR

export CURRENT_DIR="$PWD"

function run() {
  local task_tmp_dir="${1:?provide temp dir for task}"
  shift 1
  git_configure_author
  git_configure_safe_directory

  local CI_DIR="$PWD/ci"
  local SYNCED_REPO_DIR="$PWD/synced-repo"

  pushd "repo/" > /dev/null
  local git_remote_name=$(git_get_remote_name)

  local sub_readme=$(find ${CI_DIR} -name "*${git_remote_name}*.md")
  local belongs_to_dir=$(echo ${sub_readme} | xargs dirname | xargs dirname)
  local parent_readme=$(find ${CI_DIR} -name "01-*.md" -ipath "${belongs_to_dir}/*")

  local docs_md_file="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-docs.md')"
  generate_docs_md ${docs_md_file} ${task_tmp_dir}


  pandoc ${sub_readme} ${docs_md_file} ${parent_readme} ${CI_DIR}/shared/00-shared.md -f markdown -t markdown --atx-headers -o README.md

  find . -name \*.md -print0 | xargs -0 -n1 lychee --exclude "CONTRIBUTING.md" --exclude-path "vendor" -nqq

  if [[ $(git status --porcelain) ]]; then
    git add -A .
    git commit -m "Sync README.md"
  fi

  rsync -a $PWD/ "$SYNCED_REPO_DIR"

  popd > /dev/null
}

function generate_docs_md() {
  local docs_md_file=${1:?Please provide a docs markdown file}
  local task_tmp_dir=${2:?Please provide a temp dir}

  local files=$(find . -name "*.md" -ipath "./docs/*" | sort)
  if [[ "${files:-empty}" == "empty" ]]; then
    return
  fi

  local pandoc_tmpl="$(mktemp -p ${task_tmp_dir} -t 'XXXXX-file.pandoc-tmpl')"

  echo '$meta-json$' > ${pandoc_tmpl}

  cat > ${docs_md_file} <<EOF
# Docs

EOF
for f in ${files}; do pandoc $f --template ${pandoc_tmpl} | jq '.title' | xargs printf "- [%s]($f)\n" ; done >> ${docs_md_file}

  local expired=$(for f in ${files}; do pandoc $f --template ${pandoc_tmpl} | jq 'select(.expires_at != "never") | select(.expires_at < (now | strftime("%m/%d/%y")))'; done)
  if [[ "${expired:-none}" != "none" ]]; then
    echo "The following docs are now expired, please remove them"
    echo "${expired}"
    exit 1
  fi
}


function cleanup() {
  rm -rf $task_tmp_dir
}

task_tmp_dir="$(mktemp -d -t 'XXXX-task-tmp-dir')"
trap cleanup EXIT
trap 'err_reporter $LINENO' ERR
run $task_tmp_dir "$@"
