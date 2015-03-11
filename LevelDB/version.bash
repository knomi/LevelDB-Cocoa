#!/bin/bash
# Xcode: Set version and build number from Git
# --------------------------------------------
#
# This script sets the version number `CFBundleShortVersionString` to one of
# 
# - `1.2.3` -- for the tagged commit `v1.2.3` or a hyphen-separated prerelease,
#   e.g. `v1.2.3-alpha`, `v1.2.3-alpha.2`, `v1.2.3-beta`, `v1.2.3-rc`.
# - `1.2.3-7-gabc1234` -- at commit `abc1234`, 7 commits after `v1.2.3`,
# - `1.2.3-7-gabc1234-dirty` -- when there are uncommitted changes, or
# - `abc1234` or `abc1234-dirty`, respectively -- if there is no previous tag.
# 
# and the build number `CFBundleVersion` to the number of Git commits up to the
# current `HEAD`. (That should be a pretty much monotonically growing number
# that is okay for the App Store. If not,)
#
# When about to release a new version, create a prerelease like
#
#     git tag v1.2.3-rc.1
#
# and then build and archive. The script strips the hyphen-separated part from
# the resulting binary
#
# Once everything looks okay and the release is tested
# to work, set the version in stone, with release notes in the message, by running:
#
#     git tag -s v1.2.3  # signed using your GPG key
#     git tag -a v1.2.3  # unsigned
#
# Remember to push the tags to origin too:
#
#     git push --tags origin
#
# Read more about semantic versioning: http://semver.org


set -e

function strip-v () { echo -n "${1#v}"; }
function strip-pre () { local x="${1#v}"; echo -n "${x%-*}"; }

PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}"

if [[ -d "${SRCROOT}/.git" ]];
then

    COMMIT=$(git --git-dir="${SRCROOT}/.git" rev-parse HEAD)

    LATEST=$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2> /dev/null || true)
    STATIC="$(defaults read "${SRCROOT}/${INFOPLIST_FILE}" "CFBundleShortVersionString" 2> /dev/null || true)"
    if [[ -n "$STATIC" ]] && [[ "$STATIC" != $(strip-pre "${LATEST}") ]];
    then
        echo "warning: CFBundleShortVersionString ${STATIC} disagrees with tag ${LATEST}"
    fi

    TAG=$(strip-pre $(git describe --tags --match 'v[0-9]*' --abbrev=0 --exact-match 2> /dev/null || true))
    FULL_VERSION=$(strip-v $(git describe --tags --match 'v[0-9]*' --always --dirty))
    BUILD=$(echo -n $(git rev-list HEAD | wc -l))
    if [[ "${FULL_VERSION}" == *"-dirty" ]];
    then
        echo "warning: There are uncommitted changes in Git"
        SHORT_VERSION="${FULL_VERSION}"
    else
        SHORT_VERSION="${TAG:-${FULL_VERSION}}"
    fi

    defaults write "${PLIST}" "CFBundleShortVersionString" -string "${SHORT_VERSION}"
    defaults write "${PLIST}" "CFBundleVersion"            -string "${BUILD}"
    defaults write "${PLIST}" "Commit"                     -string "${COMMIT}"

else

    echo "warning: Building outside Git. Leaving version number untouched."

fi

echo "CFBundleIdentifier:"         "$(defaults read "${PLIST}" CFBundleIdentifier)"
echo "CFBundleShortVersionString:" "$(defaults read "${PLIST}" CFBundleShortVersionString)"
echo "CFBundleVersion:"            "$(defaults read "${PLIST}" CFBundleVersion)"
