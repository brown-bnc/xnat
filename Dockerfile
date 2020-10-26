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

RUN mkdir -p "${CATALINA_HOME}/webapps/ROOT" \
    && cd "${CATALINA_HOME}/webapps/ROOT" \
    && curl -Lo ROOT.war "https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VERSION}.war" \
    && jar xf ROOT.war \
    && rm ROOT.war

RUN cd /data/xnat/home/plugins \
    && curl -LO "https://github.com/brown-bnc/ldap-auth-plugin/releases/download/v1.0.1/xnat-ldap-auth-plugin-1.0.0.jar"

COPY ./docker-entrypoint.sh "${CATALINA_HOME}/bin/docker-entrypoint.sh"

ENV POSTGRES_HOST= POSTGRES_PORT=5432 POSTGRES_DB= POSTGRES_USER= POSTGRES_PASSWORD=
ENV LDAP_HOST= LDAP_USER= LDAP_PASSWORD= LDAP_SEARCH_BASE= LDAP_SEARCH_FILTER=
ENV XNAT_SITE_URL= XNAT_ADMIN_EMAIL=
ENV XNAT_SMTP_HOSTNAME= XNAT_SMTP_USER= XNAT_SMTP_PASSWORD= XNAT_SMTP_PORT= XNAT_SMTP_AUTH=true XNAT_SMTP_START_TLS=true

EXPOSE 8000/tcp 8080/tcp 8104/tcp

ENTRYPOINT ["./bin/docker-entrypoint.sh"]
CMD ["run"]
