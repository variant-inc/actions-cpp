#!/bin/bash
set -euo pipefail

sonar_logout() {
  exit_code=$?
  echo "Exit code is $exit_code"
  if [ "$exit_code" -eq 0 ]; then
    echo -e "\e[1;32m ________________________________________________________________\e[0m"
    echo -e "\e[1;32m Quality Gate Passed.\e[0m"
    echo -e "\e[1;32m ________________________________________________________________\e[0m"
  elif [ "$exit_code" -gt 0 ]; then
    set -e
    echo -e "\e[1;31m ________________________________________________________________\e[0m"
    echo -e "\e[1;31m ________________________________________________________________\e[0m"
    echo ""
    echo ""
    echo -e "\e[1;31m Sonar Quality Gate failed in $SONAR_PROJECT_KEY.\e[0m"
    echo ""
    echo ""
    echo -e "\e[1;31m ________________________________________________________________\e[0m"
    echo -e "\e[1;31m ________________________________________________________________\e[0m"
    exit 1 
  fi
}

echo "===Cmake Coverage==="
cd build
cmake -G"Unix Makefiles" -DCODE_COVERAGE=ON ..
cmake --build . -j5
make test
cd ..
echo "Current directory: $(pwd)"
sh -c "/scripts/cov.sh"


wait_flag="false"
if [ "$BRANCH_NAME" == "master" ] || [ "$BRANCH_NAME" == "main" ]; then
  wait_flag="true"
fi

pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
export PULL_REQUEST_KEY=$pull_number

sonar_args="-Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.cfamily.build-wrapper-output=build_output \
            -Dsonar.cfamily.cache.enabled=false \
            -Dsonar.qualitygate.wait=$wait_flag"

trap "sonar_logout" EXIT

if [ "$PULL_REQUEST_KEY" = null ]; then
  echo "Sonar run when pull request key is null."
  eval "sonar-scanner $sonar_args -Dsonar.branch.name=$BRANCH_NAME"

else
  echo "Sonar run when pull request key is not null."
  eval "sonar-scanner $sonar_args -Dsonar.pullrequest.key=$PULL_REQUEST_KEY"
fi