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

# ortoolsConfig.cmake does find_dependency( BZip2 ), which resolves through
# CMake's FindBZip2 module -- config mode never gets a chance, and bzip2 installs
# no package config anyway. The module looks for a library named bz2, while the
# static build installs bz2_static. bzip2's own CMakeLists is fetched during
# configure, far too late for patch-static-deps.sh to rename the output, so the
# name the module expects is added here instead.
while IFS= read -r file; do
  cp "${file}" "${file/_static/}"
  echo "bzip2: added ${file/_static/} for FindBZip2"
done < <( find "${prefix}" -name '*bz2_static*' -type f )

mkdir -p "${prefix}/licenses"

# Every licence file the tree has, not the first one found: Eigen carries six
# COPYING.* files and a COPYING.README that says which of them applies.
copyLicences()
{
  local dir="$1" name="$2" file found=0
  for file in "${dir}"/LICENSE* "${dir}"/LICENCE* "${dir}"/COPYING* "${dir}"/NOTICE*; do
    [ -f "${file}" ] || continue
    mkdir -p "${prefix}/licenses/${name}"
    cp "${file}" "${prefix}/licenses/${name}/"
    found=1
  done
  [ "${found}" = 1 ]
}

missing=""

copyLicences "${source_dir}" or-tools || missing="${missing} or-tools"

# Everything OR-Tools fetched and built for itself is installed into the same
# prefix, so its licence has to travel with it.
for dir in "${build_dir}"/_deps/*-src; do
  [ -d "${dir}" ] || continue
  name="$( basename "${dir}" )"
  copyLicences "${dir}" "${name%-src}" || missing="${missing} ${name%-src}"
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
  echo "== Dependency commits =="
  echo
  # Not decoration: OR-Tools fetches bzip2 from GIT_TAG "master", so one
  # OR-Tools tag does not pin one set of sources. This is the only record of
  # what actually went into a given archive.
  for dir in "${build_dir}"/_deps/*-src; do
    [ -d "${dir}" ] || continue
    name="$( basename "${dir}" )"
    printf '%-12s %s\n' "${name%-src}" "$( git -C "${dir}" rev-parse HEAD 2>/dev/null || echo unknown )"
  done
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
