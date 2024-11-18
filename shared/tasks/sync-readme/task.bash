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
  local CI_CONFIG_DIR="$PWD/ci-config"
  local SYNCED_REPO_DIR="$PWD/synced-repo"

  pushd "repo/" > /dev/null
  local git_remote_name
  git_remote_name=$(git_get_remote_name)

  local sub_readme
  local belongs_to_dir
  local parent_readme
  if [[ -d "${CI_CONFIG_DIR}" ]]; then
    sub_readme=$(find "${CI_CONFIG_DIR}" | grep -E "[0-9]{0,2}-?${git_remote_name}.md")
    belongs_to_dir="${CI_CONFIG_DIR}/$(echo "${sub_readme#"${CI_CONFIG_DIR}/"}" | cut -d "/" -f1)"
    parent_readme=$(find "${CI_CONFIG_DIR}" -name "01-*.md" -ipath "${belongs_to_dir}/*")
  else
    sub_readme=$(find "${CI_DIR}" | grep -E "[0-9]{0,2}-?${git_remote_name}.md")
    belongs_to_dir="${CI_DIR}/$(echo "${sub_readme#"${CI_DIR}/"}" | cut -d "/" -f1)"
    parent_readme=$(find "${CI_DIR}" -name "01-*.md" -ipath "${belongs_to_dir}/*")
  fi
  sub_readme=$(echo "${sub_readme}" | grep -v "${parent_readme}" || true)

  local docs_md_file
  docs_md_file="$(mktemp -p "${task_tmp_dir}" -t 'XXXXX-docs.md')"
  generate_docs_md ${docs_md_file} ${task_tmp_dir}


  pandoc ${sub_readme} ${docs_md_file} ${parent_readme} ${CI_DIR}/shared/00-shared.md -f markdown -t markdown --atx-headers -o README.md

  git ls-tree --name-only --full-name --full-tree -r HEAD | grep '\.md$' | grep -Ev '.github|vendor' | xargs -I {} lychee {} -nqq

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

  local expired=$(for f in ${files}; do pandoc $f --template ${pandoc_tmpl} | jq 'select(.expires_at != "never") | select(.expires_at < (now | strftime("%Y-%m-%d")))'; done)
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
