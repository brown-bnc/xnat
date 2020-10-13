FROM tomcat:7-jdk8-openjdk-slim

ARG XNAT_VERSION=1.7.6

RUN apt-get update && apt-get install -y \
    curl \
    unzip

RUN mkdir -p \
    /data/xnat/archive \
    /data/xnat/build \
    /data/xnat/cache \
    /data/xnat/ftp \
    /data/xnat/home \
    /data/xnat/home/config \
    /data/xnat/home/logs \
    /data/xnat/home/plugins \
    /data/xnat/home/work \
    /data/xnat/inbox \
    /data/xnat/pipeline \
    /data/xnat/prearchive \
    /data/xnat/dicom-export

RUN cd "${CATALINA_HOME}/webapps" \
    && curl -L -o ROOT.war "https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VERSION}.war"

COPY ./docker-entrypoint.sh "${CATALINA_HOME}/bin/docker-entrypoint.sh"
COPY ./xnat-conf.properties.template /data/xnat/home/config/xnat-conf.properties

ENV POSTGRES_HOST= POSTGRES_PORT=5432 POSTGRES_DB= POSTGRES_USER= POSTGRES_PASSWORD=

EXPOSE 8000/tcp 8080/tcp 8104/tcp

ENTRYPOINT ["./bin/docker-entrypoint.sh"]
CMD ["run"]
