#!/bin/bash
set -e -x

# Installing mysql at startup due to file permissions: https://github.com/geerlingguy/drupal-vm/issues/1497
apt-get install -y mysql-server
bundle install --local
service mysql start

# Allows passwordless auth from command line and odbc
sed -i "s/local   all             postgres                                peer/local   all             postgres                                trust/" /etc/postgresql/9.4/main/pg_hba.conf
sed -i "s/host    all             all             127.0.0.1\/32            md5/host    all             all             127.0.0.1\/32            trust/" /etc/postgresql/9.4/main/pg_hba.conf
service postgresql start

odbcinst -i -d -f /usr/share/libmyodbc/odbcinst.ini
mysql -e "DROP DATABASE IF EXISTS odbc_test; CREATE DATABASE IF NOT EXISTS odbc_test;" -uroot
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';" -uroot

odbcinst -i -d -f /usr/share/psqlodbc/odbcinst.ini.template
psql -c "CREATE DATABASE odbc_test;" -U postgres

/bin/bash
