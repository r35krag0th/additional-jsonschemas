#!/usr/bin/env zsh

# set -x
setopt shwordsplit

base_directory=${0:h}

unsorted_releases_file="${base_directory}/kube_releases.txt"
sorted_releases_file="${base_directory}/kube_releases_sorted.txt"

fat_arrow_line() {
  # $1 = message
  echo -e "\033[32m==>\033[0m ${1}"
}

triple_equals_line() {
  echo -e "\033[36m===\033[0m ${1}"
}

triple_dashes_line() {
  echo -e "--- ${1}"
}

render_schema() {
  # $1 = major.minor.patch SemVer
  # $2 = suffix
  # $3 = additional flags
  full_version="${1}"
  directory_suffix="${2}"
  additional_flags="${3}"

  segments=( ${(@s:.:)full_version} )
  major_minor="${segments[1]}.${segments[2]}"
  major_minor_dir="${base_directory}/${major_minor_dir}"
  output_dir="${major_minor_dir}/${directory_suffix}"

  schema="https://raw.githubusercontent.com/kubernetes/kubernetes/${full_version}/api/openapi-spec/swagger.json"

  if [ -n "${directory_suffix}" -a -d "${output_dir}" ]; then
    echo "    ${full_version} -- ALREADY DOWNLOADED"
  else 
    echo "    ${full_version} -- DOWNLOADING"
    cmd="--output ${output_dir} ${additional_flags} --expanded --kubernetes ${schema}"
    openapi2jsonschema $cmd
  fi

}

prefix_for_major_minor() {
  # $1 = major.minor
  # $2 = directory
  if [ -z "${2}" ]; then
    echo "_definitions.json"
    return
  fi
  echo "_definitions.json"
}

render_standalone_strict() {
  echo -e "\033[1;35m${1}\033[0m +standalone +strict"

  # openapi2jsonschema \
  #   -o "${version}-standalone-strict" \
  #   --expanded \
  #   --kubernetes \
  #   --stand-alone \
  #   --strict \
  #   "${schema}"
  render_schema "${1}" "standalone-strict" "--stand-alone --strict"
}

render_standalone() {
  echo -e "\033[1;35m${1}\033[0m +standalone"
  # openapi2jsonschema \
  #   -o "${version}-standalone" \
  #   --expanded \
  #   --kubernetes \
  #   --stand-alone \
  #   "${schema}"
  render_schema "${1}" "standalone" "--stand-alone"
}

render_local() {
  echo -e "\033[1;35m${1}\033[0m +local"
  # openapi2jsonschema \
  #   -o "${version}-local" \
  #   --expanded \
  #   --kubernetes \
  #   "${schema}"
  render_schema "${1}" "local" ""
} 

render_with_prefix() {
  echo -e "\033[1;35m${1}\033[0m +prefix"

  # openapi2jsonschema \
  #   -o "${version}" \
  #   --expanded \
  #   --kubernetes \
  #   --prefix "${prefix}" \
  #   "${schema}"
  render_schema "${1}" "" "--prefix \"$(prefix_for_major_minor $1)\""
}

if ! command -v gh >/dev/null; then
  echo "You need github CLI installed"
  exit 1
fi

if ! command -v openapi2jsonschema >/dev/null; then
  echo "You need openapi2jsonschema installed"
  exit 2
fi

if [ ! -f "${unsorted_releases_file}" ]; then
  fat_arrow_line "Fetching GitHub Releases"
  gh api \
    -H "Accept: application/vnd.github+json" \
    -q '.[].tag_name' \
    --paginate \
    /repos/kubernetes/kubernetes/releases > $unsorted_releases_file
fi

if [ ! -f "${sorted_releases_file}" ]; then
  echo ""
  fat_arrow_line "Sorting GitHub Releases"
  cat $unsorted_releases_file | sort --version-sort > $sorted_releases_file
fi

declare -a latest_major_minor_versions
declare -a major_minor_pairs
# Intentionally strip the leading 'v' here
major_minor_pairs=( $(grep -o '^v1.\d\+' ${sorted_releases_file} | tr -d 'v' | sort --version-sort | uniq) )

fat_arrow_line "Looking for latest versions"
echo ""
echo -e "There are \033[1m${#major_minor_pairs[@]}\033[0m unique Major.Minors being checked"
echo ""
for major_minor in ${major_minor_pairs[@]}; do
  # Just throw them on a single line with spaces for keeping the output clean
  echo -n "${major_minor} "

  # Add the stripped of 'v' here
  latest_major_minor=$(grep -o "v${major_minor}.\d\+" ${sorted_releases_file} | sort --version-sort | tail -n 1)
  latest_major_minor_versions+=($latest_major_minor)
done
echo ""

# Output the final list
echo ""
triple_equals_line "Latest Major.Minor List"
echo ""
for v in ${latest_major_minor_versions[@]}; do
  segments=( ${(@s:.:)v} )
  major_minor="${segments[1]}.${segments[2]}"

  major_minor_dir="${base_directory}/${major_minor}"

  if [ ${segments[1]/v/} -eq 1 -a $segments[2] -lt 21 ]; then
    echo "SKIP ${major_minor}"
    continue
  fi

  echo "${v} from ${major_minor}"

  [ ! -d "${major_minor_dir}" ] && mkdir -p "${major_minor_dir}"

  render_standalone "${v}"
  render_standalone_strict "${v}"
  render_local "${v}"
  render_with_prefix "${v}"
done
