#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
catalog_root="${I18N_CATALOG_ROOT:-${script_dir}/..}"
base_ref=""
if [[ $# -ne 0 ]]; then
  [[ $# -eq 2 && "$1" == --base && -n "$2" ]] || { echo "Usage: $0 [--base REF]" >&2; exit 2; }
  base_ref="$2"
fi
python3 "${script_dir}/check-syntax.py" "${catalog_root}" || exit 2
english_catalog="${catalog_root}/en-US/main.ftl"
scratch_dir="$(mktemp -d)"
trap 'rm -rf "${scratch_dir}"' EXIT

export LC_ALL=C
touch "${scratch_dir}/issues"

report() {
  while IFS= read -r value; do
    [[ -z "${value}" ]] || printf '%s: %s: %s\n' "${locale}" "$1" "${value}"
  done <<< "$2"
}

message_ids() {
  rg --no-filename --pcre2 -o '^[A-Za-z][A-Za-z0-9_-]*(?=\s*=)' "$1" | sort
}

message_variables() {
  awk '
    /^[A-Za-z][A-Za-z0-9_-]*[[:space:]]*=/ { message_id = $1 }
    {
      line = $0
      while (match(line, /\$[A-Za-z][A-Za-z0-9_-]*/)) {
        print message_id ":" substr(line, RSTART + 1, RLENGTH - 1)
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$1" | sort -u
}

message_ids "${english_catalog}" >"${scratch_dir}/english"
message_variables "${english_catalog}" >"${scratch_dir}/english-variables"

# The experiential empty-state selector is deliberately gated to exact en-US
# in chat_view/render.rs. Other locales keep their ordinary localized morning
# greeting, so these source-locale-only arguments are not translation slots.
printf '%s\n' \
  'chat-greeting-morning:count' \
  'chat-greeting-morning:project' \
  'chat-greeting-morning:provider' \
  'chat-greeting-morning:variant' \
  >"${scratch_dir}/locale-specific-english-variables"

status=0
stale_locale_specific_variables="$(comm -13 \
  "${scratch_dir}/english-variables" \
  "${scratch_dir}/locale-specific-english-variables")"
if [[ -n "${stale_locale_specific_variables}" ]]; then
  echo "Stale locale-specific English variable exceptions:" >&2
  printf '  %s\n' ${stale_locale_specific_variables} >&2
  status=2
fi

for catalog in "${catalog_root}"/*/main.ftl; do
  locale="$(basename "$(dirname "${catalog}")")"
  ids="${scratch_dir}/${locale}"
  variables="${scratch_dir}/${locale}-variables"
  message_ids "${catalog}" >"${ids}"
  message_variables "${catalog}" >"${variables}"

  duplicates="$(uniq -d "${ids}")"
  missing="$(comm -23 "${scratch_dir}/english" "${ids}")"
  extra="$(comm -13 "${scratch_dir}/english" "${ids}")"
  comm -23 "${scratch_dir}/english-variables" "${variables}" \
    >"${scratch_dir}/${locale}-missing-variables"
  # An absent message is already reported as missing. Its variables become
  # a separate contract to check when a contributor adds the translation.
  missing_variables="$(comm -23 \
    "${scratch_dir}/${locale}-missing-variables" \
    "${scratch_dir}/locale-specific-english-variables" |
    awk -F: 'NR == FNR { ids[$1]; next } $1 in ids' "${ids}" -)"
  extra_variables="$(comm -13 "${scratch_dir}/english-variables" "${variables}")"
  if [[ -n "${duplicates}" ]]; then
    report duplicate "${duplicates}" >&2
    status=2
  fi
  report missing "${missing}" >>"${scratch_dir}/issues"
  report extra "${extra}" >>"${scratch_dir}/issues"
  report 'missing variable' "${missing_variables}" >>"${scratch_dir}/issues"
  report 'extra variable' "${extra_variables}" >>"${scratch_dir}/issues"
done

[[ ${status} -eq 0 ]] || exit "${status}"
sort -u "${scratch_dir}/issues" -o "${scratch_dir}/issues"
if [[ -z "${base_ref}" ]]; then
  cat "${scratch_dir}/issues"
  [[ ! -s "${scratch_dir}/issues" ]]
  exit
fi

# Compare using this validator for both snapshots, including in the app subtree.
base_commit="$(git -C "${catalog_root}" rev-parse --verify "${base_ref}^{commit}")"
prefix="$(git -C "${catalog_root}" rev-parse --show-prefix)"
repo_root="$(git -C "${catalog_root}" rev-parse --show-toplevel)"
mkdir "${scratch_dir}/base"
git -C "${repo_root}" archive "${base_commit}${prefix:+:${prefix%/}}" |
  tar -x -C "${scratch_dir}/base"
base_status=0
I18N_CATALOG_ROOT="${scratch_dir}/base" bash "${script_dir}/check-catalogs.sh" \
  >"${scratch_dir}/baseline" || base_status=$?
[[ ${base_status} -le 1 ]] || exit "${base_status}"
for catalog in "${scratch_dir}/base"/*/main.ftl; do
  locale="$(basename "$(dirname "${catalog}")")"
  if [[ ! -f "${catalog_root}/${locale}/main.ftl" ]]; then
    report missing 'catalog file' >>"${scratch_dir}/issues"
  fi
done
sort -u "${scratch_dir}/issues" -o "${scratch_dir}/issues"
comm -13 "${scratch_dir}/baseline" "${scratch_dir}/issues" >"${scratch_dir}/new"
echo "Existing catalog issues: $(comm -12 "${scratch_dir}/baseline" "${scratch_dir}/issues" | wc -l | tr -d ' ')"
if [[ -s "${scratch_dir}/new" ]]; then
  echo "New catalog issues compared with ${base_ref}:" >&2
  cat "${scratch_dir}/new" >&2
  exit 1
fi
echo "No new catalog issues."
