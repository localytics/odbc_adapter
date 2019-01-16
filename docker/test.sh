#!/bin/bash

echo "Testing mysql" && CONN_STR='DRIVER=MySQL;SERVER=localhost;DATABASE=odbc_test;USER=root;PASSWORD=;' bundle exec rake && \
  echo "Testing postgres" && CONN_STR='DRIVER={PostgreSQL ANSI};SERVER=localhost;PORT=5432;DATABASE=odbc_test;UID=postgres;' bundle exec rake && \
  echo "Testing postgres utf8" && CONN_STR='DRIVER={PostgreSQL UNICODE};SERVER=localhost;PORT=5432;DATABASE=odbc_test;UID=postgres;ENCODING=utf8' bundle exec rake