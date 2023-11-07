#!/bin/bash

# This script makes the following assumptions:
# 1. All metrics needing documentation come from the IngressClient from the diego-logging-client
# 2. We don't document the metrics sent with SendApp.*
# 3. The IngressClient methods that should be documented always have the documented name as the first arg

set -eu
set -o pipefail

function run() {
    local repo_path=${1:?Provide a path to the repository}

    pushd "${repo_path}" > /dev/null

    metrics_in_code >/dev/null      # check for errors, e.g. constant not defined at the beginning of the file

    local diff_missing=$(diff <(metrics_in_code | sort | uniq) <(documented_metrics) | grep '^<' | awk '{print $2}')

    if [ $(echo -n "$diff_missing" | wc -c) -ne 0 ] ; then
        echo -ne "\033[1m"
        echo "Missing documentation for the following metrics:"
        echo "------------------------------------------------"
        echo -ne "\033[0m"
        echo -ne "\033[31m"
        echo "$diff_missing"
        echo -ne "\033[0m"
        exit 1
    fi

    local diff_extra=$(diff <(metrics_in_code | sort | uniq) <(documented_metrics | grep -Ev 'Volman') | grep '^>' | awk '{print $2}')
    # Check for Unemitted Metrics
    if [ $(echo -n "$diff_extra" | wc -c) -ne 0 ] ; then
        echo -ne "\033[1m"
        echo "Extra documentation for the following metrics:"
        echo "------------------------------------------------"
        echo -ne "\033[0m"
        echo -ne "\033[31m"
        echo "$diff_extra"
        echo -ne "\033[0m"
        exit 1
    fi

    popd > /dev/null
    exit 0
}

# Used for ensuring documentation of metrics

documented_metrics() {
    # returns a sorted list of documented metrics
    cat ./docs/metrics.md | grep '`' | awk '{print $2}' |  tr -d '`' | sort -u
}

# Returns a list of functions which are used to send metrics that might need
# documentation.
#
# formats with | separator for grep OR of invocations of the function
# format example: SendDuration|\.SendMebiBytes|\.SendMetric|\.SendBytesPerSecond
ingress_client_functions() {
    client_file=$1
    echo "\.$(
    sed \
        -ne '/type IngressClient interface {/,/}/ {' \
        -ne '/type IngressClient interface {/b' \
        -ne '/}/b' -ne '/name/!d' \
        -ne 's/\(.*\)(.*/\1/' \
        -ne 'p' \
        -ne '}' $client_file |
        tr -d '\t' |
        tr '\n' "." |
        sed 's/\./|\\\./g' |
        sed '$s/|\\\.$//'
            )"
}

metrics_in_code() {
    client_file=./src/code.cloudfoundry.org/vendor/code.cloudfoundry.org/diego-logging-client/client.go

    if [ ! -f $client_file ]; then
        echo "Failed to find $client_file" >&2
        exit 4
    fi

    search_term=$(ingress_client_functions $client_file)
    if [[ -z "$search_term" ]]; then
        echo "no ingress client functions were found!" >&2
        exit 3
    fi

    IFS=$'\n'
    result=$(grep -n --exclude={*_test.go,*fake*.go} --exclude-dir={gorouter,volman,guardian,grootfs,idmapper,vendor} -I -E -e "($search_term)\(" -r ./src/code.cloudfoundry.org)
    for line in $result; do
        file_location=$(echo -e "$line" | cut -d: -f1)
        client_call=$(echo -e "$line" | cut -d: -f3-)
        # extract the variable name, e.g. "err := SendMetric(foo...)" -> "foo"
        # Note: the sed command will stop at `,' `)' or `+'. The `+' is there to deal with prefixed metrics,
        # e.g. domainMetricPrefix+domain which is found in src/code.cloudfoundry.org/bbs/db/sqldb/lrp_convergence.go
        var_name=$(echo $client_call | sed -E "s/.*(${search_term})\(([^,+\)]*).*/\2/g")
        # look for the constant definition, e.g. for a var named foo look for `foo = "...."`
        metric_name=$(grep -E "[[:blank:]]+$var_name[[:blank:]]+=[[:blank:]]+" $file_location | sed -E 's/.*=[[:blank:]]+"([^"]*)"/\1/')
        if [ ! -z $metric_name ]; then
            echo $metric_name
        else
            str_metric_name=$(echo $var_name | sed -E 's/"([^"]*)"/\1/')
            echo $str_metric_name
        fi
    done
}

run "$@"
