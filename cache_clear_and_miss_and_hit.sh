#!/bin/bash

FILES=("sample-15s.mp3" "sample-12s.mp3" "sample-9s.mp3" "sample-6s.mp3" "sample-3s.mp3")
EDGES=(8081 8082 8083)
VOLUMES=("cdn-project_edge1_cache" "cdn-project_edge2_cache" "cdn-project_edge3_cache")

# Stop all containers
docker stop $(docker ps -q) 2>/dev/null
docker rm -f $(docker ps -aq) 2>/dev/null

# Remove cache volumes
for v in "${VOLUMES[@]}"; do
    if docker volume ls --format "{{.Name}}" | grep -q "$v"; then
        echo "Removing volume $v..."
        docker volume rm -f "$v"
    fi
done

# Start CDN containers
docker-compose up -d
sleep 3  # wait for containers to be ready

# Function to request file and print TTFB, total, and X-Cache-Status
request_file() {
    local file=$1
    local port=$2
    echo "--- Edge on port $port ---"
    URL="http://localhost:$port/audio/$file"

    # Get headers
    headers=$(curl -s -D - -o /dev/null $URL)
    cache_status=$(echo "$headers" | grep -i "X-Cache-Status" | awk '{print $2}' | tr -d '\r')
    
    # Measure times
    times=$(curl -s -o /dev/null -w "TTFB: %{time_starttransfer}s | Total: %{time_total}s" $URL)

    echo "$times | X-Cache-Status: $cache_status"
}

echo "==== First run: should show MISS ===="
for file in "${FILES[@]}"; do
    echo "=== File: $file ==="
    for port in "${EDGES[@]}"; do
        request_file $file $port
    done
    echo ""
done

sleep 1

echo "==== Second run: should show HIT ===="
for file in "${FILES[@]}"; do
    echo "=== File: $file ==="
    for port in "${EDGES[@]}"; do
        request_file $file $port
    done
    echo ""
done

