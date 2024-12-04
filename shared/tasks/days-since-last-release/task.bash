#!/bin/bash

set -e -u
set -o pipefail

GCHAT_OUTPUT_DIR="gchat-text"
SLACK_OUTPUT_DIR="slack-text"
gchat_card_file="${GCHAT_OUTPUT_DIR}/card"
slack_card_file="${SLACK_OUTPUT_DIR}/card"

release_repos=(
    "routing-release"
    "silk-release"
    "cf-networking-release"
    "diego-release"
    "garden-runc-release"
    "nats-release"
    "healthchecker-release"
    "winc-release"
    "envoy-nginx-release"
    "windows2019fs-release"
    "windowsfs-online-release"
    "windows-tools-release"
    "mapfs-release"
    "smb-volume-release"
    "nfs-volume-release"
)
last_release_index=$(( ${#release_repos[@]} - 1))
last_repo="${release_repos[$last_release_index]}"

# tmpfile to store json so we can do fancy storting and logic with jq
tmpfile="$(mktemp)"

# yup, manually making json
echo "[" > "${tmpfile}"

# get the data from github for each release
# if you get rate limited, the scripts reports that everything was released today. fun!
for i in "${release_repos[@]}";
do
    echo "getting info for ${i}"
    gh_response="$(curl -s https://api.github.com/repos/cloudfoundry/${i}/releases?per_page=1)"
    contains_rate_limit_message=$(echo "${gh_response}" | jq 'any(.; .message)' || true 2> /dev/null )

    if [[ $contains_rate_limit_message == true ]]; then
      echo "😪 Sorry, you have been rate limited. Try again in an hour."
      return
    fi
    last_release_date="$(echo "${gh_response}" | jq -r .[].published_at)"
    releases_count="$(echo "${gh_response}" | jq '. | length')"

    if [[ $releases_count == 0  ]]; then
      never_released=true
    else
      never_released=false
    fi

    time_since="$(( ($(date +%s) - $(date -d "${last_release_date}" +%s)) / (60*60*24) ))"

    # making json folks!
    # shellcheck disable=SC2059
    if [[ $i == "${last_repo}" ]]; then
        echo "{ \"release\": \"${i}\", \"days_since_release\": ${time_since}, \"never_released\": ${never_released} }" >> "${tmpfile}"
    else
        echo "{ \"release\": \"${i}\", \"days_since_release\": ${time_since}, \"never_released\": ${never_released} }," >> "${tmpfile}"
    fi

    echo "${i} - ${time_since}"
    echo ""
done
echo "]" >> "${tmpfile}"

# more json printing stuff

> $gchat_card_file
cat > $gchat_card_file <<- EOM
[
  {
    "cardId": "meow-card",
    "card": {
       "sections": [
         {
           "header": "🐱 days since last release 🐱 - - - - - - - - - - - - - - - - - - -",
           "uncollapsibleWidgetsCount": 1,
           "collapsible": false,
           "widgets": [
EOM

> $slack_card_file
cat > $slack_card_file <<- EOM
🐱 days since last release 🐱

EOM


# sort the json by oldest release and mark if "bad" or not
# bad means the last release is over a month old
index=0
jq '. | sort_by(.days_since_release)|reverse | .[] | if .days_since_release > 30 then .bad=true else .bad=false end' -r -c "${tmpfile}" | while read -r release_info; do
    release_name=$(echo "${release_info}" | jq -r '.release')
    days_since_release=$(echo "${release_info}" | jq '.days_since_release')
    never_released=$(echo "${release_info}" | jq '.never_released')
    bad=$(echo "${release_info}" | jq -r '.bad')
    emoji="✅"

    if [[ $bad == true ]]; then
        emoji="⛔️"
    fi

    cat >> $slack_card_file <<- EOM
${emoji} ${days_since_release} days - ${release_name}
EOM

    if [[ $index == "${last_release_index}" ]]; then
    cat >> $gchat_card_file <<- EOM
            {
               "columns": {
                 "columnItems":
                 [
                    {"widgets": [{"textParagraph": {"text": "${emoji} ${days_since_release} days"}}]},
                    {"widgets": [{"textParagraph": {"text": "${release_name}"}}]}
                 ]
               }
             }
EOM
    else
    cat >> $gchat_card_file <<- EOM
            {
               "columns": {
                 "columnItems":
                 [
                    {"widgets": [{"textParagraph": {"text": "${emoji} ${days_since_release} days"}}]},
                    {"widgets": [{"textParagraph": {"text": "${release_name}"}}]}
                 ]
               }
             },
EOM
    fi
    index=$(( index + 1 ))
done

cat >> $gchat_card_file <<- EOM
           ]
         }
       ]
     }
  }
]
EOM

cat $gchat_card_file

echo
echo

cat $slack_card_file
# clean up
rm -rf "${tmpfile}"
