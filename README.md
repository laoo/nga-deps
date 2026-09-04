# nga-deps

Static OR-Tools builds for [NGA](https://github.com/laoo/NGA), published as
Release assets.

This repository carries no sources of its own and no copy of OR-Tools: the
workflow fetches the upstream tag, configures it with
[`ortools-options.cmake`](ortools-options.cmake), and installs everything —
OR-Tools together with the abseil, protobuf, re2 and zlib it builds for itself —
into one self-contained prefix. NGA consumes that archive through
`FetchContent_Declare( URL ... URL_HASH ... )`; it builds nothing.

*Why* the dependency is built here rather than taken from Google's prebuilt
archives, vcpkg or `libextern/` is recorded once, in NGA's decision record on
OR-Tools. This file says only how the thing is operated.

## Assets

A Release named after the tag carries one archive per platform, plus
`SHA256SUMS`:

| Asset | Runner | Toolchain |
|---|---|---|
| `or-tools-<version>-linux-x64-gcc14.tar.gz` | `ubuntu-24.04` | g++-14 |
| `or-tools-<version>-macos-arm64.tar.gz` | `macos-latest` | Apple clang, deployment target 13.0 |
| `or-tools-<version>-windows-x64-msvc2022.zip` | `windows-latest` | MSVC 2022, Release, `/MD` |

The matrix mirrors NGA's own CI, because that is what fixes the ABI. The
compiler appears in the asset name only on Linux, the one platform where the C++
runtime is not the platform's own.

The archives are static all the way down, which took some doing: OR-Tools is
tested upstream as a shared build, so `scripts/patch-static-deps.sh` overrides
the two lines that force its dependencies shared whatever the cache says, and
`scripts/package.sh` repairs what a static bzip2 leaves inconsistent in the
installed CMake package. Both are checked rather than assumed -- the workflow
fails if a shared library reaches the prefix, and `consumer/` is configured
against the finished prefix and nothing else.

Each archive contains a `MANIFEST` — upstream tag and commit, build date, runner
image, the exact CMake cache, and what was actually installed — and a
`licenses/` directory, because redistributing binaries means redistributing the
licence texts with them.

## Building a version

```sh
git tag or-tools-9.15
git push origin or-tools-9.15
```

The tag is the trigger and the only thing that publishes a Release: a tag is in
the history, a workflow input is not. `workflow_dispatch` builds the same
archives but attaches them to the run as workflow artifacts and publishes
nothing — use it to try a version out.

Then, in NGA, edit the version and the hashes in `cmake/OrTools.cmake`. That is
the whole bump procedure; nothing else refers to these binaries.
