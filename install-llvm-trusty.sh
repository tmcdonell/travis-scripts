#!/bin/bash
#
# The LLVM apt repository has been disabled. Until it is re-enabled, download
# the pre-built LLVM binaries and install locally.
#
# As with the other scripts, you must 'source' this for it to work correctly
#

export LLVM_HOME=${HOME}/llvm-${LLVM}
export PATH=${LLVM_HOME}/bin:${PATH}
export LD_LIBRARY_PATH=${LLVM_HOME}/lib:${LD_LIBRARY_PATH}

mkdir -p ${LLVM_HOME}
travis_retry curl -L "http://llvm.org/releases/${LLVM}/clang+llvm-${LLVM}-x86_64-linux-gnu-ubuntu-14.04.tar.xz" | unxz | tar -x -C ${LLVM_HOME} --strip-components 1

