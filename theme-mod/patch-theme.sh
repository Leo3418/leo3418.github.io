#!/usr/bin/env bash

# This script patches the theme files for this Jekyll site to add support for
# plugins being used by this site and customizations to the theme, and installs
# the patched files to the site root.
#
# Normally there should be no need to run this script, because the theme files
# in this site's source tree are already patched.  The script is designed to
# reapply those patches when the theme is updated and the files have been
# changed in the upstream.
#
# When this script is being executed, the working directory needs to be either
# the site root or any directory one level down the site root.

# The name of the theme's Ruby gem
THEME_GEM='minimal-mistakes-jekyll'

# Patterns for contents of theme files that should be patched
PATTERNS=\
'site\.title|'\
'include_cached|'\
'site\.locale|'\
'\"%B %-d, %Y\"'

# The path to additional patches for specific files
PATCHES_PATH='theme-mod/patches'

# Space-separated list of additional theme files that should be patched, even
# if they do not contain matches of any PATTERNS
ADDITIONAL_FILES=\
''

# Space-separated list of directories in the site root that contain theme files
DIRS_WITH_THEME_FILES=\
'assets '\
'_includes '\
'_layouts'

# Allow executing this script from directories one level below the site root
if [[ -f ../Gemfile ]]; then
    echo "Gemfile found in the parent directory"
    cd ..
fi

if [[ ! -f Gemfile ]]; then
    echo "Could not find the Gemfile for Jekyll site"
    exit 1
fi

# The path to the theme's gem
THEME_PATH=$(bundle info --path "${THEME_GEM}")

# The label that will be inserted to every patched theme file
# This is used for differentiating patched theme files from the site's own
# assets, include files and layout files
THEME_FILE_LABEL='patched-theme-file'

# If there are any old theme files, remove them
if (grep -Fqr "${THEME_FILE_LABEL}" ${DIRS_WITH_THEME_FILES}); then
    echo "Deleting old files..."
    grep -Flr "${THEME_FILE_LABEL}" ${DIRS_WITH_THEME_FILES} | xargs rm
fi

echo "Getting files need to be patched..."
grep --exclude='*.md' -Elr "${PATTERNS}" "${THEME_PATH}" | \
    xargs cp --parents -t .
for extra in ${ADDITIONAL_FILES}; do
    if [[ ! -f "${extra}" ]]; then
        cp --parents -t . "${THEME_PATH}/${extra}"
    fi
done

# The temporary directory for theme files in the patching patches
temp_dir=$(realpath --relative-to=. "./${THEME_PATH}")

echo "Patching files..."
find "${temp_dir}" -type f -print0 | xargs -0 sed -i \
    's/site\.title/site\.data\.l10n\.title/g'
find "${temp_dir}" -type f -print0 | xargs -0 sed -i \
    's/include_cached/include/g'
find "${temp_dir}" -type f -print0 | xargs -0 sed -i \
    's/site\.locale/site\.active_lang/g'
find "${temp_dir}" -type f -print0 | xargs -0 sed -i \
    's/"%B %-d, %Y"/site\.data\.l10n\.date_format/g'
# Label the patched files
find "${temp_dir}" -type f -name '*.js' -print0 | xargs -0 sed -i \
    '$a\\n/* '${THEME_FILE_LABEL}' */'
find "${temp_dir}" -type f ! -name '*.js' -print0 | xargs -0 sed -i \
    '$a\\n{%- comment -%} '${THEME_FILE_LABEL}' {%- endcomment -%}'

echo "Installing patched files..."
cp -r "${temp_dir:?}"/* .

echo "Removing temporary files..."
rm -r "${temp_dir:?}"/*
rmdir -p "${temp_dir}"

echo "Applying additional patches..."
for patch in "${PATCHES_PATH}"/*; do
    patch -p0 < "${patch}"
done

# For minimal-mistakes-jekyll only
echo "Copying the UI text file..."
cp "${THEME_PATH}"/_data/ui-text.yml ./_data
