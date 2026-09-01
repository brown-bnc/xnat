ARG XNAT_VERSION=1.10.0

###################################################################################################
### BUILD
### Build the XNAT web artifact from source
###################################################################################################
FROM eclipse-temurin:21-jdk AS build

ARG XNAT_VERSION
ENV JAVA_OPTS="-Xmx2560m -XX:+HeapDumpOnOutOfMemoryError"

# Clone the XNAT repository
RUN apt-get update && apt-get install -y git
WORKDIR /root
RUN git clone --branch "${XNAT_VERSION}" https://bitbucket.org/xnatdev/xnat-web

# Build XNAT
WORKDIR /root/xnat-web
RUN ./gradlew --no-daemon clean war

###################################################################################################
### APPLICATION
### Runs the XNAT web application
###################################################################################################
FROM tomcat:9-jdk21-temurin

ARG XNAT_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    libfreetype6 \
    fontconfig \
    fonts-dejavu-core \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create data directories
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

# Copy built files
COPY --from=build "/root/xnat-web/build/libs/xnat-web-${XNAT_VERSION}.war" \
    "${CATALINA_HOME}/webapps/ROOT.war"
# Copy local files
COPY docker-entrypoint.sh "/usr/local/bin/docker-entrypoint.sh"

# Unpack WAR file for tomcat
RUN mkdir -p "${CATALINA_HOME}/webapps/ROOT" \
    && cd "${CATALINA_HOME}/webapps/ROOT" \
    && jar xf ../ROOT.war \
    && rm ../ROOT.war

# Install plugins
# !CAUTION: Ensure these versions are compatible with the current version of XNAT
RUN cd /data/xnat/home/plugins \
    # Authentication Plugins
    && curl -fLO "https://bitbucket.org/xnatx/ldap-auth-plugin/downloads/ldap-auth-plugin-1.3.0.jar" \
    && curl -fLO "https://bitbucket.org/xnatx/openid-auth-plugin/downloads/openid-auth-plugin-1.5.0-xpl.jar" \
    # XSYNC Plugins
    && curl -fLO "https://xnat.org/files/ohif-viewer-xnat-plugin/ohif-viewer-3.8.0-fat.jar" \
    && curl -fLO "https://bitbucket.org/xnatdev/dicom-query-retrieve/downloads/dicom-query-retrieve-3.0.0-xpl.jar" \
    && curl -fLO "https://bitbucket.org/xnatx/pipeline_engine_plugin/downloads/pipeline_engine_ui-1.2.0-xpl.jar" \
    && curl -fLO "https://bitbucket.org/xnatdev/container-service/downloads/container-service-3.8.1-fat.jar" \
    && curl -fLO "https://github.com/NrgXnat/batch-transfer-plugin/releases/download/v1.1.1/batch-transfer-1.1.1.jar"

# Ports have the following use:
#  8000 - Catalina debug port, only used if debug is set to true
#  8080 - Web port, this is how users connect to XNAT
#  8104 - Scanner port, this is how the scanner connects to XNAT
EXPOSE 8000/tcp 8080/tcp 8104/tcp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["run"]
