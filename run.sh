#!/bin/sh
set -e
PROGNAME=$(basename $0)

SCRIPT_PATH="$0"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH")"
SCRIPT_DIR="$(cd -P "$(dirname -- "$SCRIPT_PATH")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

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
    # Remove the file targets.env if it exists
    if [ -f $SCRIPT_DIR/targets.env ]; then
        rm $SCRIPT_DIR/targets.env
    fi

    # Check for updates for each component
    for component in ws api apps logger edgeboxctl; do
        
        # Convert to uppercase
        component_upper=$(echo "$component" | tr '[:lower:]' '[:upper:]')

        # echo "Checking for updates for $component_upper..."
        cd $PARENT_DIR/$component
        git pull > /dev/null 2>&1 || true

        # Check if versions.env file exists
        if [ ! -f $SCRIPT_DIR/versions.env ]; then
            # Try to get the current version from the git tags
            current_version=$(git describe --tags --exact-match 2>/dev/null || true)
        else
            current_version=$(grep -E "^${component_upper}_VERSION=" $SCRIPT_DIR/versions.env | cut -d '=' -f2)
        fi        

        # echo "Current version: $current_version"
        
        # echo "Available versions:"
        # git tag -l | sort -V

        # Get the latest version
        latest_version=$(git tag -l | sort -V | tail -1)
        # echo "Latest version: $latest_version"

        # Get the next version
        next_version=$(git tag -l | sort -V | grep -A1 "$current_version" | tail -1)

        # echo "Next version: $next_version"

        # If there is a current version, do further checks
        if [ "$current_version" != "" ]; then
            # If the current version is the latest version, there are no updates
            if [ "$current_version" = "$latest_version" ]; then
                next_version=""
            fi

             # If there is a next version (next version is not empty or is different from current version), save it to the targets.env file
            if [ "$next_version" != "" ]; then
                echo "${component_upper}_VERSION=$next_version" >> $SCRIPT_DIR/targets.env
            fi
        fi

        echo "$component_upper -> Current: $current_version, Next: $next_version, Latest: $latest_version"

    done

    # If there are no updates, exit
    if [ ! -f $SCRIPT_DIR/targets.env ]; then
        echo "\nNo updates available"
    else
        echo "\nUpdates available:"
        cat $SCRIPT_DIR/targets.env
    fi
}

# Update the system. This function is called when the --update flag is passed
# It should do the following:
# 1. Open the file targets.env and read the next version for each component (ws, api, apps, logger, edgeboxctl)
# 2. Go to each component folder and checkout the next version
# 3. Run the update script for each component
# 4. Update the versions.env file with the new versions
update() {
    
    # Check if the targets.env file exists
    if [ ! -f $SCRIPT_DIR/targets.env ]; then
        echo "No updates available. Run ./run.sh --check to check for updates"
        exit 0
    fi

    # Update each component
    for component in ws api apps logger dev edgeboxctl updater; do

        component_upper=$(echo "$component" | tr '[:lower:]' '[:upper:]')
        # Get the next version from the targets.env file
        next_version=$(grep -E "^${component_upper}_VERSION=" $SCRIPT_DIR/targets.env | cut -d '=' -f2)

        if [ "$next_version" != "" ]; then

            echo "Updating $component to version $next_version"

            # Go to the component folder
            cd $PARENT_DIR/$component

            # Checkout the next version
            git checkout $next_version

            # Run the update migration for this component, if it exists
            if [ -f $SCRIPT_DIR/migrations/$component-$next_version.sh ]; then
                echo "Running migration for $component $next_version"
                $SCRIPT_DIR/migrations/$component-$next_version.sh
            fi

            # If the component is "edgeboxctl", update the edgeboxctl binary
            if [ "$component" = "edgeboxctl" ]; then

                arch=$(uname -m)
                echo "Installing edgeboxctl $arch binary for version $next_version"
                make install-$arch
            
            fi
                
            cd $PARENT_DIR
        else
            echo "Skipping $component due to no next version target"
        fi
    done

    # Remove the targets.env file
    rm $SCRIPT_DIR/targets.env
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