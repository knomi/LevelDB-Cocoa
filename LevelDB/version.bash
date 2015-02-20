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


set -e

function strip-rc () { local x="${1#v}"; echo -n "${x%-rc*}"; }
function strip-pre () { local x="${1#v}"; echo -n "${x%-*}"; }

PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}"

if [[ -d "${SRCROOT}/.git" ]];
then

    git --git-dir="${SRCROOT}/.git" rev-parse

    TAG=$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2> /dev/null || true)
    STATIC="$(defaults read "${SRCROOT}/${INFOPLIST_FILE}" "CFBundleShortVersionString")"
    if [[ -n "$STATIC" ]] && [[ "$STATIC" != $(strip-pre "${TAG}") ]];
    then
        echo "warning: CFBundleShortVersionString ${STATIC} disagrees with tag ${TAG}"
    fi

    VERSION=$(strip-rc $(git describe --tags --always --dirty --match 'v[0-9]*'))
    BUILD=$(echo -n $(git rev-list HEAD | wc -l))
    if [[ "${VERSION}" == *"-dirty" ]];
    then
        echo "warning: There are uncommitted changes in Git"
    fi

    defaults write "${PLIST}" "CFBundleShortVersionString" "${VERSION}"
    defaults write "${PLIST}" "CFBundleVersion"            "${BUILD}"

else

    echo "warning: Building outside Git. Leaving version number untouched."

fi

echo "CFBundleIdentifier:         $(defaults read "${PLIST}" CFBundleIdentifier)"
echo "CFBundleShortVersionString: $(defaults read "${PLIST}" CFBundleShortVersionString)"
echo "CFBundleVersion:            $(defaults read "${PLIST}" CFBundleVersion)"
