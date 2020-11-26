#!/bin/bash

echo ""
echo "+---------------------------------"
echo "| Here is the MOP you must follow:"
echo "+---------------------------------"
echo ""
echo ""
echo ""

echo "Temp password = [__PWD__]"
echo "1. docker exec -it __DOCKER_NAME__ mysql -uroot -p"
echo "    Enter the default password."
echo ""
echo ""
echo "In the MySQL prompt, run:"
echo "-------------------------"
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY 'ffh_P@ssw0rd';"
echo ""


# Run the scheme creation script
echo "source /var/tmp/all.sql"
echo ""


# Set the privileges to the 'ffh user'
echo "CREATE USER 'ffh_user'@'localhost' IDENTIFIED BY 'ffh_P@ssw0rd';"
echo "CREATE USER 'ffh_user'@'%' IDENTIFIED BY 'ffh_P@ssw0rd';"
echo "GRANT ALL PRIVILEGES ON *.* TO 'ffh_user'@'localhost';"
echo "ALTER USER 'ffh_user'@'%' IDENTIFIED WITH mysql_native_password BY 'ffh_P@ssw0rd';"
echo "GRANT ALL PRIVILEGES ON *.* TO 'ffh_user'@'%';"
echo "SHOW GRANTS FOR 'ffh_user'@'localhost';"
echo ""


# Exit from the MySQL prompt
echo "Exit"
echo ""

