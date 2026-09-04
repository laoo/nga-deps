#!/usr/bin/env bash
#
# Turns an installed prefix into something redistributable: the licence texts of
# everything the archive actually contains, and a MANIFEST that answers "what is
# in this thing" without unpacking it.
#
# Usage: scripts/package.sh <prefix>   (run from the workspace root)

set -euo pipefail

prefix="${1:?usage: package.sh <prefix>}"
source_dir="${SOURCE_DIR:-or-tools}"
build_dir="${BUILD_DIR:-build}"

mkdir -p "${prefix}/licenses"

copyLicence()
{
  local dir="$1" name="$2" file
  for file in LICENSE LICENSE.txt LICENSE.md LICENCE COPYING COPYING.txt COPYRIGHT; do
    if [ -f "${dir}/${file}" ]; then
      cp "${dir}/${file}" "${prefix}/licenses/${name}-LICENSE"
      return 0
    fi
  done
  return 1
}

missing=""

copyLicence "${source_dir}" or-tools || missing="${missing} or-tools"

# Everything OR-Tools fetched and built for itself is installed into the same
# prefix, so its licence has to travel with it.
for dir in "${build_dir}"/_deps/*-src; do
  [ -d "${dir}" ] || continue
  name="$( basename "${dir}" )"
  copyLicence "${dir}" "${name%-src}" || missing="${missing} ${name%-src}"
done

# An archive that ships a binary without its licence is not redistributable, so
# this is a build failure and not a warning.
if [ -n "${missing}" ]; then
  echo "error: no licence file found for:${missing}" >&2
  exit 1
fi

{
  echo "OR-Tools static build for NGA"
  echo
  echo "upstream-tag:    v${ORTOOLS_VERSION:-unknown}"
  echo "upstream-commit: $( git -C "${source_dir}" rev-parse HEAD 2>/dev/null || echo unknown )"
  echo "built:           $( date -u +%Y-%m-%dT%H:%M:%SZ )"
  echo "runner-image:    ${ImageOS:-unknown} ${ImageVersion:-}"
  echo "workflow-run:    ${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-laoo/nga-deps}/actions/runs/${GITHUB_RUN_ID:-unknown}"
  echo "cmake:           $( cmake --version | head -1 )"
  echo "compiler:        $( "${CXX:-c++}" --version 2>/dev/null | head -1 || echo "${CXX:-unknown}" )"
  echo
  echo "== Local modifications to the upstream tree =="
  echo
  git -C "${source_dir}" --no-pager diff
  echo
  echo "== CMake initial cache =="
  echo
  cat ortools-options.cmake
  echo
  echo "== Installed libraries =="
  echo
  ( cd "${prefix}" && find . -name '*.a' -o -name '*.lib' -o -name '*.so*' -o -name '*.dylib' -o -name '*.dll' ) | sort
  echo
  echo "== Installed CMake packages =="
  echo
  ( cd "${prefix}" && find . -name '*Config.cmake' -o -name '*-config.cmake' ) | sort
} > "${prefix}/MANIFEST"

cat "${prefix}/MANIFEST"
