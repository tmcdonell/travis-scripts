
# Hint at GHC that a newer/modern version of g++ is available (installed via
# apt). This is a bit of a hack, but is required for llvm-general (>= 3.5.*).
#
if [ $(which gcc-4.9) ] && [ -e stack.yaml ]; then
  BASE=$(stack path --programs 2>/dev/null | tail -n 1)
  VER=$(stack exec ghc -- --numeric-version)
  sed -i'' -e 's,/usr/bin/gcc.*",/usr/bin/gcc-4.9",' ${BASE}/ghc-${VER}/lib/ghc-${VER}/settings
fi

