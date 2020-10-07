FROM tomcat:7-jdk8-openjdk-slim

ARG XNAT_VERSION=1.7.6

RUN apt-get update && apt-get install -y \
    curl \
    unzip

RUN mkdir -p /data/xnat/{archive,build,cache,ftp,home,inbox,pipeline,prearchive,dicom-export} \
    && mkdir -p /data/xnat/home/{config,logs,plugins,work}

RUN cd "${CATALINA_HOME}/webapps" \
    && curl -L -o ROOT.war "https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VERSION}.war"

COPY ./docker-entrypoint.sh "${CATALINA_HOME}/bin/docker-entrypoint.sh"

EXPOSE 8000/tcp 8080/tcp 8104/tcp

ENTRYPOINT ["./bin/docker-entrypoint.sh"]
CMD ["run"]
