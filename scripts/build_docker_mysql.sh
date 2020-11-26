#!/bin/bash +x



### Global variables
docker_name=ffh_mysql
db_pwd='ffh_P@ssw0rd'



### Clean-up
containers=$(docker ps -a | grep ${docker_name} | wc -l)
if [ ${containers} -eq 1 ]; then
    echo "Clean-up"
    docker rm -f ${docker_name}
fi



### Create the docker image.
echo ""
echo "Create the docker image."
docker create --net=host --name ${docker_name} -e DB_USERNAME=ffh_user -e DB_PASSWORD=${db_pwd} mysql/mysql-server:latest



### Copy the scheme creation scriptץ
init_script=scripts/db-seed/all.sql
if [ -e "${init_script}" ]; then
    docker cp ${init_script} ${docker_name}:/var/tmp/all.sql
    if [ $? != 0 ]; then
        echo "Cannot copy the init script (${init_script}) into the '${docker_name}' docker."
        exit 3
    fi
else
    echo "Cannot find the init script (${init_script})."
    exit 2
fi



### Set the new password for 'root'
docker start ${docker_name}
echo "Wait 30 seconds for the docker to load"
echo ""
sleep 30



### Get the default root password.
temp_password=$(docker logs ${docker_name} 2>&1 | grep GENERATED | awk '{print $NF}')



### Generate the MOP file.
sed -e "s/__PWD__/${temp_password}/" -e "s/__DOCKER_NAME__/${docker_name}/" scripts/mop.tmpl.sh > mop.sh



### Print the MOP to the log
/bin/sh mop.sh


