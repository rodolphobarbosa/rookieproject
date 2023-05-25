#!/usr/bin/env bash

function select_retention_days {
  case "$1" in
    myproject-development*)
        retention_days=4
        ;;
    myproject-qa*)
        retention_days=2
        ;;
    myproject-staging*)
        retention_days=2
        ;;
    prod| \
    prod-t*| \
    prod-p*)
        retention_days=31
        ;;
    *)
      echo "Project invalid."
      read -p "Type the project_id: " project_name
      select_retention_days "$project_name"
      ;;
  esac
}

if [ -z "$1" ]; then
    read -p "Type the project_id: " project_name
else
    project_name=$1
fi

select_retention_days "$project_name"

SNAPSHOTS_LIST=$(gcloud compute snapshots list \
        --project="$project_name" \
        --filter="creationTimestamp < $(date -d "-$retention_days days" -u +%Y-%m-%dT%H:%M:%SZ)" \
        --format='json' | jq 'map(del(.selfLink, .labelFingerprint, .creationSizeBytes, .downloadBytes))')

echo "$SNAPSHOTS_LIST"

snapshots_with_storage_bytes=$(echo "$SNAPSHOTS_LIST" | jq '[.[] | {storageBytes: .storageBytes}]')

total_storage_bytes=$(echo "$SNAPSHOTS_LIST" | jq '[.[] | .storageBytes | tonumber] | add')

echo "Total snapshots above retention period: $(echo "$SNAPSHOTS_LIST" | jq length)"

echo "Total Storage bytes = $total_storage_bytes "
