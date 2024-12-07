# Edgebox updater - 2024-12-94 migration
# This script is executed during the update process

# Go to the components folder
cd /home/system/components/

# Clone the browser dev module from the repository
git clone https://github.com/edgebox-iot/dev.git || true

# Go to the dev component folder
cd dev