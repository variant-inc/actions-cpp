# actions-cpp

Action for CI workflow for Cpp applications

- [actions-cpp](#actions-cpp)
  - [Prerequisites](#prerequisites)
    - [1. Setup GitHub action workflow](#1-setup-github-action-workflow)
    - [2. Add actions-setup](#2-add-actions-setup)
    - [3. Add actions-cpp](#3-add-actions-cpp)
    - [4. Add actions-octopus](#4-add-actions-octopus)
  - [Using Actions C++](#using-actions-c)
    - [Adding actions-cpp to workflow](#adding-actions-cpp-to-workflow)
    - [Input Parameters](#input-parameters)
    - [Additional files](#additional-files)
    - [Pre Test Script (optional)](#pre-test-script-optional)
      - [Example (actions-cpp)](#example-actions-cpp)

## Prerequisites

### 1. Setup GitHub action workflow

1. On GitHub, navigate to the main page of the repository.
2. Under your repository name, click Actions.
3. Find the template that matches the language and tooling you want to use, then click Set up this workflow. Either start with workflow or choose any integration workflows.

### 2. Add actions-setup

1. Add a code checkout step this will be needed to add code to the GitHub workspace.

    ```yaml
     - uses: actions/checkout@v2
       with:
         fetch-depth: 0
    ```

2. This is to add some global environment variables that are used as part of the python action. It will output `image_version`.

    ```yaml
     - name: Setup
       uses: variant-inc/actions-setup@v1
        id: actions-setup
    ```

Refer [actions-setup](https://github.com/variant-inc/actions-setup) for documentation.

### 3. Add actions-cpp

1. This step is to invoke the C++ action with release version by passing environment variables and input parameters. Input parameters section provides more insight of optional and required parameters. For C++ action, the image can be pushed to Jfrog with Conan and/or to ECR with docker.

    ```yaml
      - name: Actions Cpp
        id: actions-cpp
        uses: variant-inc/actions-cpp@v1
        with:
          conan_push_enabled: true
          conan_url: https://drivevariant.jfrog.io/artifactory/api/conan/cybertron-conan
          gcc_version: 9
          github_token: ${{ secrets.GITHUB_TOKEN }}
    ```

    ```yaml
      - name: Actions C++
        id: actions-cpp
        uses: variant-inc/actions-cpp@v1
        env:
          AWS_DEFAULT_REGION: us-east-1
        with:
          container_push_enabled: true
          dockerfile_dir_path: '.'
          ecr_repository: naveen-demo-app/demo-repo
          github_token: ${{ secrets.GITHUB_TOKEN }}
    ```

2. (Optionally) Add Script to run before running workflow.

    In `.github/actions`, add a file named `pre_test.sh` that will run any commands required for testing your codebase using this action. You will need to you a package manager supported by Debian Linux

    Example:

    ```bash
    apt-get install --no-cache \
      git \
      curl
    ```

### 4. Add actions-octopus

1. Adding octopus action will add ability to set up continuous delivery to octopus. This action can be invoked by action name and release version.

    ```yaml
     - name: Actions Octopus
       uses: variant-inc/actions-octopus@v2
       with:
         default_branch: ${{ env.MASTER_BRANCH }}
         deploy_scripts_path: deploy
         project_name: ${{ env.PROJECT_NAME }}
         version: ${{ steps.actions-setup.outputs.image-version }}
         space_name: ${{ env.OCTOPUS_SPACE_NAME }}
    ```

Refer [octopus action](https://github.com/variant-inc/actions-octopus) for documentation.

## Using Actions C++

You can set up continuous integration for your project using this workflow action.
After you set up CI, you can customize the workflow to meet your needs. By passing the right input parameters with the actions-cpp.

### Adding actions-cpp to workflow

Sample snippet to add actions-python to your workflow code.
See [action.yml](action.yml) for the full documentation for this action's inputs and outputs.

```yaml
jobs:
  build_test_scan:
    runs-on: eks
    name: CI Pipeline
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Actions Setup
        uses: variant-inc/actions-setup@v1
        id: actions-setup

      - name: Actions Cpp
        id: actions-cpp
        uses: variant-inc/actions-cpp@v1
        with:
          conan_push_enabled: true
          conan_url: https://drivevariant.jfrog.io/artifactory/api/conan/cybertron-conan
          gcc_version: 9

      - name: Actions Octopus
        uses: variant-inc/actions-octopus@v2
        with:
          default_branch: ${{ env.MASTER_BRANCH }}
          deploy_scripts_path: deploy
          project_name: ${{ env.PROJECT_NAME }}
          version: ${{ steps.actions-setup.outputs.image-version }}
          space_name: ${{ env.OCTOPUS_SPACE_NAME }}

```

### Input Parameters

| Parameter                | Default  | Description                           | Required |
| ------------------------ | -------- | ------------------------------------- | -------- |
| `dockerfile_dir_path`    | "."      | Directory path to the dockerfile      | false    |
| `ecr_repository`         |          | ECR Repository name                   | false    |
| `container_push_enabled` | "false"  | Enable build and push container image | false    |
| `conan_push_enabled`     | "false"  | Enable Build and Push with Conan"     | false    |
| `conan_url`              |          | URL for JFrog                         | false    |
| `gcc_version`            | "9"      | GCC and G++ Version                   | false    |
| `github_token`           |          | GitHub token provided by Workflow     | true     |

### Additional files

   1. `conanfile.py` or `conanfile.txt` (Required).

      Either `conanfile.py` or `conanfile.txt` is required for installing/consuming packages and its dependecies. This will specific to each repository and should be located in the root directory.

      `conanfile.py`

      ```python3
        from conans import ConanFile, CMake
        from conanutils import load_versions
        import os
        class MirageConan(ConanFile):
            name = "mirage"
            version = ""
            settings = "os", "compiler", "build_type", "arch"
            license="Variant"
            description="Mirage is our HOS & ETA validator"
            options = {"shared": [True, False], "fPIC": [True, False]}
            default_options = {"shared": False, "fPIC": True}
            generators = "cmake"
            exports_sources = "src/*"
            exports = "versions.txt","conanutils.py"
            reference = name +"/" 
            versions = {}

            def __init__(self, output, runner, display_name="", user=None, channel=None):
                self.versions =load_versions()
                super().__init__(output, runner, display_name=display_name, user=user, channel=channel)
                        
            def set_version(self):    
                self.version = str(self.versions.get("SELF_VERSION"))
                self.reference=self.reference+self.version

            def config_options(self):
                if self.settings.os == "Windows":
                    del self.options.fPIC

            def requirements(self):
                self.requires(self.versions.get("ENERGON_VERSION"))

            def build(self):
                cmake = CMake(self)
                cmake.configure(source_folder="src")
                cmake.build()

            def package(self):
                self.copy("*.hpp", dst="include", src="src")
                self.copy("*.lib", dst="lib", keep_path=False)
                if self.settings.os == "Windows":                       
                    self.copy("*.dll", dst="bin", keep_path=False)
                    self.copy("*.dylib*", dst="lib", keep_path=False)
                else:
                    self.copy("*.so", dst="lib", keep_path=False)
                    self.copy("*.a", dst="lib", keep_path=False)

            def package_info(self):
                self.cpp_info.libs = ["mirage"]
      ```

      conanfile.txt

      ```python3
        [requires]
        boost/1.77.0
        energon/0.1.0@master/stable
        mirage/0.1.0@master/stable

        [generators]
        cmake_find_package
        cmake
      ```

   2. Profiles Folder

      Folder in root directory to specify the conan profiles for development. Only `{root}/profiles/linux_release` is required. Example shown below.

       ```yaml
       [settings]
       os=Linux
       arch=x86_64
       build_type=Release
       compiler=gcc
       compiler.version=9
       compiler.libcxx=libstdc++11
       [options]
       [env]
       [build_requires]
       ```

   3. versions.txt

      SELF_VERSION will be replaced in entrypoint.sh by the runner build number

      ```yaml
      # energon version
      SELF_VERSION=0.1.0


      #dependent package versions
      ENERGON_VERSION=energon/0.1.0@master/stable
      BOOST_VERSION=boost/1.77.0@
      ```

   4. CMakeLists.txt (optioinal)
       File for development to build C++ packages.

       ```bash
       #top level CMakeLists file which is not used by conan, but for development.
       set(CMAKE_CXX_STANDARD 20)
       cmake_minimum_required(VERSION 3.20)
       project(main CXX)
       set(CMAKE_BUILD_TYPE Debug)
       add_subdirectory(src)
       add_subdirectory(unit_test)
       file(COPY unit_test/data DESTINATION ${CMAKE_BINARY_DIR}/unit_test)
       include(CTest)
       add_test(NAME test COMMAND tests
               WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/unit_test/bin)
       ```

### Pre Test Script (optional)

When using actions-python create a file in .github/actions/pre_test.sh.

Include any dependant packages your app requires when testing. These packages will need to be installed using a Debian package manager.

#### Example (actions-cpp)

```bash
#!/bin/bash

echo "____INSTALLING_SVN_____"
apt-get install --no-install-recommends -y \
  subversion

echo "____INSTALLING_PWSH_____"
wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get install -y powershell
```
