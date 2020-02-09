### GETTING STARTED ###

## PREREQUISITES ##

1. Install MySql Community Server
   Mac: https://dev.mysql.com/doc/refman/5.7/en/osx-installation-pkg.html

2. Install MySql Workbench
   https://www.mysql.com/products/workbench/
   Note: use username root and password root (can be changed later)

3. Git clone the server project from:
   https://github.com/Haverim-Larefua/haverim-lerefua-server

4. Run 'npm install'

5. Adding data to DB:
   a. Open the server project, and go to the path: haverim-lerefua-server/scripts/db-seed
   b. Copy the content of the file: all.sql
   c. Open MySql workbench and enter to localhost:3306
   d. Paste the content you copied, and run the SQL
   e. Enter again to database and verify that the tables where created with data

6. Run the project: 'npm run start'

7. Enter to swagger and verify it is working:
   http://localhost:3001/swagger/
   
