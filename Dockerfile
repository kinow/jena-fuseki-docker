## Licensed to the Apache Software Foundation (ASF) under one or more
## contributor license agreements.  See the NOTICE file distributed with
## this work for additional information regarding copyright ownership.
## The ASF licenses this file to You under the Apache License, Version 2.0
## (the "License"); you may not use this file except in compliance with
## the License.  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
## 
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

## Apache Jena Fuseki server Dockerfile.

# Full, safe 
FROM openjdk:11

## Build using Alpine as the base.
##   The Fuseki server jar adds about 25M over the base.
##   Size difference of docker images is about 630M vs 370M.
## FROM openjdk:14-alpine
## RUN apk add --no-cache curl jemalloc

## Other size savings possible: slim down the JDK.
##   jdeps,jlink to refine the JDK saves space as well.
##   Beware included jars and especially any use of jemalloc (e.g. by RocksDB)
##   which alpine does not include by default.
##   https://github.com/jemalloc/jemalloc/issues/1443

LABEL maintainer="The Apache Jena community <users@jena.apache.org>"

ARG VERSION=3.14.0

## Where to get the bytes: Maven central.
##ARG REPO=https://repository.apache.org/content/repositories/releases
ARG REPO=https://repo1.maven.org/maven2
ARG JAR_ARTIFACT=jena-fuseki-server-${VERSION}.jar
ENV JAR_URL=$REPO/org/apache/jena/jena-fuseki-server/${VERSION}/${JAR_ARTIFACT}

# Name of jarfile to run. This does not have to be the same as JAR_ARTIFACT
ENV JAR_NAME=jena-fuseki-server-${VERSION}.jar

## ---- Download, with check it was intact using the sha1 checksum
ARG CHKSUM_EXT="sha1"
ARG CHKSUM_PROG=${CHKSUM_EXT}sum
ADD $JAR_URL /
ADD "$JAR_URL.$CHKSUM_EXT" /

## NB two spaces in sha1sum input - needed for alpine/busybox
RUN \
  CHKSUM="$(cut -d' ' -f1 ${JAR_ARTIFACT}.${CHKSUM_EXT})" && \
  echo "${CHKSUM}  $JAR_ARTIFACT" | ${CHKSUM_PROG} -c > /dev/null || { echo "BAD download!!!!" ; exit 1 ; } && \
  echo "Good download"
## ----

## Fuseki file area. Build time ARGs.
##   BASE: default /var/fuseki
##        Directory where the server will run.
##        Also the place for the server jar file
##
##   LIB: default $BASE/lib
##        Extra jars to add to the classpath (can be empty)
##
##   DATA: default $BASE/data
##       Directory for TDB databases. This can be a mounted volume.
##
##   LOG: default BASE/logs
##       Directory for server log files. This can be a mounted volume.

ARG BASE=/var/fuseki
ARG DATA=$BASE/data
ARG RUN=$BASE
ARG LOG=$BASE/log
ARG LIB=$BASE/lib

ENV FUSEKI_BASE=$BASE

COPY entrypoint.sh /

# Setup directories, put jar file in place.
RUN mkdir -p $BASE && \
    mkdir -p $LOG  && \
    mkdir -p $DATA && \
    mkdir -p $LIB  && \
    chmod a+x entrypoint.sh && \
    mv jena-fuseki-server-${VERSION}.jar $BASE/${JAR_NAME} && \
    rm jena-fuseki-server-${VERSION}.jar.${CHKSUM_EXT}

## External file space.
VOLUME $DATA
VOLUME $LOG
VOLUME $LIB

## Fixed - use -p (-publish) to map ports e.g. -p 8080:3030
EXPOSE 3030

# Place choices of "log4j.properties" in the build directory
# Ensure log destinations are filepaths within the docker container.
# e.g /var/fuseki/log/
COPY log4j.properties $BASE/log4j.properties

ARG JAVA_OPTIONS="-Xmx2048m -Xms2048m"
ENV \
    JAVA_HOME=${JAVA_MINIMAL} \
    JAVA_OPTIONS="${JAVA_OPTIONS}" \
    FUSEKI_BASE=${BASE}

WORKDIR $RUN

ENTRYPOINT [ "/entrypoint.sh" ]

## Command line arguments are those for Fuseki.
CMD []
