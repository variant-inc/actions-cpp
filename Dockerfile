FROM openjdk:19-slim

ARG BUILD_DATE
ARG BUILD_REVISION
ARG BUILD_VERSION

LABEL com.github.actions.name="Lazy Action C++" \
  com.github.actions.description="Build and Push C++ Image" \
  com.github.actions.icon="code" \
  com.github.actions.color="red" \
  maintainer="Variant DevOps <devops@drivevariant.com>" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.revision=$BUILD_REVISION \
  org.opencontainers.image.version=$BUILD_VERSION \
  org.opencontainers.image.authors="Variant DevOps <devops@drivevariant.com>" \
  org.opencontainers.image.url="https://github.com/variant-inc/actions-cpp" \
  org.opencontainers.image.source="https://github.com/variant-inc/actions-cpp" \
  org.opencontainers.image.documentation="https://github.com/variant-inc/actions-cpp" \
  org.opencontainers.image.vendor="AWS ECR" \
  org.opencontainers.image.description="Build and Push C++ Packages"

ENV AWS_PAGER=""

# dockerfile_lint - ignore
RUN apt-get update &&\
  apt-get install \
  --no-install-recommends \
  --assume-yes \
  acl \
  git \
  wget \
  bash \
  curl \
  jq \
  unzip \
  python3-pip \
  python3-setuptools \
  gpg \
  lsb-release \
  libdevmapper1.02.1 &&\
  rm -rf matching cache rm /var/lib/apt/lists/*

# dockerfile_lint - ignore
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&\
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null &&\
  apt-get update &&\
  apt-get install \
  --no-install-recommends \
  --assume-yes \
  docker-ce-cli containerd.io &&\
  rm -rf matching cache rm /var/lib/apt/lists/*

ARG CMAKE_VERSION=3.21.0
ENV PATH="/usr/bin/cmake/bin:${PATH}"
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && mkdir /usr/bin/cmake \
      && /tmp/cmake-install.sh --skip-license --prefix=/usr/bin/cmake \
      && rm /tmp/cmake-install.sh

ARG SONAR_SCANNER_VERSION=4.6.1.2450
ENV PATH $PATH:/sonar-scanner/bin
RUN curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip \
  && unzip -o sonar-scanner.zip \
  && mv -v sonar-scanner-${SONAR_SCANNER_VERSION}-linux/ sonar-scanner  \
  && ln -s /sonar-scanner/bin/sonar-scanner       /usr/local/bin/     \
  && ln -s /sonar-scanner/bin/sonar-scanner-debug /usr/local/bin/ \
  && rm -f sonar-scanner-cli-*.zip

RUN curl -s -L https://sonarcloud.io/static/cpp/build-wrapper-linux-x86.zip -o sonarwrapper.zip \
  && unzip -qq sonarwrapper.zip \
  && rm -rf sonarwrapper.zip \
  && mv build-wrapper-linux-x86 build-wrapper
ENV PATH $PATH:/build-wrapper/

RUN python3 -m pip install --upgrade pip; \
    pip3 install conan; \
    pip3 install conan_package_tools;

COPY . /

RUN CONFIG_GCOV_KERNEL=y; \
    CONFIG_GCOV_PROFILE_ALL=y;

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN chmod +x -R /scripts/* /*.sh
ENTRYPOINT ["/entrypoint.sh"]
