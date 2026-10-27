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
# Stock server.xml plus a RemoteIpValve so Tomcat honors X-Forwarded-Proto from the ingress.
# The file records the Tomcat version it was taken from; fail if the base image has another one.
COPY tomcat/server.xml "${CATALINA_HOME}/conf/server.xml"
RUN version="$(sed -n 's/.*TOMCAT_VERSION=\([0-9.]*\).*/\1/p' "${CATALINA_HOME}/conf/server.xml")"; \
    if [ "${version}" != "${TOMCAT_VERSION}" ]; then \
        echo "tomcat/server.xml is from Tomcat ${version:-<unknown>}, but the base image has ${TOMCAT_VERSION}." >&2; \
        echo "Refresh it from https://raw.githubusercontent.com/apache/tomcat/${TOMCAT_VERSION}/conf/server.xml" >&2; \
        echo "(see scripts/check-server-xml.sh) and update its TOMCAT_VERSION line." >&2; \
        exit 1; \
    fi

# Unpack WAR file for tomcat
RUN mkdir -p "${CATALINA_HOME}/webapps/ROOT" \
    && cd "${CATALINA_HOME}/webapps/ROOT" \
    && jar xf ../ROOT.war \
    && rm ../ROOT.war

# Install plugins
# !CAUTION: Ensure these versions are compatible with the current version of XNAT
# Every jar is verified against a pinned sha256. When bumping a plugin, update its checksum
# (GitHub shows it as the asset "digest"; for xnat.org downloads, hash the file yourself).
RUN set -eu; \
    cd /data/xnat/home/plugins; \
    fetch() { \
        curl -fsSLO --retry 3 "$1"; \
        echo "$2  $(basename "$1")" | sha256sum -c -; \
    }; \
    # Authentication Plugins
    fetch "https://github.com/NrgXnat/ldap-auth-plugin/releases/download/1.3.0/ldap-auth-plugin-1.3.0.jar" \
          94ad3396f71ac9c84c648658718f4a9c5fd5caba92e62ae54bac2c5993631eac; \
    # TODO #30: Implement OIDC plugin
    # fetch "https://github.com/NrgXnat/openid-auth-plugin/releases/download/<version>/openid-auth-plugin-<version>-xpl.jar" <sha256>; \
    # Imaging & Workflow Plugins
    fetch "https://xnat.org/files/ohif-viewer-xnat-plugin/ohif-viewer-3.8.0-fat.jar" \
          c8fa0b6f2f479dc1311dd7a3de6c5728b6bfb79dcc46a2f7e7e3929103f19f08; \
    fetch "https://github.com/NrgXnat/dicom-query-retrieve/releases/download/3.1.0/dicom-query-retrieve-3.1.0-xpl.jar" \
          1d657eaeb31200dfa4445cb90be15cc7609e41b395cf2a5040c6a4d3c912dcb1; \
    fetch "https://github.com/NrgXnat/pipeline-engine-plugin/releases/download/1.2.0/pipeline_engine_ui-1.2.0-xpl.jar" \
          21aedd6a94521dc2ce67d7ddd4154d4866ed142a80f45a78a2ae802f9fca34cb; \
    fetch "https://github.com/NrgXnat/container-service/releases/download/3.9.0/container-service-3.9.0-fat.jar" \
          809042a18dfea8383b7bd5f53b367eb8ea05c2a8c3f35b519841aa17b93cd207; \
    fetch "https://github.com/NrgXnat/batch-transfer-plugin/releases/download/v1.1.1/batch-transfer-1.1.1.jar" \
          8b583b1e0a71cbcfafec3cef14918f861184beae6001caf22db9dc3478f2c097; \
    fetch "https://github.com/NrgXnat/batch-launch-plugin/releases/download/0.9.0/batch-launch-0.9.0-xpl.jar" \
          3783f9f5e19db5d7a7c45c5e0314fe79ecf45ef4742baac27eec4dfa43533c6e


# NOTE (BNR): Ports have the following use:
#  8000 - Catalina debug port, only used if debug is set to true
#  8080 - Web port, this is how users connect to XNAT
#  8104 - Scanner port, this is how the scanner connects to XNAT
EXPOSE 8000/tcp 8080/tcp 8104/tcp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["run"]
