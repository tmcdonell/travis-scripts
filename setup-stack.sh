#!/bin/sh
#
# Download and setup the 'stack' executable. Requires the GHC environment
# variable to contain the version of GHC we want to use, as well as a
# 'stack-$GHC.yaml' file present in the current directory, which will then be
# symlinked to 'stack.yaml' so that it is the default. Installs the required
# version of GHC into the local sandbox.
#
# Setting environment variable UPGRADE_CABAL to non-zero will do as it suggests.
#

travis_retry cabal update
sed -i 's/^jobs:/-- jobs:/' ${HOME}/.cabal/config

mkdir $HOME/bin
export PATH=$HOME/bin:$PATH
travis_retry curl -L "https://www.stackage.org/stack/linux-x86_64" | gunzip | tar -x
mv stack-*/stack $HOME/bin

if [ ${GHC} != head ]; then
  ln -s stack-${GHC%.*}.yaml stack.yaml
  travis_retry stack setup --no-terminal --no-system-ghc
fi

if [ ${GHC} != head -a ${UPGRADE_CABAL} ]; then
  travis retry stack setup --no-terminal --upgrade-cabal
fi

