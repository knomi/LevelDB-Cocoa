# Xcode: Set version and build number from Git
# --------------------------------------------
#
# This script sets the version number (CFBundleShortVersionString) to one of
# 
# - `1.2.3` -- for the tagged commit `v1.2.3` or release candidate `v1.2.3-rc*`,
# - `1.2.3-7-gabc1234` -- at commit `abc1234`, 7 commits after `v1.2.3`,
# - `1.2.3-7-gabc1234-dirty` -- when there are uncommitted changes, or
# - `abc1234` or `abc1234-dirty`, respectively -- if there is no previous tag.
# 
# and the build number (`CFBundleVersion`) to the number of Git commits up to
# the current `HEAD`. (That should be a pretty much monotonically growing number
# that is okay for the App Store.)
#
# When about to release a new version (with a new version number), run e.g.
#
#     git tag v1.2.3-rc1
#
# and then build and archive. Once everything looks okay and the release is tested
# to work, set the version in stone, with release notes in the message, by running:
#
#     git tag -s v1.2.3  # signed using your GPG key
#     git tag -a v1.2.3  # unsigned
#
# Remember to push the tags to origin too:
#
#     git push --tags origin
#
# Boom!
#
# Original version: http://kylefuller.co.uk/posts/versioning-with-xcode-and-git/

set -e
BUNDLE_ID=$(defaults read "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}" "CFBundleIdentifier")
GIT_RELEASE_VERSION=$(git describe --tags --always --dirty)
COMMITS=$(git rev-list HEAD | wc -l)
VERSION_STRING_RC="${GIT_RELEASE_VERSION#v}"
VERSION_STRING="${VERSION_STRING_RC%-rc*}"
BUNDLE_VERSION=$(($COMMITS))
defaults write "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}" "CFBundleShortVersionString" "${VERSION_STRING}"
defaults write "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}" "CFBundleVersion" "${BUNDLE_VERSION}"

echo "CFBundleIdentifier:         ${BUNDLE_ID}"
echo "CFBundleShortVersionString: ${VERSION_STRING}"
echo "CFBundleVersion:            ${BUNDLE_VERSION}"

if [[ ${VERSION_STRING} == *-dirty ]];
then
    echo "warning: There are uncommitted changes in Git!"
fi
