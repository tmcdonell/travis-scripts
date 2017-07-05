
# Hint at GHC that a newer/modern version of g++ is available (installed via
# apt). This is a bit of a hack, but is required for llvm-general (>= 3.5.*).
#
function update_gcc_setting {
  if [ $(which $1) ] && [ -e stack.yaml ]; then
    BASE=$(stack path --programs 2>/dev/null | tail -n 1)
    VER=$(stack exec ghc -- --numeric-version)
    sed -i'' -e "s,/usr/bin/gcc.*\",/usr/bin/$1\"," ${BASE}/ghc-${VER}/lib/ghc-${VER}/settings
  fi
}

function update_ld_setting {
  if [ $(which $1) ] && [ -e stack.yaml ]; then
    BASE=$(stack path --programs 2>/dev/null | tail -n 1)
    VER=$(stack exec ghc -- --numeric-version)
    sed -i'' -e "s,/usr/bin/ld.*\",/usr/bin/$1\"," ${BASE}/ghc-${VER}/lib/ghc-${VER}/settings
  fi
}

update_gcc_setting gcc-4.8
update_gcc_setting gcc-4.9
update_gcc_setting gcc-5

# update_ld_setting  ld.gold

