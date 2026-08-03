#!/bin/bash
set -euo pipefail

REGISTRY="https://docker.cleanerp.com"
USERNAME="admin"
PASSWORD="DockerHard@123,,."
KEEP=10

echo "Finding repositories..."

repos=$(find /opt/registry/docker/registry/v2/repositories \
    -mindepth 1 -maxdepth 1 \
    -type d \
    -printf "%f\n")

for repo in $repos; do
    echo "========================================"
    echo "Repository: $repo"

    TAG_DIR="/opt/registry/docker/registry/v2/repositories/$repo/_manifests/tags"

    [ -d "$TAG_DIR" ] || continue

    tags=$(ls "$TAG_DIR" | grep -E '^[0-9]+$' | sort -n)

    total=$(echo "$tags" | wc -l)

    if [ "$total" -le "$KEEP" ]; then
        echo "Keeping all ($total tags)"
        continue
    fi

    delete_tags=$(echo "$tags" | head -n $((total-KEEP)))

    for tag in $delete_tags; do

        echo "Deleting $repo:$tag"

        digest=$(curl -sI \
            -u "$USERNAME:$PASSWORD" \
            -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
            "$REGISTRY/v2/$repo/manifests/$tag" \
            | awk '/Docker-Content-Digest:/ {print $2}' \
            | tr -d '\r')

        if [ -z "$digest" ]; then
            echo "Unable to resolve digest for $repo:$tag"
            continue
        fi

        curl -s -X DELETE \
            -u "$USERNAME:$PASSWORD" \
            "$REGISTRY/v2/$repo/manifests/$digest"

    done
done

echo "Running garbage collection..."

docker exec cleanerp-registry registry garbage-collect /etc/docker/registry/config.yml

echo "Done."