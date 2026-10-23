#!/bin/sh
# Edgebox updater - 2026-10-23 migration
# API 1.4.3 — PHP2Shell emergency fix (CVE-2026-109618 / CVE-2026-109619).
# The API now runs on PHP 8.3.36 which contains the official fix. The api-ws
# image is built locally on the box, so a git checkout alone is not enough:
# the image must be rebuilt on the patched base image and the container
# recreated. Docker downtime for the dashboard/API is ~1 minute while the
# container is recreated.

set -e

cd /home/system/components/ws

echo "[api-1.4.3] Rebuilding the api-ws image on the patched PHP 8.3.36 base..."
docker compose -f docker-compose.yml --project-name edgebox build api-ws

echo "[api-1.4.3] Recreating the api-ws container..."
docker compose -f docker-compose.yml --project-name edgebox up -d --no-deps api-ws

echo "[api-1.4.3] Clearing Symfony prod cache..."
docker exec edgebox-api-ws php bin/console cache:clear -e prod || true

echo "[api-1.4.3] Running PHP version: $(docker exec edgebox-api-ws php -v | head -n 1)"
