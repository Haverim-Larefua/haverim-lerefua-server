#!/bin/bash

### MySql
docker run --name ffh-mysql -e MYSQL_ROOT_PASSWORD=root -d mysql:latest


### MySql workbench
mkdir -p config
docker run -dit --name=mysql-workbench --restart unless-stopped \
    -e PUID=1000 -e PGID=1000 -e TZ=Asia/Jerusalem \
    -p 3000:3000 -v $(pwd)/config:/config --cap-add="IPC_LOCK" lscr.io/linuxserver/mysql-workbench:latest
