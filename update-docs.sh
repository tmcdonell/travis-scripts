#!/bin/bash
#
# This is an after_success script that will attempt to update the 'gh-pages'
# branch of the current repository with the documentation generated by stack.
#
# Based on: https://chromabits.com/posts/2016/07/04/haddock-travis/
#

if [ -z "${encrypted_deploy_key}" ] || [ -z "${encrypted_deploy_iv}" ]; then
  echo "Deploy keys not available; exiting."
  return 0
fi

SOURCE_BRANCH=master
TARGET_BRANCH=master
DOCS_BRANCH=gh-pages
REMOTE_HTTPS_URL="https://github.com/${TRAVIS_REPO_SLUG}.git"
REMOTE_SSH_URL="git@github.com:${TRAVIS_REPO_SLUG}.git"

# Path to the docs
LOCAL_DOC_ROOT=$(stack path --local-doc-root)
LOCAL_HPC_ROOT=$(stack path --local-hpc-root)

# Find out who initiated the build
TRAVIS_COMMIT_EMAIL=$(git --no-pager show -s --format='%ae' HEAD)

# Pull requests or commits to other branches shouldn't update the buildbot
if [ ${TRAVIS_PULL_REQUEST} != false ] || [ ${TRAVIS_BRANCH} != ${SOURCE_BRANCH} ]; then
  echo "Skipping documentation update"
  return 0
fi

# Check out and configure the target repo. This assumes that the `gh-pages`
# branch exists and contains only the documentation files. The branch can be
# created as follows:
#
# $ git checkout --orphan gh-pages
# $ git reset --hard
#
travis_retry git clone ${REMOTE_HTTPS_URL} docs
pushd docs

# Get the deploy key from the travis encrypted file. Assume that this exists on
# the master branch only.
openssl aes-256-cbc -K ${encrypted_deploy_key} -iv ${encrypted_deploy_iv} -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval $(ssh-agent -s)
ssh-add deploy_key

# Replace the contents of the documentation branch. Note the trailing slash on
# the copy command.
git checkout ${DOCS_BRANCH}
rm -rf *
cp -R ${LOCAL_DOC_ROOT}/ .

# If there is no change, and no new untracked files, then there is nothing left to do.
if [ $( git diff --quiet ) ] && [ $( git ls-files --other --directory --exclude-standard | sed q | wc -l ) -eq 0 ]; then
  echo "No update necessary; exiting"
  return 0
fi

# Commit the new version and push to the remote repository
git config user.name "Travis CI"
git config user.email ${TRAVIS_COMMIT_EMAIL}

git add .
git commit -m "Update documentation" -m "${TRAVIS_COMMIT}"

git push ${REMOTE_SSH_URL} ${DOCS_BRANCH}

popd

