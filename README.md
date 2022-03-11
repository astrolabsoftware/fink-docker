# Dockerfiles for Fink

This repository contains Dockerfiles used in the context of [Fink](https://github.com/astrolabsoftware/fink-broker).

## Available Dockerfiles

We mainly use these in the Continuous Integration of various repositories. We currently check all codes on 2 main OS: centos7 (production) and centos 9 stream (dev).

| | development | production |
|-|-----|------|
| OS | centos 9 stream| centos7|
| Spark | 3.1.3 | 2.4.7 |
| Hadoop | 3.2 | 2.7|
| Java |11 | 8|
| HBase | 2.4.10 | 2.2.7 |
| Kafka | 2.8.1 | 2.1.0 |

The production environment is currently in use at VirtualData, Université Paris-Saclay, to process the ZTF alert stream.

## Usage

```bash
./fink_docker -h
Build Dockerfile image for Fink

 Usage:
 ./fink_docker [--os] [--tag] [--build] [--run] [--deploy] [-h]

 Specify the name of a folder with a Dockerfile with the option --os.
 Use --build to build the image, with a tag (--tag).
 Use --run with a tag (--tag) to enter the container instead
 Use --deploy with a tag (--tag) to deploy it in the DockerHub.
 For the deployment, you need to have credentials defined.
 Use -h to display this help.
```

### Building an image

To build an image from a specific Dockerfile, use:

```bash
# e.g. build the prod image based on centos7
# and name it prod
./fink_docker --build --os centos7 --tag prod
```

The images are quite big because of dependencies:

|        | size |
|--------|------|
| centos7| 204MB|
| +system build dependencies|   822MB |
| +Apache Kafka, HBase and Spark|    1.94GB  |
| +Python dependencies|  3.62GB    |

Todo:
- [ ] Multi-stages build.
- [ ] Inspect better Python dependencies.

### Start a container

```bash
# Enter a container based on the prod image
./fink_docker --run --tag prod
```

Note that when starting a container, a script is launched to automatically start Apache HBase and Apache Kafka. Several environment variables are already defined inside the container (see each Dockerfile specifically).

### Deploy images

TBD

## Image availability

We have deployed images in DockerHub, than can be used easily:

TBD
