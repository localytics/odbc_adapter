FROM ruby:2.4.0
MAINTAINER data@localytics.com

ENV    DEBIAN_FRONTEND noninteractive
RUN echo "deb http://deb.debian.org/debian/ jessie main" > /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian/ jessie main" >> /etc/apt/sources.list
RUN echo "deb http://security.debian.org/ jessie/updates main" >> /etc/apt/sources.list
RUN echo "deb-src http://security.debian.org/ jessie/updates main" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y install libnss3-tools unixodbc-dev libmyodbc mysql-client odbc-postgresql  postgresql

WORKDIR /workspace
CMD docker/docker-entrypoint.sh
