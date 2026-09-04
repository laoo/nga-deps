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

The matrix mirrors NGA's own CI, because that is what fixes the ABI. The
compiler appears in the asset name only on Linux, the one platform where the C++
runtime is not the platform's own.

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
