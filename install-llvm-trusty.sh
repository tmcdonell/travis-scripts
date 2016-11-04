#!/bin/bash
#
# The LLVM apt repository has been disabled. Until it is re-enabled, install it
# locally. Note that the prebuilt binaries don't come with the llvm shared
# library, which we need for llvm-general.
#
# As with the other scripts, you must 'source' this for it to work correctly
#

export LLVM_HOME=${HOME}/llvm/${LLVM}
export PATH=${LLVM_HOME}/bin:${PATH}
export LD_LIBRARY_PATH=${LLVM_HOME}/lib:${LD_LIBRARY_PATH}

mkdir -p ${LLVM_HOME}

# If llvm is already installed (i.e. retrieved from cache) we are done
#
if [ -x ${LLVM_HOME}/bin/llc ] &&  [ -x ${LLVM_HOME}/bin/opt ] && [ ${LLVM_BINARY_RELEASE:-0} -o -e ${LLVM_HOME}/lib/libLLVM-${LLVM}.so ]; then
  return 0
fi

# Download and install. By default choose the source release. This takes longer
# to install the first time, but we will probably need the shared library it
# provides.
#
if [ ${LLVM_BINARY_RELEASE:-0} -ne 0 ]; then

  echo "Downloading LLVM binary release"

  # Download the binary release, and unpack directly into the final location
  case ${LLVM} in
    3.4.*) travis_retry curl -L "http://llvm.org/releases/${LLVM}/clang+llvm-${LLVM}-x86_64-linux-gnu-ubuntu-14.04.xz"     | unxz | tar -x -C ${LLVM_HOME} --strip-components 1 ;;
    *)     travis_retry curl -L "http://llvm.org/releases/${LLVM}/clang+llvm-${LLVM}-x86_64-linux-gnu-ubuntu-14.04.tar.xz" | unxz | tar -x -C ${LLVM_HOME} --strip-components 1 ;;
  esac

else

  echo "Installing LLVM from source release"

  SRCDIR=$(mktemp -d)
  BUILDDIR=$(mktemp -d)

  # Download source distribution
  case ${LLVM} in
    3.4.*) travis_retry curl -L "http://llvm.org/releases/${LLVM}/llvm-${LLVM}.src.tar.gz" | gunzip | tar -x -C ${SRCDIR} --strip-components 1 ;;
    *)     travis_retry curl -L "http://llvm.org/releases/${LLVM}/llvm-${LLVM}.src.tar.xz" | unxz   | tar -x -C ${SRCDIR} --strip-components 1 ;;
  esac

  # Configure, build, install
  # Use configure-based build system for old versions of LLVM. Use CMake-based
  # system for LLVM-3.8 and onwards. Assume at least 3.x series.
  pushd ${BUILDDIR}
  case ${LLVM} in
    3.[0-7].*)
      ${SRCDIR}/configure --prefix=${LLVM_HOME} --enable-shared --enable-targets=host,x86,x86_64,nvptx
      make -j3
      make install
      ;;

    *)
      cmake -DCMAKE_INSTALL_PREFIX=${LLVM_HOME} -DLLVM_BUILD_LLVM_DYLIB=True -DLLVM_TARGETS_TO_BUILD="X86;NVPTX" ${SCRDIR}
      cmake --build . -- -j3
      cmake --build . --target install
      ;;
  esac
  popd

  # Delete the temporary directories
  rm -rf ${SRCDIR}
  rm -rf ${BUILDDIR}

fi

# Hint at GHC that a newer/modern version of g++ is available (installed via
# apt). This is a bit of a hack, but is required for llvm-general (>= 3.5.*).
#
if [ $(which gcc-4.8) ] && [ -e stack.yaml ]; then
  sed -i'' -e 's,/usr/bin/gcc.*",/usr/bin/gcc-4.8",' $(stack path --programs 2>/dev/null | tail -n 1)/ghc-${GHC}/lib/ghc-${GHC}/settings
fi

