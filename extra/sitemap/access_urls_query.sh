#!/usr/bin/env bash

set -e              # fail on error
set -u              # fail if variable not set in substitution
set -o pipefail     # fail if part of a '|' command fails

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# query for specific works; about 8.6 million circa 2021-04-29
# NOTE: filter out 12-digit access URLs (vs. 14-digit)
fatcat-cli search scholar 'doc_type:work (fulltext.access_type:ia_file OR fulltext.access_type:wayback) (NOT biblio.arxiv_id:*) (NOT biblio.pmcid:*) ((NOT biblio.publisher_type:big5) OR year:<1926 OR tags:oa)' --index-json --limit 0 \
    | jq -c 'select(.biblio.release_ident == .fulltext.release_ident)' \
    | jq -r '[.work_ident, .fulltext.access_type, .fulltext.access_url] | @tsv' \
    | rg -v '^null' \
    | rg -v 'web.archive.org/web/\d{12}/' \
    | $SCRIPT_DIR/transform_access_url.py \
    | pv -l \
    | split --lines 20000 - sitemap-access- -d -a 5 --additional-suffix .txt
