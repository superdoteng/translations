#!/usr/bin/env bash
set -euo pipefail

catalog_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "${catalog_root}/scripts/check-syntax.py" "${catalog_root}"
english_catalog="${catalog_root}/en-US/main.ftl"
scratch_dir="$(mktemp -d)"
trap 'rm -rf "${scratch_dir}"' EXIT

export LC_ALL=C

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
  status=1
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
  missing_variables="$(comm -23 \
    "${scratch_dir}/${locale}-missing-variables" \
    "${scratch_dir}/locale-specific-english-variables")"
  extra_variables="$(comm -13 "${scratch_dir}/english-variables" "${variables}")"
  if [[ -n "${duplicates}" || -n "${missing}" || -n "${extra}" ||
    -n "${missing_variables}" || -n "${extra_variables}" ]]; then
    echo "${locale}: catalog does not match en-US" >&2
    [[ -z "${duplicates}" ]] || printf '  duplicate: %s\n' ${duplicates} >&2
    [[ -z "${missing}" ]] || printf '  missing: %s\n' ${missing} >&2
    [[ -z "${extra}" ]] || printf '  extra: %s\n' ${extra} >&2
    [[ -z "${missing_variables}" ]] ||
      printf '  missing variable: %s\n' ${missing_variables} >&2
    [[ -z "${extra_variables}" ]] ||
      printf '  extra variable: %s\n' ${extra_variables} >&2
    status=1
  fi
done

exit "${status}"
