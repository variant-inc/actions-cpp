# common code and can be copied to any optimus project
import os
import platform
from typing import Dict

from conanutils import load_versions
from cpt.packager import ConanMultiPackager


class PackageUtil:
    versions: Dict

    def __init__(self) -> None:
        """
        Loads versions from versions.txt
        """
        self.versions = load_versions()

    def setup_linux(self, settings: dict):
        """
        Setup profile for Linux
        """
        settings["os"] = "Linux"
        settings["compiler"] = "gcc"
        settings["compiler.libcxx"] = "libstdc++11"

    def setup_mac(self, settings: dict):
        """
        Setup profile for Mac
        """
        settings["os"] = "Macos"
        settings["compiler"] = "apple-clang"
        settings["compiler.cppstd"] = "20"

    def setup(self, builder: ConanMultiPackager):
        """
        Sets release settings based on OS
        """
        release_settings = {"arch": "x86_64", "build_type": "Release"}
        os = platform.system()
        if os == "Darwin":
            self.setup_mac(release_settings)
        elif os == "Linux":
            self.setup_linux(release_settings)
        else:
            print("Not supported OS")

        debug_settings = release_settings.copy()
        debug_settings["build_type"] = "Debug"
        builder.add(release_settings, options={}, env_vars={}, build_requires={})
        builder.add(debug_settings, options={}, env_vars={}, build_requires={})

    # end of PackageUtil class


if __name__ == "__main__":
    """
    Conan Package with specific OS settings
    """
    package_util = PackageUtil()
    ver_ref = f'{os.environ.get("SONAR_PROJECT_KEY")}/{package_util.versions.get("SELF_VERSION")}'
    builder = ConanMultiPackager(reference=ver_ref)
    builder.build_policy = "missing"
    package_util.setup(builder)
    builder.run()
