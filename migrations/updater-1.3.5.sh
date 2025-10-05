# Edgebox updater - 2024-12-94 migration
# This script is executed during the update process

# Go to the components folder
cd /home/system/components/

sudo apt-get update
sudo apt-get install docker-compose-v2 -y