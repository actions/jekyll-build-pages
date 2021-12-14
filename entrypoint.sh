#!/bin/bash

#######################################################################################################
# 
# Calls github-pages executable to build the site using whitelisted plugins and supported configuration
#
#######################################################################################################

set -o errexit

SOURCE_DIRECTORY=${GITHUB_WORKSPACE}/$INPUT_SOURCE
DESTINATION_DIRECTORY=${GITHUB_WORKSPACE}/$INPUT_DESTINATION
PAGES_GEM_HOME=$BUNDLE_APP_CONFIG
GITHUB_PAGES=$PAGES_GEM_HOME/bin/github-pages

# Set environment variables required by supported plugins
export JEKYLL_ENV="production"
export JEKYLL_GITHUB_TOKEN=$INPUT_TOKEN
export PAGES_REPO_NWO=$GITHUB_REPOSITORY

if [ -z $INPUT_VERBOSE ]; then
  VERBOSE=''
else
  VERBOSE='--verbose'
fi

cd $PAGES_GEM_HOME

$GITHUB_PAGES build $VERBOSE --source $SOURCE_DIRECTORY --destination $DESTINATION_DIRECTORY
