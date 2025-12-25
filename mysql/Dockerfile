FROM mysql:8.0

VOLUME /data

ENV MYSQL_ALLOW_EMPTY_PASSWORD=yes \
    MYSQL_DATABASE=cities

# Remove hardcoded credentials - use environment variables from Kubernetes
# MYSQL_USER and MYSQL_PASSWORD will be set by Helm deployment

# change datadir entry in /etc/mysql/my.cnf
COPY config.sh /root/
RUN /root/config.sh

COPY scripts/* /docker-entrypoint-initdb.d/


