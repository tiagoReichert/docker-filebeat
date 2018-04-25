FROM    alpine:3.3

# Here we use several hacks collected from https://github.com/gliderlabs/docker-alpine/issues/11:
# # 1. install GLibc (which is not the cleanest solution at all) 


# Build variables
ENV     FILEBEAT_VERSION 1.1.1
ENV     FILEBEAT_URL https://download.elastic.co/beats/filebeat/filebeat-${FILEBEAT_VERSION}-x86_64.tar.gz

# Environment variables
ENV     FILEBEAT_HOME /opt/filebeat-${FILEBEAT_VERSION}-x86_64
ENV     PATH $PATH:${FILEBEAT_HOME}

WORKDIR /opt/

RUN     apk add --update python curl && \
        apk add --allow-untrusted ./bin/glibc-2.21-r2.apk ./bin/glibc-bin-2.21-r2.apk && \
        /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib

RUN     curl -sL ${FILEBEAT_URL} | tar xz -C .
ADD     filebeat.yml ${FILEBEAT_HOME}/
ADD     docker-entrypoint.sh    /entrypoint.sh
RUN     chmod +x /entrypoint.sh

ENTRYPOINT  ["/entrypoint.sh"]
CMD         ["start"]
