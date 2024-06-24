# mapfs-release

This is a bosh release that packages
[mapfs](https://github.com/cloudfoundry/mapfs) used by volume drivers to map
gid/uid of file system operations at a given path.

## Usage

Collocate mapfs job onto diego cell via operations file
[add-mapfs.yml](operations/add-mapfs.yml). See [BOSH operations
file](https://bosh.io/docs/cli-ops-files/).

`mapfs` executable will be available at /var/vcap/packages/mapfs/bin/mapfs
