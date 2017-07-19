#!/bin/bash
#
# This is an after_success script that will attempt to update the
# 'accelerate-travis-buildbot' repository to build all accelerate products with
# this new version
#
# Based on: https://gist.github.com/domenic/ec8b0fc8ab45f39403dd
#

if [ -z "${encrypted_deploy_key}" -o -z "${encrypted_deploy_iv}" ]; then
  echo "Deploy keys not available; exiting."
  return 0
fi

SOURCE_BRANCH=master
TARGET_BRANCH=master
BUILDBOT_HTTPS_URL=https://github.com/tmcdonell-bot/accelerate-travis-buildbot.git
BUILDBOT_SSH_URL=${BUILDBOT_HTTPS_URL/https:\/\/github.com\//git@github.com:}

# Find out who initiated the build
TRAVIS_COMMIT_EMAIL=$(git --no-pager show -s --format='%ae' HEAD)

REPO_NAME=${TRAVIS_REPO_SLUG#*/}
REPO_OWNER=${TRAVIS_REPO_SLUG%/*}

# Pull requests or commits to other branches shouldn't update the buildbot
if [ ${TRAVIS_PULL_REQUEST} != false -o ${TRAVIS_BRANCH} != ${SOURCE_BRANCH} ]; then
  echo "Skipping buildbot update"
  return 0
fi

# Check out and configure the buildbot repo
travis_retry git clone ${BUILDBOT_HTTPS_URL} buildbot
pushd buildbot
git checkout ${TARGET_BRANCH}

git config user.name "Travis CI"
git config user.email ${TRAVIS_COMMIT_EMAIL}

# Update the replacement script
cat update_template.sed \
  | sed "s#.*|{REPO_${REPO_NAME}}|.*#s|{REPO_${REPO_NAME}}|${TRAVIS_REPO_SLUG}|g#" \
  | sed "s#.*|{SHA_${REPO_NAME}}|.*#s|{SHA_${REPO_NAME}}|${TRAVIS_COMMIT}|#" \
  > update_template.sed.bak

mv update_template.sed.bak update_template.sed

# Update the templates.
sh do_update.sh

# If there is no change then there is nothing left to do so we can exit early
# (this can happen because it is a race to see who successfully completes their
# entry of the build matrix, and thus updates the buildbot repo)
if git diff --quiet; then
  echo "No update necessary; exiting."
  popd
  return 0
fi

# Commit the new version
git add .
git commit -m "Update dependency: ${TRAVIS_REPO_SLUG}"

# Get the deploy key from the travis encrypted file
openssl aes-256-cbc -K ${encrypted_deploy_key} -iv ${encrypted_deploy_iv} -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval $(ssh-agent -s)
ssh-add deploy_key

# Now we can push to the buildbot repository
git push ${BUILDBOT_SSH_URL} ${TARGET_BRANCH}

popd

