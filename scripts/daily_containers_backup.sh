#!/bin/bash

BACKUP_DIR=/home/ffh_user/containers_backups

# Verify that the backup dir exists
if [ ! -d ${BACKUP_DIR} ]; then
    mkdir -p ${BACKUP_DIR}
fi


# Get inside that directory
cd ${BACKUP_DIR} || exit 1


# Go over the list of containers and back them up
docker ps -q | while read -r container_id ; do
    container_name=$(docker ps | grep ${container_id} | awk '{print $NF}')
    now=$(date "+%Y%m%d_%H%M%S")
    backup_name="${container_name}_${now}"
    
    echo ""
    echo "+----------------------"
    echo "| ${container_name}"
    echo "+----------------------"

    echo "Commit the container"
    docker commit -p ${container_id} img_${container_name}

    echo "Back it up"
    docker save -o ${backup_name}.tar img_${container_name}
    echo "ok."

    echo "Zip it"
    gzip ${backup_name}.tar
    echo "ok."

    echo ""
    echo ""
done


# Cleanup 
find . -type f -mtime +7 -delete
