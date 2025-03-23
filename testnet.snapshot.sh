#!/bin/bash
set -x  

if [ $# -ne 2 ]; then
    echo "Usage: $0 <network> <node_type>"
    echo "Available options:"
    echo "  Network: heimdall, bor, erigon"
    echo "  Node type: mainnet, amoy"
    echo "Example: $0 bor mainnet"
    exit 1
fi

network=$1
node_type=$2

# URL da lista de snapshots
snapshot_list_url="https://snap.stakepool.work/snapshots-stakepool/list_snapshots.txt"

# Baixar e filtrar a lista de snapshots para o network e node_type especificados
relevant_snapshots=$(curl -s "$snapshot_list_url" | grep "$network-$node_type")

if [ -z "$relevant_snapshots" ]; then
    echo "❌ No snapshots found for $network - $node_type."
    exit 1
fi

# Encontrar o snapshot mais recente com base na data e hora
latest_snapshot=$(echo "$relevant_snapshots" | sort -k1,1r -k2,2r | head -n 1)

if [ -z "$latest_snapshot" ]; then
    echo "❌ Failed to determine the latest snapshot."
    exit 1
fi

# Extrair o nome do arquivo do snapshot mais recente
snapshot_file=$(echo "$latest_snapshot" | awk '{print $3}')

# Construir a URL completa do snapshot
url="https://snap.stakepool.work/snapshots-stakepool/$snapshot_file"

echo "Downloading and extracting the latest snapshot for $network - $node_type..."
echo "Snapshot URL: $url"

# Fazer o download e extrair o snapshot
wget -c --retry-connrefused --timeout=60 --read-timeout=120 --inet4-only "$url" -O - | dd bs=3G iflag=fullblock | zstdcat | tar -xf -

if [ $? -eq 0 ]; then
    echo "✅ Snapshot for $network - $node_type has been downloaded and extracted successfully!"
else
    echo "❌ Failed to download or extract the snapshot. Please check the URL and try again."
    exit 1
fi
