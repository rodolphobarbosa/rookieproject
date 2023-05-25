#!/bin/bash

# Verifica se foi fornecido o nome do arquivo como argumento
if [ -z "$1" ]; then
    echo "Por favor, forneça o nome do arquivo JSON."
    exit 1
fi

# Nome do arquivo JSON
FILE_NAME=$1

# Verifica se o arquivo existe
if [ ! -f "$FILE_NAME" ]; then
    echo "O arquivo $FILE_NAME não existe."
    exit 1
fi

# Lê o arquivo JSON com a lista de snapshots
SNAPSHOTS_LIST=$(cat "$FILE_NAME" | jq 'map(del(.selfLink, .labelFingerprint, .creationSizeBytes, .downloadBytes))')

# Obtém os snapshots com os campos de storageBytes e storageLocations
snapshots_with_storage_bytes=$(echo "$SNAPSHOTS_LIST" | jq '[.[] | {storageBytes: .storageBytes, storageLocations: .storageLocations}]')

# Calcula o total de storageBytes
total_storage_bytes=$(echo "$snapshots_with_storage_bytes" | jq '[.[] | select(.storageBytes) | .storageBytes | tonumber] | add')

# Calcula a soma de storageBytes por zona
snapshots_sum_by_zone=$(echo "$SNAPSHOTS_LIST" | jq '[.[] | {zone: (.sourceDisk | split("/")[8]), storageBytes: .storageBytes}] | group_by(.zone) | map({zone: .[0].zone, totalStorageBytes: (map(.storageBytes | tonumber) | add)})')

# Obtém o número total de snapshots acima do período de retenção
total_snapshots=$(echo "$SNAPSHOTS_LIST" | jq length)

# Imprime as métricas
echo "Total snapshots above retention period: $total_snapshots"
echo "Total Storage bytes = $total_storage_bytes"
# echo "Snapshot storage by storageLocations:"
# echo "$snapshots_with_storage_bytes"
echo "Snapshot storage by zone:"
echo "$snapshots_sum_by_zone"
