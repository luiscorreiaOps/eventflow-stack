#!/bin/bash

SERVICE="redecor_worker"

cleanup() {
    echo -e "\n\n[INFO] Parando"


    CONTAINERS=$(docker ps -q --filter "label=com.docker.swarm.service.name=$SERVICE")
    for CID in $CONTAINERS; do
        docker exec $CID pkill sha1sum > /dev/null 2>&1
    done
    exit
}

trap cleanup SIGINT SIGTERM

while true; do
    CONTAINERS=$(docker ps -q --filter "label=com.docker.swarm.service.name=$SERVICE")

    for CID in $CONTAINERS; do
        if ! docker exec $CID ps aux | grep -v grep | grep "sha1sum" > /dev/null; then
            echo "[STRESS]r: $CID"
            docker exec -d $CID bash -c "sha1sum /dev/zero"
        fi
    done

    sleep 2
done
