#!/bin/sh
set -e
PROGNAME=$(basename $0)
die() {
    echo "$PROGNAME: $*" >&2
    exit 1
}

usage() {
    if [ "$*" != "" ] ; then
        echo "Error: $*"
    fi
    cat << EOF

Usage: $PROGNAME [OPTION ...] [foo] [bar]

-----------------------------------------------------------------
|  CLI tool for building and managing Edgebox updates           |
-----------------------------------------------------------------

Options:
-h, --help               display this usage message and exit
-c, --check              check for updates
-u, --update             update the system

EOF
    exit 1
}

# Update check. This function is called when the --check flag is passed
# It should check for updates by doing the following:
# 1. Open the file versions.env and read the current version for each component (ws, api, apps, logger, edgeboxctl)
# 2. Check in each component folder for the available git tags
# 3. If there is a newer (semver) tag than the one read from the file, save it to a variable
# 4. Write the new available next version to the versions.env file
check() {
    echo "Checking for updates..."

    # Remove the file targets.env if it exists
    if [ -f targets.env ]; then
        rm targets.env
    fi

    # Check for updates for each component
    for component in ws api apps logger edgeboxctl; do
        
        # Convert to uppercase
        component_upper=$(echo "$component" | tr '[:lower:]' '[:upper:]')

        # echo "Checking for updates for $component_upper..."

        # TODO: Get the current version from the checked out version, not from the versions.env file
        # Get the current version from the versions.env file
        current_version=$(grep -E "^${component_upper}_VERSION=" /home/system/components/updater/versions.env | cut -d '=' -f2)

        # echo "Current version: $current_version"
        
        cd /home/system/components/$component

        # echo "Available versions:"
        # git tag -l | sort -V

        # Get the latest version
        latest_version=$(git tag -l | sort -V | tail -1)
        # echo "Latest version: $latest_version"

        # Get the next version
        next_version=$(git tag -l | sort -V | grep -A1 "$current_version" | tail -1)

        # echo "Next version: $next_version"

        # If there is a next version, save it to the targets.env file
        if [ "$next_version" != "" ]; then
            echo "${component_upper}_VERSION=$next_version" >> /home/system/components/updater/targets.env
        fi

        echo "$component_upper -> Current: $current_version, Next: $next_version, Latest: $latest_version"

        cd /home/system
    done

    # If there are no updates, exit
    if [ ! -f targets.env ]; then
        echo "\nNo updates available"
        exit 0
    else
        echo "\nUpdates available:"
        cat /home/system/components/updater/targets.env
    fi
}

# Update the system. This function is called when the --update flag is passed
# It should do the following:
# 1. Open the file targets.env and read the next version for each component (ws, api, apps, logger, edgeboxctl)
# 2. Go to each component folder and checkout the next version
# 3. Run the update script for each component
# 4. Update the versions.env file with the new versions
update() {
    echo "Updating the system..."

    # Check if the targets.env file exists
    if [ ! -f targets.env ]; then
        echo "No updates available. Run ./run.sh --check to check for updates"
        exit 0
    fi

    # Update each component
    for component in ws api apps logger edgeboxctl; do
        # Get the next version from the targets.env file
        next_version=$(grep -E "^${component_upper}_VERSION=" /home/system/components/updater/targets.env | cut -d '=' -f2)

        # Go to the component folder
        cd /home/system/components/$component

        # Checkout the next version
        git checkout $next_version

        # Run the update migration for this component, if it exists
        if [ -f /home/system/components/$component/updater/migrations/$component-$next_version.sh ]; then
            echo "Running migration for $component $next_version"
            /home/system/components/$component/updater/migrations/$component-$next_version.sh
        fi

        cd /home/system
    done

    # Remove the targets.env file
    rm targets.env

    echo "Update complete"
}

while [ $# -gt 0 ] ; do
    case "$1" in
    -h|--help)
        usage
        ;;
    -c|--check)
        check
        ;;
    -u|--update)
        update
        ;;
    -*)
        usage "Unknown option '$1'"
        ;;
    *)
        break
        ;;
    esac
    shift
done

cat <<EOF

-----------------------
| Operation Completed. | 
-----------------------

EOF