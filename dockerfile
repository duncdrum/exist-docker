FROM openjdk:8-jdk-alpine as builder

LABEL maintainer="Duncan Paterson <d.paterson@me.com>" \
      org.label-schema.build-date="$(date --iso)" \
      org.label-schema.vcs-ref="$(git rev-parse --short HEAD)" \
      org.label-schema.vcs-url="https://github.com/duncdrum/exist-docker" \
      org.label-schema.schema-version="1.0"

# arguments can be referenced at build time …
ARG BRANCH=develop
ARG MAX_MEM=2048
ARG CACHE_MEM=256
ARG DATA_DIR=webapp/WEB-INF/data

# … but also in here.
ENV BRANCH ${BRANCH}
ENV MAX_MEM ${MAX_MEM}
ENV CACHE_MEM ${CACHE_MEM}
ENV DATA_DIR ${DATA_DIR}

# ENV for builder
ENV INSTALL_PATH /target

# Install tools required to build the project

RUN mkdir -p ${INSTALL_PATH}
WORKDIR ${INSTALL_PATH}
COPY build.sh build.sh

RUN apk add --no-cache --virtual .build-deps \
        augeas \
        bash \
        curl \
        git \
        ttf-dejavu \
        && bash ./build.sh --minimal eXist ${BRANCH} \
        && rm -rf tmp \
        && apk del .build-deps


FROM gcr.io/distroless/java:latest

ENV EXIST_HOME /exist
WORKDIR ${EXIST_HOME}

# Copy compiled exist-db files
COPY --from=builder /target/exist-minimal .
COPY --from=builder /target/conf.xml ./conf.xml

# Copy over dependancies for Apache FOP, which are lacking from gcr image

COPY --from=builder /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/libfontmanager.so /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/
COPY --from=builder /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/libjavalcms.so /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/
COPY --from=builder /usr/lib/liblcms2.so.2.0.8 /usr/lib/x86_64-linux-gnu/liblcms2.so.2
COPY --from=builder /usr/lib/libpng16.so.16.34.0 /usr/lib/x86_64-linux-gnu/libpng16.so.16
COPY --from=builder /usr/lib/libfreetype.so.6.15.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6

# does not seem to stick
ENV LANG C.UTF-8

# Port configuration
EXPOSE 8080
EXPOSE 8443

ENTRYPOINT ["java", "-Djava.awt.headless=true", "-jar", "start.jar", "jetty"]
