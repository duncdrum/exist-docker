[![Build Status](https://travis-ci.org/duncdrum/exist-docker.svg?branch=master)](https://travis-ci.org/duncdrum/exist-docker)

# WIP


### Modifying the compilation of eXist
To interact with the compilation of exist you can either modify the `build.sh` file in this directory, or if you prefer to work via docker stop the build process after the builder stage.

```bash
docker build --target builder .
```

You can now interact with the build as if it were a regular linux host, e.g.:

```bash
docker cp container_name:/target/conf.xml ./src
```
