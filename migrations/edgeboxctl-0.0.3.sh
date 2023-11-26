# Edgebox updater - 2023-11-25 migration
# This script is executed during the update process

# Update / install sshx
curl -sSf https://sshx.io/get | sh

# Go to the edgeboxctl component folder
cd /home/system/components/edgeboxctl

# Build the edgeboxctl binary and install it
# TODO: Build for architecture and flavour
make build-cloud

# Start the edgeboxctl service
systemctl start edgeboxctl