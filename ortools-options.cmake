# Initial cache for the OR-Tools build, passed with `cmake -C`.
#
# One file so that the three platforms cannot drift apart: what a runner adds on
# the command line is only what is genuinely platform-specific (the macOS
# deployment target, the MSVC runtime, the install prefix).
#
# The defaults being overridden here are those of OR-Tools v9.15; every entry
# below differs from that default, which is why it is written down.

set( CMAKE_BUILD_TYPE Release CACHE STRING "" )

# A single self-contained prefix: OR-Tools fetches and builds its dependencies
# itself, and installs them next to itself, so the installed ortoolsConfig.cmake
# resolves its find_dependency() calls inside the archive.
#
# BUILD_DEPS is deliberately left OFF and the dependencies named one by one.
# BUILD_DEPS=ON is not a shorthand for that: it forces every BUILD_<dep> to ON
# through CMAKE_DEPENDENT_OPTION, so the set of things in the archive would be
# whatever upstream decides to force next, and this file would not say what is
# in it.
set( BUILD_DEPS OFF CACHE BOOL "" )
set( INSTALL_BUILD_DEPS ON CACHE BOOL "" )

set( BUILD_ZLIB ON CACHE BOOL "" )
set( BUILD_BZip2 ON CACHE BOOL "" )
set( BUILD_absl ON CACHE BOOL "" )
set( BUILD_Protobuf ON CACHE BOOL "" )
set( BUILD_re2 ON CACHE BOOL "" )

# bzip2 does not look at BUILD_SHARED_LIBS at all -- it has its own pair of
# options, shared on and static off, and OR-Tools' patch aliases BZip2::BZip2 to
# whichever target exists. The names are generic enough to reach another
# dependency, which is survivable only because the list above is short and none
# of the others declares them.
set( ENABLE_SHARED_LIB OFF CACHE BOOL "" )
set( ENABLE_STATIC_LIB ON CACHE BOOL "" )
# Eigen is not optional, whatever the solver flags say: cmake/check_deps.cmake
# demands the Eigen3::Eigen target unconditionally, and configuration fails
# without it even with USE_PDLP=OFF. Headers only, MPL2.
set( BUILD_Eigen3 ON CACHE BOOL "" )

# Static, so that a consumer needs no rpath on Unix and no DLLs on PATH for
# ctest on Windows. This is the reason we build at all rather than taking
# Google's prebuilt archives.
#
# This entry governs OR-Tools itself only: the dependency build overrides it in
# its own directory scope, which is what scripts/patch-static-deps.sh is for.
set( BUILD_SHARED_LIBS OFF CACHE BOOL "" )

set( BUILD_CXX ON CACHE BOOL "" )

# Nothing here is a library NGA links against.
set( BUILD_FLATZINC OFF CACHE BOOL "" )
set( BUILD_MATH_OPT OFF CACHE BOOL "" )
set( BUILD_SAMPLES OFF CACHE BOOL "" )
set( BUILD_EXAMPLES OFF CACHE BOOL "" )
set( BUILD_TESTING OFF CACHE BOOL "" )
set( BUILD_DOC OFF CACHE BOOL "" )

# Third-party MIP and LP solvers. Turning one off at build time also removes its
# find_dependency() line from the installed ortoolsConfig.cmake, which is what
# keeps the prefix self-contained. NGA uses CP-SAT and nothing else.
#
# USE_BOP and USE_GLOP stay ON: CP-SAT needs GLOP for its LP relaxations, and
# BOP sits on top of SAT and costs nothing.
set( USE_SCIP OFF CACHE BOOL "" )
set( USE_COINOR OFF CACHE BOOL "" )
set( USE_HIGHS OFF CACHE BOOL "" )
set( USE_PDLP OFF CACHE BOOL "" )
set( USE_GUROBI OFF CACHE BOOL "" )
set( USE_XPRESS OFF CACHE BOOL "" )
set( USE_GLPK OFF CACHE BOOL "" )
set( USE_CPLEX OFF CACHE BOOL "" )
