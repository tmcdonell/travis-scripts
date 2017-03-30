
# Hint at GHC that a newer/modern version of g++ is available (installed via
# apt). This is a bit of a hack, but is required for llvm-general (>= 3.5.*).
#
function update_ghc_settings {
  if [ $(which $1) ] && [ -e stack.yaml ]; then
    BASE=$(stack path --programs 2>/dev/null | tail -n 1)
    VER=$(stack exec ghc -- --numeric-version)
    sed -i'' -e "s,/usr/bin/gcc.*\",/usr/bin/$1\"," ${BASE}/ghc-${VER}/lib/ghc-${VER}/settings
  fi
}

update_ghc_settings gcc-4.8
update_ghc_settings gcc-4.9
update_ghc_settings gcc-5.0

