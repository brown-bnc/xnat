#-----------------------------------------------------------------------------
# BUILD
#   Build the XNAT web artifact from source
#-----------------------------------------------------------------------------
FROM openjdk:8-jdk-slim as build

# CAUTION: XNAT VERSION for this stage, make sure to also update next stage!!
ENV XNAT_VERSION=1.9.1.1
ENV JAVA_OPTS="-Xmx2560m -XX:+HeapDumpOnOutOfMemoryError"

RUN apt-get update && apt-get install -y \
    git

RUN cd /root \
  && git clone --branch "${XNAT_VERSION}" https://bitbucket.org/xnatdev/xnat-web

WORKDIR /root/xnat-web
RUN ./gradlew --no-daemon clean war

#-----------------------------------------------------------------------------
# APPLICATION
#   Runs the XNAT web application
#-----------------------------------------------------------------------------
FROM tomcat:9-jdk8-openjdk-slim

ENV XNAT_VERSION=1.9.1.1

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
    /data/xnat/home/config/auth \
    /data/xnat/home/logs \
    /data/xnat/home/plugins \
    /data/xnat/home/work \
    /data/xnat/inbox \
    /data/xnat/pipeline \
    /data/xnat/prearchive \
    /data/xnat/dicom-export

VOLUME ["/data/xnat/home/config", "/data/xnat/home/config/auth"]

COPY --from=build "/root/xnat-web/build/libs/xnat-web-${XNAT_VERSION}.war" "${CATALINA_HOME}/webapps/ROOT.war"
RUN mkdir -p "${CATALINA_HOME}/webapps/ROOT" \
    && cd "${CATALINA_HOME}/webapps/ROOT" \
    && jar xf ../ROOT.war \
    && rm ../ROOT.war

# Install LDAP and XSYNC plugins. The versions need to be compatible with the version of XNAT
RUN cd /data/xnat/home/plugins \
    && curl -fLO "https://bitbucket.org/xnatx/ldap-auth-plugin/downloads/ldap-auth-plugin-1.2.1.jar" \
    && curl -fLO "https://bitbucket.org/icrimaginginformatics/ohif-viewer-xnat-plugin/downloads/ohif-viewer-3.7.0-XNAT-1.8.10.jar" \
    && curl -fLO "https://bitbucket.org/xnatdev/dicom-query-retrieve/downloads/dicom-query-retrieve-2.1.0-xpl.jar"

    
COPY docker-entrypoint.sh "/usr/local/bin/docker-entrypoint.sh"

# NOTE (BNR): Ports have the following use:
#  8000 - Catalina debug port, only used if debug is set to true
#  8080 - Web port, this is how users connect to XNAT
#  8104 - Scanner port, this is how the scanner connects to XNAT
EXPOSE 8000/tcp 8080/tcp 8104/tcp
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["run"]
