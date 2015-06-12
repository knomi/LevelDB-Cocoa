#!/bin/bash

PROJECT_DIR="${PROJECT_DIR:-$PWD}"

appledoc \
 --project-name "LevelDB-Cocoa" \
 --project-company "Pyry Jahkola" \
 --company-id "pyrtsa" \
 --docset-atom-filename "LevelDB-Cocoa.atom" \
 --docset-feed-url "https://pyrtsa.github.com/LevelDB-Cocoa/%DOCSETATOMFILENAME" \
 --docset-package-url "https://pyrtsa.github.com/LevelDB-Cocoa/%DOCSETPACKAGEFILENAME" \
 --docset-fallback-url "https://pyrtsa.github.com/LevelDB-Cocoa/" \
 --output "${PROJECT_DIR}/doc" \
 --publish-docset \
 --logformat xcode \
 --keep-undocumented-objects \
 --keep-undocumented-members \
 --keep-intermediate-files \
 --no-repeat-first-par \
 --no-warn-invalid-crossref \
 --ignore "*.m" \
 --ignore "*.mm" \
 --ignore "LevelDB/LDBPrivate.hpp" \
 --index-desc "${PROJECT_DIR}/README.md" \
 "${PROJECT_DIR}"
