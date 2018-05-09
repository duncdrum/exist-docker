FROM openjdk:8-jdk-alpine as builder

LABEL maintainer="Duncan Paterson <d.paterson@me.com>" \
      org.label-schema.build-date="$(date --iso)" \
      org.label-schema.vcs-ref="$(git rev-parse --short HEAD)" \
      org.label-schema.vcs-url="https://github.com/duncdrum/exist-docker" \
      org.label-schema.schema-version="1.0"

ARG VCS_REF
ARG BUILD_DATE

# env for builder
ENV INSTALL_PATH /target

# Install tools required to build the project

RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY build.sh build.sh

RUN apk add --no-cache --virtual .build-deps \
        augeas \
        bash \
        curl \
        git \
        ttf-dejavu \
        && bash ./build.sh --minimal eXist develop \
        && rm -rf tmp \
        && apk del .build-deps


FROM gcr.io/distroless/java:latest

# Copy compiled exist-db files
COPY --from=builder /target/exist-minimal /exist
COPY --from=builder /target/conf.xml /exist/conf.xml

# Copy over dependancies for Apache FOP, which are lacking from gcr image

COPY --from=builder /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/libfontmanager.so /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/
COPY --from=builder /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/libjavalcms.so /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/
COPY --from=builder /usr/lib/liblcms2.so.2.0.8 /usr/lib/x86_64-linux-gnu/liblcms2.so.2
COPY --from=builder /usr/lib/libpng16.so.16.34.0 /usr/lib/x86_64-linux-gnu/libpng16.so.16
COPY --from=builder /usr/lib/libfreetype.so.6.15.0 /usr/lib/x86_64-linux-gnu/libfreetype.so.6



ENV LANG C.UTF-8

EXPOSE 8080
EXPOSE 8443

ENV EXIST_HOME=/exist
WORKDIR $EXIST_HOME
ENTRYPOINT ["java", "-Djava.awt.headless=true", "-jar", "start.jar", "jetty"]
