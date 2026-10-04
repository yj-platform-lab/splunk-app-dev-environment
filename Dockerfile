FROM redhat/ubi9-init:9.5-1746009760

USER root

# Receive the app name from app.env at build time
ARG SPLUNK_APP_NAME
RUN test -n "$SPLUNK_APP_NAME"

# OS Python 3.14
RUN dnf install -y python3.14 python3.14-pip \
    && dnf clean all \
    && ln -sfn /usr/bin/python3.14 /usr/bin/python \
    && /usr/bin/python --version 

WORKDIR /tmp/build
COPY ./lab/requirements.txt ./lab/requirements-splunk-py313.txt ./

# Install OS Python dependencies and verify PyMySQL is available for Ansible MySQL modules.
RUN /usr/bin/python -m pip install --no-cache-dir -r requirements.txt \
    && /usr/bin/python3.14 -c 'import pymysql'

# Splunk Enterprise
COPY packages/splunk-10.4.3*.rpm /tmp/splunk/
RUN dnf install -y /tmp/splunk/*.rpm \
    && dnf clean all \
    && /opt/splunk/bin/python3.13 --version

# Set the destination based on the app name
COPY splunk-app/${SPLUNK_APP_NAME}/ /opt/splunk/etc/apps/${SPLUNK_APP_NAME}/

# Deployment of Python bundled with Splunk
RUN mkdir -p "/opt/splunk/etc/apps/${SPLUNK_APP_NAME}/bin/lib" \
    && /opt/splunk/bin/python3.13 -m pip install \
    --no-cache-dir \
    --target="/opt/splunk/etc/apps/${SPLUNK_APP_NAME}/bin/lib" -r requirements-splunk-py313.txt \
    && chown -R splunk:splunk "/opt/splunk/etc/apps/${SPLUNK_APP_NAME}/bin/lib"

# mysql 8.4.11
COPY packages/mysql-community-*.rpm /tmp/mysql/
RUN dnf install -y /tmp/mysql/mysql-community*.rpm \
    && dnf clean all \
    && mysqld --version

# Files used at container startup
COPY scripts/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*.sh

EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


