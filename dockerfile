FROM openjdk:8-jdk-alpine as builder

LABEL maintainer="Duncan Paterson <d.paterson@me.com>" \
      org.label-schema.build-date="$(date --iso)" \
      org.label-schema.vcs-ref="$(git rev-parse --short HEAD)" \
      org.label-schema.vcs-url="https://github.com/duncdrum/exist-db" \
      org.label-schema.schema-version="1.0"

ARG VCS_REF
ARG BUILD_DATE

# env for builder
# ENV EXIST_HOME /usr/local/eXist
# ENV EXIST_DATA_DIR webapp/WEB-INF/data
ENV INSTALL_PATH /target

# Install tools required to build the project

RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY build.sh build.sh
# COPY .env .env

RUN apk add --no-cache --virtual .build-deps \
        augeas \
        bash \
        curl \
        git \
        && bash ./build.sh --minimal eXist develop \
        && rm -rf tmp \
        && apk del .build-deps


FROM gcr.io/distroless/java:latest
COPY --from=builder /target/exist-minimal /exist
COPY --from=builder /target/conf.xml /exist/conf.xml

ENV LANG C.UTF-8

EXPOSE 8080
EXPOSE 8443

ENV EXIST_HOME=/exist
WORKDIR $EXIST_HOME
ENTRYPOINT ["java", "-Djava.awt.headless=true", "-jar", "start.jar", "jetty"]
