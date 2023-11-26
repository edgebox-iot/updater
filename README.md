![Edgebox Logo Image](https://adm-listmonk.edgebox.io/uploads/logo_transparent_horizontal_300x100.png)
# updater

Update checks and migration scripts for the Edgebox system.
Curious about what the Edgebox is? Check out our [website](https://edgebox.io)!

## Installation

This repository should automatically be installed on the Edgebox system setup repository for the target Edgebox platform (`multipass-cofig`, `ua-netinst-config`, `image-builder`)
In this case, it will be located in `/home/system/components/updater`.

If you have a custom Edgebox setup, or one that does not yet contain this component, you can install this repository manually by running the following commands:
```bash
cd /home/system/components
git clone https://github.com/edgebox-iot/updater.git
```

## Usage

Make sure you run the following commands from the root of this repository.

### Update check

```bash
$ ./run.sh --check
```

This will check the current versions of each component, and fetch the next version of each component via git tags.
This will create the file `targets.env`, which contains the versions of each component to be updated to.

After running this command, you can then proceed to run the udpate command 👇

### Update

```bash
$ ./run.sh --update
```

This will update each component to the version specified in `targets.env`.
To generate the `targets.env` file, you must first run the update check command 👆
It will pull the target version tag from git, and run the migration script for each component version, if it exists in the `migrations` folder.

## Development

### Mocking current versions

To test the updated with custom current component versions, you can mock the current versions of each component by creating a file named `versions.env` in the root of this repository.
This file should contain the current version of each component, in the format `<COMPONENT_NAME>_VERSION=x.x.x`. In case this file does not exist, the updater will attempt to navigate to each target component folder and fetch the current version from the current checked out tag.

### Migration scripts

Migrations are bash scripts that are run for each component version. They are named after the component-version pair they correspond to, and are placed in the `migrations` folder.
These scripts are useful to update or install dependencies, or to run any other commands that are required to migrate to the next version of the component.
For example, the migration script for the `edgeboxctl` component, version `0.0.3` would be named `edgeboxctl-0.0.3.sh`.
