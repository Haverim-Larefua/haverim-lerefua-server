### GETTING STARTED ###

## PREREQUISITES ##

1. Install MySql Community Server
   Mac: https://dev.mysql.com/doc/refman/5.7/en/osx-installation-pkg.html

2. Install MySql Workbench
   https://www.mysql.com/products/workbench/
   Notes: 
   * use username root and password root (can be changed later)
   * Authentication method - select Use Legacy Authentication Method

3. Git clone the server project from:
   https://github.com/Haverim-Larefua/haverim-lerefua-server

4. Run 'npm install'

5. Adding data to DB:
   1. In case you did not use user 'root' and password 'root' when installing the database, your can run the following sql query to set it:
      ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
      COMMIT;
   2. Open the server project, and go to the path: haverim-lerefua-server/scripts/db-seed
   3. Copy the content of the file: all.sql
   4. Open MySql workbench and enter to localhost:3306
   5. Paste the content you copied, and run the SQL
   6. Enter again to database and verify that the tables where created with data

6. Run the project: 'npm run start'

7. Enter to swagger and verify it is working:
   http://localhost:3001/swagger/
   
## ERROR HANDLING ##
Error handling document can be found in the 'docs' folder
