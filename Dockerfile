ARG XNAT_VERSION=1.7.6

FROM openjdk:8-jdk-slim as build

ARG XNAT_VERSION

RUN apt-get update && apt-get install -y \
    git

RUN cd /root \
  && git clone --depth 1 --branch "${XNAT_VERSION}" https://bitbucket.org/xnatdev/xnat-web

WORKDIR /root/xnat-web
RUN ./gradlew clean war

FROM tomcat:7-jdk8-openjdk-slim

ARG XNAT_VERSION

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

COPY --from=build "/root/xnat-web/build/libs/xnat-web-${XNAT_VERSION}.war" "${CATALINA_HOME}/webapps/ROOT.war"
RUN mkdir -p "${CATALINA_HOME}/webapps/ROOT" \
    && cd "${CATALINA_HOME}/webapps/ROOT" \
    && jar xf ../ROOT.war \
    && rm ../ROOT.war

RUN cd /data/xnat/home/plugins \
    && curl -sLO "https://github.com/brown-bnc/ldap-auth-plugin/releases/download/v1.0.1/xnat-ldap-auth-plugin-1.0.0.jar"

COPY ./docker-entrypoint.sh "${CATALINA_HOME}/bin/docker-entrypoint.sh"

ENV POSTGRES_HOST= POSTGRES_PORT=5432 POSTGRES_DB= POSTGRES_USER= POSTGRES_PASSWORD=
ENV LDAP_HOST= LDAP_USER= LDAP_PASSWORD= LDAP_SEARCH_BASE= LDAP_SEARCH_FILTER=
ENV XNAT_SITE_URL= XNAT_ADMIN_EMAIL=
ENV XNAT_SMTP_HOSTNAME= XNAT_SMTP_USER= XNAT_SMTP_PASSWORD= XNAT_SMTP_PORT= XNAT_SMTP_AUTH=true XNAT_SMTP_START_TLS=true

# NOTE (BNR): Ports have the following use:
#  8000 - Debug port, only used if debug is set to true
#  8080 - Web port, this is how users connect to XNAT
#  8104 - Scanner port, this is how the scanner connects to XNAT
EXPOSE 8000/tcp 8080/tcp 8104/tcp

ENTRYPOINT ["./bin/docker-entrypoint.sh"]
CMD ["run"]
