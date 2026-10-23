# The version of XNAT to install
ARG XNAT_VERSION=1.10.2.1

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
# NOTE: As of 1.10.x XNAT is a monorepo on GitHub; bitbucket.org/xnatdev/xnat-web has no tags past 1.10.0
RUN git clone --depth 1 --branch "${XNAT_VERSION}" https://github.com/NrgXnat/xnat

# Build XNAT
WORKDIR /root/xnat
RUN ./gradlew --no-daemon :xnat-web:clean :xnat-web:war

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

# Install the OpenCV native library required by XNAT >= 1.10.2 (dcm4che JPEG-family codecs).
# Must be the exact 5.0.0-dcm build (OS-packaged OpenCV will not work); glibc only (no Alpine).
# /usr/java/packages/lib is on the JVM default java.library.path, so no -Djava.library.path is needed.
# See https://github.com/NrgXnat/xnat/blob/1.10.2/docs/installing-opencv-native.md
ARG TARGETARCH
ARG OPENCV_VERSION=5.0.0-dcm
ARG OPENCV_BASE=https://nrgxnat.jfrog.io/nrgxnat/libs-release/org/weasis/thirdparty/org/opencv/libopencv_java/${OPENCV_VERSION}
RUN set -eu; \
    case "${TARGETARCH}" in \
        amd64) classifier=linux-x86-64;  sha256=3552c806744192c734f6cf492bf95a139cbfd6f800ff662688d18b6a199f92f1 ;; \
        arm64) classifier=linux-aarch64; sha256=b07190e6ef6e233c2b7dc7f945c5b470be44450a49f9915aeaaa86f8799ef6a0 ;; \
        *) echo "No OpenCV native published for TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    mkdir -p /usr/java/packages/lib; \
    curl -fsSL --retry 3 -o /usr/java/packages/lib/libopencv_java.so \
        "${OPENCV_BASE}/libopencv_java-${OPENCV_VERSION}-${classifier}.so"; \
    echo "${sha256}  /usr/java/packages/lib/libopencv_java.so" | sha256sum -c -

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
COPY --from=build "/root/xnat/xnat-web/build/libs/xnat-web-${XNAT_VERSION}.war" \
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
    # TODO #30: Implement OIDC plugin
    # && curl -fLO "https://bitbucket.org/xnatx/openid-auth-plugin/downloads/openid-auth-plugin-1.5.0-xpl.jar" \
    # Imaging & Workflow Plugins
    && curl -fLO "https://xnat.org/files/ohif-viewer-xnat-plugin/ohif-viewer-3.8.0-fat.jar" \
    && curl -fLO "https://bitbucket.org/xnatdev/dicom-query-retrieve/downloads/dicom-query-retrieve-3.0.0-xpl.jar" \
    && curl -fLO "https://bitbucket.org/xnatx/pipeline_engine_plugin/downloads/pipeline_engine_ui-1.2.0-xpl.jar" \
    && curl -fLO "https://github.com/NrgXnat/container-service/releases/download/3.9.0/container-service-3.9.0-fat.jar" \
    && curl -fLO "https://github.com/NrgXnat/batch-transfer-plugin/releases/download/v1.1.1/batch-transfer-1.1.1.jar" \
    && curl -fLO "https://bitbucket.org/xnatx/xnatx-batch-launch-plugin/downloads/batch-launch-0.9.0-xpl.jar"


# NOTE (BNR): Ports have the following use:
#  8000 - Catalina debug port, only used if debug is set to true
#  8080 - Web port, this is how users connect to XNAT
#  8104 - Scanner port, this is how the scanner connects to XNAT
EXPOSE 8000/tcp 8080/tcp 8104/tcp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["run"]
