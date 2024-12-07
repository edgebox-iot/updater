# Edgebox updater - 2024-12-94 migration
# This script is executed during the update process

# Go to the components folder
cd /home/system/components/

# Clone the browser dev module from the repository
git clone https://github.com/edgebox-iot/dev.git || true

# Find which is the latest release to checkout
cd dev || exit

latest_version=$(git tag | sort -V | tail -n 1) || true
git checkout $latest_version || true