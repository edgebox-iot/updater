# updater

Update checks and migration scripts for Edgebox

## Usage

### Update check

```bash
$ ./updater/run.sh --check
```

This will check the current versions of each component, and fetch the next version of each component via git tags.
This will create the file `targets.env`, which contains the versions of each component to be updated to.

After running this command, you can then proceed to run the udpate command 👇

### Update

```bash
$ ./updater/run.sh --update
```

This will update each component to the version specified in `targets.env`.
It will pull the target version tag from git, and run the migration script for each component version, if it exists in the `migrations` folder.

## Migrations

Migrations are bash scripts that are run for each component version. They are named after the component-version pair they correspond to, and are placed in the `migrations` folder.
These scripts are useful to update or install dependencies, or to run any other commands that are required to migrate to the next version of the component.
For example, the migration script for the `edgeboxctl` component, version `0.0.3` would be named `edgeboxctl-0.0.3.sh`.
