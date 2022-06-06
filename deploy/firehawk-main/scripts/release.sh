#!/bin/bash

echo "NOTE: Ensure any 'ref=' or 'git clone --branch' in the repo points to tagged releases after a release."

if [[ -z "$1" ]]; then
    echo "ERROR: arg must be a description of the release in quotes"
    exit 1
fi
DESCRIPTION=$1

# ensusre local tags are current
git fetch --tags origin

#get highest tag number
HIGHESTVERSION=$(git tag -l --sort -version:refname | head -n 1 2> /dev/null) 
set -e
VERSION=${HIGHESTVERSION:-'v0.0.0'}

REMOVE="${VERSION%%v*}"; VERSION="${VERSION#*v}"
MAJOR="${VERSION%%.*}"; VERSION="${VERSION#*.}"
MINOR="${VERSION%%.*}"; VERSION="${VERSION#*.}"
PATCH="${VERSION%%.*}"; VERSION="${VERSION#*.}"

#Increase version
PATCH=$((PATCH+1))

#Get current hash and see if it already has a tag
GIT_COMMIT=$(git rev-parse HEAD)
NEEDS_TAG=$(git describe --contains $GIT_COMMIT 2> /dev/null) && exit_status=0 || exit_status=$?

#Only tag if no tag already (would be better if the git describe command above could have a silent option)
if [[ -z "$NEEDS_TAG" && ! $exit_status -eq 0 ]]; then
    #Create new tag
    NEW_TAG="v$MAJOR.$MINOR.$PATCH"
    echo "Updating to $NEW_TAG"
    git tag -a $NEW_TAG -m "$DESCRIPTION"
    echo "Tagged with $NEW_TAG"
    git push origin $NEW_TAG
    git -c advice.detachedHead=false checkout $NEW_TAG
    echo "Checkout release"
    git checkout $NEW_TAG
else
    echo "Already a tag $HIGHESTVERSION on this commit"
fi
