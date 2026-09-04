#!/usr/bin/env bash
#
# Forces OR-Tools' dependency build to produce static libraries.
#
# cmake/dependencies/CMakeLists.txt sets BUILD_SHARED_LIBS -- and protobuf's own
# equivalent -- as plain directory-scope variables, which override whatever the
# cache says. There is no option to turn that off: with BUILD_DEPS enabled,
# abseil, protobuf and re2 come out as shared libraries however the top-level
# project was configured, and only OR-Tools itself honours BUILD_SHARED_LIBS.
# That is the whole reason we build our own archive, so the two lines are
# replaced here.
#
# Both replacements assert that the line exists exactly once before touching it.
# A silent no-op on a version bump would hand us shared libraries again, and the
# consumer check does not catch that -- rpath makes it work on the runner and
# nowhere else.
#
# Usage: scripts/patch-static-deps.sh <or-tools source dir>

set -euo pipefail

source_dir="${1:?usage: patch-static-deps.sh <or-tools source dir>}"
file="${source_dir}/cmake/dependencies/CMakeLists.txt"

replaceOnce()
{
  local old="$1" new="$2" count
  count="$( grep -F -x -c -- "${old}" "${file}" || true )"
  if [ "${count}" != "1" ]; then
    echo "error: expected exactly one line '${old}' in ${file}, found ${count}." >&2
    echo "       Upstream has moved; re-read the file before bumping the version." >&2
    exit 1
  fi
  awk -v old="${old}" -v new="${new}" '$0 == old { print new; next } { print }' "${file}" > "${file}.patched"
  mv "${file}.patched" "${file}"
}

replaceOnce 'set(BUILD_SHARED_LIBS ON)' 'set(BUILD_SHARED_LIBS OFF) # nga-deps: static'
replaceOnce '  set(protobuf_BUILD_SHARED_LIBS ON)' '  set(protobuf_BUILD_SHARED_LIBS OFF) # nga-deps: static'

git -C "${source_dir}" --no-pager diff
