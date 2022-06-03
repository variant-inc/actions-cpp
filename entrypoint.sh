#!/bin/bash

function finish {
  set -x
  chown -R 1000:1000 "$GITHUB_WORKSPACE"/*
  git clean -fdx
  set +x
}
trap finish EXIT

echo "Installing GCCC-$INPUT_GCC_VERSION and build-essential"
apt-get update && apt-get install --no-install-recommends --assume-yes \
  gcc-"$INPUT_GCC_VERSION" \
  g++-"$INPUT_GCC_VERSION" \
  build-essential 

setfacl -d -Rm u:1000:rwx "$GITHUB_WORKSPACE"

set -eo

echo "Start: Setting Prerequisites"
cd "$GITHUB_WORKSPACE"
echo "Current directory: $(pwd)"

echo "Cloning into actions-collection..."
git clone -b v1 https://github.com/variant-inc/actions-collection.git ./actions-collection

echo "---Start: Pretest script"
chmod +x ./actions-collection/scripts/pre_test.sh
./actions-collection/scripts/pre_test.sh

export AWS_WEB_IDENTITY_TOKEN_FILE="/token"
echo "$AWS_WEB_IDENTITY_TOKEN" >> "$AWS_WEB_IDENTITY_TOKEN_FILE"

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:=us-east-1}"

export BRANCH_NAME="$GITVERSION_BRANCHNAME"
echo "Print Branch name: $BRANCH_NAME"

export GITHUB_USER="$GITHUB_REPOSITORY_OWNER"

echo "End: Setting Prerequisites"

echo "Start: Setting Conan Environment Variables"

if [ "$BRANCH_NAME" = "master" ]; then
  export CONAN_USERNAME="master"
  export CONAN_CHANNEL="stable"
else
  export CONAN_USERNAME="feature"
  export CONAN_CHANNEL="$GITVERSION_ESCAPEDBRANCHNAME"
fi

export CONAN_REVISIONS_ENABLED=1
export CONAN_PIP_COMMAND=pip3
export CONAN_UPLOAD=$INPUT_CONAN_URL
export CONAN_PASSWORD=$CONAN_KEY
export CC=/usr/bin/gcc-"$INPUT_GCC_VERSION"
export CXX=/usr/bin/g++-"$INPUT_GCC_VERSION"

echo "CONAN_REVISIONS_ENABLED: $CONAN_REVISIONS_ENABLED"
echo "CONAN_PIP_COMMAND: $CONAN_PIP_COMMAND"
echo "CONAN_UPLOAD: $CONAN_UPLOAD"
echo "CONAN_LOGIN_USERNAME: $CONAN_LOGIN_USERNAME"
echo "CONAN_USERNAME/CONAN_CHANNEL: $CONAN_USERNAME/$CONAN_CHANNEL"
echo "CC: $CC"
echo "CXX: $CXX"
echo "End: Setting Conan Environment Variables"

if [ -f "versions.txt" ]; then
    echo "Start: Update Versions.txt"
    sed -ie "s/SELF_VERSION=.*/SELF_VERSION=$GITVERSION_BUILDMETADATA/g" versions.txt 
    cat versions.txt
    echo "End: Update Versions.txt"
fi

echo "Start: Conan"
sh -c "/scripts/conan.sh"
echo "End: Conan"

echo "Start: Enable sonar"
pwsh ./actions-collection/scripts/enable_sonar.ps1
echo "End: Enable sonar"

echo "Start: Check sonar run"
skip_sonar_run=$(pwsh ./actions-collection/scripts/skip_sonar_run.ps1)
echo "Skip sonar run: $skip_sonar_run"
echo "End: Check sonar run"

if [ "$skip_sonar_run" != 'True' ]; then
  echo "Start: Coverage Scan"
  sh -c "/scripts/coverage_scan.sh"
  echo "End: Coverage Scan"
else
  echo "Skipping sonar run"
fi

echo "Conan Push: $INPUT_CONAN_PUSH_ENABLED"
if [ "$INPUT_CONAN_PUSH_ENABLED" = 'true' ]; then
  echo "Start: Conan Push"
  rm -rf build
  python3 package.py
  echo "End: Conan Push"
fi

echo "Container Push: $INPUT_CONTAINER_PUSH_ENABLED"
if [ "$INPUT_CONTAINER_PUSH_ENABLED" = 'true' ]; then
  echo "Start: Checking ECR Repo"
  ./actions-collection/scripts/ecr_create.sh "$INPUT_ECR_REPOSITORY"
  echo "End: Checking ECR Repo"
  echo "Start: Publish Image to ECR"
  ./actions-collection/scripts/publish.sh
  echo "End: Publish Image to ECR"
fi

echo "Start: Clean up"
git clean -fdx
echo "End: Clean up"