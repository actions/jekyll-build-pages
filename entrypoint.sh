#!/bin/bash

####################################################################################################
#
# Calls github-pages executable to build the site using allowed plugins and supported configuration
#
####################################################################################################

set -o errexit

SOURCE_DIRECTORY=${GITHUB_WORKSPACE}/$INPUT_SOURCE
DESTINATION_DIRECTORY=${GITHUB_WORKSPACE}/$INPUT_DESTINATION
PAGES_GEM_HOME=$BUNDLE_APP_CONFIG
GITHUB_PAGES_BIN=$PAGES_GEM_HOME/bin/github-pages

# Check if Gemfile's dependencies are satisfied or print a warning 
if test -e "$SOURCE_DIRECTORY/Gemfile" && ! bundle check --dry-run --gemfile "$SOURCE_DIRECTORY/Gemfile" >/dev/null 2>&1; then
  echo "::warning:: github-pages can't satisfy your Gemfile's dependencies."
fi

# Set environment variables required by supported plugins
export JEKYLL_ENV="production"
export JEKYLL_GITHUB_TOKEN=$INPUT_TOKEN
export PAGES_REPO_NWO=$GITHUB_REPOSITORY
export JEKYLL_BUILD_REVISION=$INPUT_BUILD_REVISION

# Set verbose flag
if [ "$INPUT_VERBOSE" = 'true' ]; then
  VERBOSE='--verbose'
else
  VERBOSE=''
fi

# Set future flag
if [ "$INPUT_FUTURE" = 'true' ]; then
  FUTURE='--future'
else
  FUTURE=''
fi

echo PWD = $(pwd)
echo PAGES_GEM_HOME = $PAGES_GEM_HOME
echo GITHUB_PAGES_BIN = $GITHUB_PAGES_BIN
echo GITHUB_WORKSPACE = $GITHUB_WORKSPACE
ls -la $GITHUB_WORKSPACE

cd "$PAGES_GEM_HOME"
$GITHUB_PAGES_BIN build "$VERBOSE" "$FUTURE" --source "$SOURCE_DIRECTORY" --destination "$DESTINATION_DIRECTORY"
