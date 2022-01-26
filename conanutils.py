import os


def load_versions():
    """
    Load SELF_VERSIONS from versions.txt
    """
    versions = {}
    version_file = open(os.path.join(os.path.dirname(__file__), "versions.txt"), "r")
    for line in version_file.readlines():
        if line.isspace() or line[0] == "#":
            continue
        kv = line.split("=")
        versions[kv[0].strip()] = kv[1].strip()
    return versions
